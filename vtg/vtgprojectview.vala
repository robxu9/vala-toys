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
		private Vtg.PluginInstance _plugin_instance = null;
		private Gtk.ComboBox _prjs_combo;
		private Gtk.TreeView _prj_view;
		private int _project_count = 0;

		private Module _last_selected_module;
		private Target _last_selected_target;
		
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


		const ActionEntry[] _action_entries = {
			{"packages-open-configure", Gtk.STOCK_OPEN, N_("Open configure file..."), "<control><shift>C", N_("Open configure.ac file"), on_packages_open_configure},
			{"target-open-makefile", Gtk.STOCK_OPEN, N_("Open makefile"), "<control><shift>M", N_("Open makefile.am file"), on_target_open_makefile}
		};


		private ActionGroup _actions;
		private VBox _side_panel;
		private ProjectManager _current_project = null;
		
		public ProjectManager current_project 
		{ 
			get { 
				return _current_project; 
			} 
			set { 
				if (_current_project != null) {
					_current_project.updated -= this.on_current_project_updated;
				}
				_current_project = value; 
				if (_current_project != null) {
					_current_project.updated += this.on_current_project_updated;
					_prj_view.set_model (_current_project.model);
					_prj_view.expand_all ();
				} else {
					_prj_view.set_model (null);
				}
			} 
		}
		
		public Vtg.PluginInstance plugin_instance { construct { _plugin_instance = value; } }

		public ProjectView (Vtg.PluginInstance plugin_instance)
		{
			this.plugin_instance = plugin_instance;
		}
		
		~ProjectView ()
		{
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.remove_action_group (_actions);
			var panel = _plugin_instance.window.get_side_panel ();
			panel.remove_item (_side_panel);
		}
		
		construct
		{
			var panel = _plugin_instance.window.get_side_panel ();
			_side_panel = new Gtk.VBox (false, 8);
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
			_prj_view.button_press_event += this.on_project_view_button_press;
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_prj_view);
			_side_panel.pack_start (_prjs_combo, false, false, 4);
			_side_panel.pack_start (scroll, true, true, 4);
			_side_panel.show_all ();
			panel.add_item (_side_panel, _("Projects"), null);
			panel.activate_item (_side_panel);
			_project_count = 0;

			_actions = new ActionGroup ("ProjectManagerActionGroup");
			_actions.set_translation_domain (Config.GETTEXT_PACKAGE);
			_actions.add_actions (_action_entries, this);
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.insert_action_group (_actions, -1);
			try {
				_popup_modules_ui_id = manager.add_ui_from_string (_popup_modules_ui_def, -1);
				_popup_modules = (Gtk.Menu) manager.get_widget ("/ProjectManagerPopupPackagesEdit");
				assert (_popup_modules != null);
				_popup_targets_ui_id = manager.add_ui_from_string (_popup_targets_ui_def, -1);
				_popup_targets = (Gtk.Menu) manager.get_widget ("/ProjectManagerPopupTargets");
				assert (_popup_targets != null);
			} catch (Error err) {
				GLib.warning ("Error %s", err.message);
			}
			
			//default empty project
			_prjs_combo.append_text (_("(no project opened - default)"));
			_prjs_combo.set_active (0);
			_project_count++;
		}
		
		public void add_project (Project project)
		{
			_prjs_combo.append_text (project.name);
			_prjs_combo.set_active (_project_count);
			_project_count++;
		}

		public void remove_project (Project project)
		{
			_prjs_combo.remove_text (_project_count - 1);
			_project_count--;
			if (_project_count > 0) {
				_prjs_combo.set_active (_project_count - 1);
			} else {
				update_view (null);
			}
		}

		public void on_project_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var tw = (TreeView) sender;
			var model = tw.get_model ();
			TreeIter iter;
			if (model.get_iter (out iter, path)) {
				string name, id;
				model.get (iter, 1, out name, 2, out id);
				string file = StringUtils.replace (id, "file://", ""); //HACK
				if (name != null && FileUtils.test (file, FileTest.EXISTS)) {
					_plugin_instance.activate_uri (id);
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
					string name;
					model.get_iter (out iter, path);
					model.get (iter, 1, out name, 3, out obj);
					if (obj is Module) {
						_last_selected_module = (Module) obj;
						_popup_modules.popup (null, null, null, event.button, event.time);
					} else if (obj is Target) {
						_last_selected_target = (Target) obj;
						_popup_targets.popup (null, null, null, event.button, event.time);
					}
				}
			}
			return false;
		}

		public void on_project_combobox_changed (Widget sender)
		{
			var project_name = ((ComboBox) sender).get_active_text ();
			update_view (project_name);
		}

		private void update_view (string? project_name)
		{
			ProjectManager? prj = null;

			if (project_name != null) {
				//find project
				foreach (ProjectDescriptor item in _plugin_instance.plugin.projects) {
					if (item.project.project.name == project_name) {
						prj = item.project;
						break;
					}
				}
			}
			
			current_project = prj;
		}

		private void on_current_project_updated (ProjectManager sender)
		{
			_prj_view.set_model (sender.model);
			_prj_view.expand_all ();
		}

		private void on_packages_open_configure (Gtk.Action action)
		{
			return_if_fail (_last_selected_module != null);
			string file = Path.build_filename (_last_selected_module.project.id, "configure.ac");
			
			if (FileUtils.test (file, FileTest.EXISTS)) {
				_plugin_instance.activate_uri ("file://%s".printf (file));
			}
		}

		private void on_target_open_makefile (Gtk.Action action)
		{
			return_if_fail (_last_selected_target != null);
			string file = Path.build_filename (_last_selected_target.group.id, "Makefile.am");

			if (FileUtils.test (file, FileTest.EXISTS)) {
				_plugin_instance.activate_uri ("file://%s".printf (file));
			}
		}
	}
}
