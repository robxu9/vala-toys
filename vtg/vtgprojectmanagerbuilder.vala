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
		protected Vtg.Plugin _plugin;
		protected Project _project;

		private IOChannel _stdout = null;
		private IOChannel _stderr = null;
		private TextBuffer _messages;
		private TextView _textview;
		private uint _stdout_watch_id = 0;
		private uint _stderr_watch_id = 0;
		private Gtk.ScrolledWindow _ui = null;
		
 		public Project project { get { return _project; } construct { _project = value; } default = null; }
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public LogView (Vtg.Plugin plugin, Project project)
		{
			this.plugin = plugin;
		}

		construct 
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			_messages = new TextBuffer (null);
			_textview = new TextView.with_buffer (_messages);
			_textview.set_editable (false);
			_ui = new Gtk.ScrolledWindow (null, null);
			_ui.add (_textview);
			_ui.show_all ();
			panel.add_item (_ui, _("Output"), null);
		}

		public virtual void watch (int stdo, int stde)
		{
			_stdout = new IOChannel.unix_new (stdo);
			_stdout.add_watch (IOCondition.IN, this.on_messages);
			_stderr = new IOChannel.unix_new (stde);
			_stderr.add_watch (IOCondition.IN, this.on_messages);
			_messages.set_text ("", 0);
			_plugin.gedit_window.get_bottom_panel ().activate_item (_ui);
		}

		public virtual void stop_watch ()
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
				if (len > 0) {
					log_message (message);
				}
			} catch (Error err) {
				GLib.warning ("Error reading from process %s", err.message);
			}
			return true;
		}

		public void log_message (string message)
		{
			if (message_added (message)) {
				_messages.insert_at_cursor (message, (int) message.length);
				_textview.scroll_mark_onscreen (_messages.get_insert ());
			}					
		}

		public virtual bool message_added (string message) { return true; }
	}

	public class BuildLogView : LogView
	{
		private Gtk.ScrolledWindow _ui = null;
		private ListStore _model = null;
		private TreeView _build_view = null;

		private int current_error_row = 0;
		private int error_count = 0;

		public BuildLogView (Vtg.Plugin plugin, Project project)
		{
			this.plugin = plugin;
			this.project = project;
		}

		construct 
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			var vbox = new Gtk.VBox (false, 8);
			_model = new ListStore (6, typeof(string), typeof(string), typeof(string), typeof(int), typeof(int), typeof(Project));
			_build_view = new Gtk.TreeView.with_model (_model);
			CellRenderer renderer = new CellRendererPixbuf ();
			var column = new TreeViewColumn ();
			column.title = _("Message");
 			column.pack_start (renderer, false);
			column.add_attribute (renderer, "stock-id", 0);
			renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", 1);
			_build_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("File");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", 2);
			_build_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("Line");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", 3);
			_build_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("Column");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", 4);
			_build_view.append_column (column);
			_build_view.row_activated += this.on_build_view_row_activated;
			_build_view.set_rules_hint (true);
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_build_view);
			vbox.pack_start (scroll, true, true, 4);
			vbox.show_all ();
			panel.add_item (vbox, _("Build results"), null);
		}

		public override void watch (int stdo, int stde)
		{
			current_error_row = 0;
			error_count = 0;
			_model.clear ();
			base.watch (stdo, stde);
		}

		public override bool message_added (string message)
		{
			string[] lines = message.split ("\n");
			int idx = 0;
			while (lines[idx] != null) {
				string[] tmp = lines[idx].split (":",2);
				if (tmp[0] != null && (tmp[0].has_suffix (".vala") || tmp[0].has_suffix (".vapi"))) {
					add_message (tmp[0], tmp[1]);
				}
				idx++;
			}

			return true;
		}

		public void on_build_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var tw = (TreeView) sender;
			var model = tw.get_model ();
			activate_path (path);
		}

		private void activate_path (TreePath path)
		{
			TreeIter iter;
			if (_model.get_iter (out iter, path)) {
				string name;
				int line, col;
				Project proj;

				_model.get (iter, 2, out name, 3, out line, 4, out col, 5, out proj);
				string uri = proj.source_uri_for_name (name);
				if (uri != null)
					_plugin.activate_uri (uri, line, col);
				else
					GLib.warning ("Couldn't find uri for source: %s", name);
			}
		}

		public void next_error ()
		{
			TreePath path = new TreePath.from_string (current_error_row.to_string());
			if (path != null) {
				activate_path (path);
				_build_view.get_selection ().select_path (path);
				if (current_error_row < error_count - 1)
					current_error_row++;
				else
					current_error_row = 0;
			}
		}

		public void previuos_error ()
		{
			TreePath path = new TreePath.from_string (current_error_row.to_string());
			if (path != null) {
				activate_path (path);
				_build_view.get_selection ().select_path (path);
				if (current_error_row > 0)
					current_error_row--;
				else
					current_error_row = error_count - 1;
			}
		}

		/* 
		  Example valac output:

		  vtgprojectmanagerbuilder.vala:37.3-37.16: error: missing return type in method `BuildLogView.LogView´
		  public LogView(Vtg.Plugin plugin)
		  ^^^^^^^^^^^^^^
		  vtgprojectmanagerbuilder.vala:72.16-72.16: error: syntax error, expected `;'
		  string lines[] = message.split ("\n");
			            ^
				    Compilation failed: 2 error(s), 0 warning(s)
		 */
		private void add_message (string file, string message)
		{
			string[] parts = message.split (":", 3);
			string[] src_ref = parts[0].split ("-")[0].split (".");
			int line = src_ref[0].to_int ();
			int col = src_ref[1].to_int ();
			string stock_id = null;

			if (parts[1].has_suffix ("error")) {
				stock_id = Gtk.STOCK_DIALOG_ERROR;
			} else if (parts[1].has_suffix ("warning")) {
				stock_id = Gtk.STOCK_DIALOG_WARNING;
			}

			TreeIter iter;
			_model.append (out iter);
			_model.set (iter, 0, stock_id, 1, parts[2], 2, file, 3, line, 4, col, 5, _project);
			error_count++;
		}
	}

	public class Builder : GLib.Object
	{
		private const string MAKE = "make";

		private Vtg.Plugin _plugin;
		private BuildLogView _log = null;

 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public Builder (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}

		public bool build (Project project)
		{
			var working_dir = project.filename;
			Pid child_pid;
			int stdo, stde;
			try {
				if (_log == null) {
					_log = new BuildLogView (_plugin, project);
				}
				Process.spawn_async_with_pipes (working_dir, new string[] { MAKE }, null, SpawnFlags.SEARCH_PATH, null, out child_pid, null, out stdo, out stde);
				_log.watch (stdo, stde);
				var start_message = _("Start building project: %s\n").printf (project.name);
				_log.log_message (start_message);
				_log.log_message ("%s\n\n".printf (string.nfill (start_message.length, '-')));
				return true;
			} catch (SpawnError err) {
				GLib.warning ("Error spawning build process: %s", err.message);
				return false;
			}
		}

		public void next_error ()
		{
			_log.next_error ();
		}

		public void previous_error ()
		{
			_log.previuos_error ();
		}
	}
}