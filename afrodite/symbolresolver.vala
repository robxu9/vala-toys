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

			// first resolve the using directives
			if (_ast.has_source_files) {
				Symbol dummy;
				foreach (SourceFile file in _ast.source_files) {
					if (file.has_using_directives) {
						foreach (DataType using_directive in file.using_directives) {
							//
							if (using_directive.unresolved) {
								using_directive.symbol = _ast.lookup (using_directive.type_name, out dummy);
								if (using_directive.unresolved)
									message ("file %s - can't resolve using directive: %s", file.filename, using_directive.type_name);
							}
						}
					}
				}
			}

			if (ast.root.has_children)
				visit_symbols (ast.root.children);
		}
		
		private Symbol? resolve_type (Symbol symbol, DataType type)
		{
			Symbol res = null;
			
			// void symbol
			if (type.type_name == "void") {
				res = Symbol.VOID;
			} else if (type.type_name == "...") {
				res = Symbol.VOID;
			}

			// first try with the ast symbol index: fastest mode
			if (res == null) {
				var s = _ast.symbols.@get (type.type_name);
				if (s != null) {
					res = s;
				} else {
					// namespace that contains this symbol are automatically in scope
					// from the inner one to the outmost
					Symbol curr_symbol = symbol;
					while (curr_symbol != null) {
						curr_symbol = curr_symbol.parent;
						if (curr_symbol != null) {
							s = _ast.symbols.@get ("%s.%s".printf (curr_symbol.fully_qualified_name, type.type_name));
							if (s != null && s != symbol) {
								res = s;
								break;
							}
						}
					}

					if (res == null) {
						// try with the imported namespaces
						bool has_glib_using = false;
						foreach (SourceReference reference in symbol.source_references) {
							var file = reference.file;
							if (!file.has_using_directives) {
								continue;
							}

							foreach (DataType using_directive in file.using_directives) {
								if (using_directive.unresolved)
									continue;

								if (using_directive.name == "GLib") {
									has_glib_using = true;
								}

								//Utils.trace ("resolving with %s.%s".printf (using_directive.type_name, type.type_name));
								s = _ast.symbols.@get ("%s.%s".printf (using_directive.type_name, type.type_name));
								if (s != null && s != symbol) {
									res = s;
									break;
								}
							}

							if (res != null) {
								break;
							}
						}
						if (res == null) {
							if (!has_glib_using) {
								// GLib namespace is automatically imported
								s = _ast.symbols.@get ("GLib.%s".printf (type.type_name));
								if (s != null && s != symbol) {
									res = s;
								}
							}
						}
					}
				}
			}

			/*
			// optimization: first resolve in a direct lookup (just for simple types)
			if (res == null) {
				string[] tmp = type.type_name.split (".", 2);
				var s = _ast.root.lookup_child (tmp[0]);
				if (s != null) {
					if (tmp.length > 1) {
						// search for the remaining part
						s = Ast.lookup_symbol (tmp[1], s, ref parent, Afrodite.CompareMode.EXACT);
						if (s != null && s != symbol) {
							res = s;
						}
					} else {
						res = s;
					}
				}
			}

			// resolve symbol
			//    first lookup: child symbols eg. MyInnerClass.MyEnum.VALUE
			//    after lookup: in parent symbols
			var curr_parent = symbol;
			while (res == null && curr_parent != null) {
				if (curr_parent.has_children) {
					var s = Ast.lookup_symbol (type.type_name, curr_parent, ref parent, Afrodite.CompareMode.EXACT);
					if (s != null && s != symbol) {
						res = s;
					}
				}
				curr_parent = curr_parent.parent;
			}

			if (res == null) {
				// lookup in using directives
				if (symbol.has_source_references) {
					foreach (SourceReference reference in symbol.source_references) {
						var file = reference.file;
						if (!file.has_using_directives) {
							continue;
						}
					
						foreach (DataType using_directive in file.using_directives) {
							if (using_directive.unresolved)
								continue;

							var s = Ast.lookup_symbol (type.type_name, using_directive.symbol, ref parent, Afrodite.CompareMode.EXACT);
							if (s != null && s != symbol) {
								res = s;
								break;
							}
						}
					
						if (res != null) {
							break; // symbol.source_references
						}
					}
				}
			}
			*/

			if (res != null) {
				if (type.has_generic_types) {
					if (res.has_generic_type_arguments
					   && type.generic_types.size == res.generic_type_arguments.size) {
						// test is a declaration of a specialized generic type
						bool need_specialization = false;
						for(int i = 0; i < type.generic_types.size; i++) {
							string name = res.generic_type_arguments[i].fully_qualified_name ?? res.generic_type_arguments[i].name;
							if (type.generic_types[i].type_name != name) {
								need_specialization = true;
								break;
							}
						}
						if (need_specialization) {
							//Utils.trace ("%s generic type %s resolved with type %s", symbol.fully_qualified_name, type.type_name, res.fully_qualified_name);
							res = specialize_generic_symbol (type, res);
						}
					} else {
						// resolve type generic types
						foreach (DataType generic_type in type.generic_types) {
							if (generic_type.unresolved)
								generic_type.symbol = resolve_type (res, generic_type);
						}
					}
				}

				if (res != Symbol.VOID) {
					res.add_resolved_target (symbol);
				}
			}
			return res;
		}

		private Symbol specialize_generic_symbol (DataType type, Symbol symbol)
		{
			var c = symbol.copy();
			visit_symbol (c);
			c.specialize_generic_symbol (type.generic_types);
			visit_symbol (c);
			if (c.has_base_types) {
				foreach (var item in c.base_types) {
					if (!item.unresolved) {
						if (item.symbol.has_generic_type_arguments) {
							if (item.symbol == symbol) {
								critical ("Skipping same instance reference cycle: %s %s",  symbol.description, item.type_name);
								continue;
							}
							if (item.symbol.fully_qualified_name == symbol.fully_qualified_name) {
								critical ("Skipping same name reference cycle: %s", item.symbol.description);
								continue;
							}
							//Utils.trace ("resolve generic type for %s: %s", symbol.fully_qualified_name, item.symbol.fully_qualified_name);

							item.symbol = specialize_generic_symbol (type, item.symbol);
						}
					}
				}
			}
			symbol.add_specialized_symbol (c);
			return c;
		}

		private void resolve_symbol (Afrodite.Symbol symbol, Afrodite.DataType type)
		{
			type.symbol = resolve_type (symbol, type);
			if (!type.unresolved) {
				if (type.symbol.return_type != null) {
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
		}
		
		private void visit_symbol (Symbol symbol)
		{
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

		private void visit_symbols (Vala.List<Afrodite.Symbol> symbols)
		{
			foreach (Symbol symbol in symbols) {
				visit_symbol (symbol);
			}
		}
	}
}
