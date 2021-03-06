/*
 *  vbfutils.vala - Vala Build Framework library
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */


using GLib;

namespace Vbf.Utils
{
	/**
	 * This function shouldn't be used directly but just wrapped with a private one that
	 * will specify the correct log domain. See the function trace (...) in this same source 
	 */
	internal static inline void log_message (string log_domain, string format, va_list args)
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
		log_message ("ValaBuildFramework", format, va2);
#endif
	}

	public bool is_autotools_project (string path)
	{
		string config_file = Path.build_filename (path, "configure.ac");
		string autogen_file = Path.build_filename (path, "autogen.sh");
		bool res = false;

		if (GLib.FileUtils.test (config_file, FileTest.EXISTS) || GLib.FileUtils.test (autogen_file, FileTest.EXISTS)) {
			string file = Path.build_filename (path, "Makefile.am");
			if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
				res = true;
			}
		}

		Utils.trace ("project at: %s is autotools %s", path, res.to_string ());
		return res;
	}

	public bool is_waf_project (string path)
	{
		string file = Path.build_filename (path, "wscript");
		bool res = false;

		if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
			res = true;
		}

		Utils.trace ("project at: %s is waf %s", path, res.to_string ());
		return res;
	}

	public bool is_cmake_project (string path)
	{
		string file = Path.build_filename (path, "CMakeLists.txt");
		bool res = false;

		if (GLib.FileUtils.test (file, FileTest.EXISTS)) {
			res = true;
		}

		Utils.trace ("project at: %s is cmake %s", path, res.to_string ());
		return res;
	}

	public bool is_simple_make_project (string path)
	{
		string makefile = Path.build_filename (path, "Makefile");
		string makefile_am = Path.build_filename (path, "Makefile.am");
		string makefile_in = Path.build_filename (path, "Makefile.in");
		bool res = false;

		if (GLib.FileUtils.test (makefile, FileTest.EXISTS) 
		    && !GLib.FileUtils.test (makefile_in, FileTest.EXISTS)
		    && !GLib.FileUtils.test (makefile_am, FileTest.EXISTS)) {
			res = true;
		}

		Utils.trace ("project at: %s is simple make %s", path, res.to_string ());
		return res;
	}

	public static string? guess_package_vapi (string using_name, string[]? vapi_dirs = null)
	{
		// known using names;
		string[] real_using_names;
		string vapi_file = null;
		
		if (using_name == "Gtk" || using_name == "Gtk+") {
			real_using_names = new string[2];
			real_using_names[0] = "gtk+-2.0";
			real_using_names[1] = "gtk+";
		} else {
			real_using_names = new string[1];
			real_using_names[0] = using_name;
		}
		
		string curr;
		string[] dirs;
		int dir_count = 1;
		
		if (vapi_dirs != null)
			dir_count += vapi_dirs.length;
		
		string thirdy_party_vapi_dir = Config.VALA_VAPIDIR.replace ("vala-%s".printf (Config.VALA_VERSION), "vala");
		bool thirdy_party_vapi_dir_bool = FileUtils.test (thirdy_party_vapi_dir, FileTest.IS_DIR);
		if (thirdy_party_vapi_dir_bool) {
			dir_count++;
		}
		dirs = new string[dir_count];
		dirs[0] = Config.VALA_VAPIDIR;
		for (int i=0; i < vapi_dirs.length; i++) {
			dirs[i+1] = vapi_dirs[i];
		}
		if (thirdy_party_vapi_dir_bool) {
			dirs[dirs.length-1] = thirdy_party_vapi_dir;
		}

		try {
			foreach (string real_using_name in real_using_names) {
				string filename = real_using_name + ".vapi";
				string lowercase_filename = filename.down ();
				string lowercase_using_name = real_using_name.down ();
				string lib_filename = "lib" + filename;
				string lib_lowercase_filename = "lib" + lowercase_filename;
				string lib_lowercase_using_name = "lib" + lowercase_using_name;
				
				// search in the standard package path

				foreach (string vapi_dir in dirs) {
					var dir = GLib.Dir.open (vapi_dir);

					while ((curr = dir.read_name ()) != null) {
						var curr_file = curr.locale_to_utf8 (-1, null, null, null);
						
						//debug ("searching %s vs %s", real_using_name, curr);

						if (curr_file == filename || curr_file == lib_filename
						    || curr_file == lowercase_filename || curr_file == lib_lowercase_filename
						    || curr_file.has_prefix (lowercase_using_name) || curr_file.has_prefix (lib_lowercase_using_name)) {
							if (vapi_file == null || vapi_file.length > (curr.length - 5)) {
								vapi_file = curr.substring (0, curr.length - 5); // 5 = ".vapi".length
							}
						} else if (curr.contains ("-")) {
							curr_file = curr_file.replace ("-", "");
							if (curr_file == filename || curr_file == lib_filename
							    || curr_file == lowercase_filename || curr_file == lib_lowercase_filename
							    || curr_file.has_prefix (lowercase_using_name) || curr_file.has_prefix (lib_lowercase_using_name)) {
								if (vapi_file == null || vapi_file.length > (curr.length - 5)) {
									vapi_file = curr.substring (0, curr.length - 5); // 5 = ".vapi".length
								}
							}
						}
						
					}
				}
			}
		} catch (Error err) {
			critical ("error: %s", err.message);
		}

		return vapi_file;
	}
	
	private bool is_vala_source (string filename)
	{
		return filename.has_suffix (".vala") || filename.has_suffix (".vapi");
	}
}
