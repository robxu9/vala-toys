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
		if (_results.classes_contain (cl.name)) {
			return; //already visited
		}
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
	
		foreach (Class subcl in cl.get_classes()) {
			subcl.accept (this);
		}
	
		foreach (Struct st in cl.get_structs()) {
			st.accept (this);
		}

		foreach (Delegate d in cl.get_delegates()) {
			d.accept (this);
		}
		
		if (_parent_type_already_visited) {
			if (test_symbol (_options, cl)) {
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
		}
	}

       	public override void visit_interface (Interface iface) 
	{
		if (_results.interfaces_contain (iface.name)) {
			return; //already visited
		}
		foreach (DataType type in iface.get_prerequisites ()) {
			if (type.data_type != null) {
				type.data_type.accept (this);	
			} else {
				type.accept (this);
			}
		}
		
		_parent_type_already_visited = true;
		foreach (TypeParameter p in iface.get_type_parameters ()) {
			p.accept (this);
		}

		/* process enums first to avoid order problems in C code */
		foreach (Enum en in iface.get_enums ()) {
			en.accept (this);
		}

		foreach (Field f in iface.get_fields ()) {
			f.accept (this);
		}
	
		foreach (Method m in iface.get_methods()) {
			m.accept (this);
		}
	
		foreach (Property prop in iface.get_properties()) {
			prop.accept (this);
		}
	
		foreach (Vala.Signal sig in iface.get_signals()) {
			sig.accept (this);
		}
	
		foreach (Class cl in iface.get_classes()) {
			cl.accept (this);
		}
	
		foreach (Struct st in iface.get_structs()) {
			st.accept (this);
		}

		foreach (Delegate d in iface.get_delegates()) {
			d.accept (this);
		}
	}
	
       	public override void visit_struct (Struct st) 
	{
		if (_results.structs_contain (st.name)) {
			return; // already visited
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
		
		if (_parent_type_already_visited) {
			if (test_symbol (_options, st)) {
				_results.structs.add (new SymbolCompletionItem.with_struct (st));
			}
			if (st.base_type != null) {
				st.base_type.accept (this);
			}
		} else {
			_parent_type_already_visited = true;
			if (st.base_type != null) {
				st.base_type.accept (this);
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
	}
		
       	public override void visit_method (Method m) 
	{
		if (!_results.methods_contain (m.name) && test_symbol (_options, m)) {
			_results.methods.add (new SymbolCompletionItem.with_method (m));
		}
	}
	
	public override void visit_enum_value (Vala.EnumValue e) 
	{
		_results.constants.add (new SymbolCompletionItem (e.name));
	}
	
	public override void visit_creation_method (Vala.CreationMethod m)
	{
		if (!_results.methods_contain (m.name) && test_symbol (_options, m)) {
			_results.methods.add (new SymbolCompletionItem.with_creation_method (m));
		}		
	}

       	public override void visit_delegate (Delegate d) 
	{
		if (!_results.delegates_contain (d.name) && test_symbol (_options, d)) {
			_results.others.add (new SymbolCompletionItem (d.name));
		}
	}

       	public override void visit_signal (Vala.Signal s) 
	{
		if (!_results.signals_contain (s.name) && test_symbol (_options, s)) {
			_results.signals.add (new SymbolCompletionItem.with_signal (s));
		}
	}

       	public override void visit_field (Field f) 
	{
		if (!_results.fields_contain (f.name) && test_symbol (_options, f)) {
			_results.fields.add (new SymbolCompletionItem.with_field (f));
		}
	}

       	public override void visit_constant (Vala.Constant c) 
	{
		if (!_results.constants_contain (c.name) && test_symbol (_options, c)) {
			_results.constants.add (new SymbolCompletionItem (c.name));
		}
	}
	
       	public override void visit_property (Property p) 
	{
		if (!_results.properties_contain (p.name) && test_symbol (_options, p)) {
			_results.properties.add (new SymbolCompletionItem.with_property (p));
		}
	}
	
	public override void visit_error_domain (ErrorDomain ed)
	{
		if (!_options.error_domains)
			return;
			
		if (_parent_type_already_visited && !_results.error_domains_contain (ed.name)) {
			_results.error_domains.add (new SymbolCompletionItem (ed.name));
		} else {
			_parent_type_already_visited = true;
			ed.accept_children (this);
		}
	}
	
	public override void visit_error_code (Vala.ErrorCode ec) 
	{
		_results.constants.add (new SymbolCompletionItem (ec.name));
	}
	
	private bool test_symbol (SymbolCompletionFilterOptions options, Symbol symbol)
	{
		bool res = false;
		if (options.error_domains) {
			if (options.error_base && symbol is Class) {
				var cl = (Class) symbol;
				res = cl.is_error_base;
			}
		} else {
			bool is_static = symbol_is_static (symbol);

			//test for static or instance symbols
			if (options.static_symbols && is_static)
				res = true;
			else if (!options.static_symbols && !is_static)
				res = true;
			else if (!is_static && options.instance_symbols)
				res = true;
		
			if (options.constructors) {
				if (symbol is Enum) {
					res = false | options.local_variables; //HACK: local_vars mean all scoped symbols in this context
				} else if (symbol is Constant) {
					res = false | options.local_variables;
				} else if (symbol is Method && !(symbol is CreationMethod)) {
					res = false | options.local_variables;
				} else {
					bool has_constructors = symbol_has_constructors (symbol);
					res = res | has_constructors;
				}
			}
			//test symbol accessibility
			if (res) {
				if (options.public_symbols && symbol.access == Vala.SymbolAccessibility.PUBLIC ||
				   options.private_symbols && symbol.access == Vala.SymbolAccessibility.PRIVATE ||
				   options.protected_symbols && symbol.access == Vala.SymbolAccessibility.PROTECTED ||
				   options.internal_symbols && symbol.access == Vala.SymbolAccessibility.INTERNAL) {
					res = true;
				} else {
					res = false;
				}
			}
		}
		
		return res;
	}
	
	/*
	 * Return if the Symbol can be constructed
	 */
	private bool symbol_has_constructors (Symbol symbol)
	{
		return (symbol is Constructor) || (symbol is Class) || (symbol is Namespace) || (symbol is CreationMethod);
	}
	
	private bool symbol_is_static (Symbol symbol, bool instanziable_types = false)
	{
		bool res = false;
		if (symbol is Method) {
			res = ((Method) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Field) {
			res = ((Field) symbol).binding == MemberBinding.STATIC;			
		} else if (symbol is Property) {
			res = ((Property) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Constructor) {
			res = ((Constructor) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Destructor) {
			res = ((Destructor) symbol).binding == MemberBinding.STATIC;
		} else if (symbol is Enum) {
			res = true;
		} else if (symbol is Constant) {
			res = true;
		} else if (symbol is Namespace) {
			res = true;
		} else if (symbol is Class) {
			//class is fully visited only if looking for
			//static symbols
			if (_options.static_symbols) {
				var cl = (Class) symbol;
				res = class_is_static (cl);
			}
		}
		return res;
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
		
		foreach (Class subcl in cl.get_classes()) {
			if (symbol_is_static(subcl))
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
			typefinder.searched_typename = name;
			typefinder.visit_namespace (_context.root);
			sym = typefinder.result;
			
			
			if (sym == null && !SymbolCompletion.symbol_has_known_namespace (name)) {
				foreach (UsingDirective item in _current_file.get_using_directives ()) {
					string ns_name = get_qualified_namespace_name (item.namespace_symbol);
					if (name.has_prefix ("%s.".printf (ns_name)))
						break; //exit since symbol is fully qualified

					var using_name = "%s.%s".printf (ns_name, name);
					typefinder.searched_typename = using_name;
					typefinder.visit_namespace (_context.root);
					if (typefinder.result != null) {
						sym = typefinder.result;
						break;
					}
				}
			}

		}

		return sym;
	}
	
	private string get_qualified_namespace_name (Symbol namespace_symbol)
	{
		string ns_name = null;
		Symbol ns = namespace_symbol;
		while (ns != null) {
			if (ns_name == null) {
				ns_name = ns.name;
			} else {
				ns_name = "%s.%s".printf (ns.name, ns_name);
			}
			if (ns is UnresolvedSymbol) {
				ns = ((UnresolvedSymbol) ns).inner;
			} else {
				ns = ns.parent_symbol;
			}
		}
		return ns_name;
	}

}

