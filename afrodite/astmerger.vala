/* astmerger.vala
 *
 * Copyright (C) 2009  Andrea Del Signore
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Andrea Del Signore <sejerpz@tin.it>
 */

using GLib;
using Vala;

namespace Afrodite
{
	public class AstMerger : CodeVisitor
	{
		Afrodite.Symbol _current = null;
		Afrodite.DataType _current_type = null;
		Afrodite.SourceReference _current_sr = null;
		Afrodite.SourceFile _source_file = null;
		Afrodite.DataType _inferred_type = null;
		Vala.Literal _last_literal = null;
		
		string _vala_symbol_fqn = null;
		bool _merge_glib = true;
		int _child_count = 0;
		
		private Afrodite.Ast _ast = null;
		
		public AstMerger (Afrodite.Ast ast)
		{
			this._ast = ast;
		}

		public void merge_vala_context (Vala.SourceFile source, CodeContext context, bool merge_glib = false)
		{
			_merge_glib = merge_glib;
			_vala_symbol_fqn = null;
			_current_type = null;
			_child_count = 0;
			_current = _ast.root;
			if (_ast.lookup_source_file (source.filename) != null)
				critical ("two sources %s!", source.filename);
			
			//debug ("COMPLETING FILE %s", source.filename);
			
			_source_file = _ast.add_source_file (source.filename);
			foreach (UsingDirective u in source.current_using_directives) {
				_source_file.add_using_directive (u.namespace_symbol.name);
			}
			context.root.accept_children (this);
		}

		public void remove_source_filename (string filename)
		{
			var source = _ast.lookup_source_file (filename);
			if (source == null) {
				warning ("remove_source: file not found %s", filename);
			}
			if (source.has_symbols) {
				foreach (Symbol symbol in source.symbols) {
					remove_symbol (source, symbol);
				}
				source.symbols = null;
			}
			_ast.remove_source (source);
		}

		private bool remove_symbol (SourceFile source, Symbol symbol)
		{
			bool orphaned = false;
			bool removed = false;
			
			if (symbol.has_source_references) {
				var source_ref = symbol.lookup_source_reference_filename (source.filename);
				if (source_ref != null) {
					symbol.remove_source_reference (source_ref);
					// only orphan a symbol if we removed something and there isn't no more source refs
					orphaned = !symbol.has_source_references; 
				}
			}

			// leave glib symbols, or symbols with references in other source files
			if (symbol.has_children) {
				Vala.List<Symbol> to_del = new Vala.ArrayList<Symbol> ();
				
				foreach (Symbol child in symbol.children) {
					if (remove_symbol (source, child)) {
						to_del.add (child);
					}
				}
				
				foreach (Symbol child in to_del) {
					symbol.remove_child (child);
				}
			}
			
			if (orphaned) {
				// the symbol should be deleted since there aren't any source ref
				if (symbol.has_children && symbol.type_name == "Namespace") {
					// there are still children and the symbol is "mergeable" I can't delete it
					// I reparent the symbol to the first valid source of the first child node
					SourceReference source_ref = null;

					foreach (Symbol child in symbol.children) {
						if (child.has_source_references) {
							source_ref = child.source_references.get(0);
							break;
						}
					}

					if (source_ref != null) {
						source_ref.file.add_symbol (symbol);
						if (symbol.lookup_source_reference_filename (source_ref.file.filename) == null)
							symbol.add_source_reference (source_ref);
					} else {
						critical ("no valid source reference in child for orphaned symbol %s", symbol.name);
					}
				} else {
					// orphaned without child, let's destroy it
					if (!symbol.has_children && orphaned) {
						removed = true;
						if (symbol.has_resolve_targets) {
							foreach (Symbol target in symbol.resolve_targets) {
								// remove from return type
								if (target.return_type != null && target.return_type.symbol == symbol) {
									target.return_type.symbol = null;
								}
								// remove from parameters
								if (target.has_parameters) {
									foreach (DataType type in target.parameters) {
										if (type.symbol == symbol) {
											type.symbol = null;
										}
									}
								}
				
								// remove from local_variables
								if (target.has_local_variables) {
									foreach (DataType type in target.local_variables) {
										if (type.symbol == symbol) {
											type.symbol = null;
										}
									}
								}
								symbol.resolve_targets = null;
							}
						}
					}
				}
			}
			return removed;
		}

