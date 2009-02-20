/*
 *  vtgprojectexecuter.vala - Vala developer toys for GEdit
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
	internal class ProjectExecuter : GLib.Object
	{
		private Vtg.PluginInstance _plugin_instance;
		private BuildLogView _build_view = null;
		//TODO: hashtable with Project as key
		private uint _child_watch_id = 0;
		private	Pid child_pid = (Pid) 0;
		
		public signal void process_start ();
		public signal void process_exit (int exit_status);
		
 		public Vtg.PluginInstance plugin_instance { get { return plugin_instance; } construct { _plugin_instance = value; } default = null; }
 		
		public bool is_executing {
			get {
				return _child_watch_id != 0;
			}
		}
		
		public ProjectExecuter (Vtg.PluginInstance plugin_instance)
		{
			this.plugin_instance = plugin_instance;
		}

		public bool execute (Project project, string command_line)
		{
			if (_child_watch_id != 0)
				return false;

			var working_dir = project.id;
			int stdo, stde, stdi;
			try {
				var log = _plugin_instance.output_view;
				
				string cmd;
				log.clean_output ();
				if (command_line == null) {
					log.log_message ("No command line specified for project %s".printf(project.name));
					return false;
				} else {
					cmd = Path.build_filename (project.id, command_line);
				}
				string[] cmds;
				Shell.parse_argv (cmd, out cmds);
				var start_message = _("Starting from project %s executable: %s\n").printf (project.name, cmd);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				Process.spawn_async_with_pipes (working_dir, cmds, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, out stdi, out stdo, out stde);
				if (child_pid != (Pid) 0) {
					_child_watch_id = ChildWatch.add (child_pid, this.on_child_watch);
					log.start_watch (_child_watch_id, stdo, stde, stdi);
					log.activate ();
					this.process_start ();
				} else {
					log.log_message ("error spawning process\n");
				}
				return true;
			} catch (SpawnError err) {
				GLib.warning ("Error spawning build process: %s", err.message);
				return false;
			}
		}

		public void kill_last ()
		{
			if ((int) child_pid != 0) {
				if (Posix.Processes.kill ((int) child_pid, 9) != 0) {
					GLib.warning ("exec error: kill failed");
				}
			}
		}

		private void on_child_watch (Pid pid, int status)
		{
			var log = _plugin_instance.output_view;

			Process.close_pid (child_pid);
			log.stop_watch (_child_watch_id);
			log.log_message (_("\nprocess terminated with exit status %d\n").printf(status));
			_build_view.activate ();
			_child_watch_id = 0;
			this.process_exit (Process.exit_status(status));
			child_pid = (Pid) 0;
		}
	}
}
