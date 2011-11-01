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
using Vbf;

namespace Vtg
{
	internal class ProjectView : GLib.Object
	{
		private unowned Vtg.PluginInstance _plugin_instance = null;
		private Gtk.ComboBox _prjs_combo;
		private Gtk.ListStore _prjs_model;
		private Gtk.TreeView _prj_view;
		private int _project_count = 0;

		private Group _last_selected_group;
		
		private Gtk.Menu _popup_modules;
		private uint _popup_modules_ui_id;
		private string _popup_modules_ui_def = """
                                        <ui>
                                        <popup name='ProjectManagerPopupPackagesEdit'>
                                            <menuitem action='packages-open-configure'/>
                                        </popup>
                                        </ui>""";

		private Gtk.Menu _popup_targets;
		private uint _popup_targets_ui_id;
		private string _popup_targets_ui_def = """
                                        <ui>
                                        <popup name='ProjectManagerPopupTargets'>
                                            <menuitem action='target-open-makefile'/>
                                        </popup>
                                        </ui>""";


		const Gtk.ActionEntry[] _action_entries = {
			{"packages-open-configure", Gtk.Stock.OPEN, N_("Open configure file..."), "<control><shift>C", N_("Open configure.ac file"), on_packages_open_configure},
			{"target-open-makefile", Gtk.Stock.OPEN, N_("Open makefile"), "<control><shift>M", N_("Open makefile.am file"), on_target_open_makefile}
		};


		private Gtk.ActionGroup _actions;
		private VBox _side_panel;
		private ProjectManager _current_project = null;
		private Gtk.TreeModelFilter _filtered_model;
		private Gtk.CheckButton _check_button_show_sources = null;
		
		public ProjectManager current_project 
		{ 
			get { 
				return _current_project; 
			} 
			set {
				if (_current_project != value) {
					if (_current_project != null) {
						_current_project.updated.disconnect (this.on_current_project_updated);
					}
					_current_project = value; 
					if (_current_project != null) {
						_current_project.updated.connect (this.on_current_project_updated);
	 					if (_current_project.model != null) {
	 						update_project_treeview ();
						} else {
							clear_project_treeview ();
						}

						//sync the project combo view
						Gtk.TreeIter iter;
						if (_current_project.project != null) {
							if (this.lookup_iter_for_project_name (_current_project.project.name, out iter))
								_prjs_combo.set_active_iter (iter);
						}
					} else {
						clear_project_treeview ();
					}
				}
			}
		}

		public ProjectView (Vtg.PluginInstance plugin_instance)
		{
			this._plugin_instance = plugin_instance;
			_prjs_model = new Gtk.ListStore(2, typeof(string), typeof(Project));
			
			var panel = _plugin_instance.window.get_side_panel ();
			_side_panel = new Gtk.VBox (false, 8);
			_prjs_combo = new Gtk.ComboBox.with_model (_prjs_model);
			CellRenderer renderer = new Gtk.CellRendererText ();
			_prjs_combo.pack_start (renderer, true);
			_prjs_combo.add_attribute (renderer, "text", 0);
			_prjs_combo.changed.connect (this.on_project_combobox_changed);
			
			_prj_view = new Gtk.TreeView ();
			renderer = new CellRendererPixbuf ();
			
			var column = new TreeViewColumn ();
			column.pack_start (renderer, false);
			column.add_attribute (renderer, "pixbuf", 0);
			renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", 1);
			
			_prj_view.append_column (column);
			_prj_view.set_headers_visible (false);
			_prj_view.row_activated.connect (this.on_project_view_row_activated);
			_prj_view.button_press_event.connect (this.on_project_view_button_press);
			
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_prj_view);

			_check_button_show_sources = new Gtk.CheckButton.with_label (_("Show only source files"));
			_check_button_show_sources.active = Vtg.Plugin.main_instance.config.project_only_show_sources;
			_check_button_show_sources.toggled.connect (this.on_show_data_dir_toggled);
			
