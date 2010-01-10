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
		
		private Vala.List<Vtg.ProjectDescriptor> _project_descriptors = new Vala.ArrayList<Vtg.ProjectDescriptor> ();
		private Vtg.ProjectDescriptor _default_project = null;
		
		public Projects (Plugin plugin)
		{
			_plugin = plugin;
			initialize_default_project ();
		}
		
		private void initialize_default_project ()
		{
			//return default_project anyway
			_default_project = new ProjectDescriptor ();
			_default_project.project = new ProjectManager (_plugin.config.symbol_enabled);
			_default_project.project.create_default_project ();
			_project_descriptors.add (_default_project);
		}
		
		internal Vala.List<Vtg.ProjectDescriptor> project_descriptors
		{
			get {
				return _project_descriptors;
			}
		}

		internal bool is_default_project (ProjectDescriptor project_descriptor)
		{
			return _default_project == project_descriptor;
		}

		internal void add (ProjectDescriptor project_descriptor)
		{
			_project_descriptors.add (project_descriptor);
		}

		internal void remove_with_project_manager (ProjectManager project_manager)
		{
			var project_descriptor = get_project_descriptor_for_project_manager (project_manager);
			if (project_descriptor != null)
				_project_descriptors.remove (project_descriptor);
		}

		internal ProjectDescriptor? get_project_descriptor_for_project_manager (Vtg.ProjectManager? project_manager)
		{
 			if (project_manager != null) {
				foreach (ProjectDescriptor project_descriptor in _project_descriptors) {
					if (project_descriptor.project == project_manager) {
						return project_descriptor;
					}
				}
 			}
 			
 			return null;
		}

		internal ProjectDescriptor get_project_descriptor_for_document (Gedit.Document document)
		{
			var file = Utils.get_document_name (document);
			if (file != null) {
				foreach (ProjectDescriptor project_descriptor in _project_descriptors) {
					if (project_descriptor.project.contains_file (file)) {
						return project_descriptor;
					}
				}
			}

			// if not found always return default project
			return _default_project;
		}
		
		internal ProjectDescriptor? get_project_descriptor_for_project_name (string? project_name)
		{
			if (project_name != null) {
				foreach (ProjectDescriptor item in _project_descriptors) {
					if (item.project.project.name == project_name) {
						return item;
					}
				}
			}
			
			return null;
		}
	}
}
