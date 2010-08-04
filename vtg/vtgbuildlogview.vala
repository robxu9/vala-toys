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
	internal class BuildLogView : GLib.Object
	{
		private Gtk.VBox _ui;
		private ListStore _child_model = null;
		private Gtk.TreeModelFilter _model;
		private TreeView _build_view = null;

		private int current_error_row = 0;
		private int _error_count = 0;
		private int _warning_count = 0;
		private unowned Vtg.PluginInstance _plugin_instance = null;
		private unowned ProjectManager _project;
		
		private bool show_warnings = true;
		private bool show_errors = true;

		private ToggleToolButton _vala_warning_button = null;
		private ToggleToolButton _vala_error_button = null;

 		public Vtg.PluginInstance plugin_instance { get { return _plugin_instance; } construct { _plugin_instance = value; } }
		
		public int error_count {
			get {
				return _error_count;
			}
		}

		public int warning_count {
			get {
				return _warning_count;
			}
		}
		
		public BuildLogView (Vtg.PluginInstance plugin_instance)
		{
			GLib.Object (plugin_instance: plugin_instance);
		}

		~BuildLogView ()
		{
			var panel = _plugin_instance.window.get_bottom_panel ();
			panel.remove_item (_ui);
		}

		construct 
		{
			
			
			var panel = _plugin_instance.window.get_bottom_panel ();
			_ui = new Gtk.VBox (false, 8);

			//toobar
			var toolbar = new Gtk.Toolbar ();
			toolbar.set_style (ToolbarStyle.BOTH_HORIZ);
			toolbar.set_icon_size (IconSize.SMALL_TOOLBAR);

			_vala_warning_button = new Gtk.ToggleToolButton ();
			_vala_warning_button.set_label (_("Warnings"));
			_vala_warning_button.set_is_important (true);
			_vala_warning_button.set_icon_name (Gtk.STOCK_DIALOG_WARNING);
			_vala_warning_button.set_active (true);
			_vala_warning_button.toggled.connect (on_toggle_warnings_toggled);
			_vala_warning_button.set_tooltip_text (_("Show or hide the warnings from the build result view"));
			toolbar.insert (_vala_warning_button, -1);

			_vala_error_button = new Gtk.ToggleToolButton ();
			_vala_error_button.set_label (_("Errors"));
			_vala_error_button.set_is_important (true);
			_vala_error_button.set_icon_name (Gtk.STOCK_DIALOG_ERROR);
			_vala_error_button.toggled.connect (on_toggle_errors_toggled);
			_vala_error_button.set_tooltip_text (_("Show or hide the errors from the build result view"));
			_vala_error_button.set_active (true);
			toolbar.insert (_vala_error_button, -1);

			_ui.pack_start (toolbar, false, true, 0);
			
			//error / warning list view
			this._child_model = new ListStore (7, typeof(string), typeof(string), typeof(string), typeof(int), typeof(int), typeof (int), typeof(GLib.Object));
			_model = new Gtk.TreeModelFilter (_child_model, null);
			_model.set_visible_func (this.filter_model);
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
			_build_view.row_activated.connect (this.on_build_view_row_activated);
			_build_view.set_rules_hint (true);
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_build_view);
			_ui.pack_start (scroll, true, true, 0);
			_ui.show_all ();
			panel.add_item_with_stock_icon (_ui, _("Build results"), Gtk.STOCK_EXECUTE);
			_plugin_instance.output_view.message_added.connect (this.on_message_added);
			_child_model.set_sort_column_id (5, SortType.ASCENDING);
			
			update_toolbar_button_status ();
		}

		public void initialize (ProjectManager? project = null)
		{
			this._project = project;
			current_error_row = 0;
			_error_count = 0;
			_warning_count = 0;
			_child_model.clear ();
			update_toolbar_button_status ();
		}

		public void activate ()
		{
			var panel = _plugin_instance.window.get_bottom_panel ();
			panel.activate_item (this._ui);
			var view = _plugin_instance.window.get_active_view ();
			if (view != null && !view.is_focus) {
				view.grab_focus ();
			}
		}

		private void on_toggle_warnings_toggled (Gtk.ToggleToolButton sender)
		{
			show_warnings = sender.get_active ();
			if (_model != null)
				_model.refilter ();
		}

		private void on_toggle_errors_toggled (Gtk.ToggleToolButton sender)
		{
			show_errors = sender.get_active ();
			if (_model != null)
				_model.refilter ();
		}
		
		public void on_message_added (OutputView sender, OutputTypes output_type, string message)
		{
			if (output_type != OutputTypes.BUILD)
				return;
				
			string[] lines = message.split ("\n");
			int idx = 0;
			while (lines[idx] != null) {
				string[] tmp = lines[idx].split (":",2);
				if (!StringUtils.is_null_or_empty (tmp[0])
				    && !StringUtils.is_null_or_empty (tmp[1]) 
				    && (tmp[0].has_suffix (".vala") || tmp[0].has_suffix (".vapi"))) {
					add_message (tmp[0], tmp[1]);
				}
				idx++;
			}
		}

		public void on_build_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			activate_path (path);
		}

		private void activate_path (TreePath path)
		{
			TreeIter iter;
			if (_child_model.get_iter (out iter, path)) {
				string name;
				int line, col;
				ProjectManager? proj;

				_child_model.get (iter, 2, out name, 3, out line, 4, out col, 6, out proj);

				if (proj != null) {
					string uri = proj.source_uri_for_name (name);
					if (uri != null)
						_plugin_instance.activate_uri (uri, line, col);
					else
						GLib.warning ("Couldn't find uri for source: %s", name);
				} else {
					_plugin_instance.activate_display_name (name, line, col);
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
			}
			if (current_error_row < (_error_count + _warning_count) - 1)
				current_error_row++;
			else
				current_error_row = 0;
		}

		public void previous_error ()
		{
			TreePath path = new TreePath.from_string (current_error_row.to_string());
			if (path != null) {
				activate_path (path);
				_build_view.scroll_to_cell (path, null, false, 0, 0);
				_build_view.get_selection ().select_path (path);
			}
			if (current_error_row > 0)
				current_error_row--;
			else
				current_error_row = (_error_count + _warning_count) - 1;
		}

		/* 
		  Examples:

		  Vala Errors:
		  	vtgprojectmanagerbuilder.vala:37.3-37.16: error: missing return type in method `BuildLogView.LogView´
		  	public LogView(Vtg.Plugin plugin)
		  	^^^^^^^^^^^^^^
		  	vtgprojectmanagerbuilder.vala:72.16-72.16: error: syntax error, expected `;'
		  	string lines[] = message.split ("\n");
				            ^
					    Compilation failed: 2 error(s), 0 warning(s)

		  Vala Warnings:
			vtgprojectmanagerui.vala:377.13-377.16: warning: local variable `iter' declared but never used

		  GCC Warning:

		  vtgsourceoutlinerview.c:703: warning: passing argument 2 of ‘vtg_source_outliner_view_on_show_private_symbol_toggled’ from incompatible pointer type
		  vtgsourceoutlinerview.vala:186: note: expected ‘struct GtkWidget *’ but argument is of type ‘struct GtkToggleButton *’
		 */
		private void add_message (string file, string message)
		{
			if (!file.has_suffix (".vala"))
				return;
			
			string[] parts = message.split (":", 3);
			string[] src_ref = parts[0].split ("-")[0].split (".");
			if (src_ref.length < 2)
				return;
			
			int line = src_ref[0].to_int ();
			int col = 0;

			if (src_ref[1] != null)
				col = src_ref[1].to_int ();

			string stock_id = null;

			if (parts[1] != null) {
				int sort_id = 0;
				if (parts[1].has_suffix ("error")) {
					stock_id = Gtk.STOCK_DIALOG_ERROR;
					_error_count++;
					sort_id = 0; //errors come first
				} else if (parts[1].has_suffix ("warning")) {
					stock_id = Gtk.STOCK_DIALOG_WARNING;
					_warning_count++;
					sort_id = 1;
				} else {
					_error_count++;
					sort_id = 0; //errors come first
				}

				if (parts[2] != null) {
					TreeIter iter;
					_child_model.append (out iter);
					_child_model.set (iter, 0, stock_id, 1, parts[2], 2, file, 3, line, 4, col, 5, sort_id, 6, _project);
					update_toolbar_button_status ();
				}
			}
		}
		
		private void update_toolbar_button_status ()
		{
			if (_warning_count == 0) {
				_vala_warning_button.set_label (_("Warnings"));
				_vala_warning_button.set_sensitive (false);
			} else {
				_vala_warning_button.set_label ("%s (%d)".printf (_("Warnings"), _warning_count));
				_vala_warning_button.set_sensitive (true);
			}
			
			if (_error_count == 0) {
				_vala_error_button.set_label (_("Errors"));
				_vala_error_button.set_sensitive (false);
			} else {
				_vala_error_button.set_label ("%s (%d)".printf (_("Errors"), _error_count));
				_vala_error_button.set_sensitive (true);
			}
		}
		
		private bool filter_model (TreeModel model, TreeIter iter)
		{
			if (show_warnings && show_errors)
				return true;
			
			int val;
			model.get (iter, 5, out val);
			if (val == 0 && show_errors)
				return true;
			else if (val == 1 && show_warnings)
				return true;
				
			return false;
		}

	}
}
