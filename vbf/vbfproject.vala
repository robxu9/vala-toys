/*
 *  vbfproject.vala - Vala Build Framework library
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */


using GLib;
using Gee;

namespace Vbf
{
	public class Project : ConfigNode
	{
		public string id;
		public string name;
		public string url;
		public string version;
		public string working_dir;
			
		public signal void updated ();
		
		private Gee.List<Group> groups = new Gee.ArrayList<Group> ();	
		private Gee.List<Module> modules = new Gee.ArrayList<Module> ();
		private Gee.List<Variable> variables = new Gee.ArrayList<Variable> ();
		private Gee.List<FileMonitor> file_mons = new Gee.ArrayList<FileMonitor> ();
		private bool in_refresh = false;
		
		internal IProjectManager backend = null;
		
		public Project (string id)
		{
			this.id = id;
		}
		
		public Gee.List<Group> get_groups ()
		{
			return new ReadOnlyList<Group> (groups);
		}
		
		public Group? get_group (string id)
		{
			foreach (Group group in groups) {
				if (group.id == id) {
					return group;
				}
			}
			
			return null;
		}

		internal void add_group (Group group)
		{
			groups.add (group);
		}
		
		public Gee.List<Module> get_modules ()
		{
			return new ReadOnlyList<Module> (modules);
		}
		
		internal void add_module (Module module)
		{
			modules.add (module);
		}
		
		public Gee.List<Variable> get_variables ()
		{
			return new ReadOnlyList<Variable> (variables);
		}
		
		internal void add_variable (Variable variable)
		{
			variables.add (variable);
		}
		
		public override string to_string ()
		{
			return "%s %s: %s".printf (name, version, id);
		}
		
		internal void clear ()		
		{
			groups.clear ();
			variables.clear ();
			modules.clear ();
			cleanup_file_monitors ();
		}
		
		internal void setup_file_monitors ()
		{
			try {
				string fname;
				GLib.File file;
				foreach (Group group in groups) {
					fname = Path.build_filename (group.id, "Makefile.am");
					file = GLib.File.new_for_path (fname);
					var file_mon = FileMonitor.file (file, FileMonitorFlags.NONE, null);
					file_mons.add (file_mon);
					file_mon.changed += this.on_project_file_changed;
				}
				fname = Path.build_filename (id, "configure.ac");
				file = GLib.File.new_for_path (fname);
				var file_mon = FileMonitor.file (file, FileMonitorFlags.NONE, null);
				file_mons.add (file_mon);
				file_mon.changed += this.on_project_file_changed;
			} catch (Error err) {
				critical ("setup_file_monitors error: %s", err.message);
			}
		}
		
		internal void cleanup_file_monitors ()
		{
			foreach (FileMonitor file_mon in file_mons) {
				file_mon.changed -= this.on_project_file_changed;
				file_mon.cancel ();
			}
			file_mons.clear ();
		}
		
		private void on_project_file_changed (FileMonitor sender, GLib.File file, GLib.File? other_file, GLib.FileMonitorEvent event_type)
		{
			update ();
		}
		
		public void update ()
		{
			if (in_refresh)
				return;
				
			in_refresh = true;
			backend.refresh (this);
			this.updated ();
			in_refresh = false;
		}
	}
}

