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
using Gee;

namespace Vbf
{
	public class Group : GLib.Object
	{
		public string name;
		public string id;
		public unowned Project project = null;

		private Gee.List<Package> packages = new Gee.ArrayList<Package> ();
		private Gee.List<string> include_dirs = new Gee.ArrayList<string> ();
		private Gee.List<string> built_libraries = new Gee.ArrayList<string> ();
		
		private Gee.List<Target> targets = new Gee.ArrayList<Target> ();
		private Gee.List<Variable> variables = new Gee.ArrayList<Variable> ();
		private Gee.List<Group> subgroups = new Gee.ArrayList<Group> ();

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
		
		public Gee.List<Target> get_targets ()
		{
			return new ReadOnlyList<Target> (targets);
		}
		
		internal void add_target (Target target)
		{
			targets.add (target);
		}
		
		public Gee.List<Package> get_packages ()
		{
			return new ReadOnlyList<Package> (packages);
		}
		
		internal void add_package (Package package)
		{
			packages.add (package);
		}
				
		public Gee.List<string> get_include_dirs ()
		{
			return new ReadOnlyList<string> (include_dirs);
		}
		
		internal void add_include_dir (string dir)
		{
			include_dirs.add (dir);
		}

		public Gee.List<string> get_built_libraries ()
		{
			return new ReadOnlyList<string> (built_libraries);
		}
		
		internal void add_built_library (string dir)
		{
			built_libraries.add (dir);
		}
						
		public Gee.List<Group> get_subgroups ()
		{
			return new ReadOnlyList<Group> (subgroups);
		}

		public Gee.List<Variable> get_variables ()
		{
			return new ReadOnlyList<Variable> (variables);
		}
		
		internal void add_variable (Variable variable)
		{
			variables.add (variable);
		}
	}
}