		private Afrodite.Symbol visit_symbol (Vala.Symbol s, out Afrodite.SourceReference source_reference, bool replace = false)
		{
			Afrodite.Symbol symbol;
			Afrodite.Symbol parent;
			
			set_fqn (s.name);
			symbol = _ast.lookup (_vala_symbol_fqn, out parent);

			assert (parent != null);
			if (symbol == null) {
				symbol = add_symbol (s, out source_reference);
				parent.add_child (symbol);
			} else if (replace) {
				parent.remove_child (symbol);
				symbol = add_symbol (s, out source_reference);
				parent.add_child (symbol);
			} else if (!replace) {
				// add one more source reference to the symbol
				source_reference = symbol.lookup_source_reference_filename (_source_file.filename);
				if (source_reference == null)	{
					source_reference = create_source_reference (s);
					symbol.add_source_reference (source_reference);
					_source_file.add_symbol (symbol);
				} else {
					warning ("two sources with the same name were merged: %s", _source_file.filename);
				}
			}

			return symbol;
		}
		
		private Afrodite.Symbol add_symbol (Vala.Symbol s, out Afrodite.SourceReference source_ref, int last_line = 0, int last_column = 0)
		{
			var symbol = new Afrodite.Symbol (_vala_symbol_fqn, s.type_name);
			if (symbol.lookup_source_reference_filename (_source_file.filename) == null) {
				source_ref = create_source_reference (s, last_line, last_column);
				symbol.add_source_reference (source_ref);
			}
			symbol.access = get_vala_symbol_access (s.access);
			_source_file.add_symbol (symbol);
			return symbol;
		}

		private Afrodite.Symbol add_codenode (string type_name, Vala.CodeNode c, out Afrodite.SourceReference source_ref, int last_line = 0, int last_column = 0)
		{
			var symbol = new Afrodite.Symbol (_vala_symbol_fqn, type_name);
			if (symbol.lookup_source_reference_filename (_source_file.filename) == null) {
				source_ref = create_source_reference (c, last_line, last_column);
				symbol.add_source_reference (source_ref);
			}
			symbol.access = Afrodite.SymbolAccessibility.PRIVATE;
			_source_file.add_symbol (symbol);
			return symbol;
		}
		
		private Afrodite.SymbolAccessibility get_vala_symbol_access (Vala.SymbolAccessibility access)
		{
			switch (access) {
				case Vala.SymbolAccessibility.PRIVATE:
					return Afrodite.SymbolAccessibility.PRIVATE;
				case Vala.SymbolAccessibility.INTERNAL:
					return Afrodite.SymbolAccessibility.INTERNAL;
				case Vala.SymbolAccessibility.PROTECTED:
					return Afrodite.SymbolAccessibility.PROTECTED;
				case Vala.SymbolAccessibility.PUBLIC:
					return Afrodite.SymbolAccessibility.PUBLIC;
				default:
					warning ("Unknown vala symbol accessibility constant");
					return Afrodite.SymbolAccessibility.INTERNAL;
			}
		}

		private Afrodite.MemberBinding get_vala_member_binding (global::MemberBinding binding)
		{
			switch (binding) {
				case global::MemberBinding.INSTANCE:
					return Afrodite.MemberBinding.INSTANCE;
				case global::MemberBinding.CLASS:
					return Afrodite.MemberBinding.CLASS;
				case global::MemberBinding.STATIC:
					return Afrodite.MemberBinding.STATIC;
				default:
					warning ("Unknown vala member binding constant");
					return Afrodite.MemberBinding.INSTANCE;
			}
		}
		
		private Afrodite.SourceReference create_source_reference (Vala.CodeNode s, int last_line = 0, int last_column = 0)
		{
			var source_ref = new Afrodite.SourceReference ();
			source_ref.file = _source_file;
			int first_line = 0;
			int first_column = 0;
			
			if (s.source_reference != null) {
				first_line = s.source_reference.first_line;
				first_column = s.source_reference.first_column;
				if (last_line == 0)
					last_line = s.source_reference.last_line;
				if (last_column == 0)
					last_column = s.source_reference.last_column;
			}
			source_ref.first_line = first_line;
			source_ref.first_column = first_column;
			source_ref.last_line = last_line;
			source_ref.last_column = last_column;
			
			return source_ref;
		}

