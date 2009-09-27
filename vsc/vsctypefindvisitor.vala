/*
 *  vsctypefindvisitor.vala - Vala symbol completion library
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
 * Code visitor getting the root symbol from whom
 * generate a list of items
 */
public class Vsc.TypeFinderVisitor : CodeVisitor {
	private string _current_typename = null;
	private CodeContext _context;
	private SourceFile _current_file = null;
	private Gee.List<string> _unresolved_types = new Gee.ArrayList<string>();
	private Symbol? _result = null;
	private string _searched_typename = null;
	
	public string qualified_typename = null;
	
	public Symbol? result {
		get {
			return _result;
		}
	}
	
	public string searched_typename
	{
		get {
			return _searched_typename;
		}
		set {
			_searched_typename = value;
			_result = null;
			qualified_typename = null;
			_current_typename = null;
			_unresolved_types.clear ();
		}
	}
	
	public TypeFinderVisitor (SourceFile? source = null, CodeContext? context = null)
	{
		_context = context;
        	_current_file = source;
	}

	
	private bool list_contains_string (Gee.List<string> list, string @value)
	{
		foreach (string current in list) {
			if (current == @value)
				return true;
		}
		return false;
	}
	
	public override void visit_namespace (Namespace ns) 
	{
		if (_result != null) //found
			return;
			
		var previous_typename = _current_typename;
		
		if (_current_typename == null) {
			_current_typename = ns.name;			
		} else {
			_current_typename = "%s.%s".printf (_current_typename, ns.name);
		}
		if (_current_typename == _searched_typename) {
                	_result = ns;
                	qualified_typename = _current_typename;
		} else {
			ns.accept_children (this);
		}
		
                _current_typename = previous_typename;
        }
        
       	public override void visit_class (Class cl)
	{
		if (_result != null) //found
			return;
		var previous_typename = _current_typename;

		if (_current_typename == null) {
			_current_typename = cl.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, cl.name);
		}
		//debug ("_current_type vs search: %s vs %s", _searched_typename, _current_typename);
		
