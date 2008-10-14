/*
 *  vtgprojectmanager.vala - Vala developer toys for GEdit
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
	public class LogView : GLib.Object
	{
		private Vtg.Plugin _plugin;

		private IOChannel _stdout = null;
		private IOChannel _stderr = null;
		private TextBuffer _messages;
		private uint _stdout_watch_id = 0;
		private uint _stderr_watch_id = 0;
		private Gtk.ScrolledWindow _ui = null;
		
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public LogView(Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}

		construct 
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			_messages = new TextBuffer (null);
			var textview = new TextView.with_buffer (_messages);
			_ui = new Gtk.ScrolledWindow (null, null);
			_ui.add (textview);
			_ui.show_all ();
			panel.add_item (_ui, _("Build process"), null);
		}

		public void watch (int stdo, int stde)
		{
			_stdout = new IOChannel.unix_new (stdo);
			_stdout.add_watch (IOCondition.IN, this.on_messages);
			_stderr = new IOChannel.unix_new (stde);
			_stderr.add_watch (IOCondition.IN, this.on_messages);
			_messages.set_text ("", 0);
			_plugin.gedit_window.get_bottom_panel ().activate_item (_ui);
		}

		public void stop_watch ()
		{
			if (_stdout_watch_id != 0) {
				Source.remove (_stdout_watch_id);
			}
			if (_stderr_watch_id != 0) {
				Source.remove (_stderr_watch_id);
			}
			_stdout = null;
			_stderr = null;
		}

		private bool on_messages (IOChannel source, IOCondition condition)
		{
			try {
				string message;
				size_t len = 0;
				source.read_to_end (out message, out len);
				if (len > 0)
					_messages.insert_at_cursor (message, (int) len);
			} catch (Error err) {
				GLib.warning ("Error reading from process %s", err.message);
			}
			return true;
		}
	}

	public class Builder : GLib.Object
	{
		private const string MAKE = "make";

		private Vtg.Plugin _plugin;
		private LogView _log = null;

 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public Builder (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}

		public bool build (Project project)
		{
			var working_dir = project.name;
			Pid child_pid;
			int stdo, stde;
			try {
				if (_log == null) {
					_log = new LogView (_plugin);
				}
				Process.spawn_async_with_pipes (working_dir, new string[] { MAKE }, null, SpawnFlags.SEARCH_PATH, null, out child_pid, null, out stdo, out stde);
				_log.watch (stdo, stde);
				return true;
			} catch (SpawnError err) {
				GLib.warning ("Error spawning build process: %s", err.message);
				return false;
			}
		}
	}
}