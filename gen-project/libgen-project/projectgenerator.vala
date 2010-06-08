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
		private string make_name;
		private string upper_case_make_name;
		private string license_program_type;
		private string license_name;
		private string license_version;
		private string license_publisher;
		private string license_website;
		private string license_header;
		private string license_header_vala;
		
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
				string[] argv = new string [] { "tar", "-C", options.path, "-zpxf", options.template.archive_filename };
				
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
								
				string license_filename = null;
				license_program_type = "program";
				license_header = "";
				license_header_vala = "";
				license_name = "";
				license_version = "";
				license_publisher = "";
				license_website = "";
				
				// common initialization for all supported licenses
				switch (options.license)
				{
					case ProjectLicense.GPL2:
					case ProjectLicense.GPL3:
					case ProjectLicense.LGPL2:
					case ProjectLicense.LGPL3:
				license_header = """This ${license-program-type} is free software: you can redistribute it and/or modify
it under the terms of the ${license-name} as published by
the ${license-publisher}, either version ${license-version} of the License, or
(at your option) any later version.
 
This ${license-program-type} is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
${license-name} for more details.
 
You should have received a copy of the ${license-name}
along with this ${license-program-type}.  If not, see ${license-web-site}.
""";

						license_publisher = "Free Software Foundation";
						license_website = """<http://www.gnu.org/licenses/>""";
						break;
				}
				
				// per license info
				switch (options.license) {
					case ProjectLicense.GPL2:
						license_filename = Config.PACKAGE_DATADIR + "/licenses/gpl-2.0.txt";
						if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
							license_filename = "/usr/share/common-licenses/GPL-2";
						}					
						license_name = "GNU General Public License";
						license_version = "2";
						license_program_type = "program";
						break;
					case ProjectLicense.GPL3:
						license_filename = Config.PACKAGE_DATADIR + "/licenses/gpl-3.0.txt";
						if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
							license_filename = "/usr/share/common-licenses/GPL-3";
						}
						license_name = "GNU General Public License";
						license_version = "3";
						license_program_type = "program";
						break;
					case ProjectLicense.LGPL2:
						license_filename = Config.PACKAGE_DATADIR + "/licenses/lgpl-2.1.txt";
						if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
							license_filename = "/usr/share/common-licenses/LGPL-2.1";
						}
						license_name = "GNU Lesser General Public License";
						license_version = "2.1";
						license_program_type = "library";
						break;
					case ProjectLicense.LGPL3:
						license_filename = Config.PACKAGE_DATADIR + "/licenses/lgpl-3.0.txt";
						if (!FileUtils.test (license_filename, FileTest.EXISTS)) {
							license_filename = "/usr/share/common-licenses/LGPL-3";
						}
						license_name = "GNU Lesser General Public License";
						license_version = "3";
						license_program_type = "library";
						break;
				}
				
				// derive a header with a vala compatible syntax
 				if (license_header != null) {
	 				StringBuilder sb = new StringBuilder ();
	 				sb.append ("\n");
	 				foreach(string line in license_header.split ("\n")) {
	 					sb.append (" * ");
	 					sb.append (line);
	 					sb.append ("\n");
	 				}
	 				sb.truncate (sb.len - 1);
					license_header_vala = sb.str;
				}

				// copy the license file
				if (license_filename != null && FileUtils.test (license_filename, FileTest.EXISTS)) {
					FileUtils.get_contents (license_filename, out s);
					FileUtils.set_contents (options.path + "/COPYING", s, -1);
				}
				
				// scan for known tag to substitute
				scan_path_for_tag_substitution (options.path);
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
			var result = data;
			
			result = result.replace ("${license-header}", license_header);
			result = result.replace ("${license-header-vala}", license_header_vala);
			result = result.replace ("${license-program-type}", license_program_type);
			result = result.replace ("${license-name}", license_name);
			result = result.replace ("${license-version}", license_version);
			result = result.replace ("${license-web-site}", license_website);
			result = result.replace ("${license-publisher}", license_publisher);
			result = result.replace ("${author-name}", options.author);
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

