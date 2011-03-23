/*
 *  vbfsmartfolder.vala - Vala Build Framework library
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

namespace Vbf.Backends
{
	public class SmartFolder : IProjectBackend, GLib.Object
	{
		private enum ProjectSubType
		{
			UNKNOWN,
			WAF,
			CMAKE,
			MAKE,
		}

		private unowned Project _project;
		private string _configure_command;
		private string _build_command;
		private string _clean_command;
		private GLib.Regex _regex;
		private GLib.Regex _regex_genie;
		private Vala.List<FileMonitor> _file_mons = new Vala.ArrayList<FileMonitor> ();
		private Vala.List<string> _visited_directory;
		private ProjectSubType _project_subtype = ProjectSubType.UNKNOWN;
		
		public string? configure_command {
			owned get {
				return _configure_command;
			}
		}
		
		public string? build_command {
			owned get {
				return _build_command;
			}
		}
		
		public string? clean_command {
			owned get {
				return _clean_command;
			}
		}

		public bool probe (string project_file)
		{
			bool res = false;
			
			if (GLib.FileUtils.test (project_file, FileTest.EXISTS | FileTest.IS_DIR)) {
				res = Utils.is_waf_project (project_file)
				      || Utils.is_cmake_project (project_file)
				      || Utils.is_simple_make_project (project_file);
			}
			
			return res;
		}

		public Project? open (string project_file)
		{
			_project = null;
			_configure_command = null;
			_build_command = null;
			_clean_command = null;
			
			Project project = new Project(project_file);
			project.backend = this;
			refresh (project);
			
			if (project.name == null)
				return null; //parse failed!
			else {
				_project = project;
				return project;
			}
		}

		private void cleanup_file_monitors ()
		{
			foreach (FileMonitor file_mon in _file_mons) {
				file_mon.changed.disconnect(this.on_project_directory_changed);
				file_mon.cancel ();
			}
			_file_mons.clear ();
		}

		public void refresh (Project project)
		{
			cleanup_file_monitors ();
			try {
				string build_filename = null;

				project.clear ();
				project.working_dir = project.id;
				var file = GLib.File.new_for_path (project.id);
				project.name = GLib.Filename.display_basename (file.get_basename ());
				var group = new Group(project, project.id);
				group.name = project.name;
				var target = new Target (group, Vbf.TargetTypes.PROGRAM, project.id, project.name);
				//target.name = project.name;
				group.add_target (target);
				project.add_group (group);

				// try to infer build/clean/configure command
				if (Utils.is_waf_project (project.id)) {
					string waf_command = Path.build_filename (project.id,"waf");
					Utils.trace ("waf command is %s", waf_command);
					_configure_command = "%s configure".printf (waf_command);
					_build_command = "%s build".printf (waf_command);
					_clean_command = "%s clean".printf (waf_command);
					_project_subtype = ProjectSubType.WAF;
					build_filename = "wscript";
				} else if (Utils.is_cmake_project (project.id)) {
					_configure_command = "cmake";
					_build_command = "make";
					_clean_command = "make clean";
					_project_subtype = ProjectSubType.CMAKE;
					build_filename = "CMakeLists.txt";
				} else if (Utils.is_simple_make_project (project.id)) {
					_build_command = "make";
					_clean_command = "make clean";
					_project_subtype = ProjectSubType.MAKE;
				} else {
					_project_subtype = ProjectSubType.UNKNOWN;
				}

				_regex = new GLib.Regex ("""^\s*(using)\s+(\w\S*)\s*;.*$""", GLib.RegexCompileFlags.MULTILINE);
				_regex_genie = new GLib.Regex ("""^(uses|\t+|\s+)(\w\S*)\s*\n""", GLib.RegexCompileFlags.MULTILINE);
				_visited_directory = new Vala.ArrayList<string> ();
				scan_directory (project.id, project, build_filename);
				
				if (project.name != null)
					setup_file_monitors (project);
				
				_regex = null;
				_regex_genie = null;
				_visited_directory.clear ();
				_visited_directory = null;
			} catch (Error err) {
				critical ("open: %s", err.message);
				return;
			}
		}
		
		private void scan_directory (string directory, Project project, string? build_filename = null) throws Error
		{
			_visited_directory.add (directory);
			var dir = GLib.File.new_for_path (directory);
			var enm = dir.enumerate_children ("standard::*", 0, null);
			FileInfo file_info;
			while ((file_info = enm.next_file (null)) != null) {
				//Utils.trace ("%s %s", file_info.get_file_type () == FileType.DIRECTORY ? "directory" : "file", file_info.get_display_name ());
				if (file_info.get_file_type () == FileType.DIRECTORY) {
					if (!file_info.get_name ().has_prefix (".") && !file_info.get_name ().has_prefix ("_"))
						scan_directory (Path.build_filename (directory, file_info.get_name ()), project, build_filename);
				} else {
					Target target;
					var name = file_info.get_display_name ();
					if (name.has_suffix (".vala") || name.has_suffix (".gs")) {
						target = project.get_group (project.id).get_target_for_id (project.id);
						add_vala_source (target, directory, file_info);
					} else if (name.has_suffix (".vapi")) {
						target = project.get_group (project.id).get_target_for_id (project.id);
						add_vapi_source (target, directory, file_info);
					} else if (build_filename != null && name == build_filename) {
						target = project.get_group (project.id).get_target_for_id (project.id);
						parse_build_file_infos (target, Path.build_filename (directory, file_info.get_name ()));
					}
				}
			}
		}

		private void parse_build_file_infos (Target target, string filename)
		{
			switch (_project_subtype) {
				case ProjectSubType.CMAKE:
					parse_cmake_build_file (target, filename);
					break;
				case ProjectSubType.WAF:
					parse_waf_build_file (target, filename);
					break;
				case ProjectSubType.MAKE:
				default:
					// not implemented yet
					break;
			}
		}

		private void parse_cmake_build_file (Target target, string filename)
		{
			try {
				Utils.trace ("parsing cmake build file: %s", filename);
				string content = null;
				if (FileUtils.get_contents (filename , out content) && content != null) {
					int start_position = 0;
					string token;
					bool in_precompile = false;
					bool in_package = false;
					int par_level = 0;
					while ( (token = get_token (content, ref start_position)) != null) {
						//Utils.trace ("token %s", token);
						if (token.has_prefix("#")) {
							start_position = skip_line (content, start_position);
						} else if (in_package) {
							if (token.length > 1 && token == "OPTIONS" || token == "CUSTOM_VAPIS" || token.up () == token) {
								in_package = false;
								break; // out of package --> exit the while loop
							} else {
								Utils.trace ("cmake backend adding package: %s", token);
								if (!target.contains_package (token))
								{
									target.add_package (new Vbf.Package (token));
								}
							}
						} else if (in_precompile) {
							if (token == "(") {
								par_level++; // nested parenthesis
							} else if (token == ")") {
								if (par_level == 0) {
									in_precompile = false;
									break; // out of precompile --> exit the while loop
								} else {
									par_level--;
								}
							} else if (token == "PACKAGES") {
								in_package = true;
							}
						} else {
							if (token == "vala_precompile") {
								in_precompile = expect_token ("(", content, ref start_position);
							}
						}
					}
				}
			} catch (Error err) {
				critical ("Error parsing cmake build file '%s': %s", filename, err.message);
			}
		}

		private void parse_waf_build_file (Target target, string filename)
		{
			try {
				Utils.trace ("parsing waf build file: %s", filename);
				string content = null;
				if (FileUtils.get_contents (filename , out content) && content != null) {
					int start_position = 0;
					string token;
					bool in_build = false;
					bool in_package = false;
					int par_level = 0;
					while ( (token = get_token (content, ref start_position)) != null) {
						//Utils.trace ("token %s", token);
						if (token.has_prefix("#")) {
							start_position = skip_line (content, start_position);
						} else if (in_package) {
							if (token.length == 1 && (token == "\"" || token == "'")) {
								in_package = false;
								break; // out of package --> exit the while loop
							} else {
								Utils.trace ("waf backend adding package: %s", token);
								if (!target.contains_package (token))
								{
									target.add_package (new Vbf.Package (token));
								}
							}
						} else if (in_build) {
							if (token == "(") {
								par_level++; // nested parenthesis
							} else if (token == ")") {
								if (par_level == 0) {
									in_build = false;
									break; // out of precompile --> exit the while loop
								} else {
									par_level--;
								}
							} else if (token == "prog.packages") {
								in_package = expect_token ("=", content, ref start_position);
								// skip the ' token
								get_token (content, ref start_position);
							}
						} else {
							if (token == "def") {
								in_build = expect_token ("build", content, ref start_position);
								start_position = skip_line (content, start_position);
							}
						}
					}
				}
			} catch (Error err) {
				critical ("Error parsing waf wscript file '%s': %s", filename, err.message);
			}
		}

		private bool expect_token (string token, string content, ref int start_position)
		{
			string tmp = get_token (content, ref start_position);
			//Utils.trace ("Expect token '%s' got '%s'", token, tmp);
			return token == tmp;
		}

		private string? get_token (string content, ref int start_position)
		{
			string token = null;

			//Utils.trace ("parsing from: %d", start_position);
			start_position = skip_spaces (content, start_position);
			//Utils.trace ("    skipped spaces to: %d", start_position);
			while (!eof(content, start_position)) {
				unichar ch = content[start_position];
				//Utils.trace ("    ch '%s' %d", ch.to_string (), start_position);
				if (token == null) {
					if ((ch != '_' && ch != '$' && ch.isalnum () == false)) {
						token = ch.to_string(); // special case one character lenght token
						start_position++;
						break;
					} else {
						token = ch.to_string();
					}
				} else {
					if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == ')' || ch == '}'
					    || ch == '\'' || ch == '\"'
					    || (ch == '(' && token[token.length-1] != '$')
					    || (ch == '{' && token[token.length-1] != '$')) {
						break;
					} else {
						token += ch.to_string();
					}
				}
				start_position++;
			}

			//Utils.trace ("get token: '%s'", token);
			return token;
		}

		private int skip_line (string content, int start_position)
		{
			while (!eof(content, start_position)) {
				unichar ch = content[start_position];
				if (ch != '\n') {
					start_position++;
				} else {
					break;
				}
			}

			return start_position;
		}

		private int skip_spaces (string content, int start_position)
		{
			while (!eof(content, start_position)) {
				unichar ch = content[start_position];
				if (ch.isspace () || ch == '\t' || ch == '\n') {
					start_position++;
				} else {
					break;
				}
			}
			
			return start_position;
		}

		private bool eof (string content, int position)
		{
			return content.length <= position;
		}

		private void add_vala_source (Target target, string directory, FileInfo file_info)
		{
			var file = GLib.File.new_for_path (directory).resolve_relative_path (file_info.get_name());
			Utils.trace ("adding vala source: %s", file.get_path ());
			var source = new Vbf.Source (target, file.get_path ());
			source.type = FileTypes.VALA_SOURCE;
			target.add_source (source);
			// try to infer vapi used by source
			// open the source file and read the initial lines
			try {
				var input_stream = file.read ();
				var data_stream = new GLib.DataInputStream (input_stream);
				int count = 0;
				string line;
				size_t len;
				GLib.Regex regex;
				if (source.uri.has_suffix (".gs")) {
					regex = _regex_genie;
				} else {
					regex = _regex;
				}
				while ((line = data_stream.read_line (out len)) != null && count < 100) {
					count++;
					GLib.MatchInfo match;
					regex.match (line, RegexMatchFlags.NEWLINE_ANY, out match);
					while (match.matches ()) {
						string package_name = Utils.guess_package_vapi (match.fetch (2));
						Utils.trace ("guessing name for %s: %s", match.fetch (2), package_name);
						if (package_name != null) {
							if (!target.contains_package (package_name))
							{
								target.add_package (new Vbf.Package (package_name));
							}
						}
						match.next ();
					}
				}
			} catch (Error err) {
				warning ("error sniffing file %s: %s", file.get_path (), err.message);
			}
		}

		private void add_vapi_source (Target target, string directory, FileInfo file_info)
		{
			string vapifile = file_info.get_name ();

			if (vapifile.has_suffix (".vapi")) {
				vapifile = vapifile.substring (0, vapifile.length - 5); // 5 = ".vapi".length
			}
			Utils.trace ("adding vapi package: %s", vapifile);
			var package = new Vbf.Package (vapifile);
			target.add_package (package);

			// adding the include path for later searching
			string path = Path.build_filename (directory, file_info.get_name ());
			var file = GLib.File.new_for_path (path).resolve_relative_path (path);
			string vapidir = file.get_parent ().get_path ();

			if (!target.contains_include_dir (vapidir)) {
				Utils.trace ("adding include dir: %s", vapidir);
				target.add_include_dir (vapidir);
			}
		}

		internal void setup_file_monitors (Project project)
		{
			try {
				GLib.File file;
				FileMonitor file_mon;

				foreach (string dirname in _visited_directory) {
					file = GLib.File.new_for_path (dirname);
					Utils.trace ("setup_file_monitors for: %s", dirname);
					file_mon = file.monitor_directory (FileMonitorFlags.NONE);
					file_mon.changed.connect (this.on_project_directory_changed);
					_file_mons.add (file_mon);
				}

			} catch (Error err) {
				critical ("setup_file_monitors error: %s", err.message);
			}
		}

		private void on_project_directory_changed (FileMonitor sender, GLib.File file, GLib.File? other_file, GLib.FileMonitorEvent event_type)
		{
			if (!sender.is_cancelled ()) {
				if (event_type == FileMonitorEvent.CREATED || event_type == FileMonitorEvent.DELETED) {
					if (Utils.is_vala_source (file.get_path ())) {
						Utils.trace ("file %s: %s", event_type == FileMonitorEvent.CREATED ? "created" : "deleted", file.get_path ());
						_project.update ();
					}
				}
			}
		}

	}
}
