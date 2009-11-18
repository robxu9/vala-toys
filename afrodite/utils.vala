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
}
