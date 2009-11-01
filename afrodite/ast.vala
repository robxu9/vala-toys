/* ast.vala
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
using Gee;

namespace Afrodite
{
	public enum LookupCompareMode
	{
		EXACT,
		START_WITH
	}
	
	public class Ast
	{
		public Symbol root = new Symbol (null, null);
		public Gee.List<SourceFile> source_files = null;
		
		public Symbol? lookup (string fully_qualified_name, out Symbol? parent)
		{
			Symbol result = null;
			
			if (root.has_children) {
				result = lookup_symbol (fully_qualified_name, root.children, out parent, LookupCompareMode.EXACT);
			}
			
			if (parent == null) {
				parent = root;
			}
			return result;
		}
		
		internal static Symbol? lookup_symbol (string qualified_name, Gee.List<Symbol> symbols, 
			out Symbol? parent,  LookupCompareMode mode,
			SymbolAccessibility access = SymbolAccessibility.ANY, MemberBinding binding = MemberBinding.ANY)
		{
			string[] tmp = qualified_name.split (".", 2);
			string name = tmp[0];
		
			parent = null;
			foreach (Symbol symbol in symbols) {
				//print ("  Looking for %s: %s in %s\n", fully_qualified_name, name, symbol.fully_qualified_name);
				
				if (compare_symbol_names (symbol.name, name, mode)
				    && (symbol.access & access) != 0
				    && (symbol.binding & binding) != 0) {
					if (tmp.length > 1) {
						Symbol child_sym = null;
						
						if (symbol.has_children) {
							child_sym = lookup_symbol (tmp[1], symbol.children, out parent, mode, access, binding);
						}
						
						if (child_sym == null) {
							parent = symbol; // the last valid parent
						} else {
							parent = child_sym.parent;
						}
						return child_sym;
					} else {
						parent = symbol.parent;
						return symbol;
					}
				}
			}
			
			return null;
		}
		
		public bool has_source_files
		{
			get {
				return source_files != null;
			}
		}

		internal SourceFile add_source_file (string filename)
		{
			var file = lookup_source_file (filename);
			if (file == null) {
				file = new SourceFile (filename);
				if (source_files == null) {
					source_files = new ArrayList<SourceFile> ();
				}
				source_files.add (file);
			}
			return file;			
		}
		
		public SourceFile? lookup_source_file (string filename)
		{
			if (source_files != null) {
				foreach (SourceFile file in source_files) {
					//debug ("searching %s vs %s", file.filename, filename);
					
					if (file.filename == filename) {
						return file;
					}
				}
			} else {
				debug ("no source files!!!");
				
			}		
			return null;
		}
		
		internal void remove_source (SourceFile source)
		{
			return_if_fail (source_files != null);
			source_files.remove (source);
		}
		
		public Symbol? lookup_symbol_at (string filename, int line, int column)
		{
			var source = lookup_source_file (filename);
			if (source == null || !source.has_symbols)
				return null;
			
			Symbol sym = lookup_symbol_with_source_at (source, line, column);
			return sym;
		}

		public Symbol? lookup_name_at (string qualified_name, string filename, int line, int column,
			LookupCompareMode mode,
			SymbolAccessibility access = SymbolAccessibility.ANY, MemberBinding binding = MemberBinding.ANY)
		{
			return  lookup_name_or_type_at (qualified_name, filename, line, column, false, mode, access, binding);
		}

		public Symbol? lookup_name_for_type_at (string qualified_name, string filename, int line, int column,
			LookupCompareMode mode,
			SymbolAccessibility access = SymbolAccessibility.ANY, MemberBinding binding = MemberBinding.ANY)
		{
			return  lookup_name_or_type_at (qualified_name, filename, line, column, true, mode, access, binding);
		}		
		
		private Symbol? lookup_name_or_type_at (string qualified_name, string filename, int line, int column, 
			bool lookup_type, LookupCompareMode mode,
			SymbolAccessibility access = SymbolAccessibility.ANY, MemberBinding binding = MemberBinding.ANY)
		{
			var source = lookup_source_file (filename);
			if (source == null || !source.has_symbols) {
				warning ("source file not found %s", filename);
				return null;
			}
			
			Symbol sym = lookup_symbol_with_source_at (source, line, column);
			if (sym != null) {
				string[] parts = qualified_name.split (".");
				sym = lookup_name_with_symbol (parts[0], sym, source, mode);
				if (sym != null && sym.return_type != null)
					sym = sym.return_type.symbol;
				
				if (parts.length > 1 && sym != null && sym.has_children) {
					// change the scope of symbol search
					if (parts[0] == "this") {
						binding = binding & (~ ((int) MemberBinding.STATIC));
					} else if (parts[0] == "base") {
						binding = binding & (~ ((int) MemberBinding.STATIC));
						access = access & (~ ((int) SymbolAccessibility.PRIVATE));
					}
					if (sym.type_name == "Namespace"
					    || (parts[0] == sym.name && (sym.type_name == "Class" || sym.type_name == "Struct" || sym.type_name == "Interface"))) {
					    	// namespace access or MyClass.my_static_method
						binding = MemberBinding.STATIC;
					}
					for (int i = 1; i < parts.length; i++) {
	 					Symbol parent = sym;
	 					Symbol dummy;
	 					
	 					print ("lookup %s in %s", parts[i], sym.name);
						sym = lookup_symbol (parts[i], sym.children, out dummy, mode);
						print ("... result: %s\n", sym == null ? "not found" : sym.name);
						if (sym != null && lookup_type && sym.return_type != null) {
								sym = sym.return_type.symbol;
						}
						
						if (sym == null) {
							// lookup on base types also
							sym = lookup_name_in_base_types (parts[i], parent);
						}
						
						if (sym == null)
							break;
					}
				}
			}
			
			// return the symbol or the return type: for properties, field and methods
			if (sym != null && sym.return_type != null && lookup_type)
				return sym.return_type.symbol;
			else
				return sym;
		}
		
		public Symbol? lookup_symbols_in (string filename)
		{
			var options = DetachCopyOptions.standard ();
			var res = root.detach_copy (0, options);
			
			lookup_symbol_in_filename (filename, res, root);
			
			if (res.has_children) {
				return res;
			}
			
			return null;
		}

		private void lookup_symbol_in_filename (string filename, Symbol results, Symbol parent)
		{
			if (!parent.has_children)
				return;

			foreach (Symbol symbol in parent.children) {
				print ("  Looking for %s in %s, parent count %d, %s\n", filename, symbol.fully_qualified_name, parent.children.size, parent.fully_qualified_name);
				
				if (symbol_has_filename_reference(filename, symbol)) {
					var options = DetachCopyOptions.standard ();
					var sym = symbol.detach_copy (0, options);
					
					//print ("    adding %s", sym.name);
					
					results.add_child (sym);
					if (symbol.has_children) {
						// try to catch circular references
						var item = parent;
						bool circular_ref = false;
						
						while (item != null) {
							if (sym == parent) {
								warning ("circular reference %s", sym.fully_qualified_name);
								circular_ref = true;
								break;
							}
							item = item.parent;
						}
						// find in children
						if (!circular_ref)
							lookup_symbol_in_filename (filename, sym, symbol);
					}
				}
			}
		}
		
		private bool symbol_has_filename_reference (string filename, Symbol symbol)
		{
			if (!symbol.has_source_references)
				return false;

			foreach (SourceReference sr in symbol.source_references) {
				if (sr.file.filename == filename) {
					return true;
				}
			}
			
			return false;
		}
		private Symbol? lookup_name_in_base_types (string name, Symbol? symbol,
			SymbolAccessibility access = SymbolAccessibility.ANY, MemberBinding binding = MemberBinding.ANY)
		{
			// search in base classes / interfaces
			if (symbol.has_base_types) {
				Symbol parent;
				foreach (DataType type in symbol.base_types) {
					if (!type.unresolved) {
						if (type.symbol.name == name
						    && (type.symbol == null || (type.symbol.access & access) != 0)
						    && (type.symbol == null || (type.symbol.binding & binding) != 0)) {
							return type.symbol;
						}
						if (type.symbol.has_children) {
							var sym = lookup_symbol (name, type.symbol.children, out parent, LookupCompareMode.EXACT, access, binding);
							if (sym != null) {
								return sym;
							}
						}
					}
				}
					
			}
			
			return null;

		}
		
		private Symbol? lookup_this_symbol (Symbol? root)
		{
			// search first class in the parent chain, break when a namespace is found
			Symbol current = root;
			while (current != null) {
				if (current.type_name == "Class" || current.type_name == "Struct") {
					break;
				} else if (current.type_name == "Namespace") {
					current = null; // exit
				} else
					current = current.parent;
			}
			
			return current;
		}
		
		private static bool compare_symbol_names (string name1, string name2, LookupCompareMode mode)
		{
			if (mode == LookupCompareMode.START_WITH) {
				return name1.has_prefix (name2);
			} else {
				return name1 == name2;
			}
		}

		private Symbol? lookup_name_with_symbol (string name, Symbol? symbol, SourceFile source, LookupCompareMode mode,
			SymbolAccessibility access = SymbolAccessibility.ANY, MemberBinding binding = MemberBinding.ANY)
		{
			// first try to find the symbol datatype
			if (name == "this") {
				return lookup_this_symbol (symbol);
			} else if (name == "base") {
				Symbol? this_sym = lookup_this_symbol (symbol);
				
				if (this_sym != null && this_sym.has_base_types) {
					foreach (DataType type in this_sym.base_types) {
						debug ("search base types: %s", type.type_name);
						
						if (!type.unresolved && type.symbol.type_name == "Class") {
							return type.symbol;
						}
					}
				}
			} else {
				// search in local vars going up in the scope chain
				var current_sym = symbol;
				while (current_sym != null) {
					if (current_sym.has_local_variables) {
						foreach (DataType type in current_sym.local_variables) {
							if (compare_symbol_names (type.name, name, mode)
							    && (type.symbol == null || (type.symbol.access & access) != 0)
							    && (type.symbol == null || (type.symbol.binding & binding) != 0)) {
								return type.symbol;
							}
						}
					}
					current_sym = current_sym.parent;
				}
				
				// search in symbol parameters
				if (symbol.has_parameters) {
					foreach (DataType type in symbol.parameters) {
						if (compare_symbol_names (type.name, name, mode)
						    && (type.symbol == null || (type.symbol.access & access) != 0)
						    && (type.symbol == null || (type.symbol.binding & binding) != 0)) {
							return type.symbol;
						}
					}
				}
				
				// search in sibling
				current_sym = symbol.parent;
				while (current_sym != null) {
					if (current_sym != null && current_sym.has_children) {
						foreach (Symbol sibling in current_sym.children) {
							if (sibling != symbol && compare_symbol_names (sibling.name, name, mode)
							    && (sibling.access & access) != 0
							    && (sibling.binding & binding) != 0) {
								return sibling;
							}
						}
					}
					current_sym = current_sym.parent;
				}
								
				var sym = lookup_name_in_base_types (name, symbol, access, binding);
				if (sym != null)
					return sym;
					
				// search in using directives
				if (source.has_using_directives) {
					foreach (Symbol u in source.using_directives) {
						Symbol parent;
						
						sym = lookup (u.name, out parent);
						if (sym != null) {
							if (compare_symbol_names (sym.name, name, mode)) {
								// is a reference to a namespace
								return sym;
							} else if (sym.has_children) {
								sym = lookup_symbol (name, sym.children, out parent, mode, access, binding);
								if (sym != null) {
									return sym;
								}
							}
						}
					}
				}
			}
			
			return null;
		}

		public Symbol? lookup_symbol_with_source_at (SourceFile source, int line, int column)
		{
			Symbol result = null;
			SourceReference result_sr = null;
			
			foreach (Symbol symbol in source.symbols) {
				var sr = symbol.lookup_source_reference_sourcefile (source);
				//print ("%s: %d-%d %d-%d vs %d, %d\n", symbol.name, sr.first_line, sr.first_column, sr.last_line, sr.last_column, line, column);
				if ((sr.first_line < line || ((line == sr.first_line && column >= sr.first_column) || sr.first_column == 0))
				    && (line < sr.last_line || ((line == sr.last_line && column <= sr.last_column) || sr.last_column == 0))) {
					// let's find the best symbol
					if (result == null 
					   || result_sr.first_line < sr.first_line 
					   || (result_sr.first_line == sr.first_line && result_sr.first_column < sr.first_column && result_sr.first_column != 0 && sr.first_column != 0)
					   || result_sr.last_line > sr.last_line
					   || (result_sr.last_line == sr.last_line && result_sr.last_column  > sr.last_column && result_sr.last_column != 0 && sr.last_column  != 0))
					{
						// this symbol is better
						//print ("lookup_symbol_at: found %s\n", symbol.name);
						result = symbol;
						result_sr = sr;
					}
				}
			}
			
			return result;
		}
	}
}