		if (_current_typename == _searched_typename) {
			_result = cl;
                	qualified_typename = _current_typename;
		} else {
			//cl.accept_children (this);
			//Minor optimization
			if (_result == null) {
				foreach (DataType type in cl.get_base_types ()) {
					if (type != null) {
						type.accept (this);
						if (_result != null) {
							break;
						}
					}
				}
			}
			
			/* process enums first to avoid order problems in C code */
			//Minor optimization
			if (_result == null) {
				foreach (Enum en in cl.get_enums ()) {
					en.accept (this);
					if (_result != null) {
						break;
					}
				}
			}

			//Minor optimization
			if (_result == null) {
				foreach (Field f in cl.get_fields ()) {
					f.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
			//Minor optimization
			if (_result == null) {
				foreach (Constant c in cl.get_constants()) {
					c.accept (this);
					if (_result != null) {
						break;
					}
				}
			}

			//Minor optimization
			if (_result == null) {
				foreach (Method m in cl.get_methods()) {
					m.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
			
			//Minor optimization
			if (_result == null) {
				foreach (Property prop in cl.get_properties()) {
					prop.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
			//Minor optimization
			if (_result == null) {
				foreach (Class subcl in cl.get_classes()) {
					subcl.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
			
			//Minor optimization
			if (_result == null) {
				foreach (Struct st in cl.get_structs()) {
					st.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
		}
		_current_typename = previous_typename;
	}

       	public override void visit_interface (Interface iface)
	{
		if (_result != null) //found
			return;
		var previous_typename = _current_typename;

		if (_current_typename == null) {
			_current_typename = iface.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, iface.name);
		}

		if (_current_typename == _searched_typename) {
			_result = iface;
                	qualified_typename = _current_typename;
		} else {
			//cl.accept_children (this);
			//Minor optimization
			if (_result == null) {
				foreach (DataType type in iface.get_prerequisites ()) {
					if (type != null) {
						type.accept (this);
						if (_result != null) {
							break;
						}
					}
				}
			}
			
			/* process enums first to avoid order problems in C code */
			//Minor optimization
			if (_result == null) {
				foreach (Enum en in iface.get_enums ()) {
					en.accept (this);
					if (_result != null) {
						break;
					}
				}
			}

			//Minor optimization
			if (_result == null) {
				foreach (Field f in iface.get_fields ()) {
					f.accept (this);
					if (_result != null) {
						break;
					}
				}
			}

			//Minor optimization
			if (_result == null) {
				foreach (Method m in iface.get_methods()) {
					m.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
			
			//Minor optimization
			if (_result == null) {
				foreach (Property prop in iface.get_properties()) {
					prop.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
			//Minor optimization
			if (_result == null) {
				foreach (Class cl in iface.get_classes()) {
					cl.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
			
			//Minor optimization
			if (_result == null) {
				foreach (Struct st in iface.get_structs()) {
					st.accept (this);
					if (_result != null) {
						break;
					}
				}
			}
		}
		_current_typename = previous_typename;
	}
	        
       	public override void visit_struct (Struct st) 
	{
		if (_result != null) //found
			return;

		var previous_typename = _current_typename;
		
		if (_current_typename == null) {
			_current_typename = st.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, st.name);
		}
		
		if (_current_typename == _searched_typename) {
			_result = st;
			qualified_typename = _current_typename;
		} else {
			st.accept_children (this);
		}
		
		_current_typename = previous_typename;
	}

       	public override void visit_enum (Enum en) 
	{
		if (_result != null) //found
			return;

		var previous_typename = _current_typename;
	
		if (_current_typename == null) {
			_current_typename = en.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, en.name);
		}
	
		if (_current_typename == _searched_typename) {
			_result = en;
			qualified_typename = _current_typename;
		} else {
			en.accept_children (this);
		}
		
		_current_typename = previous_typename;
	}

       	public override void visit_error_domain (ErrorDomain ed) 
	{
		if (_result != null) //found
			return;

		var previous_typename = _current_typename;
	
		if (_current_typename == null) {
			_current_typename = ed.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, ed.name);
		}
	
		if (_current_typename == _searched_typename) {
			_result = ed;
			qualified_typename = _current_typename;
		} else {
			ed.accept_children (this);
		}
		
		_current_typename = previous_typename;
	}
	
	public override void visit_method (Method m) 
	{
		if (_result != null) //found
			return;

		var previous_typename = _current_typename;
	
		if (_current_typename == null) {
			_current_typename = "%s".printf (m.name);
		} else {
			_current_typename = "%s.%s".printf (_current_typename, m.name);
		}
			
		if (_current_typename == _searched_typename) {
			_result = m;
			qualified_typename = _current_typename;
		}
		
		_current_typename = previous_typename;
	}
		
	public override void visit_property (Property p) 
	{
		if (_result != null) //found
			return;

		var previous_typename = _current_typename;
	
		if (_current_typename == null) {
			_current_typename = p.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, p.name);
		}
		if (_current_typename == _searched_typename) {
			_result = p;
			qualified_typename = _current_typename;
		}
		
		_current_typename = previous_typename;
	}
	
	public override void visit_field (Field f) 
	{
		if (_result != null) //found
			return;

		var previous_typename = _current_typename;
	
		if (_current_typename == null) {
			_current_typename = f.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, f.name);
		}
	
		if (_current_typename == _searched_typename) {
			_result = f;
			qualified_typename = _current_typename;
		}
		
		_current_typename = previous_typename;
	}

	public override void visit_constant (Constant c) 
	{
		if (_result != null) //found
			return;

		var previous_typename = _current_typename;
	
		if (_current_typename == null) {
			_current_typename = c.name;
		} else {
			_current_typename = "%s.%s".printf (_current_typename, c.name);
		}
	
		if (_current_typename == _searched_typename) {
			_result = c;
			qualified_typename = _current_typename;
		}
		
		_current_typename = previous_typename;
	}
	
	public override void visit_data_type (DataType data_type) {
		if (_result != null || _context == null)
			return;

		if (!(data_type is UnresolvedType)) {
			return;
		}
		
		var previous_typename = _current_typename;
		
		var unresolved_type = (UnresolvedType) data_type;
		string name = unresolved_type.to_qualified_string ();
		if (name == null) {
			name = unresolved_type.unresolved_symbol.name;
		}
		//avoid recoursion
		if (list_contains_string (_unresolved_types, name))
		   return;
		
		_unresolved_types.add (name);
		var sym = resolve_type (unresolved_type);
		debug ("resolving: %s = %s ", name, (sym == null ? "no" : "yes"));
		_unresolved_types.remove (name);
		if (sym != null) {
			if (sym is DataType) {
				unresolved_type.parent_node.replace_type (unresolved_type, (DataType) sym);
			}
			sym.accept (this);
		}
		_current_typename = previous_typename;
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
				foreach (UsingDirective item in _current_file.current_using_directives) {
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
		int i = 0;
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
			i++;
		}
		return ns_name;
	}
}

