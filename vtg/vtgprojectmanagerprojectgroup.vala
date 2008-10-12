/*
 *  vtgprojectmanagerprojectgroup.vala - Vala developer toys for GEdit
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
	public class ProjectGroup
	{
		public string name;
		public string id;
		public Gee.List<ProjectTarget> targets = new Gee.ArrayList<ProjectTarget> ();
		
		public ProjectGroup (string id)
		{
			if (id == null || id.length == 0) {
				this.id = _("other");
				this.name = this.id;
			} else {
				this.id = id;
				if (id.length > 2)
					this.name = id.substring (1,id.length-2);
				else
					this.name = id;
			}
		}
		
		public ProjectTarget? find_target (string id)
		{
			foreach (ProjectTarget target in targets) {
				if (target.id == id) {
					return target;
				}
			}
			
			return null;
		}
	}
}