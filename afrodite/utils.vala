/* utils.vala
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

namespace Afrodite.Utils
{
	/**
	 * This function shouldn't be used directly but just wrapped with a private one that
	 * will specify the correct log domain. See the function trace (...) in this same source 
	 */
	public static inline void log_message (string log_domain, string format, va_list args)
	{
		logv (log_domain, GLib.LogLevelFlags.LEVEL_INFO, format, args);
	}

	[Diagnostics]
	[PrintfFormat]
	internal static inline void trace (string format, ...)
	{
#if DEBUG
		var va = va_list ();
		var va2 = va_list.copy (va);
		log_message ("Afrodite", format, va2);
#endif
	}

	public static Vala.List<string>? get_package_paths (string pkg, CodeContext? context = null, string[]? vapi_dirs = null)
	{
		var ctx = context;
		if (ctx == null) {
			ctx = new Vala.CodeContext();
		}
		
		var package_path = ctx.get_package_path (pkg, vapi_dirs);
		if (package_path == null) {
			return null;
		}
		
		var results = new ArrayList<string> ();
		
		var deps_filename = Path.build_filename (Path.get_dirname (package_path), "%s.deps".printf (pkg));
		if (FileUtils.test (deps_filename, FileTest.EXISTS)) {
			try {
				string deps_content;
				ulong deps_len;
				FileUtils.get_contents (deps_filename, out deps_content, out deps_len);
				foreach (string dep in deps_content.split ("\n")) {
					dep.strip ();
					if (dep != "") {
						var deps = get_package_paths (dep, ctx);
						if (deps == null) {
							warning ("%s, dependency of %s, not found in specified Vala API directories".printf (dep, pkg));
						} else {
							foreach (string dep_package in deps) {
								results.add (dep_package);
							}
						}
					}
				}
			} catch (FileError e) {
				warning ("Unable to read dependency file: %s".printf (e.message));
			}
		}
		
		results.add (package_path);
		return results;
	}

	public static bool add_package (string pkg, CodeContext context) 
	{
		if (context.has_package (pkg)) {
			// ignore multiple occurences of the same package
			return true;
		}

		Vala.List<string> packages = get_package_paths (pkg, context);
		if (packages == null) {
			return false;
		}
	
		context.add_package (pkg);
		
		foreach (string package_path in packages) {
			context.add_source_file (new Vala.SourceFile (context, package_path, true));
		}
		return true;
	}
	
	namespace Symbols
	{
		private static PredefinedSymbols _predefined = null;
		
		public static PredefinedSymbols get_predefined ()
		{
			if (_predefined == null)
				_predefined = new PredefinedSymbols ();
				
			return _predefined;
		}

		public class PredefinedSymbols
		{
			private Symbol _connect_method;
			private Symbol _disconnect_method;
			private Symbol _signal_symbol;
			
			public DataType signal_type;
			
			public PredefinedSymbols ()
			{
				_connect_method = new Afrodite.Symbol ("connect", "Method");
				_connect_method.return_type = new DataType ("void");
				_connect_method.return_type.symbol =  Symbol.VOID;
				_connect_method.access = SymbolAccessibility.ANY;
				_connect_method.binding = MemberBinding.ANY;
			
				_disconnect_method = new Afrodite.Symbol ("disconnect", "Method");
				_disconnect_method.return_type = new DataType ("void");
				_disconnect_method.return_type.symbol =  Symbol.VOID;
				_disconnect_method.access = SymbolAccessibility.ANY;
				_disconnect_method.binding = MemberBinding.ANY;
				
				_signal_symbol = new Symbol ("#signal", "Class");
				_signal_symbol.add_child (_connect_method);
				_signal_symbol.add_child (_disconnect_method);
				
				signal_type = new DataType ("#signal");
				signal_type.symbol = _signal_symbol;
			}
		}
	}

	public static string unescape_xml_string (string text)
	{
		var res = text;
		return res.replace ("&lt;", "<").replace ("&gt;", ">");
	}
}
