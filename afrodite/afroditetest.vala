/* afroditetest.vala
 *
 * Copyright (C) 2010  Andrea Del Signore
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
using Afrodite;

string option_symbol_name;
int option_line;
int option_column;
string option_namespace;
[NoArrayLength ()]
string[] option_files;

const OptionEntry[] options = {
	{ "symbol-name", 's', 0, OptionArg.STRING, ref option_symbol_name, "Symbol to search NAME", "NAME" },
	{ "line", 'l', 0, OptionArg.INT, ref option_line, "Line NUMBER", "NUMBER" },
	{ "column", 'c', 0, OptionArg.INT, ref option_column, "Column NUMBER", "NUMBER" },
	{ "dump-namespace", 'n', 0, OptionArg.STRING, ref option_namespace, "Namespace to dump NAME", "NAME" },
	{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref option_files, "Source files NAME", "NAME" },
	{ null }
};

public class AfroditeTest.Application : Object {
	public void run (string[] args) {
		int i = 0;
		
		// parse options
		var opt_context = new OptionContext ("- Afrodite Test");
		opt_context.set_help_enabled (true);
		opt_context.add_main_entries (options, null);
		try {
			opt_context.parse (ref args);
		} catch (Error err) {
			error (_("parsing options"));
		}
		
		var engine = new Afrodite.CompletionEngine ("afrodite-test-engine");
		
		print ("Adding sources:\n");
		while (option_files[i] != null) {
			string filename = option_files[i];
			print ("   %s\n", filename);
			engine.queue_sourcefile (filename);
			i++;
		}
		
		Afrodite.Ast ast;

		print ("\nAfrodite engine is parsing sources");
		// Wait for the engine to complete the parsing
		i = 0;
		while (engine.is_parsing)
		{
			if (i % 10 == 0)
				print (".");
			Thread.usleep (1 * 500000);
			i++;
		}
		print (": done\n\n");	
		
		print ("Looking for '%s' %d,%d\n\nDump follows:\n", option_symbol_name, option_line, option_column);
		while (true)
		{
			// try to acquire ast
			if (engine.try_acquire_ast (out ast)) {
				// dumping tree (just a debug facility)
				var dumper = new Afrodite.AstDumper ();
				dumper.dump (ast, option_namespace);
				print ("\n");
				
				// Setup query options
				QueryOptions options = QueryOptions.standard ();
				options.auto_member_binding_mode = true;
				options.compare_mode = CompareMode.EXACT;
				options.access = Afrodite.SymbolAccessibility.ANY;
				options.binding = Afrodite.MemberBinding.ANY;
				
				// Query the AST
				QueryResult sym = ast.get_symbol_type_for_name_and_path (options, option_symbol_name, option_files[0], option_line, option_column);
				print ("The type for '%s' is: ", option_symbol_name);
				if (!sym.is_empty) {
					foreach (ResultItem item in sym.children) {
						print ("%s\n     Childs:\n", item.symbol.name);
						if (item.symbol.has_children) {
							int count = 0;
							// print an excerpt of the child symbols
							foreach (var child in item.symbol.children) {
								print ("          %s\n", child.description);
								count++;
								if (count == 6) {
									print ("          ......\n");
									break;
								}
							}
						}
					}
				} else {
					print ("unresolved :(\n");
				}
				engine.release_ast (ast);
				break;
			}
		}
		
		print ("done\n");
	}

	static int main (string[] args) {
		var application = new Application ();
		application.run (args);
		return 0;
	}
}
