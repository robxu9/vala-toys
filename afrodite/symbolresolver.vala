/* symbolresolver.vala
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
	public class SymbolResolver
	{
		Ast _ast = null;
		string _vala_symbol_fqn = null;
		
		/*
		private void print_symbol (Symbol s)
		{
			string message = "  %s: %s, fqn %s\n".printf (s.type_name, s.name,  s.fully_qualified_name);
			print (message);
		}
		*/
	
		public void resolve (Ast ast)
		{
			_vala_symbol_fqn = null;
			this._ast = ast;
			if (ast.root.has_children)
				visit_symbols (ast.root.children);
		}
		
		private unowned Symbol? resolve_type (Symbol symbol, DataType type)
		{
			Symbol parent;
			unowned Symbol res = null;
			
			// void symbol
			if (type.type_name == "void") {
				res = Symbol.VOID;
			}
			
			// first resolve type generic types
			if (type.has_generic_types) {
				foreach (DataType generic_type in type.generic_types) {
					if (generic_type.unresolved)
						generic_type.symbol = resolve_type (symbol, generic_type);
				}
			}
					
			// first the container types defined in the child symbols
			if (res == null && symbol.has_children) {
				
				var s = Ast.lookup_symbol (type.type_name, symbol.children, out parent, Afrodite.CompareMode.EXACT);
				if (s != null) {
					res = s;
				}
			}
			
			// search in the parent chain
			parent = symbol;
			while (parent != null && type.symbol == null) {
				//debug ("searching1 %s %s", type.type_name, type.name);
				string[] names =  type.type_name.split (".");
				
				var curr_parent = parent;
				for (int i = 0; i < names.length; i++) {
					string name = names[i];
					var s = curr_parent.lookup_child (name);
					if (s != null) {
						if (i == names.length -1) {
							res = s; // last name part: symbol found
						}
						else
							curr_parent = s; // search inside symbols of the found symbol
					} else if (i == names.length -1) {
						// debug ("searching2 %s %s in %s", type.type_name, type.name, curr_parent.name);
						
						// search the last part of the name also on the local variables
						if (curr_parent.has_local_variables) {
							foreach (var item in curr_parent.local_variables) {
								//debug ("localvar %s: %s vs %s:%s unresolved %d", item.name, item.type_name, type.name, type.type_name, (int) type.unresolved);
								if (!item.unresolved && item.name == name) {
									type.type_name = item.type_name;
									res = item.symbol;
									break;
								}
							}
						}
						// search the last part of the name also on the method parameters
						if (curr_parent.has_parameters) {
							foreach (var item in curr_parent.parameters) {
								//debug ("parameter %s: %s vs %s:%s unresolved %d", item.name, item.type_name, type.name, type.type_name, (int) type.unresolved);
								if (!item.unresolved && item.name == name) {
									type.type_name = item.type_name;
									res = item.symbol;
									break;
								}
							}
						}

					}
				}
				parent = parent.parent;
			}
			
			if (res == null) {
				// then the using directives
				if (symbol.has_source_references) {
					foreach (SourceReference reference in symbol.source_references) {
						var file = reference.file;
						if (file.using_directives == null) {
							//warning ("file without any using directive: %s", file.filename);
							continue;
						}
						foreach (Symbol using_directive in file.using_directives) {
							//Utils.trace ("searching %s in imported namespace: %s", type.type_name, using_directive.name);
							var ns = _ast.lookup (using_directive.fully_qualified_name, out parent);
						
							if (ns != null) {
								string[] parts = type.type_name.split (".");
								Symbol s = ns;
								for (int i = 0; i < parts.length; i++) {
									s = s.lookup_child (parts[i]);
									if (s == null) {
										break; // file.using_directives
									}
								}
								res = s;
							}
						}
						
						if (res != null) {
							break; // symbol.source_references
						}
					}
				}
			}	
			
			if (res != null) {
				res.add_resolve_target (symbol);
			}
			return res;
		}

		private void resolve_symbol (Afrodite.Symbol symbol, Afrodite.DataType type)
		{
			type.symbol = resolve_type (symbol, type);
			if (!type.unresolved && type.symbol.return_type != null) {
				var dt = type.symbol.return_type;
				type.type_name = dt.type_name;
				if (type.is_iterator) {
					if (dt.has_generic_types && dt.generic_types.size == 1) {
						type.type_name = dt.generic_types[0].type_name;
						type.symbol = dt.generic_types[0].symbol;
					}
				}
			}
		}
		
		private void visit_symbols (Vala.List<Afrodite.Symbol> symbols)
		{
			foreach (Symbol symbol in symbols) {
				//print_symbol (symbol);
				
				// resolving base types
				if (symbol.has_base_types) {
					foreach (DataType type in symbol.base_types) {
						if (type.unresolved) {
							type.symbol = resolve_type (symbol, type);
						}
					}
				}
				// resolving return type
				if (symbol.return_type != null) {
					if (symbol.return_type.unresolved) {
						symbol.return_type.symbol = resolve_type (symbol, symbol.return_type);
					}
				}
				
				// resolving symbol parameters
				if (symbol.has_parameters) {
					foreach (DataType type in symbol.parameters) {
						if (type.unresolved) {
							type.symbol = resolve_type (symbol, type);
						}
					}
				}
				// resolving local variables
				if (symbol.has_local_variables) {
					foreach (DataType type in symbol.local_variables) {
						if (type.unresolved) {
							resolve_symbol (symbol, type);	
						}
					}
				}
				if (symbol.has_children) {
					visit_symbols (symbol.children);
				}
			}
		}
	}
}