		private void set_fqn (string name)
		{
			if (_vala_symbol_fqn == null) {
				_vala_symbol_fqn = name;
			} else {
				_vala_symbol_fqn = _vala_symbol_fqn.concat (".", name);
			}
		}
		
		public bool is_symbol_defined_current_source (Vala.Symbol? sym)
		{
			return sym.source_reference.file.filename == _source_file.filename;
		}

		public override void visit_namespace (Namespace ns) 
		{
			if ((_merge_glib && ns.name == "GLib")
			    || (ns.name != "GLib")) {// && is_symbol_defined_current_source (ns))) {
				var prev_vala_fqn = _vala_symbol_fqn;
				var prev = _current;
				var prev_sr = _current_sr;
				var prev_child_count = _child_count;
				
				_current = visit_symbol (ns, out _current_sr);
				ns.accept_children (this);
				
				// if the symbol isn't defined in this source file
				// and I haven't added any child from this source file
				// remove my source reference.
				if (!is_symbol_defined_current_source (ns) && _child_count == prev_child_count) {
					//debug ("sourcereference removing sr: %s to %s", _current_sr.file.filename, _vala_symbol_fqn);
					_current.remove_source_reference (_current_sr);
					if (!_current.has_source_references) {
						Afrodite.Symbol parent;
						_ast.lookup (_vala_symbol_fqn, out parent);
						parent.remove_child (_current);
					}
				} //else {
					//debug ("sourcereference added: %s to %s", _current_sr.file.filename, _vala_symbol_fqn);
				//}
				
				_child_count = prev_child_count;
				_current = prev;
				_current_sr = prev_sr;
				_vala_symbol_fqn = prev_vala_fqn;
			}
		}
		
