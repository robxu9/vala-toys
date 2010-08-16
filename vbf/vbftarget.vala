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
using Vala;

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
		
		private Vala.List<Source> sources = new Vala.ArrayList<Source> ();
		private Vala.List<Vbf.File> files = new Vala.ArrayList<Vbf.File> ();
		private Vala.List<Package> packages = new Vala.ArrayList<Package> ();
		private Vala.List<string> include_dirs = new Vala.ArrayList<string> ();
		private Vala.List<string> built_libraries = new Vala.ArrayList<string> ();

		public Target (Group group, TargetTypes type, string id)
		{
			this.group = group;
			this.id = id;
			string[] tmp = id.split (".",2);
			this.name = tmp[0];
			this.type = type;
		}
		
		public Vala.List<Source> get_sources ()
		{
			return sources;
		}
		
		public Source? get_source (string filename)
		{
			foreach (Source source in sources) {
				if (source.filename == filename)
					return source;
			}
			
			return null;
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
		
		public void add_source (Source source)
		{
			sources.add (source);
		}

		public void remove_source (Source source)
		{
			sources.remove (source);
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

		public bool has_file_with_extension (string extension)
		{
			var ext = ".%s".printf (extension);
			foreach (File file in files) {
				if (file.filename.has_suffix (ext)) {
					return true;
				}
			}
			
			return false;
		}
		
		public Vala.List<Vbf.File> get_files ()
		{
			return files;
		}
		
		internal void add_file (Vbf.File file)
		{
			files.add (file);
		}

		public Vala.List<Package> get_packages ()
		{
			return packages;
		}
				
		public void add_package (Package package)
		{
			packages.add (package);
			package.parent_target = this;
		}

		public bool contains_package (string package_id)
		{
			foreach (Package package in packages) {
				if (package.id == package_id) {
					return true;
				}
			}
			
			return false;
		}

		public Vala.List<string> get_include_dirs ()
		{
			return include_dirs;
		}

		public bool contains_include_dir (string dir)
		{
			foreach (string item in include_dirs) {
				if (item == dir) {
					return true;
				}
			}
			return false;
		}
		
		internal void add_include_dir (string dir)
		{
			include_dirs.add (dir);
		}

		public Vala.List<string> get_built_libraries ()
		{
			return built_libraries;
		}
		
		internal void add_built_library (string dir)
		{
			built_libraries.add (dir);
		}		
	}
}

