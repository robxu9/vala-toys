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

namespace Vsc
{
	public class CompletionShell : Object
	{
		private SymbolCompletion _completion = new SymbolCompletion ();
		private MainLoop _loop;
		private bool _pause_execution = false;

		public void run ()
		{
			_loop = new MainLoop (null, false);
			var inp = new IOChannel.unix_new (0); //stdin
			inp.set_line_term ("\n", 1);
			inp.add_watch (IOCondition.IN, this.on_input);
			print_message ("Welcome!");

			//automatically add GLib
			add_package_from_namespace ("GLib");
			prompt ();
			_loop.run ();
		}

		private bool on_input (IOChannel source, IOCondition condition)
		{
			try {
				string data;
				size_t length, term_pos;

				source.read_line (out data, out length, out term_pos);
				
				if (length > 0) {
					if (term_pos > 0) {
						// strip terminator
						data = data.substring (0, (long) term_pos);
					}
					if (!execute (data))
						return false; //request to exit
				}
				prompt ();

			} catch (Error err) {
				warning ("error reading command: %s", err.message);
			}
			return true;
		}

		private bool execute (string command)
		{
			if (command != null && command.length > 0) {
				string[] toks = command.split (" ", 0);
				int count = 0;
				while (toks[count] != null)
					count++;

				switch (toks[0]) {
				    case "\n":
						debug ("p");
						this._pause_execution = false;
						break;
					case "quit":
						print_message ("Bye bye!");
						_loop.quit ();
						return false;
					case "add-package":
						add_package (toks[1]);
						break;
					case "find":
						if (count == 2)
							find_by_name (toks[1]);
						else
							print_error ("invalid command arguments");
						break;
					case "describe":
						if (count == 5) {
							describe_symbol (toks[1], toks[2], toks[3].to_int (), toks[4].to_int ());
						} else {
							print_error ("invalid command arguments");
						}
						break;
					case "add-source":
						add_source (toks[1]);
						break;
					case "using":
						add_package_from_namespace (toks[1]);
						break;
					case "execute":
						import (toks[1]);
						break;
					case "pause":
						pause ();
						break;
					default:
						print_error ("unknown command '%s'".printf (command));
						break;
				}
			}
			return true;
		}

		private void describe_symbol (string name, string sourcefile, int line, int column)
		{
			try {
				var dt = _completion.find_datatype_for_name (name, sourcefile, line, column);
				if (dt is Vala.UnresolvedSymbol) {
					UnresolvedSymbol sym = dt as UnresolvedSymbol;
					print_message ("unresolved symbol: %s".printf(sym.name));
				} else if (dt != null) {
					string name = dt.to_qualified_string ();
					if (name.has_suffix ("?")) {
						name = name.substring (0, name.length - 1);
					}
					print_message ("datatype found: %s (%s)".printf(name, dt.to_qualified_string ()));
					
					find_by_name ("%s.".printf(name));
				} else {
					print_message ("no datatype found");
				}
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void pause ()
		{
			this._pause_execution = true;
		}

		private void import (string filename)
		{
			try {
				if (FileUtils.test (filename, FileTest.EXISTS)) {
					size_t len;
					string buffer;
					FileUtils.get_contents (filename, out buffer, out len);
					print_message ("running...");
					foreach (string command in buffer.split("\n")) {
						print_message ("   %s".printf(command));
						execute (command);
					}
				} else {
					print_error ("file not found");
				}
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void add_package (string packagename)
		{
			try {
				_completion.add_package (packagename);
				print_message ("package '%s' added".printf (packagename));
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void add_source (string filename)
		{
			try {
				_completion.add_source (filename);
				print_message ("source file '%s' added".printf (filename));
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void add_package_from_namespace (string @namespace)
		{
			try {
				_completion.add_package_from_namespace (@namespace);
				print_message ("package '%s' added".printf (@namespace));
			} catch (Error err) {
				print_error (err.message);
			}
		}

		private void append_symbols (StringBuilder sb, Gee.List<Vala.Symbol> symbols)
		{
			foreach (Vala.Symbol symbol in symbols) {
				sb.append ("      %s\n".printf(symbol.name));
			}
		}

		private void find_by_name (string data)
		{
			try {
				var options = new SymbolCompletionFilterOptions ();
				var result = _completion.find_by_name (options, data);
				display_result (result);
			} catch (Error err) {
				print_error (err.message);
			} 
		}

		private void display_result (SymbolCompletionResult result)
		{
			if (!result.is_empty) {
				print_message ("symbols:");
				var sb = new StringBuilder ();

				if (result.fields.size > 0) {
					sb.append ("   fields:\n");
					append_symbols (sb, result.fields);
				}
				if (result.properties.size > 0) {
					sb.append ("   properties:\n");
					append_symbols (sb, result.properties);
				}
				if (result.methods.size > 0) {
					sb.append ("   methods:\n");
					append_symbols (sb, result.methods);
				}

				if (result.signals.size > 0) {
					sb.append ("   signals:\n");
					append_symbols (sb, result.signals);
				}

				if (result.classes.size > 0) {
					sb.append ("   classes:\n");
					append_symbols (sb, result.classes);
				}
				if (result.interfaces.size > 0) {
					sb.append ("   interfaces:\n");
					append_symbols (sb, result.interfaces);
				}

				if (result.structs.size > 0) {
					sb.append ("   structs:\n");
					append_symbols (sb, result.structs);
				}
				if (result.others.size > 0) {
					sb.append ("   others:\n");
					append_symbols (sb, result.others);
				}

				print_message (sb.str);
			} else {
				print_message ("no symbol found");
			}
		}

		private void prompt ()
		{
			stdout.printf ("> ");
			stdout.flush ();
		}

		public void print_error (string message)
		{
			stdout.printf ("* error: %s\n", message);
			stdout.flush ();
		}

		public void print_message (string message, bool new_line = true)
		{
			if (new_line)
				stdout.printf ("%s\n", message);
			else
				stdout.printf ("%s", message);

			stdout.flush ();
		}
	}

	public static void main (string [] args)
	{
		var cs = new CompletionShell ();
		cs.run ();
	}
}