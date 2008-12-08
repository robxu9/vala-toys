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
	private string _current_typename = null;
	private bool _type_found = false;
	private CodeContext _context;
	private SourceFile _current_file = null;
		
	//this flag blocks the visit of unmergeable types, like classes, struct etc
	//it isn't setted for namespaces that we want to merge across files, and context
	private bool _typename_already_visited = false; 
	private string _searched_typename = null;
	
	public string searched_typename
	{
		get {
			return _searched_typename;
		}
		set {
			_searched_typename = value;
		}
	}
	
	public CompletionVisitor (SymbolCompletionFilterOptions options, SymbolCompletionResult results, SourceFile? source = null, CodeContext? context = null)
	{
		_results = results;
		_options = options;
		_context = context;
        	_current_file = source;
	}
	
	public override void visit_namespace (Namespace ns) 
	{
		var previous_typename = _current_typename;
		var previous_type_found = _type_found;
		
		if (_current_typename == null) {
			_current_typename = ns.name;			
		} else {
			_current_typename = "%s.%s".printf (_current_typename, ns.name);
		}
		
		if (_type_found && test_symbol (_options, ns)) {
			if (!_results.namespaces_contain (ns.name))
				_results.namespaces.add (new SymbolCompletionItem (ns.name));
		} else {
			if (!_type_found && _current_typename == _searched_typename) {
				GLib.debug ("(visit_namespace): found %s", _current_typename);
	                	_type_found = true;
			}
			ns.accept_children (this);
		}
		
                _current_typename = previous_typename;
                _type_found = previous_type_found;
        }
        
       	public override void visit_class (Class cl) 
	{
		//check for duplicates since for more accurate results
		//container types are searched and merged in all the context		
		//beaware that cl.name isn't fully qualified!
		//This can be a problem in the future
		if (!_results.classes_contain (cl.name)) {
			var previous_typename = _current_typename;
			var previous_type_found = _type_found;

			if (_current_typename == null) {
				_current_typename = cl.name;
			} else {
				_current_typename = "%s.%s".printf (_current_typename, cl.name);
			}

			//GLib.debug ("(visit_class): class %s for %s", _current_typename, _searched_typename);
			if (!_type_found && _current_typename == _searched_typename) {
				if (!_typename_already_visited) {
					GLib.debug ("(visit_class): found class %s", _current_typename);
					_type_found = true;
					//if I just found the type I'll visit all the children
					_typename_already_visited = true;
					cl.accept_children (this);
				}
			} else if (_type_found && test_symbol (_options, cl)) {
				var item = new SymbolCompletionItem.with_class (cl);
				_results.classes.add (item);
			}
	
			_type_found = previous_type_found;
			_current_typename = previous_typename;
		}
	}
	        
       	public override void visit_struct (Struct st) 
	{
		//check for duplicates since for more accurate results
		//container types are searched and merged in all the context		
		//beaware that st.name isn't fully qualified!
		//This can be a problem in the future
		if (!_results.structs_contain (st.name)) {
			var previous_typename = _current_typename;
			var previous_type_found = _type_found;
		
			if (_current_typename == null) {
				_current_typename = st.name;
			} else {
				_current_typename = "%s.%s".printf (_current_typename, st.name);
			}
		
			//GLib.debug ("(visit_struct): class %s for %s", _current_typename, _searched_typename);
			if (!_type_found && _current_typename == _searched_typename) {
				if (!_typename_already_visited) {
					GLib.debug ("(visit_struct): found %s", _current_typename);
					_type_found = true;
					_typename_already_visited = true;
					st.accept_children (this);
				}
			} else if (_type_found && test_symbol (_options, st)) {
					_results.structs.add (new SymbolCompletionItem.with_struct (st));
			}
		
		        _type_found = previous_type_found;
			_current_typename = previous_typename;
		}
	}

       	public override void visit_enum (Enum en) 
	{
		//check for duplicates since for more accurate results
		//container types are searched and merged in all the context		
		//beaware that en.name isn't fully qualified!
		//This can be a problem in the future
		if (!_results.enums_contain (en.name)) {
			var previous_typename = _current_typename;
			var previous_type_found = _type_found;
		
			if (_current_typename == null) {
				_current_typename = en.name;
			} else {
				_current_typename = "%s.%s".printf (_current_typename, en.name);
			}
		
			if (!_type_found && _current_typename == _searched_typename) {
				GLib.debug ("(visit_struct): found %s", _current_typename);
				_type_found = true;
				en.accept_children (this);
			} else if (_type_found && test_symbol (_options, en)) {
				_results.enums.add (new SymbolCompletionItem (en.name));		
			}
		
		        _type_found = previous_type_found;
			_current_typename = previous_typename;
		}
	}
	
	public override void visit_data_type (DataType data_type) {
		data_type.accept_children (this);

		//no need to resolve a type if I haven't found its parent
		if (!(_type_found && data_type is UnresolvedType)) {
			return;
		}

		return_if_fail (_context != null);
		
		var unresolved_type = (UnresolvedType) data_type;
		string name = unresolved_type.unresolved_symbol.name;

		Symbol sym = null;
		if (unresolved_type.unresolved_symbol.qualified) {
			GLib.debug ("(visit_data_type): lookup %s in %s: %d", name, _context.root.name, (int) _context.root.scope);
			sym = _context.root.scope.lookup (name);
			if (sym != null)
				sym.accept (this);
		}
		
		if (sym == null && _current_file != null) {
			foreach (UsingDirective item in _current_file.get_using_directives ()) {
				name = "%s.%s".printf (item.namespace_symbol.name, unresolved_type.unresolved_symbol.name);
				GLib.debug ("(visit_data_type): symbol not qualified looking for %s", name);
				var completion = new CompletionVisitor (_options, _results);
				completion._searched_typename = name;
				completion.visit_namespace (_context.root);
			}
		}
		GLib.debug ("(visit_data_type): unresolved type, symbol %s", name);		
	}
		
       	public override void visit_method (Method m) 
	{
		if (test_symbol (_options, m)) {
			_results.methods.add (new SymbolCompletionItem.with_method (m));
		}
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
		if (!_type_found)
			return false;

		GLib.debug ("(test_symbol): testing %s", symbol.name);
			
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
		
		//test symbol accesibility
		if (res && (options.public_symbols && symbol.access == Vala.SymbolAccessibility.PUBLIC) ||
			(options.private_symbols && symbol.access == Vala.SymbolAccessibility.PRIVATE) ||
			(options.protected_symbols && symbol.access == Vala.SymbolAccessibility.PROTECTED) ||
			(options.internal_symbols && symbol.access == Vala.SymbolAccessibility.INTERNAL)) {
			    res = true;
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
		}
		
		return false;
	}		
}

