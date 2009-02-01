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
		public string makefile;
		public unowned Project project = null;
		
		private Gee.List<Target> targets = new Gee.ArrayList<Target> ();
		private Gee.List<Variable> variables = new Gee.ArrayList<Variable> ();
		private Gee.List<Group> subgroups = new Gee.ArrayList<Group> ();

		public Group (Project project, string makefile)
		{
			this.project = project;
			this.makefile = makefile;
			this.name = makefile.split ("/")[0];
			setup_file_monitor ();
		}

		public Gee.List<Target> get_targets ()
		{
			return new ReadOnlyList<Target> (targets);
		}
		
		internal void add_target (Target target)
		{
			targets.add (target);
		}
		
		public Gee.List<Group> get_subgroups ()
		{
			return new ReadOnlyList<Group> (subgroups);
		}
/*
		internal void add_subgroup (Group group)
		{
			subgroups.add (group);
		}
*/
		public Gee.List<Variable> get_variables ()
		{
			return new ReadOnlyList<Variable> (variables);
		}
		
		internal void add_variable (Variable variable)
		{
			variables.add (variable);
		}
		
		internal void setup_file_monitor ()
		{
			
		}
	}
}

