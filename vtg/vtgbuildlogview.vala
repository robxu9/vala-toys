/*
 *  vtgbuildlogview.vala - Vala developer toys for GEdit
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
	public class BuildLogView : GLib.Object
	{
		private Gtk.VBox _ui;
		private ListStore _model = null;
		private TreeView _build_view = null;

		private int current_error_row = 0;
		private int _error_count = 0;
		private Vtg.Plugin _plugin;
		private unowned ProjectManager _project;

 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }
		
		public int error_count {
			get {
				return _error_count;
			}
		}
		
		public BuildLogView (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}

		~BuildLogView ()
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			panel.remove_item (_ui);
		}

		construct 
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			_ui = new Gtk.VBox (false, 8);
			this._model = new ListStore (6, typeof(string), typeof(string), typeof(string), typeof(int), typeof(int), typeof(GLib.Object));
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
			_ui.pack_start (scroll, true, true, 4);
			_ui.show_all ();
			panel.add_item_with_stock_icon (_ui, _("Build results"), Gtk.STOCK_EXECUTE);
			_plugin.output_view.message_added += this.on_message_added;
		}

		public void initialize (ProjectManager? project = null)
		{
			this._project = project;
			current_error_row = 0;
			_error_count = 0;
			_model.clear ();
		}

		public void activate ()
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			panel.activate_item (this._ui);
			var view = _plugin.gedit_window.get_active_view ();
			if (view != null && !view.is_focus) {
				view.grab_focus ();
			}
		}

		public bool on_message_added (OutputView sender, string message)
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
			activate_path (path);
		}

		private void activate_path (TreePath path)
		{
			TreeIter iter;
			if (_model.get_iter (out iter, path)) {
				string name;
				int line, col;
				ProjectManager? proj;

				_model.get (iter, 2, out name, 3, out line, 4, out col, 5, out proj);

				if (proj != null) {
					string uri = proj.source_uri_for_name (name);
					if (uri != null)
						_plugin.activate_uri (uri, line, col);
					else
						GLib.warning ("Couldn't find uri for source: %s", name);
				} else {
					_plugin.activate_display_name (name, line, col);
				}
			}
		}

		public void next_error ()
		{
			TreePath path = new TreePath.from_string (current_error_row.to_string());
			if (path != null) {
				activate_path (path);
				_build_view.scroll_to_cell (path, null, false, 0, 0);
				_build_view.get_selection ().select_path (path);
				if (current_error_row < _error_count - 1)
					current_error_row++;
				else
					current_error_row = 0;
			}
		}

		public void previous_error ()
		{
			TreePath path = new TreePath.from_string (current_error_row.to_string());
			if (path != null) {
				activate_path (path);
				_build_view.scroll_to_cell (path, null, false, 0, 0);
				_build_view.get_selection ().select_path (path);
				if (current_error_row > 0)
					current_error_row--;
				else
					current_error_row = _error_count - 1;
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
			int col = 0;

			if (src_ref[1] != null)
				col = src_ref[1].to_int ();

			string stock_id = null;

			if (parts[1] != null) {
				if (parts[1].has_suffix ("error")) {
					stock_id = Gtk.STOCK_DIALOG_ERROR;
				} else if (parts[1].has_suffix ("warning")) {
					stock_id = Gtk.STOCK_DIALOG_WARNING;
				}


				if (parts[2] != null) {
					TreeIter iter;
					_model.append (out iter);
					_model.set (iter, 0, stock_id, 1, parts[2], 2, file, 3, line, 4, col, 5, _project);
					_error_count++;
				}
			}
		}
	}
}