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
		public string name;
		public string url;
		public string version;
		public string filename;
				
		public signal void updated();
		
		private Gee.List<Group> groups = new Gee.ArrayList<Group> ();	
		private Gee.List<Module> modules = new Gee.ArrayList<Module> ();
		private Gee.List<Variable> variables = new Gee.ArrayList<Variable> ();
		
		public Project (string name)
		{
			this.name = name;
		}
		
		public Gee.List<Group> get_groups ()
		{
			return new ReadOnlyList<Group> (groups);
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
			return "%s %s: %s".printf (name, version, filename);
		}
	}
}

