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
			assert (_ast.lookup_source_file (source.filename) == null);

			//debug ("COMPLETING FILE %s", source.filename);
			_source_file = _ast.add_source_file (source.filename);
			foreach (UsingDirective u in source.current_using_directives) {
				_source_file.add_using_directive (u.namespace_symbol.get_full_name ());
			}
			context.root.accept_children (this);
		}

		public void remove_source_filename (string filename)
		{
			var source = _ast.lookup_source_file (filename);
			assert (source != null);

			_ast.remove_source (source);
		}

		private Afrodite.Symbol visit_symbol (Vala.Symbol s, out Afrodite.SourceReference source_reference)
		{
			Afrodite.Symbol symbol;

			set_fqn (s.name);
			//symbol = _ast.lookup (_vala_symbol_fqn, out parent);
			//assert (parent != null);
			symbol = _ast.symbols.@get (_vala_symbol_fqn);

			if (symbol == null) {
				symbol = add_symbol (s, out source_reference);
				//Utils.trace ("adding %s to source %s", symbol.fully_qualified_name, _source_file.filename);
				_current.add_child (symbol);
			} else {
				Afrodite.Symbol parent = symbol.parent;
				//NOTE: see if we should replace the symbol
				// we should replace it if is not a namespace
				// this can change whenever vala will support
				// partial classes
				bool replace = s.type_name != "ValaNamespace";
				if (replace) {
					parent.remove_child (symbol);
					symbol = add_symbol (s, out source_reference);
					parent.add_child (symbol);
				} else {
					// add one more source reference to the symbol
					source_reference = symbol.lookup_source_reference_filename (_source_file.filename);
					if (source_reference == null) {
						source_reference = create_source_reference (s);
						symbol.add_source_reference (source_reference);
						//Utils.trace ("adding source reference %s to source %s", symbol.fully_qualified_name, _source_file.filename);
						_source_file.add_symbol (symbol);
					} else {
						warning ("two sources with the same name were merged: %s", _source_file.filename);
					}
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

		public override void visit_namespace (Namespace ns)
		{
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			var prev_child_count = _child_count;
			
			_current = visit_symbol (ns, out _current_sr);
			ns.accept_children (this);

			_child_count = prev_child_count;
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_class (Class c)
		{
			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			_current = visit_symbol (c, out _current_sr);
			_current.is_abstract = c.is_abstract;
			c.accept_children (this);

			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_struct (Struct s)
		{
			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			_current = visit_symbol (s, out _current_sr);
			s.accept_children (this);
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_interface (Interface iface)
		{
			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;

			_current = visit_symbol (iface, out _current_sr);
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
			// check if return type is generic
			if (_current.has_generic_type_arguments) {
				foreach (var gt in _current.generic_type_arguments) {
					if (s.return_type.type_name == gt.fully_qualified_name) {
						s.return_type.is_generic = true;
						break;
					}
				}
			}

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
			sym.binding = _current.binding;
			_current.add_child (sym);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
		
		public override void visit_enum (Vala.Enum e) 
		{
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
			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			
			set_fqn (f.name);
			var s = add_symbol (f, out _current_sr);
			s.return_type = new DataType (get_datatype_typename (f.variable_type));
			s.binding =  get_vala_member_binding (f.binding);
			if (_current.has_generic_type_arguments) {
				foreach (var gt in _current.generic_type_arguments) {
					if (s.return_type.type_name == gt.fully_qualified_name) {
						s.return_type.is_generic = true;
						break;
					}
				}
			}

			_current.add_child (s);
			_current = s;

			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}

		public override void visit_constant (Vala.Constant c) 
		{
			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (c.name);
			var s = add_symbol (c, out _current_sr);
			s.binding = MemberBinding.STATIC;
			s.return_type = new DataType (c.type_reference.to_string ());
			_current.add_child (s);
			
			_current = prev;
			_current_sr = prev_sr;
			_vala_symbol_fqn = prev_vala_fqn;
		}
	
		public override void visit_property (Property p) 
		{
			_child_count++;
			var prev_vala_fqn = _vala_symbol_fqn;
			var prev = _current;
			var prev_sr = _current_sr;
			
			set_fqn (p.name);
			var s = add_symbol (p, out _current_sr);
			s.return_type = new DataType (p.property_type.to_string ());
			if (_current.has_generic_type_arguments) {
				foreach (var gt in _current.generic_type_arguments) {
					if (s.return_type.type_name == gt.fully_qualified_name) {
						Utils.trace ("property %s is generic: %s", p.name, _current.fully_qualified_name);
						s.return_type.is_generic = true;
						break;
					}
				}
			}

			_current.add_child (s);
			
			_current = s;
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

		private string? expression_to_string (Vala.Expression e)
		{
			if (e is Vala.Literal) {
				return e.to_string ();
			} else if (e is Vala.MemberAccess) {
				var ma = (Vala.MemberAccess) (e);
				return "%s".printf (ma.member_name);
			} else if (e is Vala.BinaryExpression) {
				var be = (Vala.BinaryExpression) e;
				return "%s %s %s".printf (expression_to_string (be.left), Utils.binary_operator_to_string (be.operator), expression_to_string (be.right));
			} else if (e is Vala.UnaryExpression) {
				var ue = (Vala.UnaryExpression) e;
				return "%s%s".printf (Utils.unary_operator_to_string (ue.operator), expression_to_string (ue.inner));
			} else {
				Utils.trace ("expression_to_string, unknown expression type: %s", e.type_name);
				return null;
			}
		}

		public override void visit_formal_parameter (FormalParameter p) 
		{
			DataType d;
			
			if (p.ellipsis) {
				d = Symbol.ELLIPSIS;
			} else {
				d = new DataType (get_datatype_typename (p.variable_type), p.name);
				if (p.initializer != null) {
					d.default_expression = expression_to_string (p.initializer);
				}
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
