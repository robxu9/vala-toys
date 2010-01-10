/*
 *  vbfgroup.vala - Vala Build Framework library
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
using Vala;

namespace Vbf
{
	public class Group : GLib.Object
	{
		public string name;
		public string id;
		public unowned Project project = null;

		private Vala.List<Package> packages = new Vala.ArrayList<Package> ();
		private Vala.List<string> include_dirs = new Vala.ArrayList<string> ();
		private Vala.List<string> built_libraries = new Vala.ArrayList<string> ();
		
		private Vala.List<Target> targets = new Vala.ArrayList<Target> ();
		private Vala.List<Variable> variables = new Vala.ArrayList<Variable> ();
		private Vala.List<Group> subgroups = new Vala.ArrayList<Group> ();

		public Group (Project project, string id)
		{
			this.project = project;
			this.id = id;
			this.name = id.replace (project.id, "");
			if (this.name.has_prefix ("/"))
				this.name = this.name.split ("/")[1];
			else
				this.name = this.name.split ("/")[0];
			
			if (name == "") {
				name = "/ - " + project.name;
			}
		}
		
		public Vala.List<Target> get_targets ()
		{
			return new ReadOnlyList<Target> (targets);
		}

		public bool contains_target (string id)
		{
			return (get_target_for_id (id) != null);
		}
		
		public Target? get_target_for_id (string id)
		{
			foreach (Target target in targets) {
				if (target.id == id) {
					return target;
				}
			}
			return null;
		}
		
		public void add_target (Target target)
		{
			targets.add (target);
		}
		
		public Vala.List<Package> get_packages ()
		{
			return new ReadOnlyList<Package> (packages);
		}
		
		
		internal void add_package (Package package)
		{
			packages.add (package);
		}
				
		public Vala.List<string> get_include_dirs ()
		{
			return new ReadOnlyList<string> (include_dirs);
		}
		
		internal void add_include_dir (string dir)
		{
			include_dirs.add (dir);
		}

		public Vala.List<string> get_built_libraries ()
		{
			return new ReadOnlyList<string> (built_libraries);
		}
		
		internal void add_built_library (string dir)
		{
			built_libraries.add (dir);
		}
						
		public Vala.List<Group> get_subgroups ()
		{
			return new ReadOnlyList<Group> (subgroups);
		}

		public Vala.List<Variable> get_variables ()
		{
			return new ReadOnlyList<Variable> (variables);
		}
		
		internal void add_variable (Variable variable)
		{
			variables.add (variable);
		}
	}
}

