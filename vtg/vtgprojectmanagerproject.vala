/*
 *  vtgprojectmanagerproject.vala - Vala developer toys for GEdit
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
using Gbf;

namespace Vtg.ProjectManager
{
	public class Project : GLib.Object
	{
		private weak Backend _backend = null;
		private Gbf.Project _gbf_project = null;

		public string name = null;
		public Gee.List<ProjectModule> modules = new Gee.ArrayList<ProjectModule> ();
		public Gee.List<ProjectGroup> groups = new Gee.ArrayList<ProjectGroup> ();

		public ProjectGroup? find_group (string name)
		{
			foreach (ProjectGroup group in groups) {
				if (group.name == name) {
					return group;
				}
			}
			
			return null;
		}

		public bool contains_source_file (string uri)
		{
			foreach (ProjectGroup group in groups) {
				foreach (ProjectTarget target in group.targets) {
					foreach (ProjectSource source in target.sources) {
						if (source.uri == uri) {
							GLib.debug ("source found %s", source.uri);
							return true;
						}
					}
				}
			}

			return false;
		}

		public void open (string project_name) throws GLib.Error
		{
			this.name = project_name;

			GLib.debug ("initializing gbf backends...");
			Gbf.Backend.init ();
		
			weak Gbf.Backend found = null;

			GLib.debug ("looking for a backend for: %s", project_name);
			foreach (weak Gbf.Backend item in Backend.get_backends ()) {
				var proj = Backend.new_project (item.id);
				if (proj.probe (name)) {
					_backend = item;
					break;
				}
			}
		
			_gbf_project = null;

			if (_backend != null) {
				GLib.debug ("loading project %s with %s\n", name, _backend.id);
				_gbf_project = Backend.new_project (_backend.id);			
				_gbf_project.load (name);
				parse_project ();		       
			} else {
				GLib.warning ("Can't load project, no suitable backend found");
			}
		}

		private string normalize_path (string name)
		{
			string[] name_parts = name.substring (1, name.length - 1).split ("/");
			string last_item = null;

			string target_name = "";

			foreach (string item in name_parts) {
				if (item != "..") {
					if (last_item != null) {
						target_name += "/" + last_item;
					}

					last_item = item;
				} else {
					last_item = null;
				}
			}

			if (last_item != null && last_item != "..") {
				target_name += "/" + last_item;
			}

			return target_name;
		}

		private void parse_project ()
		{
			try {
				foreach (string mod_id in _gbf_project.get_config_modules ()) {
					var module = new ProjectModule (mod_id);
					this.modules.add (module);
					foreach (string pkg_id in _gbf_project.get_config_packages (mod_id)) {
						module.packages.add (new ProjectPackage(pkg_id));
					}
				}

				foreach (string grp_id in _gbf_project.get_all_groups ()) {
					string grp_name = normalize_path (grp_id);
					ProjectGroup group = this.find_group (grp_name);
					if (group == null) {
						group = new ProjectGroup (grp_name);
						this.groups.add (group);
						foreach (string tgt_id in _gbf_project.get_group (grp_id).targets) {
							string[] tgt_parts = tgt_id.split (":");
							var tgt_name = tgt_parts[0].substring (grp_id.length, tgt_id.length - grp_id.length);
							ProjectTarget target = group.find_target (tgt_name);
							if (target == null) {
								target = new ProjectTarget (tgt_id);
								group.targets.add (target);
								foreach (string src_id in _gbf_project.get_target(tgt_id).sources) {
									var src_name = src_id.substring (tgt_id.length + 1, src_id.length - tgt_id.length);
									ProjectSource src = target.find_source (src_name);
									if (src == null) {
										src = new ProjectSource (src_name);
										target.add_source (src);
									}
								}								
							}
						}
					}
				}
			} catch (Error err) {
				GLib.warning ("error %s", err.message);
			}
		}
	}

}