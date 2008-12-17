/*
 *  vsccompletionvisitor.vala - Vala symbol completion library
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;
using Gee;
using Vala;

/**
 * Code visitor getting a list of completion items
 */
public class Vsc.CompletionVisitor : CodeVisitor {
	private SymbolCompletionResult _results;
	private SymbolCompletionFilterOptions _options;
	private CodeContext _context;
	private SourceFile _current_file = null;
		
	//this flag blocks the visit of unmergeable types, like classes, struct etc
	//it isn't setted for namespaces that we want to merge across files, and context
	private bool _parent_type_already_visited = false; 
	private string _searched_typename = null;

	
	public CompletionVisitor (SymbolCompletionFilterOptions options, SymbolCompletionResult results, SourceFile? source = null, CodeContext? context = null)
	{
		_results = results;
		_options = options;
		_context = context;
        	_current_file = source;
	}
		
	public string searched_typename
	{
		get {
			return _searched_typename;
		}
		set {
			_searched_typename = value;
		}
	}
	
	public void integrate_completion (Symbol symbol)
	{
		_parent_type_already_visited = false;
		symbol.accept (this);
	}
	
	public override void visit_namespace (Namespace ns) 
	{
		if (_parent_type_already_visited) {
			if (test_symbol (_options, ns)) {
				if (!_results.namespaces_contain (ns.name)) {
					_results.namespaces.add (new SymbolCompletionItem (ns.name));
				}
			}
		} else {
			_parent_type_already_visited = true;
			ns.accept_children (this);
		}
        }
        
       	public override void visit_class (Class cl) 
	{
		if (_parent_type_already_visited) {
			if (!_results.classes_contain (cl.name) && test_symbol (_options, cl)) {
				var item = new SymbolCompletionItem.with_class (cl);
				_results.classes.add (item);
			}
		} else {
			bool tmp = _parent_type_already_visited;
			foreach (DataType type in cl.get_base_types ()) {
				if (type is Vala.ObjectType) {
					var obj = (ObjectType) type;
					obj.type_symbol.accept (this);
				} else {
					type.accept (this);
				}
				_parent_type_already_visited = tmp;
			}
			
			_parent_type_already_visited = true;
			foreach (TypeParameter p in cl.get_type_parameters ()) {
				p.accept (this);
			}

			/* process enums first to avoid order problems in C code */
			foreach (Enum en in cl.get_enums ()) {
				en.accept (this);
			}

			foreach (Field f in cl.get_fields ()) {
				f.accept (this);
			}
		
			foreach (Constant c in cl.get_constants()) {
				c.accept (this);
			}
		
			foreach (Method m in cl.get_methods()) {
				m.accept (this);
			}
		
			foreach (Property prop in cl.get_properties()) {
				prop.accept (this);
			}
		
			foreach (Vala.Signal sig in cl.get_signals()) {
				sig.accept (this);
			}
		
			foreach (Class cl in cl.get_classes()) {
				cl.accept (this);
			}
		
			foreach (Struct st in cl.get_structs()) {
				st.accept (this);
			}

			foreach (Delegate d in cl.get_delegates()) {
				d.accept (this);
			}
		}
	}
	        
       	public override void visit_struct (Struct st) 
	{
		if (_parent_type_already_visited) {
			if (!_results.structs_contain (st.name) && test_symbol (_options, st)) {
				_results.structs.add (new SymbolCompletionItem.with_struct (st));
			}
			foreach (DataType type in st.get_base_types()) {
				type.accept (this);
			}
		} else {
			_parent_type_already_visited = true;
			foreach (DataType type in st.get_base_types()) {
				type.accept (this);
			}
			foreach (TypeParameter p in st.get_type_parameters()) {
				p.accept (this);
			}
		
			foreach (Field f in st.get_fields()) {
				f.accept (this);
			}
		
			foreach (Constant c in st.get_constants()) {
				c.accept (this);
			}
		
			foreach (Method m in st.get_methods()) {
				m.accept (this);
			}			
		}
	}

       	public override void visit_enum (Enum en) 
	{
		if (_parent_type_already_visited) {
			if (!_results.enums_contain (en.name) && test_symbol (_options, en)) {
				_results.enums.add (new SymbolCompletionItem (en.name));
			}
		} else {
			_parent_type_already_visited = true;
			en.accept_children (this);			
		}
	}
	
	public override void visit_data_type (DataType data_type) {
		if (!(data_type is UnresolvedType)) {
			return;
		}
		
		return_if_fail (_context != null);
		
		var unresolved_type = (UnresolvedType) data_type;
		var sym = resolve_type (unresolved_type);
		debug ("resolving type started");
		if (sym == null) {
			GLib.warning ("(visit-data-type): can't resolve type");
			return;
		}
		
		if (_parent_type_already_visited) {
			sym.accept (this);
		} else {
			_parent_type_already_visited = true;
			sym.accept_children (this);
		}
		debug ("resolving type ended");
	}
		
       	public override void visit_method (Method m) 
	{
		if (test_symbol (_options, m)) {
			_results.methods.add (new SymbolCompletionItem.with_method (m));
		}
	}
	
	public override void visit_enum_value (Vala.EnumValue e) 
	{
		_results.constants.add (new SymbolCompletionItem (e.name));
	}
	
