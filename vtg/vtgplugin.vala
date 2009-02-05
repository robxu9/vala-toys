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
	internal class ProjectDescriptor : GLib.Object
	{
		public Vsc.SymbolCompletion completion;
		public ProjectManager project;

		~ProjectDescriptor ()
		{
			if (completion != null) {
				completion.cleanup ();
			}
		}
	}

	public class Plugin : Gedit.Plugin
	{
		private Gedit.Window _window = null;
		private Gee.List<Vtg.BracketCompletion> _bcs = new Gee.ArrayList<Vtg.BracketCompletion> ();
		private Gee.List<Vtg.SymbolCompletionHelper> _scs = new Gee.ArrayList<Vtg.SymbolCompletionHelper> ();
		private Gee.List<Vtg.ProjectDescriptor> _projects = new Gee.ArrayList<Vtg.ProjectDescriptor> ();
		private Configuration _config = null;
		private Vtg.ProjectDescriptor _default_project = null;
		private ProjectManagerUi _project_manager_ui;
		
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

		public OutputView output_view { get; set; }
		public ProjectManagerUi project_manager_ui
		{ 
			get { return _project_manager_ui; }
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

		public override void activate (Gedit.Window window)
		{
			this._window = window;
			Signal.connect_after (this._window, "tab-added", (GLib.Callback) on_tab_added, this);
			Signal.connect_after (this._window, "tab-removed", (GLib.Callback) on_tab_removed, this);

			initialize_views (this._window);
			foreach (Document doc in this._window.get_documents ()) {
				initialize_document (doc);
			}

			_output_view = new OutputView (this);
			_project_manager_ui = new ProjectManagerUi (this);
			//_prj_man.project_loaded += this.on_project_loaded;
			
		}

		public override void deactivate (Gedit.Window window)
		{
			deactivate_modules ();
			_project_manager_ui = null;
			_output_view = null;
			_window = null;
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
			if (doc != null) {
				var prj = project_descriptor_find_from_document (doc);
				if (!(prj.project == null && (doc.language == null || doc.language.id != "vala"))) {
					_project_manager_ui.project_view.current_project = prj.project;
				}
			}
		}
		
		public Gedit.Window gedit_window
		{
			get { return _window; }
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
			int size;
			if (options == DeactivateModuleOptions.ALL || options == DeactivateModuleOptions.SYMBOL) {
				size = 0;
				while (_scs.size > 0 && _scs.size != size) {
					size = _scs.size;
					deactivate_symbol (_scs.get(0));					
				} 

			}
			if (options == DeactivateModuleOptions.ALL || options == DeactivateModuleOptions.BRACKET) {
				size = 0;
				while (_bcs.size > 0 && _bcs.size != size) {
					size = _bcs.size;
					deactivate_bracket (_bcs.get(0));
				}
			}
		}


		private void activate_modules (DeactivateModuleOptions options = DeactivateModuleOptions.ALL)
		{
			initialize_views (this._window);
		}

		private void activate_bracket (Gedit.View view)
		{
			var bc = new BracketCompletion (this, view);
			_bcs.add (bc);

		}
		
		private void deactivate_bracket (BracketCompletion bc)
		{
			bc.deactivate ();
			_bcs.remove (bc);
		}

		private void activate_symbol (ProjectDescriptor project, Gedit.View view)
		{
			var sc = new Vtg.SymbolCompletionHelper (this, view, project.completion);
			_scs.add (sc);
		}

 		private void deactivate_symbol (SymbolCompletionHelper sc)
		{
			sc.deactivate ();
			_scs.remove (sc);
		}

		private static void on_tab_added (Gedit.Window sender, Gedit.Tab tab, Vtg.Plugin instance)
		{
			var doc = tab.get_document ();
			var project = instance.project_descriptor_find_from_document (doc);

			if (doc.language != null && doc.language.id == "vala") {
				var view = tab.get_view ();
				instance.initialize_view (project, view);
			}
			instance.initialize_document (doc);
		}

		private static void on_tab_removed (Gedit.Window sender, Gedit.Tab tab, Vtg.Plugin instance)
		{
			var view = tab.get_view ();
			var doc = tab.get_document ();

			instance.uninitialize_view (view);
			instance.uninitialize_document (doc);
		}

		private ProjectDescriptor project_descriptor_find_from_document (Gedit.Document document)
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

		private bool scs_contains (Gedit.View view)
		{
			return (scs_find_from_view (view) != null);
		}

		public Vtg.SymbolCompletionHelper? scs_find_from_view (Gedit.View view)
		{
			foreach (Vtg.SymbolCompletionHelper sc in _scs) {
				if (sc.view == view)
					return sc;
			}
			return null;
		}

		private bool bcs_contains (Gedit.View view)
		{
			return (bcs_find_from_view (view) != null);
		}

		private BracketCompletion? bcs_find_from_view (Gedit.View view)
		{
			foreach (BracketCompletion bc in _bcs) {
				if (bc.view == view)
					return bc;
			}

			return null;
		}

		private void initialize_views (Gedit.Window window)
		{
			foreach (Gedit.View view in window.get_views ()) {
				var doc = (Gedit.Document) (view.get_buffer ());
				if (doc.language != null && doc.language.id == "vala") {
					var project = project_descriptor_find_from_document (doc);
					initialize_view (project, view);
				}
			}
		}

		private void initialize_view (ProjectDescriptor project, Gedit.View view)
		{
			if (_config.symbol_enabled && !scs_contains (view)) {
				activate_symbol (project, view);
			} else {
				GLib.warning ("sc already initialized for view");
			}

			if (_config.bracket_enabled && !bcs_contains (view)) {
				activate_bracket (view);
			} else {
				GLib.warning ("bc already initialized vor view");
			}
		}

		private void initialize_document (Gedit.Document doc)
		{
			Signal.connect (doc, "notify::language", (GLib.Callback) on_notify_language, this);
		}

		private void uninitialize_view (Gedit.View view)
		{
			var sc = scs_find_from_view (view);
			if (sc != null) {
				deactivate_symbol (sc);
			} else {
				GLib.warning ("sc not found");
			}

			var bc = bcs_find_from_view (view);
			if (bc != null) {
				deactivate_bracket (bc);
			} else {
				GLib.warning ("bc not found");
			}
		}

		private void uninitialize_document (Gedit.Document doc)
		{
			SignalHandler.disconnect_by_func (doc, (void*) on_notify_language, this);
		}

		private static void on_notify_language (Gedit.Document sender, ParamSpec pspec, Vtg.Plugin instance)
		{
			//search the view
			var app = App.get_default ();
			foreach (Gedit.View view in app.get_views ()) {
				if (view.get_buffer () == sender) {
					if (sender.language  == null || sender.language.id != "vala") {
						instance.uninitialize_view (view);
					} else {
						var project = instance.project_descriptor_find_from_document (sender);
						instance.initialize_view (project, view);
					}
					break;
				}
			}
		}


		public void activate_display_name (string display_name, int line = 0, int col = 0)
		{
			foreach (Document doc in _window.get_documents ()) {
				if (doc.get_short_name_for_display () == display_name) {
					var tab = Tab.get_from_document (doc);
					_window.set_active_tab (tab);
					doc.goto_line (line - 1);
					tab.get_view ().scroll_to_cursor ();
				}
			}
		}
		
		public Gedit.Tab activate_uri (string uri, int line = 0, int col = 0)
		{
			Gedit.Tab tab = null;
			Document existing_doc = null;
			foreach (Document doc in _window.get_documents ()) {
				if (doc.get_uri () == uri) {
					tab = Tab.get_from_document (doc);
					existing_doc = doc;
					break;
				}
			}

			if (tab == null)
				tab = _window.create_tab_from_uri (uri, Encoding.get_utf8 (), line, true, true);
			else {
				_window.set_active_tab (tab);
				if (existing_doc != null && line > 0) {
					existing_doc.goto_line (line - 1);
					tab.get_view ().scroll_to_cursor ();
				}
			}
			return tab;		
		}
		
		internal void on_project_closed (ProjectManagerUi sender, ProjectManager project)
		{
			return_if_fail (project != _default_project.project);

			foreach (ProjectDescriptor descriptor in _projects) {
				if (descriptor.project == project) {
					_projects.remove (descriptor);
					break;
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

			/* setup vapidir, built libraries and local packages */
			foreach (Group group in project.get_groups ()) {
				foreach(string package in group.get_built_libraries ()) {
					completion.parser.add_built_package (package);
				}
				foreach(string path in group.get_include_dirs ()) {
					completion.parser.add_path_to_vapi_search_dir (path);
				}
				foreach(Package package in group.get_packages ()) {
					completion.parser.try_add_package (package.id);
				}
			}
			
			/* setup source files */
			foreach (Group group in project.get_groups ()) {
				foreach (Target target in group.get_targets ()) {
					foreach (Vbf.Source source in target.get_sources ()) {
						if (source.uri.has_suffix (".vala") && source.uri.has_prefix ("file://")) {
							string filename = source.uri.substring (7, source.uri.length - 7);
							try {
								completion.parser.add_source (filename);
							} catch (Error err) {
								GLib.warning ("Error adding source %s: %s", filename, err.message);
							}
						}
					}
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
