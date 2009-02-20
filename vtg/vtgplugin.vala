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
using Vsc;
using Vbf;

namespace Vtg
{	
	public class Plugin : Gedit.Plugin
	{
		private Gee.List<PluginInstance> _instances = new Gee.ArrayList<PluginInstance> ();
		private Gee.List<Vtg.ProjectDescriptor> _projects = new Gee.ArrayList<Vtg.ProjectDescriptor> ();
		private Configuration _config = null;
		private Vtg.ProjectDescriptor _default_project = null;
		
		private enum DeactivateModuleOptions
		{
			ALL,
		        BRACKET,
			SYMBOL
	        }

		public Gee.List<Vtg.ProjectDescriptor> projects
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
			var doc = window.get_active_document ();
			var instance = get_plugin_instance_for_window (window);
			
			if (doc != null) {
				var prj = project_descriptor_find_from_document (doc);
				if (!(prj.project == null && (doc.language == null || doc.language.id != "vala"))) {
					instance.project_manager_ui.project_view.current_project = prj.project;
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

			//return default_project anyway
			if (_default_project == null) {
				_default_project = new ProjectDescriptor ();
				_default_project.completion = new Vsc.SymbolCompletion ();
				_default_project.completion.parser.resume_parsing ();
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
			var completion = new Vsc.SymbolCompletion ();
			var project = project_manager.project;
								
			/* setup referenced packages */
			foreach (Vbf.Module module in project.get_modules ()) {
				foreach (Vbf.Package package in module.get_packages ()) {
					completion.parser.try_add_package (package.name);
				}
			}

			/* first adding a built packages*/
			foreach (Group group in project.get_groups ()) {
				foreach(string package in group.get_built_libraries ()) {
					completion.parser.add_built_package (package);
				}
				foreach(Target target in group.get_targets ()) {
					foreach(string package in target.get_built_libraries ()) {
						completion.parser.add_built_package (package);
					}
				}
			}

			/* setup vapidir and local packages */
			foreach (Group group in project.get_groups ()) {
				foreach(string path in group.get_include_dirs ()) {
					completion.parser.add_path_to_vapi_search_dir (path);
				}
				foreach(Package package in group.get_packages ()) {
					completion.parser.try_add_package (package.id);
				}
				foreach(Target target in group.get_targets ()) {
					foreach(string path in target.get_include_dirs ()) {
						completion.parser.add_path_to_vapi_search_dir (path);
					}
					foreach(Package package in target.get_packages ()) {
						completion.parser.try_add_package (package.id);
					}
				}
			}
			
			/* setup source files */
			foreach (Group group in project.get_groups ()) {
				foreach (Target target in group.get_targets ()) {
					foreach (Vbf.Source source in target.get_sources ()) {
						if (source.type == FileTypes.VALA_SOURCE) {
							try {
								completion.parser.add_source (source.filename);
							} catch (Error err) {
								GLib.warning ("Error adding source %s: %s", source.filename, err.message);
							}
						}
					}
				}
			}
			
			/* update the other project manager views */
			foreach (PluginInstance instance in _instances) {
				if (instance.project_manager_ui != sender) {
					instance.project_manager_ui.project_view.add_project (project);
				}
			}

			prj.completion = completion;
			prj.project = project_manager;
			_projects.add (prj);
			completion.parser.resume_parsing ();
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
