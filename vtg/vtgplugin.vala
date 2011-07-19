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
	//TODO: remove this class an consolidate all this logic inside PluginInstance
	public class PluginWindowAdapter : Peas.ExtensionBase, Gedit.WindowActivatable
	{
		private Gedit.Window _window;

		public Gedit.Window window { owned get { return _window; } construct { _window = value; } }

		public PluginWindowAdapter ()
		{
			GLib.Object ();
		}

		public void activate () 
		{
			Plugin.main_instance.activate_for_window (_window);
		}

		public void deactivate () 
		{
			//TODO
		}

		public void update_state () {
			Plugin.main_instance.update_state_for_window (_window);
		}
	}

	public class Plugin : Peas.ExtensionBase, Gedit.AppActivatable
	{
		public static unowned Vtg.Plugin main_instance = null;
		
		private Vala.List<PluginInstance> _instances = new Vala.ArrayList<PluginInstance> ();
		private Configuration _config = null;
		private Vtg.Projects _projects = null;

		private enum DeactivateModuleOptions
		{
			ALL,
		        BRACKET,
			SYMBOL,
			SOURCECODE_OUTLINER
	        }

		public Vala.List<PluginInstance> instances
		{
			get { return _instances; }
		}

		public Vtg.Projects projects
		{
			get { return _projects; }
		}
		
		public Configuration config 
		{ 
			get {
				return _config;
			}
		}
		
		public Gedit.App app
		{
			owned get;
			construct;
		}

		public Plugin ()
		{
			GLib.Object ();
		}

		construct
		{
			main_instance = this;
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
		
		public void activate_for_window (Gedit.Window window)
		{
			if (get_plugin_instance_for_window (window) == null) {
				var instance = new PluginInstance (window);
				_instances.add (instance);
			}
		}
		
		public void activate ()
		{
			_config = new Configuration ();
			_config.notify.connect (this.on_configuration_property_changed);
			GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, null);
			_projects = new Vtg.Projects (this);
			_projects.project_opened.connect (this.on_project_opened);
			_projects.project_closed.connect (this.on_project_closed);
		}

		public void deactivate ()
		{
			deactivate_modules ();
			_instances.clear ();
		}

		public void update_state_for_window (Gedit.Window window)
		{
			var view = window.get_active_view ();
			var instance = get_plugin_instance_for_window (window);

			Gedit.Document doc = null;
			if (view != null) {
				doc =  (Gedit.Document) view.get_buffer ();
			
				if (doc != null) {
					try {
						var prj = _projects.get_project_manager_for_document (doc);
						if (prj != null && Utils.is_vala_doc (doc)) {
							instance.project_view.current_project = prj;
						}
						if (instance.source_outliner != null)
							instance.source_outliner.active_view = view;
					} catch (Error err) {
						critical ("error: %s", err.message);
					}
				}
			}

			if (view == null || doc == null || !Utils.is_vala_doc (doc))
				instance.source_outliner.active_view = null;
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
		
		internal bool project_need_save (ProjectManager project)
		{
			foreach (PluginInstance instance in _instances) {
				foreach (Gedit.Document doc in instance.window.get_unsaved_documents ()) {
					if (project.contains_filename (Utils.get_document_name (doc))) {
						return true;
					}
				}
			}
			
			return false;
		}

		internal bool saving = false;
		
		[CCode(instance_pos=-1)]
		private void on_document_saved (Gedit.Document doc, void *arg1)
		{
			saving = false;
		}
		
		private void save_doc_sync (PluginInstance instance, Gedit.Document doc)
		{
			//HACK: save the gEdit document synchronously
			saving = true;
			ulong id = Signal.connect (doc, "saved", (GLib.Callback) this.on_document_saved, this);
			Gedit.commands_save_document (instance.window, doc);
			while (saving) {
				MainContext.default().iteration (false);
			}
			doc.disconnect (id);
		}
		
		internal void project_save_all (ProjectManager project)
		{
			foreach (PluginInstance instance in _instances) {
				foreach (Gedit.Document doc in instance.window.get_unsaved_documents ()) {
					var filename = Utils.get_document_name (doc);
					if (!StringUtils.is_null_or_empty (filename) && project.contains_filename (filename)) {
						this.save_doc_sync (instance, doc);
					}
				}
			}
		}	

		private void on_project_closed (Vtg.Projects sender, GLib.Object pm)
		{
			var project = (ProjectManager)pm;
			return_if_fail (!project.is_default);

			foreach (PluginInstance instance in _instances) {
				foreach (Gedit.Document doc in instance.window.get_documents ()) {
					if (project.contains_filename (Utils.get_document_name (doc))) {
						//close tab
						var tab = Tab.get_from_document (doc);
						instance.window.close_tab (tab);
					}
				}
				instance.project_view.remove_project (project.project);
			}
		}

		private void on_project_opened (Projects sender, GLib.Object pm)
		{
			var project_manager = (Vtg.ProjectManager)pm;
			var project = project_manager.project;
			
			foreach (PluginInstance instance in _instances) {
				instance.project_view.add_project (project);
			}

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
			_projects.project_opened.disconnect (this.on_project_opened);
			_projects.project_closed.disconnect (this.on_project_closed);
			deactivate_modules ();
			main_instance = null;
		}
	}

	public class PluginConfig : Peas.ExtensionBase, PeasGtk.Configurable 
	{
	    public PluginConfig () 
	    {
	          Object ();
            }

	    public Gtk.Widget create_configure_widget () 
	    {
		  return Plugin.main_instance.config.get_configuration_dialog ();
	    }
	}
}

[ModuleInit]
public void peas_register_types (TypeModule module) 
{
	var objmodule = module as Peas.ObjectModule;
 	objmodule.register_extension_type (typeof (Gedit.AppActivatable),
                                     typeof (Vtg.Plugin));
 	objmodule.register_extension_type (typeof (Gedit.WindowActivatable),
                                     typeof (Vtg.PluginWindowAdapter));
        objmodule.register_extension_type (typeof (PeasGtk.Configurable),
                                     typeof (Vtg.PluginConfig));

}
