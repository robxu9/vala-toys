/*
 *  vtgplugin.vala - Vala developer toys for GEdit
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
using Afrodite;
using Vbf;

namespace Vtg
{	
	public class Plugin : Gedit.Plugin
	{
		private Vala.List<PluginInstance> _instances = new Vala.ArrayList<PluginInstance> ();
		private Vala.List<Vtg.ProjectDescriptor> _projects = new Vala.ArrayList<Vtg.ProjectDescriptor> ();
		private Configuration _config = null;
		private Vtg.ProjectDescriptor _default_project = null;
		
		private enum DeactivateModuleOptions
		{
			ALL,
		        BRACKET,
			SYMBOL,
			SOURCECODE_OUTLINER
	        }

		public Vala.List<Vtg.ProjectDescriptor> projects
		{
			get { return _projects; }
		}
		
		public Configuration config 
		{ 
			get {
				return _config;
			}
		}
		
		construct
		{
			_config = new Configuration ();
			_config.notify += this.on_configuration_property_changed;
			GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, null);
			initialize_default_project ();
		}

		private void initialize_default_project ()
		{
			//return default_project anyway
			_default_project = new ProjectDescriptor ();
			_default_project.project = new ProjectManager (_config.symbol_enabled);
			_default_project.project.create_default_project ();
			_projects.add (_default_project);
		}

		private PluginInstance? get_plugin_instance_for_window (Gedit.Window window)
		{
			foreach (PluginInstance instance in _instances) {
				if (instance.window == window) {
					return instance;
				}
			}
			
			return null;
		}
		public override void activate (Gedit.Window window)
		{
			if (get_plugin_instance_for_window (window) == null) {
				var instance = new PluginInstance (this, window);
				_instances.add (instance);
			}
		}
		
		public override void deactivate (Gedit.Window window)
		{
			deactivate_modules ();
			_instances.clear ();
		}
	  
		public override bool is_configurable ()
		{
			return true;
		}

		public override weak Gtk.Widget? create_configure_dialog ()
		{
			return _config.get_configuration_dialog ();
		}

		public override void update_ui (Gedit.Window window)
		{
			var view = window.get_active_view ();
			if (view != null) {
				var doc =  (Gedit.Document) view.get_buffer ();
				var instance = get_plugin_instance_for_window (window);
			
				if (doc != null) {
					var prj = project_descriptor_find_from_document (doc);
					if (prj.project != null && Utils.is_vala_doc (doc)) {
						instance.project_manager_ui.project_view.current_project = prj.project;
					}
					if (instance.source_outliner != null)
						instance.source_outliner.active_view = view;
				}
			}
		}

		private void on_configuration_property_changed (GLib.Object sender, ParamSpec param)
		{
			var name = param.get_name ();
			
			if (name == "bracket-enabled") {
				if (_config.bracket_enabled) {
					activate_modules (DeactivateModuleOptions.BRACKET);
				} else {
					deactivate_modules (DeactivateModuleOptions.BRACKET);
			        }
			} else if (name == "symbol-enabled") {
				if (_config.bracket_enabled) {
					activate_modules (DeactivateModuleOptions.SYMBOL);
				} else {
					deactivate_modules (DeactivateModuleOptions.SYMBOL);
			        }
			} else if (name == "sourcecode-outliner-enabled") {
				if (_config.sourcecode_outliner_enabled) {
					activate_modules (DeactivateModuleOptions.SOURCECODE_OUTLINER);
				} else {
					deactivate_modules (DeactivateModuleOptions.SOURCECODE_OUTLINER);
				}
			}
		}

		private void deactivate_modules (DeactivateModuleOptions options = DeactivateModuleOptions.ALL)
		{
			if (options == DeactivateModuleOptions.ALL || options == DeactivateModuleOptions.SYMBOL) {
				foreach (PluginInstance instance in _instances) {
					instance.deactivate_symbols ();
				}
			}
			if (options == DeactivateModuleOptions.ALL || options == DeactivateModuleOptions.BRACKET) {
				foreach (PluginInstance instance in _instances) {
					instance.deactivate_brackets ();
				}
			}
			if (options == DeactivateModuleOptions.ALL || options == DeactivateModuleOptions.SOURCECODE_OUTLINER) {
				foreach (PluginInstance instance in _instances) {
					instance.deactivate_sourcecode_outliner ();
				}
			}
		}

		private void activate_modules (DeactivateModuleOptions options = DeactivateModuleOptions.ALL)
		{
			foreach (PluginInstance instance in _instances) {
				instance.initialize_views ();
			}
		}

		internal ProjectDescriptor project_descriptor_find_from_document (Gedit.Document document)
		{
			var file = document.get_uri ();
			if (file == null) {
				file = document.get_short_name_for_display ();
			}
			foreach (ProjectDescriptor project in _projects) {
				if (project.project.contains_file (file)) {
					return project;
				}
			}

			return _default_project;
		}

		internal void on_project_closed (ProjectManagerUi sender, ProjectManager project)
		{
			return_if_fail (project != _default_project.project);

			foreach (PluginInstance instance in _instances) {
				foreach (Gedit.Document doc in instance.window.get_documents ()) {
					if (project.contains_file (doc.get_uri ())) {
						//close tab
						var tab = Tab.get_from_document (doc);
						instance.window.close_tab (tab);
					}
				}
				if (instance.project_manager_ui != sender) {
					instance.project_manager_ui.project_view.remove_project (project.project);
				} 
			}

			foreach (ProjectDescriptor descriptor in _projects) {
				if (descriptor.project == project) {
					_projects.remove (descriptor);
					break;
				}
			}

		}
		
		internal bool project_need_save (ProjectManager project)
		{
			foreach (PluginInstance instance in _instances) {
				foreach (Gedit.Document doc in instance.window.get_unsaved_documents ()) {
					if (project.contains_file (doc.get_uri ())) {
						return true;
					}
				}
			}
			
			return false;
		}

		internal void project_save_all (ProjectManager project)
		{
			foreach (PluginInstance instance in _instances) {
				foreach (Gedit.Document doc in instance.window.get_unsaved_documents ()) {
					var uri = doc.get_uri ();
					if (!StringUtils.is_null_or_empty (uri) && project.contains_file (uri)) {
						doc.save (DocumentSaveFlags.IGNORE_MTIME);
					}
				}
			}
		}	

		internal void on_project_loaded (ProjectManagerUi sender, ProjectManager project_manager)
		{
			var prj = new ProjectDescriptor ();
			var project = project_manager.project;
			
			/* update the other project manager views */
			foreach (PluginInstance instance in _instances) {
				if (instance.project_manager_ui != sender) {
					instance.project_manager_ui.project_view.add_project (project);
				}
			}

			prj.project = project_manager;
			_projects.add (prj);
			
			weak Gtk.RecentManager recent = Gtk.RecentManager.get_default ();
			Gtk.RecentData recent_data = Gtk.RecentData ();
			string name = project.name;
			string[] groups = new string[] { "vtg" };
			recent_data.display_name = name;
			recent_data.groups = groups;
			recent_data.is_private = true;
			recent_data.mime_type = "text/plain";
			recent_data.app_name = "vtg";
			recent_data.app_exec = "gedit %u";
			try {
				if (!recent.add_full (Filename.to_uri (project.id + "/configure.ac"), recent_data)) {
					GLib.warning ("cannot add project %s to recently used list", project.id);
				}
			} catch (Error e) {
					GLib.warning ("error %s converting file configure.ac to uri", e.message);
			}

		}

		~Plugin ()
		{
			deactivate_modules ();
		}
	}
}

[ModuleInit]
public GLib.Type register_gedit_plugin (TypeModule module) 
{
	return typeof (Vtg.Plugin);
}
