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
			
			// first the container types defined in the child symbols
			if (res == null && symbol.has_children) {
				
				var s = Ast.lookup_symbol (type.type_name, symbol.children, out parent, Afrodite.CompareMode.EXACT);
				if (s != null) {
					//debug ("resolved symbol %s from children to: %s", symbol.fully_qualified_name, s.fully_qualified_name);
					res = s;
				}
			}
			
			// search in the parent chain
			parent = symbol.parent;
			while (parent != null && type.symbol == null) {
				string[] names =  type.type_name.split (".");
				
				var curr_parent = parent;
				for (int i = 0; i < names.length; i++) {
					string name = names[i];
					
					var s = curr_parent.lookup_child (name);
					if (s != null) {
						if (i == names.length -1)
							res = s; // last name part: symbol found
						else
							curr_parent = s; // search inside symbols of the found symbol
					}
				}
				parent = parent.parent;
			}
			
			if (res == null) {
				// then the using directives
				if (symbol.has_source_references) {
					foreach (SourceReference reference in symbol.source_references) {
						var file = reference.file;
						foreach (Symbol using_directive in file.using_directives) {
							var ns = _ast.lookup (using_directive.fully_qualified_name, out parent);
						
							if (ns != null) {
								var s = ns.lookup_child (type.type_name);
								if (s != null) {
									res = s;
									break; // file.using_directives
								}
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
				if (symbol.return_type != null && symbol.return_type.unresolved) {
					symbol.return_type.symbol = resolve_type (symbol, symbol.return_type);
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
							type.symbol = resolve_type (symbol, type);
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
