/*
 *  vtgprojectmanagerexecuter.vala - Vala developer toys for GEdit
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
	public class Executer : GLib.Object
	{
		private Vtg.Plugin _plugin;
		private BuildLogView _build_view = null;
		//TODO: hashtable with Project as key
		private uint _child_watch_id = 0;
		private	Pid child_pid = (Pid) 0;

 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public Executer (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}

		public bool execute (Project project)
		{
			if (_child_watch_id != 0)
				return false;

			var working_dir = project.filename;
			int stdo, stde, stdi;
			try {
				var log = _plugin.output_view;
				string process_file;
				var programs = project.exec_targets;

				log.clean_output ();
				if (programs.size == 0) {
					log.log_message ("No executable in %s".printf(project.name));
					return false;
				}

				//TODO: support multiexec projects
				process_file = Path.build_filename (project.filename, programs[0]);
				var start_message = _("Starting %s, from project: %s\n").printf (process_file, project.name);
				log.log_message (start_message);
				log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				Process.spawn_async_with_pipes (working_dir, new string[] { process_file }, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, out stdi, out stdo, out stde);
				if (child_pid != (Pid) 0) {
					_child_watch_id = ChildWatch.add (child_pid, this.on_child_watch);
					log.start_watch (_child_watch_id, stdo, stde, stdi);
					log.activate ();
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
				GLib.debug ("killing %d", (int) child_pid);
				if (Posix.Processes.kill ((int) child_pid, 9) != 0) {
					GLib.debug ("kill failed");
				}
			}
		}

		private void on_child_watch (Pid pid, int status)
		{
			var log = _plugin.output_view;

			Process.close_pid (child_pid);
			child_pid = (Pid) 0;

			log.stop_watch (_child_watch_id);
			log.log_message (_("\nprocess terminated with exit status %d\n").printf(status));
			_build_view.activate ();
			_child_watch_id = 0;
		}
	}
}
