/*
 *  vtgsymbolcompletionshell.vala - Vala developer toys for GEdit
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *   
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *   
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330,
 *  Boston, MA 02111-1307, USA.
 */

using GLib;
using Vala;
using Vsc;
using ReadLine;

namespace Vsc
{
	public class CompletionShell : Object
	{
		static string option_execute_script = null;

		const OptionEntry[] options = {
			{ "exec", 'e', 0, OptionArg.STRING, ref option_execute_script, "Execute script", "FILE" },
			{ null }
		};

		private SymbolCompletion _completion = new SymbolCompletion ();
		private string redirect_filename = "";
		
		public void run (string? script = null)
		{
			bool exit = false;
			_completion.parser.resume_parsing ();
			if (script != null) {
				exit = !execute_command ("execute %s".printf (script));
			}
			while (!exit) {
				string line = read_line ("> ");
				if (line != null && line != "") {
					add_history (line);
					exit = !execute_command (line.strip ());
				}
			}
		}

		private bool execute_command (string command)
		{
			if (command != null && command.length > 0) {
				string[] toks = command.split (" ", 0);
				int count = 0;
				while (toks[count] != null)
					count++;

				switch (toks[0]) {
					case "quit":
						print_message ("Stopping the parser engine");
						_completion.cleanup ();
						print_message ("Bye bye!");
						return false;
					case "add-package":
						add_package (toks[1]);
						break;
					case "type-name":
						if (count == 5) {
							int line = toks[3].to_int ();
							int col = toks[4].to_int ();
							
							type_name (toks[1], toks[2], line, col);
						} else
							print_error ("invalid command arguments");

						break;
					case "complete":
 						switch (count) {
 						case 5:
 							complete (toks[1], toks[2], toks[3].to_int (), toks[4].to_int ());
 							break;
 						case 3:
 							complete (toks[1], toks[2], 0, 0);
 							break;
 						case 2:
 							complete (toks[1], null, 0, 0);
 							break;
 						default:
 							print_error ("invalid command arguments");
 							break;
 						}
						break;
					case "add-source":
						if (count == 2)
							add_source (toks[1]);
						else if (count == 3) {
							bool sec = toks[2].to_int () != 0;
							add_source (toks[1], sec);
						}							
						break;
					case "remove-source":
						if (count == 2)
							remove_source (toks[1]);
						else if (count == 3) {
							bool sec = toks[2].to_int () != 0;
							remove_source (toks[1], sec);
						}							
						break;
					case "update-source":
						if (count == 2)
							update_source (toks[1]);
						else if (count == 3) {
							bool sec = toks[2].to_int () != 0;
							update_source (toks[1], sec);
						}							
						break;						
					case "add-namespace":
						add_package_from_namespace (toks[1]);
						break;
					case "execute":
						execute (toks[1]);
						break;
					case "reparse":
						reparse (toks[1] == "both");
						break;
					case "redirect-output":
						set_redirect_file (toks[1]);
						break;
					case "suspend-parsing":
						_completion.parser.suspend_parsing ();
						break;
					case "resume-parsing":
						_completion.parser.resume_parsing ();
						break;
					case "wait-parser-engine":
						print_message ("waiting parser engine...");
						while (_completion.parser.is_cache_building ()) 
							Thread.usleep(10000);
						break;
					case "get-namespaces":
						get_namespaces ();
						break;
					case "get-classes":
						if (count == 2)
							get_classes (toks[1]);
						break;
					case "visible-types":
						if (4 == count) {
							visible_types (toks[1], toks[2].to_int(), toks[3].to_int());
						} else {
 							print_error ("invalid command arguments");
						}
						break;
					case "visible-symbols":
						if (4 == count) {
							visible_symbols (toks[1], toks[2].to_int(), toks[3].to_int());
						} else {
 							print_error ("invalid command arguments");
						}
						break;
					default:
						print_error ("unknown command '%s'".printf (command));
						break;
				}
			}
			return true;
		}

		private void set_redirect_file (string? filename)
		{
			if (filename == "")
				this.redirect_filename = null;
			else
				this.redirect_filename = filename;
		}
		