			_side_panel.pack_start (_prjs_combo, false, false, 4);
			_side_panel.pack_start (scroll, true, true, 4);
			_side_panel.pack_start (_check_button_show_sources, false, false, 4);
			_side_panel.show_all ();
			panel.add_item_with_stock_icon (_side_panel, "Projects", _("Projects"), Gtk.Stock.DIRECTORY);
			panel.activate_item (_side_panel);
			_project_count = 0;

			_actions = new Gtk.ActionGroup ("ProjectManagerActionGroup");
			_actions.set_translation_domain (Config.GETTEXT_PACKAGE);
			_actions.add_actions (_action_entries, this);

			var manager = _plugin_instance.window.get_ui_manager ();
			try {
				manager.insert_action_group (_actions, -1);
				_popup_modules_ui_id = manager.add_ui_from_string (_popup_modules_ui_def, -1);
				_popup_modules = (Gtk.Menu) manager.get_widget ("/ProjectManagerPopupPackagesEdit");
				assert (_popup_modules != null);
				_popup_targets_ui_id = manager.add_ui_from_string (_popup_targets_ui_def, -1);
				_popup_targets = (Gtk.Menu) manager.get_widget ("/ProjectManagerPopupTargets");
				assert (_popup_targets != null);
			} catch (Error err) {
				GLib.warning ("Error %s", err.message);
			}
		}

		~ProjectView ()
		{
			Utils.trace ("ProjectView destroying");
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.remove_ui (_popup_modules_ui_id);
			manager.remove_ui (_popup_targets_ui_id);
			manager.remove_action_group (_actions);
			var panel = _plugin_instance.window.get_side_panel ();
			panel.remove_item (_side_panel);
			Utils.trace ("ProjectView destroyed");
		}

		private void update_project_treeview ()
		{
			_filtered_model = new Gtk.TreeModelFilter (_current_project.model, null);
			_filtered_model.set_visible_func (this.filter_function);
			_prj_view.set_model (_filtered_model);
			_prj_view.expand_all ();
		}

		private void clear_project_treeview ()
		{
			_prj_view.set_model (null);
			_filtered_model = null;
		}

		private bool filter_function (Gtk.TreeModel sender, Gtk.TreeIter iter)
		{
			bool res = true;
			
			if (_check_button_show_sources.active) {
				GLib.Object obj;
				string node_id;
				sender.get (iter, 2, out node_id, 3, out obj);

				if (node_id == "project-reference")
					res = false;
				else if (obj is Vbf.Group) {
					Vbf.Group group = (Vbf.Group) obj;
					res = group.has_sources_of_type (FileTypes.VALA_SOURCE);
				} else if (obj is Vbf.Target) {
					Vbf.Target target = (Vbf.Target) obj;
					res = target.has_sources_of_type (FileTypes.VALA_SOURCE);
				}
			}
			
			return res;
		}
		
		private void on_show_data_dir_toggled (Widget sender)
		{
			var check = (CheckButton) sender;
			Vtg.Plugin.main_instance.config.project_only_show_sources = check.active;
			_filtered_model.refilter ();
		}

		public void add_project (Project project)
		{
			Gtk.TreeIter iter;
			_prjs_model.append (out iter);
			_prjs_model.set (iter, 0, project.name, 1, project);
			_prjs_combo.set_active_iter (iter);
			_project_count++;
		}

		public void remove_project (Project project)
		{
			Gtk.TreeIter iter;
			if (this.lookup_iter_for_project_name (project.name, out iter)) {
				_prjs_model.remove (iter);
			}
			
			_project_count--;
			if (_project_count > 0) {
				_prjs_combo.set_active (0);
				if (_prjs_combo.get_active_iter (out iter)) {
					Project selected_project;
					_prjs_model.get (iter, 1, out selected_project);
					update_view (selected_project.name);
				} else {
					update_view (null);
				}
			} else {
				update_view (null);
			}
		}

