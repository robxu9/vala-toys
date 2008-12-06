/*
 *  vtgprojectmanagerbuilder.vala - Vala developer toys for GEdit
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

namespace Vtg.ProjectManager
{
	public class Builder : GLib.Object
	{
		private const string MAKE = "make";

		private Vtg.Plugin _plugin;
		private BuildLogView _build_view = null;
		private uint _child_watch_id = 0;
		private bool is_bottom_pane_visible;
		private int last_exit_code = 0;
		
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		construct
		{
			this._build_view = new BuildLogView (_plugin);
			is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
		}

		public Builder (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}


		public bool compile_file (string filename)
		{
			if (_child_watch_id != 0)
				return false;

			var working_dir = Path.get_dirname (filename);
			Pid? child_pid;
			int stdo, stde;
			var log = _plugin.output_view;
			try {
				string command = "valac";

				log.clean_output ();
				var start_message = _("Start compiling file: %s\n").printf (filename);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				log.log_message ("%s %s\n".printf (command, filename));
				Process.spawn_async_with_pipes (working_dir, new string[] { command, filename }, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, null, out stdo, out stde);
				if (child_pid != null) {
					_child_watch_id = ChildWatch.add (child_pid, this.on_child_watch);
					_build_view.initialize ();
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
					log.start_watch (_child_watch_id, stdo, stde);
					log.activate ();
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
		
		public bool build (Project project)
		{
			if (_child_watch_id != 0)
				return false;

			var working_dir = project.filename;
			Pid? child_pid;
			int stdo, stde;
			try {
				var log = _plugin.output_view;

				log.clean_output ();
				var start_message = _("Start building project: %s\n").printf (project.name);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				log.log_message ("%s\n".printf (MAKE));
				Process.spawn_async_with_pipes (working_dir, new string[] { MAKE }, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, null, out stdo, out stde);
				if (child_pid != null) {
					_child_watch_id = ChildWatch.add (child_pid, this.on_child_watch);
					_build_view.initialize (project);
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
					log.start_watch (_child_watch_id, stdo, stde);
					log.activate ();
				} else {
					log.log_message ("error spawning 'make' process\n");
				}
				return true;
			} catch (SpawnError err) {
				GLib.warning ("Error spawning build process: %s", err.message);
				return false;
			}
		}

		public bool clean (Project project, bool vala_stamp = false)
		{
			if (_child_watch_id != 0)
				return false;

			var working_dir = project.filename;
			Pid? child_pid;
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
				Process.spawn_async_with_pipes (working_dir, new string[] { MAKE, "clean" }, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, null, out stdo, out stde);
				if (child_pid != null) {
					_child_watch_id = ChildWatch.add (child_pid, this.on_child_watch);
					_build_view.initialize (project);
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin.gedit_window.get_bottom_panel ().visible;
					log.start_watch (_child_watch_id, stdo, stde);
					log.activate ();
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

			Process.close_pid (pid);

			log.stop_watch (_child_watch_id);
			last_exit_code = Process.exit_status (status);
			log.log_message (_("\ncompilation end with exit status %d\n").printf (last_exit_code));

			_build_view.activate ();
			if (last_exit_code == 0) {
				if (!this.is_bottom_pane_visible) {
					_plugin.gedit_window.get_bottom_panel ().hide ();
				}
			} else {
				Gdk.beep ();				
			}
			_child_watch_id = 0;
		}
	}
}
