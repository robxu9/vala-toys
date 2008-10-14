/*
 *  vtgprojectmanagerview.vala - Vala developer toys for GEdit
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
	public class View : GLib.Object
	{
		private Vtg.Plugin _plugin = null;
		private Gtk.ComboBox _prjs_combo;
		private Gtk.TreeView _prj_view;
		private Gtk.TreeModel _model;
		private int _project_count = 0;
		public Project _current_project = null;

		public Project current_project { get { return _current_project; } }
		public Vtg.Plugin plugin { construct { _plugin = value; } }

		public View (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}

		construct
		{
			var panel = _plugin.gedit_window.get_side_panel ();
			var vbox = new Gtk.VBox (false, 8);
			_prjs_combo = new Gtk.ComboBox.text ();
			_prjs_combo.changed += this.on_project_combobox_changed;
			_prj_view = new Gtk.TreeView ();
			CellRenderer renderer = new CellRendererPixbuf ();
			var column = new TreeViewColumn ();
 			column.pack_start (renderer, false);
			column.add_attribute (renderer, "stock-id", 0);
			renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", 1);
			_prj_view.append_column (column);
			_prj_view.set_headers_visible (false);
			_prj_view.row_activated += this.on_project_view_row_activated;
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_prj_view);
			vbox.pack_start (_prjs_combo, false, false, 4);
			vbox.pack_start (scroll, true, true, 4);
			vbox.show_all ();
			panel.add_item (vbox, _("Projects"), null);
			panel.activate_item (vbox);
			_project_count = 0;
		}

		public void add_project (Project project)
		{
			_prjs_combo.append_text (project.name);
			_prjs_combo.set_active (_project_count);
			_project_count++;
		}

		public void on_project_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var tw = (TreeView) sender;
			var model = tw.get_model ();
			TreeIter iter;
			if (model.get_iter (out iter, path)) {
				string name, id;
				model.get (iter, 1, out name, 2, out id);
				if (name != null && (name.has_suffix (".vala") || name.has_suffix (".vapi"))) {
					_plugin.activate_uri (id);
				}
			}
		}


		public void on_project_combobox_changed (Widget sender)
		{
			var project_name = ((ComboBox) sender).get_active_text ();
			update_view (project_name);
		}

		private void update_view (string project_name)
		{
			_current_project = null;
			//find project
			foreach (ProjectDescriptor item in _plugin.projects) {
				GLib.debug ("%s vs %s", item.project.name, project_name);
				if (item.project.name == project_name) {
					GLib.debug ("found!");
					_prj_view.set_model (item.project.model);
					_prj_view.expand_all ();
					_current_project = item.project;
					break;
				}
			}
		}
	}
}