/*
 *  vtgprojectbuilder.vala - Vala developer toys for GEdit
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
using Gedit;
using Gdk;
using Gtk;
using Vbf;

namespace Vtg
{
	public class ProjectBuilder : GLib.Object
	{
		private const string MAKE = "make";

		private Vtg.Plugin _plugin;
		private BuildLogView _build_view = null;
		private uint _child_watch_id = 0;
		private bool is_bottom_pane_visible;
		private int last_exit_code = 0;
		private Pid _child_pid;
		
		public signal void build_start ();
		public signal void build_exit (int exit_status);
		
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }
		public BuildLogView error_pane {
			get {
				return _build_view;
			}
		}
		
		public bool is_building {
			get {
				return _child_watch_id != 0;
			}
		}

		construct
		{
			this._build_view = new BuildLogView (_plugin);
			is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
		}

		public ProjectBuilder (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}


		public bool compile_file (string filename, string? params = null)
		{
			if (_child_watch_id != 0)
				return false;

			var working_dir = Path.get_dirname (filename);
			int stdo, stde;
			var log = _plugin.output_view;
			try {
				string cmd;
				if (params != null) {
					cmd = "%s %s %s".printf ("valac", params, filename);
				} else {
					cmd = "valac %s".printf (filename);
				}
				string[] pars;
				Shell.parse_argv (cmd, out pars);
				log.clean_output ();
				var start_message = _("Start compiling file: %s\n").printf (filename);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				log.log_message ("%s %s\n".printf (cmd, filename));
				Process.spawn_async_with_pipes (working_dir, pars, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out _child_pid, null, out stdo, out stde);
				if (_child_pid != (Pid) 0) {
					_child_watch_id = ChildWatch.add (_child_pid, this.on_child_watch);
					_build_view.initialize ();
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
					log.start_watch (_child_watch_id, stdo, stde);
					log.activate ();
					this.build_start ();
				} else {
					log.log_message ("error compiling file\n");
				}
				return true;
			} catch (SpawnError err) {
				var msg = "error spawning compiler process: %s".printf (err.message);
				GLib.warning (msg);
				log.log_message (msg);
				return false;
			}
		
		}
		
		public bool build (ProjectManager project_manager, string? params = null)
		{
			if (_child_watch_id != 0)
				return false;


			var project = project_manager.project;
			var working_dir = project.id;
			int stdo, stde;
			try {
				var log = _plugin.output_view;

				log.clean_output ();
				var start_message = _("Start building project: %s\n").printf (project.name);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				string cmd;
				if (params != null) {
					cmd = "%s %s".printf (MAKE, params);
				} else {
					cmd = MAKE;
				}
				string[] pars;
				Shell.parse_argv (cmd, out pars);
				log.log_message ("%s\n".printf (cmd));
				Process.spawn_async_with_pipes (working_dir, pars, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out _child_pid, null, out stdo, out stde);
				if (_child_pid != (Pid) 0) {
					_child_watch_id = ChildWatch.add (_child_pid, this.on_child_watch);
					_build_view.initialize (project_manager);
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
					log.start_watch (_child_watch_id, stdo, stde);
					log.activate ();
					this.build_start ();
				} else {
					log.log_message ("error spawning 'make' process\n");
				}
				return true;
			} catch (SpawnError err) {
				GLib.warning ("Error spawning build process: %s", err.message);
				return false;
			}
		}

		public bool configure (ProjectManager project_manager, string? params = null)
		{
			if (_child_watch_id != 0)
				return false;

			var project = project_manager.project;
			var working_dir = project.id;
			int stdo, stde;
			string configure_command = null;
			foreach (string item in new string[] { "./configure", "./autogen.sh"}) {
				string file = Path.build_filename (working_dir, item);
				if (FileUtils.test (file, FileTest.EXISTS)) {
					configure_command = item;
					break;
				}
			}
			if (configure_command == null) {
				return false;
			}
			try {
				var log = _plugin.output_view;

				log.clean_output ();
				var start_message = _("Start configure project: %s\n").printf (project.name);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				string cmd;
				if (params != null) {
					cmd = "%s %s".printf (configure_command, params);
				} else {
					cmd = configure_command;
				}
				string[] pars;
				Shell.parse_argv (cmd, out pars);
				log.log_message ("%s\n".printf (cmd));
				Process.spawn_async_with_pipes (working_dir, pars, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out _child_pid, null, out stdo, out stde);
				if (_child_pid != (Pid) 0) {
					_child_watch_id = ChildWatch.add (_child_pid, this.on_child_watch);
					_build_view.initialize (project_manager);
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
					log.start_watch (_child_watch_id, stdo, stde);
					log.activate ();
					this.build_start ();
				} else {
					log.log_message (_("error spawning '%s' process\n").printf (configure_command));
				}
				return true;
			} catch (SpawnError err) {
				GLib.warning ("Error spawning build process: %s", err.message);
				return false;
			}
		}

		public bool clean (ProjectManager project_manager, bool vala_stamp = false)
		{
			if (_child_watch_id != 0)
				return false;
				
			var project = project_manager.project;
			var working_dir = project.working_dir;
			int stdo, stde;
			try {
				var log = _plugin.output_view;

				log.clean_output ();
				var start_message = _("Start cleaning project: %s\n").printf (project.name);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));

				if (vala_stamp) {
					log.log_message (_("cleaning 'stamp' files for project: %s\n").printf (project.name));
					string command = "find %s -name *.stamp -delete".printf(working_dir);
					log.log_message ("%s\n\n".printf (command));
					if (!Process.spawn_command_line_sync (command)) {
						log.log_message (_("error cleaning 'stamp' files for project: %s\n").printf (project.name));
						return false;
					}
				}
				log.log_message ("%s %s\n".printf (MAKE, "clean"));
				Process.spawn_async_with_pipes (working_dir, new string[] { MAKE, "clean" }, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out _child_pid, null, out stdo, out stde);
				if (_child_pid != (Pid) 0) {
					_child_watch_id = ChildWatch.add (_child_pid, this.on_child_watch);
					_build_view.initialize (project_manager);
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
					log.start_watch (_child_watch_id, stdo, stde);
					log.activate ();
					this.build_start ();
				} else {
					log.log_message ("error spawning 'make clean' process\n");
				}
				return true;
			} catch (SpawnError err) {
				GLib.warning ("Error spawning clean command: %s", err.message);
				return false;
			}
		}

		public void next_error ()
		{
			_build_view.next_error ();
		}

		public void previous_error ()
		{
			_build_view.previous_error ();
		}

		private void on_child_watch (Pid pid, int status)
		{
			var log = _plugin.output_view;

			log.stop_watch (_child_watch_id);
			last_exit_code = Process.exit_status (status);
			log.log_message (_("\ncompilation end with exit status %d\n").printf (last_exit_code));
			_build_view.activate ();
			_child_watch_id = 0;
			this.build_exit (last_exit_code);
			
			Process.close_pid (pid);			
			if (last_exit_code == 0) {
				if (!this.is_bottom_pane_visible) {
					_plugin.gedit_window.get_bottom_panel ().hide ();
				}
			} else {
				Gdk.beep ();				
			}
			 _child_pid = (Pid) 0;
		}
		
		public void stop_build ()
		{
			if ((int) _child_pid != 0) {
				if (Posix.Processes.kill ((int) _child_pid, 9) != 0) {
					GLib.warning ("stop build error: kill failed");
				} else {
					var ctx = GLib.MainContext.default ();
					while (_child_watch_id != 0 && ctx.pending ())
						ctx.iteration (false);
				}
			}
		}

	}
}