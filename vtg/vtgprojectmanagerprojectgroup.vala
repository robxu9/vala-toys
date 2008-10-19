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
		public Gee.List<string> vapidirs = new Gee.ArrayList<string> ();
		public Gee.List<string> packages = new Gee.ArrayList<string> ();
		public Gee.List<string> built_libraries = new Gee.ArrayList<string> ();

		private const string[] files_to_scan = {"Makefile.am", "Makefile"};

		public ProjectGroup (Project parent, string id)
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
			initialize_vapis (parent.filename);
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


		private void initialize_vapis (string project_path)
		{
			string buffer;
			foreach (string file in files_to_scan) {
				string filename = Path.build_filename (project_path, id, file);
				GLib.debug ("READING!!!!!!!!!!!!!!!! reading makefile: %s", filename);					
				//find user referenced vapi & vapidir from Makefile
				try {
					if (FileUtils.get_contents (filename, out buffer)) {
						string[] lines = buffer.split ("\n");
						buffer = null; //this frees some memory
						foreach (string line in lines) {
							string[] tmps = line.split (" ");
							int count = 0;
							while (tmps[count] != null)
								count++;
						
							for(int idx=0; idx < count; idx++) {
								if (tmps[idx] == "--vapidir" && (idx + 1) < count) {									
									var tmp = Path.build_filename (project_path, id, tmps[idx+1]);
									GLib.debug ("vapidir reference: %s", tmp);
									vapidirs.add (tmp);
								} else if (tmps[idx] == "--pkg" && (idx + 1) < count) {
									var tmp = tmps[idx+1];
									GLib.debug ("package reference: %s", tmp);
									packages.add (tmp);
								} else if (tmps[idx] == "--library") {
									var tmp = tmps[idx+1];
									GLib.debug ("library generated: %s", tmp);
									built_libraries.add (tmp);
								}
							}
						}
						return;
					}
				} catch (FileError err) {
					GLib.warning ("Error reading file %s: %s", this.id, err.message);
				}
			}
		}
	}
}