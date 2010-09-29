/* sourcefile.vala
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
	public class SourceFile
	{
		public Vala.List<DataType> using_directives { get; set; }
		public Vala.List<unowned Symbol> symbols { get; set; }
		public unowned Ast parent { get; set; }

		
		
		public string filename {
			get; set;
		}
		
		public SourceFile (string filename)
		{
			this.filename = filename;
		}

		~SourceFile ()
		{
			Utils.trace ("SourceFile destroying: %s", filename);
#if DEBUG
			Utils.trace ("     symbol count before destroy %d", parent.leaked_symbols.size);
#endif
			while (symbols != null && symbols.size > 0) {
				var symbol = symbols.get (0);
				remove_symbol (symbol);
			}
#if DEBUG
			Utils.trace ("     symbol count after destroy  %d", parent.leaked_symbols.size);
#endif
			Utils.trace ("SourceFile destroyed: %s", filename);
		}

		public DataType add_using_directive (string name)
		{
			var u = lookup_using_directive (name);
			if (u == null) {
				if (using_directives == null) {
					using_directives = new ArrayList<DataType> ();
				}
				u = new DataType (name, "UsingDirective");
				using_directives.add (u);
			}
			return u;
		}
		
		public DataType? lookup_using_directive (string name)
		{
			if (using_directives != null) {
				foreach (DataType u in using_directives) {
					if (u.type_name == name) {
						return u;
					}
				}
			}
			
			return null;
		}
		
		public void remove_using_directive (string name)
		{
			var u = lookup_using_directive (name);
			if (u != null) {
				using_directives.remove (u);
				if (using_directives.size == 0)
					using_directives = null;
			}
		}
		
		public bool has_using_directives
		{
			get {
				return using_directives != null;
			}
		}
		
		public void add_symbol (Symbol symbol)
		{
			if (symbols == null) {
				symbols = new ArrayList<unowned Symbol> ();
			}
			assert (symbols.contains (symbol) == false);

			symbols.add (symbol);

#if DEBUG
			// debug
			if (!parent.leaked_symbols.contains (symbol)) {
				parent.leaked_symbols.add (symbol);
				symbol.weak_ref (this.on_symbol_destroy);
			} else {
				Utils.trace ("Symbol already added to the leak check: %s", symbol.fully_qualified_name);
			}
#endif
		}

		public void remove_symbol (Symbol symbol)
		{
			var sr = symbol.lookup_source_reference_sourcefile (this);
			assert (sr != null);
			symbol.remove_source_reference (sr);

			if (symbols.remove (symbol)) {
				if (!symbol.has_source_references && symbol.parent != null) {
					symbol.parent.remove_child (symbol);
				}
			}
			//Utils.trace ("%s remove symbol %s: %u", filename, symbol.fully_qualified_name, symbol.ref_count);
			if (symbols.size == 0)
				symbols = null;
		}
		
		public bool has_symbols
		{
			get {
				return symbols != null;
			}
		}

#if DEBUG
		private void on_symbol_destroy (Object obj)
		{
			parent.leaked_symbols.remove ((Symbol)obj);
			//Utils.trace ("symbol destroyed (%p)",  obj);
		}
#endif
	}
}
