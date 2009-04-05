/*
 *  vbftarget.vala - Vala Build Framework library
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
	public enum TargetTypes
	{
		PROGRAM,
		LIBRARY,
		DATA,
		BUILT_SOURCES
	}
	
	public class Target : GLib.Object
	{
		public string id;
		public string name;
		public TargetTypes type;
		public bool no_install = false;
		public unowned Group group;
		
		private Gee.List<Source> sources = new Gee.ArrayList<Source> ();
		private Gee.List<Vbf.File> files = new Gee.ArrayList<Vbf.File> ();
		private Gee.List<Package> packages = new Gee.ArrayList<Package> ();
		private Gee.List<string> include_dirs = new Gee.ArrayList<string> ();
		private Gee.List<string> built_libraries = new Gee.ArrayList<string> ();

		public Target (Group group, TargetTypes type, string id)
		{
			this.group = group;
			this.id = id;
			string[] tmp = id.split (".",2);
			this.name = tmp[0];
			this.type = type;
		}
		
		public Gee.List<Source> get_sources ()
		{
			return new ReadOnlyList<Source> (sources);
		}
		
		public bool has_sources_of_type (FileTypes type)
		{
			foreach (Source source in sources) {
				if (source.type == type) {
					return true;
				}
			}
			
			return false;
		}
		
		internal void add_source (Source source)
		{
			sources.add (source);
		}

		public bool has_file_of_type (FileTypes type)
		{
			foreach (File file in files) {
				if (file.type == type) {
					return true;
				}
			}
			
			return false;
		}
		public Gee.List<Vbf.File> get_files ()
		{
			return new ReadOnlyList<Vbf.File> (files);
		}
		
		internal void add_file (Vbf.File file)
		{
			files.add (file);
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
	}
}