		private void reparse (bool both_context)
		{
			_completion.parser.reparse (both_context);
		}

		private void execute (string filename)
		{
			try {
				if (FileUtils.test (filename, FileTest.EXISTS)) {
					size_t len;
					string buffer;
					FileUtils.get_contents (filename, out buffer, out len);
					print_message ("running script '%s'...".printf (filename));
					foreach (string line in buffer.split("\n")) {
						string command = line.strip ();
						if (command != null && command != "") {
							print_message ("   %s".printf(command));
							execute_command (command);
						}
					}
				} else {
					print_error ("script file not found: %s".printf (filename));
				}
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void add_package (string packagename)
		{
			try {
				_completion.parser.add_package (packagename);
				print_message ("package '%s' added".printf (packagename));
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void update_source (string filename, bool secondary = false)
		{
			_completion.parser.suspend_parsing ();
			remove_source (filename);
			add_source (filename, secondary);
			_completion.parser.resume_parsing ();		
		}
		
		private void add_source (string filename, bool secondary = false)
		{
			try {
				if (secondary) {
					string source = null;
					ulong len = 0;
					FileUtils.get_contents (filename, out source, out len);
					_completion.parser.add_source_buffer (new Vsc.SourceBuffer (filename, source));
					
				} else {
					_completion.parser.add_source (filename);
				}
				print_message ("source '%s' added to context %s".printf (filename, secondary ? "secondary" : "primary"));
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void remove_source (string filename, bool secondary = false)
		{
			try {
				if (secondary) {
					_completion.parser.remove_source_buffer_by_name (filename);
				} else {
					_completion.parser.remove_source (filename);
				}
				print_message ("source file '%s' removed".printf (filename));
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void add_package_from_namespace (string @namespace)
		{
			try {
				_completion.parser.add_package_from_namespace (@namespace);
				print_message ("package '%s' added".printf (@namespace));
			} catch (Error err) {
				print_error (err.message);
			}
		}


		private void type_name (string word, string source, int line, int col)
		{
			try {
				var typename = _completion.get_datatype_name_for_name (word, source, line, col);
				if (typename != null) {
					print_message ("typename for %s: %s".printf (word, typename));
				} else {
					print_message ("type name not found for %s".printf (word));
				}
			} catch (Error err) {
				print_error (err.message);
			}
		}
		
		private void complete (string typename, string? source, int line, int col)
		{
			try {
				var options = new SymbolCompletionFilterOptions ();
				var completion_result = _completion.get_completions_for_name (options, typename, source, line, col);
				display_result (completion_result);
			} catch (Error err) {
				print_error (err.message);
			} 
		}

		private void get_namespaces ()
		{
			display_result (_completion.get_namespaces ());
		}

		private void get_classes (string filename)
		{
			display_result (_completion.get_classes_for_source (filename));
		}
		
		private void visible_types (string filename, int line, int column)
		{
			display_result (_completion.get_visible_symbols (new SymbolCompletionFilterOptions (), filename, line, column, true));
		}
		
		private void visible_symbols (string filename, int line, int column)
		{
			display_result (_completion.get_visible_symbols (new SymbolCompletionFilterOptions (), filename, line, column, false));
		}
		
		private void append_symbols (string type, StringBuilder sb, Vala.List<SymbolCompletionItem> symbols)
		{
			foreach (SymbolCompletionItem symbol in symbols) {
 				sb.append ("%s:%s:%s;:;:;%s:%d;%d;\n".printf(type, symbol.name, get_access(symbol), symbol.file, symbol.first_line, symbol.last_line));
 			}
 		}
 		
 		private static void append_methods (StringBuilder sb, Vala.List<SymbolCompletionItem> methods)
 		{
			Method? method;
			DataType? sometype;
			string is_owned;
			string typename;
			string paramname;
			
			foreach (SymbolCompletionItem item in methods) {
				method = (Method?)item.symbol;
				if (null != method) {
					// TYPE:NAME:MODIFIER;STATIC:RETURN_TYPE;OWNERSHIP:ARGS;FILE:FIRST_LINE;LAST_LINE;
					sometype = method.return_type;
					if (null != sometype) {
						typename = sometype.to_string();
						is_owned = sometype.value_owned? "": "unowned";
					}
					else { 
						is_owned = "";
						typename = "";
					}
					
					sb.append("method:%s:%s;%s:%s;%s:".printf (item.name, get_access(item), "", typename, is_owned));
					foreach (FormalParameter param in method.get_parameters ()) {
						//  name,vala type,OWNERSHIP
						sometype = param.parameter_type;
						if (null != sometype) {
							typename = sometype.to_string();
							is_owned = sometype.value_owned? "": "unowned";
						}
						else { 
							is_owned = "";
							typename = "";
						}
						
						paramname = ("(null)" == param.name.strip ())? "...": param.name;
						
						sb.append ("%s,%s,%s;".printf( paramname, typename, is_owned));
					}

					sb.append ("%s:%d;%d;\n".printf(item.file, item.first_line, item.last_line));
				} else {
					sb.append ("method:%s:;:;:;%s:%d;%d;\n".printf (item.name, item.file, item.first_line, item.last_line));
				}
			}
 		}
 
 		private static string get_access(SymbolCompletionItem symbol) 
 		{
 			Symbol? sym_real = symbol.symbol;
 			string access = "";
 			
 			if (null != sym_real) {
 				switch (sym_real.access) {
 							case SymbolAccessibility.PUBLIC:
 								access = "public";
 								break;
 							case SymbolAccessibility.PRIVATE:
 								access = "private";
 								break;
 							case SymbolAccessibility.PROTECTED:
 								access = "protected";
 								break;
 							case SymbolAccessibility.INTERNAL:
 								access = "internal";
 								break;
 							default:
 								break;
 				}
 			}
 
 			return access;
		}

		private void display_result (SymbolCompletionResult completions)
		{
			if (!completions.is_empty) {
				var sb = new StringBuilder ();

				print_message ("symbols found");
				if (completions.enums.size > 0) {
					append_symbols ("enums", sb, completions.enums);
				}
				if (completions.constants.size > 0) {
					append_symbols ("constants", sb, completions.constants);
				}
				if (completions.namespaces.size > 0) {
					append_symbols ("namespaces", sb, completions.namespaces);
				}
				if (completions.fields.size > 0) {
					append_symbols ("field", sb, completions.fields);
				}
				if (completions.properties.size > 0) {
					append_symbols ("property", sb, completions.properties);
				}
				if (completions.methods.size > 0) {
					append_methods (sb, completions.methods);
				}

				if (completions.signals.size > 0) {
					append_symbols ("signal", sb, completions.signals);
				}
				if (completions.classes.size > 0) {
					append_symbols ("class", sb, completions.classes);
				}
				if (completions.interfaces.size > 0) {
					append_symbols ("interface", sb, completions.interfaces);
				}
				if (completions.structs.size > 0) {
					append_symbols ("struct", sb, completions.structs);
				}
				if (completions.others.size > 0) {
					append_symbols ("other", sb, completions.others);
				}
				print_message (sb.str);
			} else {
				print_message ("no symbol found");
			}
		}

		public void print_error (string message)
		{
			stdout.printf ("vsc-shell *** ERROR *** - %s\n", message);
			stdout.flush ();
		}

		public void print_message (string message)
		{
			string data;
			data = "%s".printf (message);
			string[] lines = data.split ("\n");
			FileStream file = null;
			if (this.redirect_filename != null) {
				file = FileStream.open (this.redirect_filename, "w+");
			}
			
			foreach (string line in lines) {
				string buffer = "vsc-shell - %s\n".printf (line);
				stdout.printf (buffer);
				if (file != null)
					file.puts (buffer);
				stdout.flush ();
			}
			
			if (file != null) {
				file.flush ();
				file = null;
			}
		}

		public static int main (string [] args)
		{
			try {
		                var opt_context = new OptionContext ("- Vsc Completion Shell");
		                opt_context.add_main_entries (options, null);
		                opt_context.parse (ref args);
		        } catch (OptionError e) {
		                stdout.printf ("%s\n", e.message);
		                stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
		                return 1;
		        }
			var cs = new CompletionShell ();
			cs.run (option_execute_script);
			return 0;
		}
	}
}
