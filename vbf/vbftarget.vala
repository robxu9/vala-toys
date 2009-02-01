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
		VALA_PROGRAM
	}
	
	public class Target : GLib.Object
	{
		public string name;
		public TargetTypes target_type;
		public bool no_install = false;
		public unowned Group group;
		
		private Gee.List<Source> sources = new Gee.ArrayList<Source> ();
		private Gee.List<File> files = new Gee.ArrayList<File> ();
		
		public Target (Group group, TargetTypes type, string name)
		{
			this.group = group;
			this.name = name;
			this.target_type = type;
		}
		
		public Gee.List<Source> get_sources ()
		{
			return new ReadOnlyList<Source> (sources);
		}
		
		internal void add_source (Source source)
		{
			sources.add (source);
		}
		
		public Gee.List<File> get_files ()
		{
			return new ReadOnlyList<File> (files);
		}
/*
		internal void add_file (File file)
		{
			files.add (file);
		}
*/
	}
}