		private bool lookup_iter_for_project_name (string project_name, out TreeIter? combo_iter)
		{
			TreeModel model = _prjs_combo.get_model ();
			Gtk.TreeIter iter;
			
			combo_iter = null;
			bool valid = model.get_iter_first (out iter);
			while (valid) {
				string name;
				model.@get (iter, 0, out name);
	
				if (name == project_name) {
					combo_iter = iter;
					return true;
				}
				valid = model.iter_next (ref iter);
			}
			
			return false;
		}

		public void on_project_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var tw = (TreeView) sender;
			var model = tw.get_model ();
			TreeIter iter;
			if (model.get_iter (out iter, path)) {
				string name, id;
				model.get (iter, 1, out name, 2, out id);
				try {
					if (id != null) {
						string file = Filename.from_uri (id);
						if (name != null && FileUtils.test (file, FileTest.EXISTS)) {
							_plugin_instance.activate_uri (id);
						}
					}
				} catch (Error e) {
					GLib.warning ("on_project_view_row_activated error: %s", e.message);
				}

			}
		}

		public bool on_project_view_button_press (Gtk.Widget sender, Gdk.EventButton event)
		{
			if (event.button == 3) {
				weak TreeModel model;

				var rows =  _prj_view.get_selection ().get_selected_rows (out model);
				if (rows.length () == 1) {
					TreeIter iter;
					GLib.Object obj;
					weak TreePath path = rows.nth_data (0);
					string id;
					model.get_iter (out iter, path);
					model.get (iter, 2, out id, 3, out obj);
					if (id == "project-root") {
						string file = Path.build_filename (current_project.project.id, "configure.ac");
			
						if (FileUtils.test (file, FileTest.EXISTS)) {
							_popup_modules.popup (null, null, null, event.button, event.time);
						}
					} else if (obj is Group) {
						_last_selected_group = (Group) obj;
						string file = Path.build_filename (_last_selected_group.id, "Makefile.am");
			
						if (FileUtils.test (file, FileTest.EXISTS)) {
							_popup_targets.popup (null, null, null, event.button, event.time);
						}
					}
				}
			}
			return false;
		}

		public void on_project_combobox_changed (Widget sender)
		{
			Gtk.TreeIter iter;
			if (_prjs_combo.get_active_iter (out iter)) {
				Project project;
				_prjs_model.get (iter, 1, out project);
				update_view (project.name);
			} else {
				update_view (null);
			}
		}

		private void update_view (string? project_name)
		{
			ProjectManager? prj;
			
			if (current_project != null && current_project.project.name == project_name) {
				return;
			}
			
			//find project
			prj = Vtg.Plugin.main_instance.projects.get_project_manager_for_project_name (project_name);
			current_project = prj;
		}

		private void on_current_project_updated (ProjectManager sender)
		{
			update_project_treeview ();

			var doc = _plugin_instance.window.get_active_document ();
			if (doc != null && Utils.is_vala_doc (doc)) {
				try {
					var new_project = Plugin.main_instance.projects.get_project_manager_for_document (doc);
					if (new_project != null)
						this.current_project = new_project;
				} catch (Error err) {
					critical ("error: %s", err.message);
				}
			}
		}

		private void on_packages_open_configure (Gtk.Action action)
		{
			return_if_fail (current_project != null);
			string file = Path.build_filename (current_project.project.id, "configure.ac");
			
			if (FileUtils.test (file, FileTest.EXISTS)) {
				try {
					_plugin_instance.activate_uri (Filename.to_uri (file));
				} catch (Error e) {
					GLib.warning ("error %s converting file %s to uri", e.message, file);
				}
			}
		}

		private void on_target_open_makefile (Gtk.Action action)
		{
			return_if_fail (_last_selected_group != null);
			string file = Path.build_filename (_last_selected_group.id, "Makefile.am");
			try {
				if (FileUtils.test (file, FileTest.EXISTS)) {
					_plugin_instance.activate_uri (Filename.to_uri (file));
				}
			} catch (Error e) {
					GLib.warning ("error %s converting file %s to uri", e.message, file);
			}
		}
	}
}
