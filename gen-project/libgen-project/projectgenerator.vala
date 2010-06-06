/* projectgenerator.vala
 *
 * Copyright (C) 2007-2010  Jürg Billeter
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 * 	Andrea Del Signore <sejerpz@tin.it>
 * 	Nicolas Joseph <nicolas.joseph@valaide.org>
 */

using GLib;

namespace GenProject
{
	public class ProjectGenerator : GLib.Object {
		private string namespace_name;
		private string make_name;
		private string upper_case_make_name;
		
		public ProjectOptions options { get; construct; }

		public ProjectGenerator (ProjectOptions options) {
			GLib.Object (options: options);
		}

		public void create_project () {
			// only use [a-zA-Z0-9-]* as projectname
			var project_name_str = new StringBuilder ();
			var make_name_str = new StringBuilder ();
			var namespace_name_str = new StringBuilder ();
			for (int i = 0; i < options.name.len (); i++) {
				unichar c = options.name[i];
				if ((c >= 'a' && c <= 'z' ) || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')) {
					project_name_str.append_unichar (c);
					make_name_str.append_unichar (c);
					namespace_name_str.append_unichar (c);
				} else if (c == '-' || c == ' ') {
					project_name_str.append_unichar ('-');
					make_name_str.append_unichar ('_');
				}
			}

			options.name = project_name_str.str;
			namespace_name = namespace_name_str.str.substring (0, 1).up () + namespace_name_str.str.substring (1, namespace_name_str.str.len () - 1);
			make_name = make_name_str.str;
			upper_case_make_name = make_name.up ();

			print (_("creating project %s in %s with template %s...\n"), options.name, options.path, options.template.name);
			try {
				/**
				* @FIXME Get umask for directory creation
				*/
				if (!FileUtils.test (options.path, FileTest.EXISTS)) {
					DirUtils.create_with_parents (options.path, 0777);
				}
				
				string std_out;
				string std_err;
				string s;
				int exit_status;
				string[] argv = new string [] { "tar", "-C", options.path, "--strip-components=1", "-zpxf", options.template.archive_filename };
				
				// untar the project in the destination directory
				if (!Process.spawn_sync (options.path, 
					argv,
					null,
					SpawnFlags.SEARCH_PATH,
					null,
					out std_out,
					out std_err,
					out exit_status)) {
					error ("error extracting data from template. exit code %d", exit_status);
					return;
				}
				
				scan_path_for_tag_substitution (options.path);
				
				string license_filename = null;
				if (options.license == ProjectLicense.GPL2) {
					license_filename = Config.PACKAGE_DATADIR + "/licenses/gpl-2.0.txt";
					if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
						license_filename = "/usr/share/common-licenses/GPL-2";
					}
				} else if (options.license == ProjectLicense.LGPL2) {
					license_filename = Config.PACKAGE_DATADIR + "/licenses/lgpl-2.1.txt";
					if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
						license_filename = "/usr/share/common-licenses/LGPL-2.1";
					}
				} else if (options.license == ProjectLicense.GPL3) {
					license_filename = Config.PACKAGE_DATADIR + "/licenses/gpl-3.0.txt";
					if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
						license_filename = "/usr/share/common-licenses/GPL-3";
					}
				} else if (options.license == ProjectLicense.LGPL3) {
					license_filename = Config.PACKAGE_DATADIR + "/licenses/lgpl-3.0.txt";
					if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
						license_filename = "/usr/share/common-licenses/LGPL-3";
					}
				}
				if (license_filename != null && FileUtils.test (license_filename, FileTest.EXISTS)) {
					FileUtils.get_contents (license_filename, out s);
					FileUtils.set_contents (options.path + "/COPYING", s, -1);
				}
			} catch (Error e) {
				critical ("Error while creating project: %s", e.message);
			}
		}

		private void scan_path_for_tag_substitution (string path)
		{
			try {
				var dir = Dir.open (path);
				if (dir != null) {
					string file; 
					while ((file = dir.read_name ()) != null) {
						string file_path = Path.build_filename (path, file); 
						if (FileUtils.test (file_path, FileTest.IS_DIR)) {
							scan_path_for_tag_substitution (file_path);
						} else {
							if (file.has_suffix (".template")) {
								string c;
								FileUtils.get_contents (file_path, out c);
								c = replace_tags (c);
								
								//set_contents change the file attributes
								FileUtils.set_contents (file_path, c, -1);
								string new_file_path = file_path.substring (0, file_path.length - ".template".length);
								FileUtils.rename (file_path, new_file_path);
								
								//ugly workaround
								if (new_file_path.has_suffix ("/autogen.sh")) {
									FileUtils.chmod (new_file_path, 0755);
								}
							}
						}
					}
				}
			} catch (Error e) {
				warning ("replace_tags: error reading path %s", path);
			}
		}
		
		//TODO: this method it'snt very efficient
		private string replace_tags (string data)
		{
			var result = data.replace ("${author-name}", options.author);
			result = result.replace ("${author-email}", options.email);
			result = result.replace ("${project-name}", options.name);
			result = result.replace ("${project-description}", options.name);
			result = result.replace ("${project-uppercase-make-name}", upper_case_make_name);
			result = result.replace ("${project-make-name}", make_name);			
			return result;
		}

		/* These fuctions can be useful in future
		private string? get_automake_path () {
			var automake_paths = new string[] { "/usr/share/automake",
				                            "/usr/share/automake-1.10",
				                            "/usr/share/automake-1.9" };

			foreach (string automake_path in automake_paths) {
				if (FileUtils.test (automake_path, FileTest.IS_DIR)) {
					return automake_path;
				}
			}

			return null;
		}

		private bool get_automake_has_native_vala_support ()
		{
			bool res = false;
			try {
				string am_output;
				Process.spawn_command_line_sync ("automake --version", out am_output);
				//version example: automake (GNU automake) 1.10.2
				if (am_output != null)
				{
					string first_line = am_output.split ("\n", 2)[0];
					string[] tmps = first_line.split(" ");
					if (tmps.length > 0)
					{
						string ver = tmps[tmps.length - 1];
						tmps = ver.split(".");
						if (tmps.length >= 2 && tmps[0].to_int() >= 1 && tmps[1].to_int() >= 11) {
							res = true;

						}
					}
				}
			} catch (Error err) {
				warning ("Cannot spawn automake: %s. Native vala support test failed.", err.message);
			}
			return res;
		}
		*/

	}
}