		public override void visit_class (Class c)
		{
			if (!is_symbol_defined_current_source (c))
				return;
			
			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			_current = visit_symbol (c, out _current_sr, true); // class are not mergeable like namespaces
			_current.is_abstract = c.is_abstract;
			c.accept_children (this);
			// TODO: add a GLib.Type base type to non compact classes
			// this is the code but with this type the completion list is messier
			//if (!c.is_compact && !_current.has_base_types) {
			//	_current.add_base_type (new Afrodite.DataType("GLib.Type", "Type"));
			//}

			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_struct (Struct s)
		{
			if (!is_symbol_defined_current_source (s))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			_current = visit_symbol (s, out _current_sr, true); // class are not mergeable like namespaces
			s.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_interface (Interface iface)
		{
			if (!is_symbol_defined_current_source (iface))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;

			_current = visit_symbol (iface, out _current_sr, true); // class are not mergeable like namespaces
			iface.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_expression_statement (Vala.ExpressionStatement e)
		{
			e.accept_children (this);
		}
		
		public override void visit_method_call (Vala.MethodCall c)
		{
			//Utils.trace ("visit method call: %s", c.call.type_name);
			c.accept_children (this);
		}
		
		public override void visit_method (Method m)
		{
			if (!is_symbol_defined_current_source (m))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (m.name);
			int last_line = 0;
			if (m.body != null && m.body.source_reference != null)
				last_line = m.body.source_reference.last_line;
				
			var s = add_symbol (m, out _current_sr, last_line);
			s.return_type = new DataType (m.return_type.to_string ());
			s.is_abstract = m.is_abstract;
			s.is_virtual = m.is_virtual;
			s.overrides = m.overrides;
			s.binding =  get_vala_member_binding (m.binding);
			_current.add_child (s);
			
			_current = s;
			visit_type_for_generics (m.return_type, s.return_type);
			m.accept_children (this);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}

		public override void visit_creation_method (CreationMethod m)
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;

			set_fqn (m.name);
			int last_line = 0;
			if (m.body != null && m.body.source_reference != null)
				last_line = m.body.source_reference.last_line;
				
			var s = add_symbol (m, out _current_sr, last_line);
			if (m.name == ".new")
				s.return_type = new DataType (m.return_type.to_string ());
			else {
				// creation method
				s.return_type = new DataType (m.parent_symbol.get_full_name ());
			}
			s.is_abstract = m.is_abstract;
			s.is_virtual = m.is_virtual;
			s.overrides = m.overrides;
			if (m.name == ".new") {
				s.display_name = m.class_name;
			} else {
				s.display_name = "%s.%s".printf (m.class_name, m.name);
			}
			s.binding =  get_vala_member_binding (m.binding);
			_current.add_child (s);
			
			_current = s;
			visit_type_for_generics (m.return_type, s.return_type);
			m.accept_children (this);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_constructor (Constructor m)
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn ("constructor:%s".printf(_current.fully_qualified_name));
			int last_line = 0;
			if (m.body != null && m.body.source_reference != null)
				last_line = m.body.source_reference.last_line;
				
			var s = add_symbol (m, out _current_sr, last_line);
			s.binding =  get_vala_member_binding (m.binding);
			s.return_type = new DataType (_current.fully_qualified_name);
			_current.add_child (s);
			
			_current = s;
			m.accept_children (this);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_destructor (Destructor m)
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn ("destructor:%s".printf(_current.fully_qualified_name));
			int last_line = 0;
			if (m.body != null && m.body.source_reference != null)
				last_line = m.body.source_reference.last_line;
				
			var s = add_symbol (m, out _current_sr, last_line);
			s.binding =  get_vala_member_binding (m.binding);
			s.display_name = "~%s".printf (s.name);
			_current.add_child (s);
			 
			_current = s;
			m.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_enum_value (Vala.EnumValue ev) 
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (ev.name);
			var sym = add_symbol (ev, out _current_sr);
			sym.access = _current.access;
			_current.add_child (sym);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_enum (Vala.Enum e) 
		{
			if (!is_symbol_defined_current_source (e))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (e.name);
			var s = add_symbol (e, out _current_sr);
			_current.add_child (s);
			_current = s;
			e.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_delegate (Delegate d) 
		{
			if (!is_symbol_defined_current_source (d))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (d.name);
			var sym = add_symbol (d, out _current_sr);
			_current.add_child (sym);
			_current = sym;
			d.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}

	       	public override void visit_signal (Vala.Signal s) 
		{
			if (!is_symbol_defined_current_source (s))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (s.name);
			var sym = add_symbol (s, out _current_sr);
			sym.return_type = new DataType (s.return_type.to_string ());
			sym.is_virtual = s.is_virtual;
			_current.add_child (sym);
			_current = sym;
			s.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_field (Field f) 
		{
			if (!is_symbol_defined_current_source (f))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			
			set_fqn (f.name);
			var s = add_symbol (f, out _current_sr);
			s.return_type = new DataType (get_datatype_typename (f.variable_type));
			
			s.binding =  get_vala_member_binding (f.binding);
			_current.add_child (s);
			_current = s;
			visit_type_for_generics (f.variable_type, s.return_type);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}

		public override void visit_constant (Vala.Constant c) 
		{
			if (!is_symbol_defined_current_source (c))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (c.name);
			var s = add_symbol (c, out _current_sr);
			s.return_type = new DataType (c.type_reference.to_string ());
			_current.add_child (s);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
	
		public override void visit_property (Property p) 
		{
			if (!is_symbol_defined_current_source (p))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (p.name);
			var s = add_symbol (p, out _current_sr);
			s.return_type = new DataType (p.property_type.to_string ());
			_current.add_child (s);
			
			_current = s;
			visit_type_for_generics (p.property_type, s.return_type);
			p.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
	
		public override void visit_property_accessor (PropertyAccessor a)
		{
			this.visit_scoped_codenode (a.readable ? "get" : "set", a, a.body);
			/*
			var prev = _current;
			var prev_sr = _current_sr;
			
			if (a.body != null 
			    && a.body.source_reference != null
			    && a.body.source_reference.last_line > _current_sr.last_line) {
				_current_sr.last_line = a.body.source_reference.last_line;
			}
			
			a.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;*/
		}
		
		public override void visit_error_domain (ErrorDomain ed)
		{
			if (!is_symbol_defined_current_source (ed))
				return;

			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
						
			set_fqn (ed.name);
			var s = add_symbol (ed, out _current_sr);
			_current.add_child (s);
			
			_current = s;
			ed.accept_children (this);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_error_code (ErrorCode ecode) 
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (ecode.name);
			var s = add_symbol (ecode, out _current_sr);
			s.access = _current.access;
			_current.add_child (s);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_formal_parameter (FormalParameter p) 
		{
			DataType d;
			
			if (p.ellipsis) {
				d = Symbol.ELLIPSIS;
			} else {
				d = new DataType (get_datatype_typename (p.variable_type), p.name);
				switch (p.direction) {
					case Vala.ParameterDirection.OUT:
						d.is_out = true;
						break;
					case Vala.ParameterDirection.REF:
						d.is_ref = true;
						break;
				}
			}
			_current.add_parameter (d);
		}

		public override void visit_block (Block b) 
		{
			if (_current != null && _current_sr != null) {
				// see if this block extends a parent symbol
				if (b.source_reference != null && b.source_reference.last_line > _current_sr.last_line) {
					_current_sr.last_line = b.source_reference.last_line;
				}
			}
			b.accept_children (this);
		}
		
		public override void visit_local_variable (LocalVariable local) 
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			
			set_fqn (local.name);
			DataType s = new DataType ("", local.name);
			if (local.variable_type != null) {
				s.type_name = get_datatype_typename (local.variable_type);
			} else if (local.variable_type == null && local.initializer != null) {
				// try to resolve local variable type from initializers
				var prev_inferred_type = _inferred_type;
				_inferred_type = s;
				//Utils.trace ("infer from init '%s': %s", s.name, local.initializer.type_name);
				
				if (local.initializer is ObjectCreationExpression) {
					//debug ("START: initialization %s from %s: %s", local.name, s.name, _inferred_type.type_name);
					var obj_initializer = (ObjectCreationExpression) local.initializer;
					obj_initializer.member_name.accept (this); 
					//debug ("END: initialization done %s", _inferred_type.type_name);
				} else if (local.initializer is MethodCall) {
					//Utils.trace ("method call: %s", s.name);
 					((MethodCall) local.initializer).call.accept (this); // this avoid visit parameters of method calls
 				} else if (local.initializer is BinaryExpression) {
 					((BinaryExpression) local.initializer).accept_children (this);
 				} else if (local.initializer is CastExpression) {
 					var cast_expr = (CastExpression)local.initializer;
					cast_expr.accept (this);
 					if (cast_expr.type_reference != null)
 					{
	 					s.type_name = get_datatype_typename (cast_expr.type_reference);
 					}
 				} else if (local.initializer is ArrayCreationExpression) {
 					//Utils.trace ("ArrayCreationExpression infer from init '%s' %s", s.name, local.initializer.type_name);
 					var ac = (ArrayCreationExpression) local.initializer; 
 					ac.accept_children (this);
 					s.is_array = true;
 					s.type_name = get_datatype_typename (ac.element_type);
					//Utils.trace ("init type %s: %s %s", local.name, s.type_name, ac.element_type.type_name);
				} else {
					local.accept_children (this);
				}
				_last_literal = null;
				//debug ("infer from init done %s", _inferred_type.type_name);
				_inferred_type = prev_inferred_type;
				
				
				if (s.type_name != null && s.type_name.has_suffix ("Literal")) {
					if (s.type_name == "ValaIntegerLiteral") {
						s.type_name = "int";
					} else if (s.type_name == "ValaBooleanLiteral") {
						s.type_name = "bool";
					} else if (s.type_name == "ValaCharacterLiteral") {
						s.type_name = "char";
					} else if (s.type_name == "ValaStringLiteral") {
						s.type_name = "string";
					} else if (s.type_name == "ValaRealLiteral") {
						s.type_name = "double";
					}
				}
			}
			
			s.source_reference = this.create_source_reference (local);
			if (_current.has_local_variables) {
				 var old_var = _current.lookup_local_variable (s.name);
				 if (old_var != null) {
				 	//Utils.trace ("replacing local var: %s", s.name);
				 	_current.remove_local_variable (old_var);
				 }
			}
			//Utils.trace ("adding local var: %s to %s", s.name, _current.fully_qualified_name);
			_current.add_local_variable (s);
			if (local.variable_type != null)
				visit_type_for_generics (local.variable_type,s);
			_current = prev;
			_vala_symbol_fqn = prev_vala_fqn;
		}

		public override void visit_lambda_expression (LambdaExpression expr)
		{
			//debug ("visit lambda called");
			visit_scoped_codenode ("lambda-section", expr, null);
			//expr.accept_children (this);
		}

		public override void visit_member_access (MemberAccess expr) 
		{
			if (_inferred_type == null)
				return;
			
			//Utils.trace ("visit member access %s: %s", _inferred_type.type_name, expr.member_name);
			if (_inferred_type.type_name == null || _inferred_type.type_name == "")
				_inferred_type.type_name = expr.member_name;
			else {
				string member_name = null;
				// lookup in the scope variables
				if (_current != null) {
					DataType d = _current.scope_lookup_datatype_for_variable (CompareMode.EXACT, expr.member_name);
					if (d != null) {
						member_name = d.type_name;
					}
				}
				
				// if not found assume that is a static type
				if (member_name == null)
					member_name = expr.member_name;
				_inferred_type.type_name = "%s.%s".printf (member_name, _inferred_type.type_name);
			}
		}
		
		public override void visit_object_creation_expression (ObjectCreationExpression expr) 
		{
			if (_inferred_type == null)
				return;

			expr.member_name.accept_children (this);
		}
		
		public override void visit_expression (Expression expr) 
		{
			//debug ("visit expression %p, %s", expr, expr.type_name);
			expr.accept_children (this);
		}

		public override void visit_initializer_list (InitializerList list) 
		{
			//debug ("vidit init list");
			list.accept_children (this);
		}
	
		public override void visit_binary_expression (BinaryExpression expr) 
		{
			//debug ("vidit binary expr %p", expr);
			expr.accept_children (this);
		}
		
		public override void visit_boolean_literal (BooleanLiteral lit) 
		{
			if (_inferred_type == null)
				return;
			
			if (_inferred_type.type_name == null || _inferred_type.type_name == "")
				_inferred_type.type_name = "bool";
			else  if (_inferred_type.type_name != "bool")
				_inferred_type.type_name = "%s.%s".printf ("bool", _inferred_type.type_name);
		}


		public override void visit_character_literal (CharacterLiteral lit) 
		{
			if (_inferred_type == null)
				return;
				
			if (_inferred_type.type_name == null || _inferred_type.type_name == "")
				_inferred_type.type_name = "char";
			else if (_inferred_type.type_name != "char")
				_inferred_type.type_name = "%s.%s".printf ("char", _inferred_type.type_name);
		}

		public override void visit_integer_literal (IntegerLiteral lit) 
		{
			if (_inferred_type == null)
				return;

			if (_inferred_type.type_name == null || _inferred_type.type_name == "")
				_inferred_type.type_name = lit.type_name;
			else if (_inferred_type.type_name != lit.type_name)
				_inferred_type.type_name = "%s.%s".printf (lit.type_name, _inferred_type.type_name);
		}

		public override void visit_real_literal (RealLiteral lit) 
		{
			if (_inferred_type == null)
				return;
			if (_inferred_type.type_name == null || _inferred_type.type_name == "")
				_inferred_type.type_name = lit.get_type_name ();
			else if (_inferred_type.type_name != lit.get_type_name ())
				_inferred_type.type_name = "%s.%s".printf (lit.get_type_name (), _inferred_type.type_name);
		}

		public override void visit_string_literal (StringLiteral lit) 
		{
			if (_inferred_type == null)
				return;
			
			if (_inferred_type.type_name == null || _inferred_type.type_name == "")
				_inferred_type.type_name = "string";
			else if (_inferred_type.type_name != "string")
				_inferred_type.type_name = "%s.%s".printf ("string", _inferred_type.type_name);
		}
		
		public override void visit_declaration_statement (DeclarationStatement stmt)
		{
			stmt.accept_children (this);
		}

		public override void visit_foreach_statement (ForeachStatement stmt) 
		{
			var s = visit_scoped_codenode ("foreach", stmt, stmt.body);
			
			var d = new DataType ("", stmt.variable_name);
			if (stmt.type_reference == null) {
				var prev_inferred_type = _inferred_type;
				_inferred_type = d;

				stmt.accept_children (this);
				_inferred_type = prev_inferred_type;
			} else {
				d.type_name = get_datatype_typename (stmt.type_reference);
			}

			d.is_iterator = true;
			d.source_reference = create_source_reference (stmt);
			s.add_local_variable (d);
		}

		public override void visit_while_statement (WhileStatement stmt) 
		{
			visit_scoped_codenode ("while", stmt, stmt.body);
		}
		
		public override void visit_do_statement (DoStatement stmt) 
		{
			visit_scoped_codenode ("do", stmt, stmt.body);
		}
		
		public override void visit_for_statement (ForStatement stmt) 
		{
			visit_scoped_codenode ("for", stmt, stmt.body);
		}

		public override void visit_try_statement (TryStatement stmt) 
		{
			visit_scoped_codenode ("try", stmt, stmt.body);
		}
		
		public override void visit_catch_clause (CatchClause clause)
		{
			var s = visit_scoped_codenode ("catch", clause, clause.body);
			var d = new DataType (get_datatype_typename (clause.error_type), clause.variable_name);
			s.add_local_variable (d);			
		}
		
		public override void visit_if_statement (IfStatement stmt) 
		{
			visit_scoped_codenode ("if", stmt, stmt.true_statement);
			if (stmt.false_statement != null)
				visit_scoped_codenode ("else", stmt, stmt.false_statement);
		}

		public override void visit_switch_statement (SwitchStatement stmt) 
		{
			visit_scoped_codenode ("switch", stmt, null);
		}

		public override void visit_switch_section (SwitchSection section) 
		{
			visit_scoped_codenode ("switch-section", section, section); // a section is also a block
		}

		public override void visit_type_parameter (TypeParameter p)
		{
			/*
			var d = new DataType (get_datatype_typename (p), p.name);
			switch (p.direction) {
				case Vala.ParameterDirection.OUT:
					d.is_out = true;
					break;
				case Vala.ParameterDirection.REF:
					d.is_ref = true;
					break;
			}*/

			var symbol = new Afrodite.Symbol (p.name, p.type_name);
			symbol.access = SymbolAccessibility.ANY;

			//Utils.trace ("adding type parameter: '%s' to '%s'", p.name, _current.fully_qualified_name);
			_current.add_generic_type_argument (symbol);
			p.accept_children (this);
		}


		public override void visit_data_type (Vala.DataType type)
		{
			var t = new Afrodite.DataType (get_datatype_typename (type), null);
			if (_current_type != null) {
				//debug ("adding gen type %s %s %s", _current.name, get_datatype_typename (type), Type.from_instance (type).name ());
				_current_type.add_generic_type (t);
				
			} else if (_current != null
				&& (_current.type_name == "Class" || _current.type_name == "Interface" || _current.type_name == "Struct")) {
				// add this type to the base class types
				if (t.type_name.length == 1 && t.type_name.up () == t.type_name) {
					// there's must be a better method
					Utils.trace ("You should fix this hack: %s - %s: '%s' to '%s'",
					type.type_name,
					type.type_parameter != null ? type.type_parameter.to_string () : "type parameter is null",
					t.type_name,
					_current.fully_qualified_name);
				} else {
					_current.add_base_type (t);
					visit_type_for_generics (type, t);
				}
			}
		}
		
		private void visit_type_for_generics (Vala.DataType t, Afrodite.DataType ct) 
		{
			var prev_type = _current_type;
			_current_type = ct;
			foreach (Vala.DataType type in t.get_type_arguments ()) {
				type.accept (this);
			}
			_current_type = prev_type;
		}
		
		private Afrodite.Symbol visit_scoped_codenode (string name, CodeNode node, Block? body)
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn ("!%s".printf (name));
			int last_line = 0;
			if (body != null && body.source_reference != null) {
				last_line = body.source_reference.last_line;
				//print ("body for %s: %d,%d to %d,%d\n", name, body.source_reference.first_line, body.source_reference.first_column, body.source_reference.last_line, body.source_reference.last_column);
			}
				
			var s = add_codenode ("Block", node, out _current_sr, last_line);
			s.display_name = name;
			
			_current.add_child (s);
			
			_current = s;
			if (body == null) {
				node.accept_children (this);
			} else {
				body.accept_children (this);
			}
			_current = prev;
			_current_sr = prev_sr;
			
			_vala_symbol_fqn = prev_vala_fqn;
			
			return s;
		}

		private string get_datatype_typename (Vala.DataType? type)
		{
			if (type is UnresolvedType) {
				return ((UnresolvedType) type).unresolved_symbol.to_string ();
			} else if (type == null) {
				return "DataType is null: %s".printf (_vala_symbol_fqn);
			} else {
				return type.to_string ();
			}
		}
	}
}