	public override void visit_creation_method (Vala.CreationMethod m)
	{
		if (test_symbol (_options, m)) {
			_results.methods.add (new SymbolCompletionItem.with_method (m));
		}		
	}

       	public override void visit_delegate (Delegate d) 
	{
		if (test_symbol (_options, d)) {
			_results.others.add (new SymbolCompletionItem (d.name));
		}
	}

       	public override void visit_signal (Vala.Signal s) 
	{
		if (test_symbol (_options, s)) {
			_results.signals.add (new SymbolCompletionItem.with_signal (s));
		}
	}

       	public override void visit_field (Field f) 
	{
		if (test_symbol (_options, f)) {
			_results.fields.add (new SymbolCompletionItem.with_field (f));
		}
	}
	
       	public override void visit_property (Property p) 
	{
		if (test_symbol (_options, p)) {
			_results.properties.add (new SymbolCompletionItem.with_property (p));
		}
	}
	
	private bool test_symbol (SymbolCompletionFilterOptions options, Symbol symbol)
	{
		bool res = false;
		bool is_static = symbol_is_static (symbol);
		bool has_constructors = symbol_has_constructors (symbol);

		//test for static or instance symbols
		if (options.static_symbols && is_static && !options.only_constructors)
			res = true;
		else if (!options.static_symbols && !is_static)
			res = true;
		
		if (options.only_constructors) {
			res = has_constructors;
		}
		
		//test symbol accessibility
		if (res && (options.public_symbols && symbol.access == Vala.SymbolAccessibility.PUBLIC) ||
			(options.private_symbols && symbol.access == Vala.SymbolAccessibility.PRIVATE) ||
			(options.protected_symbols && symbol.access == Vala.SymbolAccessibility.PROTECTED) ||
			(options.internal_symbols && symbol.access == Vala.SymbolAccessibility.INTERNAL)) {
			    res = true;
		} else {
			res = false;
		}
		//GLib.debug ("(test_symbol): testing %s: %s", symbol.name, (res ? "true" : "false"));
		return res;
	}
	
	/*
	 * Return if the Symbol can be constructed
	 */
	private bool symbol_has_constructors (Symbol symbol)
	{
		return (symbol is Constructor) || (symbol is Class) || (symbol is Namespace) || (symbol is CreationMethod);
	}
	
	private bool symbol_is_static (Symbol symbol)
	{
		if (symbol is Method) {
			return ((Method) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Field) {
			return ((Field) symbol).binding == MemberBinding.STATIC;			
		} else if (symbol is Property) {
			return ((Property) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Constructor) {
			return ((Constructor) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Destructor) {
			return ((Destructor) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Enum) {
			return true;
		} else if (symbol is Constant) {
			return true;
		} else if (symbol is Namespace) {
			return true;
		} else if (symbol is Class) {
			//class is fully visited only if looking for
			//static symbols
			if (_options.static_symbols) {
				var cl = (Class) symbol;
				return class_is_static (cl);
			}
		}
		return false;
	}
	
	private bool class_is_static (Class cl)		
	{
		if (cl.get_enums ().size > 0 || cl.get_constants ().size > 0)
			return true;
		
		foreach (Field f in cl.get_fields ()) {
			if (symbol_is_static(f))
				return true;
		}
	
		foreach (Method m in cl.get_methods()) {
			if (symbol_is_static(m))
				return true;
		}
	
		foreach (Property prop in cl.get_properties()) {
			if (symbol_is_static(prop))
				return true;
		}
	
		foreach (Struct st in cl.get_structs()) {
			if (symbol_is_static(st))
				return true;
		}

		foreach (Delegate d in cl.get_delegates()) {
			if (symbol_is_static(d))
				return true;
		}

		foreach (DataType type in cl.get_base_types ()) {
			if (type is UnresolvedType) {
				var unresolved_type = (UnresolvedType) type;
				var sym = resolve_type (unresolved_type);
				if (sym != null) {
					if (symbol_is_static(sym)) {
						return true;		
					}
				}
			} else if (symbol_is_static(type.data_type))
				return true;
		}
		
		foreach (Class cl in cl.get_classes()) {
			if (symbol_is_static(cl))
				return true;
		}
		
		return false;
	}
	
	private Symbol? resolve_type (UnresolvedType unresolved_type)
	{
		Symbol sym = null;

		string name = unresolved_type.to_qualified_string ();
		if (name == null) {
			name = unresolved_type.unresolved_symbol.name;
		}

		if (sym == null && _current_file != null) {
			var typefinder = new TypeFinderVisitor ();


			//trying on the root context
			debug ("(resolve_type): root namespace type %s", name);
			typefinder.searched_typename = name;
			typefinder.visit_namespace (_context.root);
			sym = typefinder.result;
			
			
			if (sym == null && !SymbolCompletion.symbol_has_known_namespace (name)) {
				foreach (UsingDirective item in _current_file.get_using_directives ()) {
					var using_name = "%s.%s".printf (item.namespace_symbol.name, name);
					debug ("(resolve_type): using directives resolving type %s", using_name);
					typefinder.searched_typename = using_name;
					typefinder.visit_namespace (_context.root);
					if (typefinder.result != null) {
						sym = typefinder.result;
						break;
					}
				}
			}

		}

		if (sym != null)
			debug ("(resolve_type): type solved %s", sym.get_full_name ());
		return sym;
	}
}

