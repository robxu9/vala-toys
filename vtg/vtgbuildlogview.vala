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
		private unowned Gtk.TreeModelFilter _model;
		private TreeView _build_view = null;

		private int _current_error_row = 0;
		private int _vala_error_count = 0;
		private int _vala_warning_count = 0;
		private int _c_error_count = 0;
		private int _c_warning_count = 0;

		private unowned Vtg.PluginInstance _plugin_instance = null;
		private unowned ProjectManager _project;
		
		private bool _show_vala_warnings = true;
		private bool _show_vala_errors = true;
		private bool _show_c_warnings = false;
		private bool _show_c_errors = true;

		private ToggleToolButton _vala_warning_button = null;
		private ToggleToolButton _vala_error_button = null;
		private ToggleToolButton _c_warning_button = null;
		private ToggleToolButton _c_error_button = null;

		private enum Columns
		{
			ICON,
			MESSAGE,
			FILENAME,
			LINE,
			COLUMN,
			IS_WARNING,
			IS_VALA_SOURCE,
			PROJECT,
			COLUMNS_COUNT
		}

		public int error_count {
			get {
				return _vala_error_count + _c_error_count;
			}
		}

		public int warning_count {
			get {
				return _vala_warning_count  + _c_warning_count;
			}
		}
		
		private int shown_messages {
			get {
				int count = 0;

				if (_show_vala_warnings) {
					count += _vala_warning_count;
				}
				if (_show_vala_errors) {
					count += _vala_error_count;
				}
				if (_show_c_warnings) {
					count += _c_warning_count;
				}
				if (_show_c_errors) {
					count += _c_error_count;
				} 

				return count;
			}
		}
		
		public BuildLogView (Vtg.PluginInstance plugin_instance)
		{
			this._plugin_instance = plugin_instance;
			var panel = _plugin_instance.window.get_bottom_panel ();
			_ui = new Gtk.VBox (false, 8);

			//toobar
			var toolbar = new Gtk.Toolbar ();
			toolbar.set_style (ToolbarStyle.BOTH_HORIZ);
			toolbar.set_icon_size (IconSize.SMALL_TOOLBAR);

			/* Vala Warnings & Errors */
			_vala_warning_button = new Gtk.ToggleToolButton ();
			_vala_warning_button.set_label (_("Warnings"));
			_vala_warning_button.set_is_important (true);
			_vala_warning_button.set_icon_name (Gtk.STOCK_DIALOG_WARNING);
			_vala_warning_button.set_active (true);
			
			
			_vala_warning_button.toggled.connect (on_toggle_vala_warnings_toggled);
			_vala_warning_button.set_tooltip_text (_("Show or hide the warnings from the build result view"));
			toolbar.insert (_vala_warning_button, -1);

			_vala_error_button = new Gtk.ToggleToolButton ();
			_vala_error_button.set_label (_("Errors"));
			_vala_error_button.set_is_important (true);
			_vala_error_button.set_icon_name (Gtk.STOCK_DIALOG_ERROR);
			_vala_error_button.toggled.connect (on_toggle_vala_errors_toggled);
			_vala_error_button.set_tooltip_text (_("Show or hide the errors from the build result view"));
			_vala_error_button.set_active (true);
			toolbar.insert (_vala_error_button, -1);

			/* Separator */
			var separator = new SeparatorToolItem ();
			toolbar.insert (separator, -1);
			
			/* C Warnings & Errors */
			_c_warning_button = new Gtk.ToggleToolButton ();
			_c_warning_button.set_label (_("C Warnings"));
			_c_warning_button.set_is_important (true);
			_c_warning_button.set_icon_name (Gtk.STOCK_DIALOG_WARNING);
			_c_warning_button.set_active (_show_c_warnings);
			
			_c_warning_button.toggled.connect (on_toggle_c_warnings_toggled);
			_c_warning_button.set_tooltip_text (_("Show or hide the C warnings from the build result view"));
			toolbar.insert (_c_warning_button, -1);

			_c_error_button = new Gtk.ToggleToolButton ();
			_c_error_button.set_label (_("C Errors"));
			_c_error_button.set_is_important (true);
			_c_error_button.set_icon_name (Gtk.STOCK_DIALOG_ERROR);
			_c_error_button.toggled.connect (on_toggle_c_errors_toggled);
			_c_error_button.set_tooltip_text (_("Show or hide the C errors from the build result view"));
			_c_error_button.set_active (true);
			toolbar.insert (_c_error_button, -1);

			_ui.pack_start (toolbar, false, true, 0);
			
			//error / warning list view
			this._child_model = new ListStore (Columns.COLUMNS_COUNT, typeof(string), typeof(string), typeof(string), typeof(int), typeof(int), typeof (int), typeof (bool), typeof(GLib.Object));
			var model_tmp = new Gtk.TreeModelFilter (_child_model, null);
			_model = model_tmp;
			_model.set_visible_func (this.filter_model);
			_build_view = new Gtk.TreeView.with_model (_model);
			CellRenderer renderer = new CellRendererPixbuf ();
			var column = new TreeViewColumn ();
			column.title = _("Message");
 			column.pack_start (renderer, false);
			column.add_attribute (renderer, "stock-id", Columns.ICON);
			renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", Columns.MESSAGE);
			_build_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("File");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", Columns.FILENAME);
			_build_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("Line");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", Columns.LINE);
			_build_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("Column");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", Columns.COLUMN);
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

		~BuildLogView ()
		{
			Utils.trace ("BuildLogView destroying");
			Utils.trace ("BuildLogView destroyed");
		}

		public void destroy ()
		{

			Gedit.Panel panel = _plugin_instance.window.get_bottom_panel ();
			panel.remove_item (_ui);

			_ui = null;
			_model = null;
			_build_view = null;
			_child_model = null;
		}

		public void initialize (ProjectManager? project = null)
		{
			this._project = project;
			_current_error_row = 0;
			_vala_error_count = 0;
			_vala_warning_count = 0;
			_c_error_count = 0;
			_c_warning_count = 0;
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

		private void on_toggle_vala_warnings_toggled (Gtk.ToggleToolButton sender)
		{
			_show_vala_warnings = sender.get_active ();
			if (_model != null)
				_model.refilter ();
		}

		private void on_toggle_vala_errors_toggled (Gtk.ToggleToolButton sender)
		{
			_show_vala_errors = sender.get_active ();
			if (_model != null)
				_model.refilter ();
		}

		private void on_toggle_c_warnings_toggled (Gtk.ToggleToolButton sender)
		{
			_show_c_warnings = sender.get_active ();
			if (_model != null)
				_model.refilter ();
		}

		private void on_toggle_c_errors_toggled (Gtk.ToggleToolButton sender)
		{
			_show_c_errors = sender.get_active ();
			if (_model != null)
				_model.refilter ();
		}

		public void on_message_added (OutputView sender, OutputTypes output_type, string message)
		{
			add_message (output_type, message);
		}

		public void on_build_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var child_path = _model.convert_path_to_child_path (path);
			activate_path (child_path);
		}

		private void activate_path (TreePath path)
		{
			TreeIter iter;
			if (_child_model.get_iter (out iter, path)) {
				string name;
				int line, col;
				bool is_vala_source;
				ProjectManager? proj;

				_child_model.get (iter,
					Columns.FILENAME, out name,
					Columns.LINE, out line,
					Columns.COLUMN, out col,
					Columns.IS_VALA_SOURCE, out is_vala_source,
					Columns.PROJECT, out proj);

				if (proj != null) {
					string uri = null;
					
					if (is_vala_source)
						uri = proj.source_uri_for_name (name);
					else {
						if (name.has_prefix (Path.DIR_SEPARATOR.to_string ())) {
							// path is rooted
							try {
								uri = Filename.to_uri (name);
							} catch (Error err) {
								GLib.critical ("error: %s", err.message);
							}
						} else {
							string vala_name = name.substring (0, name.length - ".c".length) + ".vala";
							uri = proj.source_uri_for_name (vala_name);
							if (uri == null) {
								// try with vapi extension
								vala_name = name.substring (0, name.length - ".c".length) + ".vapi";
								uri = proj.source_uri_for_name (vala_name);
							}
							if (uri != null)
								uri = Path.build_filename (Path.get_dirname (uri), name);
						}
					}
					
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
			TreePath path = new TreePath.from_string (_current_error_row.to_string());
			if (path != null) {
				var child_path = _model.convert_path_to_child_path (path);
				activate_path (child_path);
				_build_view.scroll_to_cell (path, null, false, 0, 0);
				_build_view.get_selection ().select_path (path);
			}
			if (_current_error_row < (this.shown_messages) - 1)
				_current_error_row++;
			else
				_current_error_row = 0;
		}

		public void previous_error ()
		{
			TreePath path = new TreePath.from_string (_current_error_row.to_string());
			if (path != null) {
				var child_path = _model.convert_path_to_child_path (path);
				activate_path (child_path);
				_build_view.scroll_to_cell (path, null, false, 0, 0);
				_build_view.get_selection ().select_path (path);
			}
			if (_current_error_row > 0)
				_current_error_row--;
			else
				_current_error_row = (this.shown_messages) - 1;
		}

		public void clear_messages_for_source (string filename)
		{
			TreeIter iter;
			if (_child_model.get_iter_first (out iter)) {
				Vala.List<TreeIter?> to_del = new Vala.ArrayList<TreeIter?> ();
				var basename = Path.get_basename (filename);
				do {
					string file;
					bool is_warning;
					_child_model.get (iter, Columns.FILENAME, out file, Columns.IS_WARNING, out is_warning);
					if (file == basename) {
						TreeIter copy = iter;
						to_del.add (copy);
						if (is_warning)
							_vala_warning_count--;
						else
							_vala_error_count--;
					}
				} while (_child_model.iter_next (ref iter));
				foreach (TreeIter item in to_del) {
					_child_model.remove (item);
				}
				update_toolbar_button_status ();
			}
		}

		public void update_parse_result (string filename, Afrodite.ParseResult parse_result)
		{
			foreach (string message in parse_result.errors) {
				add_message (OutputTypes.BUILD, message);
			}
			foreach (string message in parse_result.warnings) {
				add_message (OutputTypes.BUILD, message);
			}
			update_toolbar_button_status ();
		}

		private void add_message (OutputTypes output_type, string message)
		{
			if (output_type != OutputTypes.BUILD)
				return;

			string[] lines = message.split ("\n");
			int idx = 0;
			while (lines[idx] != null) {
				string[] tmp = lines[idx].split (":",2);
				if (!StringUtils.is_null_or_empty (tmp[0])
				    && !StringUtils.is_null_or_empty (tmp[1])) {
					if (tmp[0].has_suffix (".vala") || tmp[0].has_suffix (".vapi")) {
						add_vala_message (tmp[0], tmp[1]);
					} else if (tmp[0].has_suffix (".c") || tmp[0].has_suffix (".h")) {
						add_c_message (tmp[0], tmp[1]);
					}
				}
				idx++;
			}
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

		 */
		private void add_vala_message (string file, string message)
		{
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
				if (parts[2] != null) {
					int is_warning = 0;
					if (parts[1].has_suffix ("error")) {
						stock_id = Gtk.STOCK_DIALOG_ERROR;
						_vala_error_count++;
						is_warning = 0; //errors come first
					} else if (parts[1].has_suffix ("warning")) {
						stock_id = Gtk.STOCK_DIALOG_WARNING;
						_vala_warning_count++;
						is_warning = 1;
					} else {
						_vala_error_count++;
						is_warning = 0; //errors come first
					}

					TreeIter iter;
					_child_model.append (out iter);
					_child_model.set (iter, 
						Columns.ICON, stock_id, 
						Columns.MESSAGE, parts[2], 
						Columns.FILENAME , file, 
						Columns.LINE, line, 
						Columns.COLUMN, col, 
						Columns.IS_WARNING, is_warning, 
						Columns.IS_VALA_SOURCE, true, 
						Columns.PROJECT, _project);
					update_toolbar_button_status ();
				}
			}
		}

		/* 
		  Examples:

		  GCC Warning:

		  vtgsourceoutlinerview.c:703: warning: passing argument 2 of ‘vtg_source_outliner_view_on_show_private_symbol_toggled’ from incompatible pointer type
		  vtgsourceoutlinerview.vala:186: note: expected ‘struct GtkWidget *’ but argument is of type ‘struct GtkToggleButton *’
		  
		  
		  we have also this message:
		  
		  In file included from tuntun-applet.c:39:
		  /usr/include/glib-2.0/glib/gi18n-lib.h:33:1: warning: "Q_" redefined
		  In file included from /usr/include/libbonobo-2.0/bonobo/bonobo-i18n.h:39,
		                   from /usr/include/libbonobo-2.0/bonobo/bonobo-generic-factory.h:16,
		                   from /usr/include/panel-2.0/panel-applet.h:33,
		                   from tuntun-applet.c:32:
		  /usr/include/glib-2.0/glib/gi18n.h:29:1: warning: this is the location of the previous definition
		 */

		private void add_c_message (string file, string message)
		{
			string[] parts = message.split (":", 3);
			string[] src_ref = parts[0].split ("-")[0].split (".");
			if (src_ref.length > 1)
				return;
			
			int line = src_ref[0].to_int ();

			string stock_id = null;

			if (parts[1] != null) {
				if (parts[2] != null) {
					string message_type;
					string message_text;
					int is_warning = 0;
					if (parts[1].to_int () != 0) {
						string[] tmp = parts[2].split(":", 2);
						message_type = tmp[0].strip ();
						message_text = tmp[1];
					} else {
						message_type = parts[1];
						message_text = parts[2];
					}
					if (message_type.has_suffix ("error")) {
						stock_id = Gtk.STOCK_DIALOG_ERROR;
						_c_error_count++;
						is_warning = 0; //errors come first
					} else if (message_type.has_suffix ("warning")) {
						stock_id = Gtk.STOCK_DIALOG_WARNING;
						_c_warning_count++;
						is_warning = 1;
					} else if (!message_type.chomp().has_suffix ("note")) {
						Utils.trace ("unrecognized message category, default to error for %s: '%s' ---> '%s' '%s' '%s'", file, message, parts[0], message_type, message_text);
						_c_error_count++;
						is_warning = 0; //errors come first
					} else {
						return;
					}

					TreeIter iter;
					_child_model.append (out iter);
					_child_model.set (iter, 
						Columns.ICON, stock_id, 
						Columns.MESSAGE, message_text, 
						Columns.FILENAME , file, 
						Columns.LINE, line, 
						Columns.COLUMN, 0, 
						Columns.IS_WARNING, is_warning, 
						Columns.IS_VALA_SOURCE, false, 
						Columns.PROJECT, _project);
					update_toolbar_button_status ();
				}
			}
		}

		private void update_toolbar_button_status ()
		{
			if (_vala_warning_count == 0) {
				_vala_warning_button.set_label (_("Warnings"));
				_vala_warning_button.set_sensitive (false);
			} else {
				_vala_warning_button.set_label ("%s (%d)".printf (_("Warnings"), _vala_warning_count));
				_vala_warning_button.set_sensitive (true);
			}

			if (_vala_error_count == 0) {
				_vala_error_button.set_label (_("Errors"));
				_vala_error_button.set_sensitive (false);
			} else {
				_vala_error_button.set_label ("%s (%d)".printf (_("Errors"), _vala_error_count));
				_vala_error_button.set_sensitive (true);
			}

			if (_c_warning_count == 0) {
				_c_warning_button.set_label (_("C Warnings"));
				_c_warning_button.set_sensitive (false);
			} else {
				_c_warning_button.set_label ("%s (%d)".printf (_("C Warnings"), _c_warning_count));
				_c_warning_button.set_sensitive (true);
			}

			if (_c_error_count == 0) {
				_c_error_button.set_label (_("C Errors"));
				_c_error_button.set_sensitive (false);
			} else {
				_c_error_button.set_label ("%s (%d)".printf (_("C Errors"), _c_error_count));
				_c_error_button.set_sensitive (true);
			}
		}

		private bool filter_model (TreeModel model, TreeIter iter)
		{
			bool is_vala_source;
			int val;
			model.get (iter, Columns.IS_VALA_SOURCE, out is_vala_source, Columns.IS_WARNING, out val);
			
			if (is_vala_source) {
				if (_show_vala_warnings && _show_vala_errors)
					return true;
			
				if (val == 0 && _show_vala_errors)
					return true;
				else if (val == 1 && _show_vala_warnings)
					return true;
			} else {
				if (_show_c_warnings && _show_c_errors)
					return true;
			
				if (val == 0 && _show_c_errors)
					return true;
				else if (val == 1 && _show_c_warnings)
					return true;
			}

			return false;
		}

	}
}
