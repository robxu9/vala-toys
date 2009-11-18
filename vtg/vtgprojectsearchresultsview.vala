/*
 *  vtgprojectsearchresultsview.vala - Vala developer toys for GEdit
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
	internal class ProjectSearchResultsView : GLib.Object
	{
		private Gtk.VBox _ui;
		private ListStore _model = null;
		private TreeView _results_view = null;

		private TreePath? _current = null;
		private int _match_count = 0;
		private Vtg.PluginInstance _plugin_instance;
		private unowned ProjectManager _project;
				
 		public Vtg.PluginInstance plugin_instance { get { return _plugin_instance; } construct { _plugin_instance = value; } default = null; }
		
		public ProjectSearchResultsView (Vtg.PluginInstance plugin_instance)
		{
			GLib.Object (plugin_instance: plugin_instance);
		}

		~SearchResultsLogView ()
		{
			var panel = _plugin_instance.window.get_bottom_panel ();
			panel.remove_item (_ui);
		}

		construct 
		{
			var panel = _plugin_instance.window.get_bottom_panel ();
			_ui = new Gtk.VBox (false, 8);
			
			this._model = new ListStore (4, typeof(string), typeof(int), typeof(string), typeof(GLib.Object));
			_results_view = new Gtk.TreeView.with_model (_model);
			CellRenderer renderer = new CellRendererPixbuf ();
			renderer = new CellRendererText ();
			var column = new TreeViewColumn ();
			column.title = _("File");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", 0);
			_results_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("Line");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", 1);
			_results_view.append_column (column);
			renderer = new CellRendererText ();
			column = new TreeViewColumn ();
			column.title = _("Text");
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "text", 2);
			_results_view.append_column (column);			
			_results_view.row_activated += this.on_results_view_row_activated;
			_results_view.set_rules_hint (true);
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_results_view);
			_ui.pack_start (scroll, true, true, 0);
			_ui.show_all ();
			panel.add_item_with_stock_icon (_ui, _("Search results"), Gtk.STOCK_FIND);
			_plugin_instance.output_view.message_added += this.on_message_added;
			_model.set_sort_column_id (0, SortType.ASCENDING);
		}

		public void initialize (ProjectManager? project = null)
		{
			this._project = project;
			_current = null;
			_match_count = 0;
			_model.clear ();
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
		
		public void on_message_added (OutputView sender, OutputTypes output_type, string message)
		{
			if (output_type != OutputTypes.SEARCH)
				return;
				
			string[] lines = message.split ("\n");
			int idx = 0;
			while (lines[idx] != null) {
				string[] tmp = lines[idx].split (":",2);
				if (tmp[0] != null && (tmp[0].has_suffix (".vala") || tmp[0].has_suffix (".vapi"))) {
					string file = tmp[0].replace(_project.project.id + "/", "");
					add_message (file, tmp[1]);
				}
				idx++;
			}
		}

		public void on_results_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			_current = path.copy ();
			activate_path (_current);
		}

		private void activate_path (TreePath path)
		{
			TreeIter iter;
			if (_model.get_iter (out iter, path)) {
				string name;
				int line;
				ProjectManager? proj;

				_model.get (iter, 0, out name, 1, out line, 3, out proj);
				if (proj != null) {
					string uri = proj.source_uri_for_name (Path.build_filename(_project.project.id, name));
					if (uri != null)
						_plugin_instance.activate_uri (uri, line);
					else
						GLib.warning ("Couldn't find uri for source: %s", name);
				} else {
					_plugin_instance.activate_display_name (name, line);
				}
			}
		}

		public void next_match ()
		{
			if (_match_count == 0)
				return;
				
			if (_current == null || _current.to_string ().to_int () == _match_count - 1) {
				_current = new TreePath.first ();
			} else {
				_current.next ();
			}
			activate_path (_current);
			_results_view.scroll_to_cell (_current, null, false, 0, 0);
			_results_view.get_selection ().select_path (_current);
		}

		public void previous_match ()
		{
			if (_match_count == 0)
				return;
			
			if (_current == null || !_current.prev ()) {
				_current = new TreePath.from_indices (_match_count - 1);
			}
			activate_path (_current);
			_results_view.scroll_to_cell (_current, null, false, 0, 0);
			_results_view.get_selection ().select_path (_current);
		}

		/* 
		  Example 'grep -Hn vtg *.vala' output:

			vtgvcsbackendsgit.vala:2: *  vtgvcsbackendsgit.vala - Vala developer toys for GEdit
			vtgvcsbackendsivcs.vala:2: *  vtgvcsbackendsivcs.vala - Vala developer toys for GEdit
			vtgvcsbackendssvn.vala:2: *  vtgvcsbackendssvn.vala - Vala developer toys for GEdit
		 */
		private void add_message (string file, string message)
		{
			string[] parts = message.split (":", 2);
			int line = parts[0].to_int ();
			string text = Pango.trim_string (parts[1]);

			TreeIter iter;
			_model.append (out iter);
			_model.set (iter, 0, file, 1, line, 2, text, 3, _project);
			_match_count++;
		}
	}
}
