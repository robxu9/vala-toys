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
		private string _project_dir;
		private string _configure_command;
		private string _build_command;
		private string _clean_command;
		private GLib.Regex _regex;
		
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
				res = true;
			}
			
			return res;
		}

		public Project? open (string project_file)
		{
			_project_dir = null;
			_configure_command = null;
			_build_command = null;
			_clean_command = null;
			
			Project project = new Project(project_file);
			project.backend = this;
			refresh (project);
			
			if (project.name == null)
				return null; //parse failed!
			else {
				_project_dir = project.id;
				
				return project;
			}
		}
		
		public void refresh (Project project)
		{
			try {
				project.working_dir = project.id;
				var file = GLib.File.new_for_path (project.id);
				project.name = GLib.Filename.display_basename (file.get_basename ());
				var group = new Group(project, project.id);
				group.name = project.name;
				var target = new Target (group, Vbf.TargetTypes.PROGRAM, project.id);
				target.name = project.name;
				group.add_target (target);
				project.add_group (group);
				
				// try to infer build/clean/configure command
				if (Utils.is_waf_project (project.id)) {
					string waf_command = Path.build_filename (project.id,"waf");
					Utils.trace ("waf command is %s", waf_command);
					_configure_command = "%s configure".printf (waf_command);
					_build_command = "%s build".printf (waf_command);
					_clean_command = "%s clean".printf (waf_command);
				} else if (Utils.is_cmake_project (project.id)) {
					_configure_command = "cmake";
					_build_command = "make";
					_clean_command = "make clean";
				} else if (Utils.is_simple_make_project (project.id)) {
					_build_command = "make";
					_clean_command = "make clean";
				}
				_regex = new GLib.Regex ("""^\s*(using)\s+(\w\S*)\s*;.*$""");
				scan_directory (project.id, project);
				_regex = null;
				//project.setup_file_monitors ();
			} catch (Error err) {
				critical ("open: %s", err.message);
				return;
			}
		}
		
		private void scan_directory (string directory, Project project) throws Error
		{
			var dir = GLib.File.new_for_path (directory);
			var enm = dir.enumerate_children ("standard::*", 0, null);
			FileInfo file_info;
			while ((file_info = enm.next_file (null)) != null) {
				Utils.trace ("%s %s", file_info.get_file_type () == FileType.DIRECTORY ? "directory" : "file", file_info.get_display_name ());
				if (file_info.get_file_type () == FileType.DIRECTORY) {
					scan_directory (Path.build_filename (directory, file_info.get_name ()), project);
				} else {
					Target target;
					var name = file_info.get_display_name ();
					if (name.has_suffix (".vala")) {
						target = project.get_group (project.id).get_target_for_id (project.id);
						add_vala_source (target, directory, file_info);
					} else if (name.has_suffix (".vapi")) {
						target = project.get_group (project.id).get_target_for_id (project.id);
						add_vapi_source (target, directory, file_info);
					}
				}
			}
		}
		
		private void add_vala_source (Target target, string directory, FileInfo file_info)
		{
			string path = Path.build_filename (directory, file_info.get_name ());
			var file = GLib.File.new_for_path (path).resolve_relative_path (path);
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
				while ((line = data_stream.read_line (out len)) != null && count < 100) {
					count++;
					GLib.MatchInfo match;
					_regex.match (line, RegexMatchFlags.NEWLINE_ANY, out match);
					while (match.matches ()) {
						string package_name = Utils.guess_package_name (match.fetch (2));
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
				warning ("error sniffing file: %s", file.get_path ());
			}
		}
		
		private void add_vapi_source (Target target, string directory, FileInfo file_info)
		{
			string path = Path.build_filename (directory, file_info.get_name ());
			var file = GLib.File.new_for_path (path).resolve_relative_path (path);
			Utils.trace ("adding vapi source: %s", file.get_path ());
			var package = new Vbf.Package (file.get_basename ());
			target.add_package (package);
			if (!target.contains_include_dir (file.get_path ())) {
				target.add_include_dir (Path.get_dirname (file.get_path ()));
			}
		}
	}
}
