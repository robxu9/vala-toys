/*
 *  vtgprojects.vala - Vala developer toys for GEdit
 *  
 *  Copyright (C) 2010 - Andrea Del Signore <sejerpz@tin.it>
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
	public class Projects : GLib.Object
	{
		private unowned Plugin _plugin;
		
		private Vala.List<Vtg.ProjectManager> _project_managers = new Vala.ArrayList<Vtg.ProjectManager> ();
		private Vtg.ProjectManager _default_project = null;
		
		public signal void project_opened (GLib.Object project);
		public signal void project_closed (GLib.Object project);

		public Projects (Plugin plugin)
		{
			_plugin = plugin;
			initialize_default_project ();
		}
		
		private void initialize_default_project ()
		{
			//return default_project anyway
			_default_project = new ProjectManager (_plugin.config.symbol_enabled);
			_default_project.create_default_project ();
			_project_managers.add (_default_project);
		}
		
		internal Vtg.ProjectManager default_project
		{
			get {
				return _default_project;
			}
		}
		
		internal Vala.List<Vtg.ProjectManager> project_managers
		{
			get {
				return _project_managers;
			}
		}

		private void add (ProjectManager project_manager)
		{
			_project_managers.add (project_manager);
			project_manager.updated.connect (this.on_project_updated);
		}

		private void remove (ProjectManager project_manager)
		{
			project_manager.updated.disconnect (this.on_project_updated);
			_project_managers.remove (project_manager);
		}

		private void on_project_updated (ProjectManager sender)
		{
			// see if vala source of a Default project is
			// now part of the updated project
			if (sender.is_default)
				return; // no need to check the default project

			foreach (Vbf.Source source in sender.all_vala_sources) {
				foreach (Vbf.Source def_source in _default_project.all_vala_sources) {
					if (source.filename == def_source.filename) {
						var group = _default_project.project.get_group("Sources");
						Target target = group.get_target_for_id ("Default");
						target.remove_source (def_source);
						_default_project.updated ();
						break;
					}
				}
			}
		}

		internal ProjectManager? open_project (string path) throws GLib.Error
		{
			// open project
			var project = new ProjectManager (Vtg.Plugin.main_instance.config.symbol_enabled);

			if (project.open (path)) {
				this.add (project);
				this.project_opened (project);
			}

			return project;
		}

		internal void close_project (ProjectManager project)
		{
			this.project_closed (project);
			project.close ();
			this.remove (project);
		}

		internal ProjectManager get_project_manager_for_document (Gedit.Document document) throws GLib.Error
		{
			ProjectManager result = null;
			
			var file = Utils.get_document_name (document);
			if (file != null) {
				foreach (ProjectManager project_manager in _project_managers) {
					if (project_manager.contains_filename (file)) {
						result = project_manager;
						break;
					}
				}
			}

			if (result == null && FileUtils.test (file, FileTest.EXISTS)) {
				// check if we can automatically open a project in its root folder
				string root = null;
				if (Vtg.Plugin.main_instance.config.project_find_root_folder
				    && Utils.is_vala_doc (document)
				    && find_project_root_folder (file, out root)) {

					// don't reopen the same project multiple times
					foreach (ProjectManager project_manager in _project_managers) {
						if (project_manager.project.id.has_prefix (root)) {
							result = project_manager;
							break;
						}
					}

					if (result == null) {
						var project = this.open_project (root);
						project.automanaged = true;
						result = project;
					}
				}
			}

			// if not found always return default project
			if (result == null) {
				result = _default_project;
			}

			return result;
		}

		private bool find_project_root_folder (string file, out string? root)
		{
			var dir = GLib.File.new_for_path (Path.get_dirname (file));
			root = null;

			do {
				Utils.trace ("testing directory: %s", dir.get_path ());
				Vbf.IProjectBackend dummy;
				if (Vbf.probe (dir.get_path (), out dummy)) {
					root = dir.get_path ();
				} else {
					if (root != null) {
						break; // we return the best root we found until now
					}
				}
				dir = dir.get_parent ();
			} while (dir != null);

			if (root != null) {
				Utils.trace ("found project directory: %s", root);
			}
			return root != null;
		}

		internal ProjectManager? get_project_manager_for_project_id (string? project_id)
		{
			foreach (ProjectManager item in _project_managers) {
				if (item.project.id == project_id) {
					return item;
				}
			}

			return null;
		}

		internal ProjectManager? get_project_manager_for_project_name (string? project_name)
		{
			if (project_name != null) {
				foreach (ProjectManager item in _project_managers) {
					if (item.project.name == project_name) {
						return item;
					}
				}
			}

			return null;
		}

		internal Vbf.Target? get_target_for_document (Gedit.Document? document)
		{
			if (document != null) {
				var file = Utils.get_document_name (document);
				if (file != null) {
					foreach (ProjectManager item in _project_managers) {
						var source = item.get_source_file_for_filename (file);
						if (source != null)
							return source.target;
					}
				}
			}
			
			return null;
		}
	}
}
