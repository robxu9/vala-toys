/* contextdump.vala
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
	public class AstDumper : CodeVisitor
	{
		string pad = null;
		int level = 0;
		int symbols = 0;
		int unresolved_types = 0;
		int types = 0;
				
		private void inc_pad ()
		{
			if (pad == null) {
				pad = "";
				level = 0;
			} else {
				level++;
				pad = string.nfill (level, '\t');
			}
		}
		
		private void dec_pad ()
		{
			if (pad == null) {
				pad = "";
				level = 0;
				GLib.error ("dec_pad call!!!");
			} else if (level == 0) {
				pad = null;
			} else {
				level--;
				pad = string.nfill (level, '\t');
			}
		}
		
		private string print_datatype (DataType type, bool update_counters = true)
		{
			if (update_counters)
				types++;
			var sb = new StringBuilder ();
			sb.append (type.type_name);
			if (type.symbol == null) {
				sb.append (" (U)");
				if (update_counters)
					unresolved_types++;
			}
			if (type.name != null) {
				if (type.symbol != null)
					sb.append (" ");
				sb.append_printf ("%s", type.name);
			}
			return sb.str;
		}
		
		private void print_symbol (Afrodite.Symbol? s)
		{
			print ("%s\n", create_symbol_dump_info (s));
		}

		public string create_symbol_dump_info (Afrodite.Symbol? s, bool update_counters = true)
		{
			if (s == null)
				return "(empty)";
			
			if (pad == null)
				inc_pad ();
				
			var sb = new StringBuilder ();
			
			sb.append (pad);
			
			// accessibility
			sb.append_printf ("%s ", s.access_string);
			
			// accessibility
			string binding;
			switch (s.binding) {
				case Afrodite.MemberBinding.CLASS:
					binding = "@class";
					break;
				case Afrodite.MemberBinding.STATIC:
					binding = "static";
					break;
				case Afrodite.MemberBinding.INSTANCE:
				default:
					binding = null;
					break;
			}
			if (binding != null)
				sb.append_printf ("%s ", binding);
			

			if (s.type_name == "Namespace"
			    || s.type_name == "Class"
			    || s.type_name == "Struct"
			    || s.type_name == "Interface"
			    || s.type_name == "Enum"
			    || s.type_name == "ErrorDomain")
				sb.append_printf ("%s ", s.type_name.down ());

			sb.append_printf ("%s ", s.description);
			
			if (s.has_source_references) {
				sb.append ("   - [");
				foreach (SourceReference sr in s.source_references) {
					sb.append_printf ("(%d - %d) %s, ", sr.first_line, sr.last_line, sr.file.filename);
				}
				sb.truncate (sb.len - 2);
				sb.append ("]");
			}
			if (update_counters)
				symbols++;
			return sb.str;
		}

		public void dump (Ast ast, string? filter_symbol = null)
		{
			pad = null;
			level = 0;
			symbols = 0;
			unresolved_types = 0;
			types = 0;
				
			var timer = new Timer ();
			timer.start ();
			
			if (ast.root.has_children) {
				dump_symbols (ast.root.children, filter_symbol);
				print ("Dump done. Symbols %d, Types examinated %d of which unresolved %d\n", symbols, types, unresolved_types);
			} else
				print ("context empty!\n");
			
			if (ast.has_source_files) {
				print ("Source files:\n");
				foreach (SourceFile file in ast.source_files) {
					print ("\tsource: %s\n", file.filename);
					if (file.has_using_directives) {
						print ("\t\tusing directives:\n");
						foreach (Symbol symbol in file.using_directives) {
							print ("\t\t\tusing: %s\n", symbol.fully_qualified_name);
						}
					}
				}
			}
			timer.stop ();
			print ("Dump done in %g\n", timer.elapsed ());
		}
		
		private void dump_symbols (Gee.List<Afrodite.Symbol> symbols, string? filter_symbol)
		{
			inc_pad ();
			foreach (Symbol symbol in symbols) {
				if (filter_symbol == "" || filter_symbol == null || filter_symbol == symbol.fully_qualified_name) {
					print_symbol (symbol);
					if (symbol.has_local_variables) {
						inc_pad ();
						print ("%slocal variables\n", pad);
						foreach (DataType local in symbol.local_variables) {
							print ("%s   %s\n", pad, print_datatype (local));
						}
						dec_pad ();
					}
					if (symbol.has_children) {
						dump_symbols (symbol.children, null);
					}
				}
			}
			dec_pad ();
		}
	}
}
