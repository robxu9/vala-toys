/*
 *  vtgprojectsearch.vala - Vala developer toys for GEdit
 *  
 *  Copyright (C) 2009 - Andrea Del Signore <sejerpz@tin.it>
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
	internal class ProjectSearch : GLib.Object
	{
		private const string GREP = "grep";
		
		private unowned Vtg.PluginInstance _plugin_instance = null;
		private ProjectSearchResultsView _results_view = null;
		//TODO: hashtable with Project as key
		private uint _child_watch_id = 0;
		private	Pid child_pid = (Pid) 0;
		private bool is_bottom_pane_visible;
		private int last_exit_code = 0;
		
		public signal void search_start ();
		public signal void search_exit (int exit_status);
		
 		public Vtg.PluginInstance plugin_instance { get { return plugin_instance; } construct { _plugin_instance = value; } }
 		
		public bool is_searching {
			get {
				return _child_watch_id != 0;
			}
		}
		
		construct
		{
			this._results_view = new ProjectSearchResultsView (_plugin_instance);
			is_bottom_pane_visible = _plugin_instance.window.get_bottom_panel ().visible;
		}
		
		public ProjectSearch (Vtg.PluginInstance plugin_instance)
		{
			GLib.Object (plugin_instance: plugin_instance);
		}

		public void next_match ()
		{
			_results_view.next_match ();
		}

		public void previous_match ()
		{
			_results_view.previous_match ();
		}

		public bool search (ProjectManager project_manager, string text, bool match_case)
		{
			if (_child_watch_id != 0)
				return false;

			var project = project_manager.project;
			var working_dir = project.id;
			int stdo, stde, stdi;
			try {
				var log = _plugin_instance.output_view;
				
				string cmd;
				log.clean_output ();
				if (text == null) {
					log.log_message (OutputTypes.MESSAGE, "No command text to search specified for project %s".printf(project.name));
					return false;
				} else {
					cmd = "sh -c '%s -Hn%s %s".printf (GREP, (match_case ? "" : "i"), text.replace (" ", "\\ "));
					string dirs = "";
					foreach (Group group in project.get_groups ()) {
						foreach (Target target in group.get_targets ()) {
							if (target.has_sources_of_type (FileTypes.VALA_SOURCE)) {
								dirs = dirs.concat (" ", Path.build_filename (group.id, "*.vala").replace (" ", "\\ "));
							}
							if (target.has_file_with_extension ("vapi")) {
								dirs = dirs.concat (" ", Path.build_filename (group.id, "*.vapi").replace (" ", "\\ "));
							}
						}
					}
					cmd += " " + dirs + "'";
				}
				string[] cmds;
				Shell.parse_argv (cmd, out cmds);				
				var start_message = _("Searching for '%s' in project %s\n").printf (text, project.name);
				log.log_message (OutputTypes.MESSAGE, start_message);
				log.log_message (OutputTypes.MESSAGE, "%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
				Process.spawn_async_with_pipes (working_dir, cmds, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, out stdi, out stdo, out stde);
				if (child_pid != (Pid) 0) {
					_child_watch_id = ChildWatch.add (child_pid, this.on_child_watch);
					_results_view.initialize (project_manager);
					if (last_exit_code == 0)
						is_bottom_pane_visible = _plugin_instance.window.get_bottom_panel ().visible;					
					log.start_watch (OutputTypes.SEARCH, _child_watch_id, stdo, stde, stdi);
					log.activate ();
					this.search_start ();
				} else {
					log.log_message (OutputTypes.ERROR, "error spawning process\n");
				}
				return true;
			} catch (Error err) {
				GLib.warning ("Error spawning search process: %s", err.message);
				return false;
			}
		}


/*
		public void kill_last ()
		{
			if ((int) child_pid != 0) {
				if (Posix.Processes.kill ((int) child_pid, 9) != 0) {
					GLib.warning ("exec error: kill failed");
				}
			}
		}
*/

		private void on_child_watch (Pid pid, int status)
		{
			var log = _plugin_instance.output_view;
			
			last_exit_code = Process.exit_status (status);
			log.stop_watch (_child_watch_id);			
			Process.close_pid (child_pid);
			log.log_message (OutputTypes.MESSAGE, _("\nsearch terminated with exit status %d\n").printf(status));
			_results_view.activate ();			
			_child_watch_id = 0;
			this.search_exit (Process.exit_status(status));
			child_pid = (Pid) 0;
		}
	}
}
