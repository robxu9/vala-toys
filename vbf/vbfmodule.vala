/*
 *  vbfmodule.vala - Vala Build Framework library
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
	public class Module : GLib.Object
	{
		public string id;
		public string name;
		public unowned Project project;
		
		private Gee.List<Package> packages = new Gee.ArrayList<Package> ();
		
		public Module (Project project, string id)
		{
			this.id = id;
			this.name = id;
			this.project = project;
		}
		
		public Gee.List<Package> get_packages ()
		{
			return new ReadOnlyList<Package> (packages);
		}
		
		internal void add_package (Package package)
		{
			packages.add (package);
		}
	}
}
