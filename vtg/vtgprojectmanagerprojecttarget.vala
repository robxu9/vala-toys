/*
 *  vtgprojectmanagerprojecttarget.vala - Vala developer toys for GEdit
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
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

namespace Vtg.ProjectManager
{
	public class ProjectTarget
	{
		public string name;
		public string id;
		public Gee.List<ProjectSource> sources = new Gee.ArrayList<ProjectSource> ();
		private bool _simple = false;
		public bool vala_sources = false;
		public bool generated_sources = false;
		
		public ProjectTarget (string name)
		{
			this.id = name;
			this.name = name;
		}

		public bool simple
		{
			get {
				return _simple && !generated_sources;
			}
		}
		
		public void add_source (ProjectSource source)
		{
			if (sources.size == 0) {
				//defaults
				vala_sources = true;
				generated_sources = true;
				if (name.has_suffix ("/other:extra") || 
					name.has_suffix (":rule") ||
					name.has_suffix (":intltool_rule"))
					_simple = false;
				else
					_simple = true;
			}
			if (! (source.uri.has_suffix (".vala") || source.uri.has_suffix (".vapi"))) {
				vala_sources = false;
			}
			if (! (source.uri.has_suffix (".c") || source.uri.has_suffix (".h"))) {
				generated_sources = false;
			}
			
			sources.add (source);
		}
		
		public ProjectSource? find_source (string uri)
		{
			foreach (ProjectSource source in sources) {
				if (source.uri == uri) {
					return source;
				}
			}

			return null;
		}
		
	}
}