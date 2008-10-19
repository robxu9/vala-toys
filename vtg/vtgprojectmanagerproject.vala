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
		private Gtk.TreeStore _model;

		public string name = null;
		public string filename = null;

		public Gee.List<ProjectModule> modules = new Gee.ArrayList<ProjectModule> ();
		public Gee.List<ProjectGroup> groups = new Gee.ArrayList<ProjectGroup> ();

		public Gtk.TreeModel model { get { return _model; } }

		public ProjectGroup? find_group (string id)
		{
			foreach (ProjectGroup group in groups) {
				if (group.id == id) {
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

		public string? source_uri_for_name (string name)
		{
			foreach (ProjectGroup group in groups) {
				foreach (ProjectTarget target in group.targets) {
					foreach (ProjectSource source in target.sources) {
						if (source.name == name) {
							GLib.debug ("source uri found for %s: %s", name, source.uri);
							return source.uri;
						}
					}
				}
			}

			return null;
		}

		public bool open (string project_filename) throws GLib.Error
		{
			this.filename = project_filename;
			string[] tmp = this.filename.split ("/");
			int count = 0;
			while (tmp[count] != null) {
				count++;
			}
			if (count == 0) {
				this.name = this.filename;
			} else {
				this.name = tmp[count-1];
			}

			GLib.debug ("initializing gbf backends...");
			Gbf.Backend.init ();
		
			weak Gbf.Backend found = null;

			GLib.debug ("looking for a backend for: %s", project_filename);
			foreach (weak Gbf.Backend item in Backend.get_backends ()) {
				var proj = Backend.new_project (item.id);
				if (proj.probe (filename)) {
					_backend = item;
					break;
				}
			}
		
			_gbf_project = null;

			if (_backend != null) {
				GLib.debug ("loading project %s with %s\n", filename, _backend.id);
				_gbf_project = Backend.new_project (_backend.id);			
				_gbf_project.load (filename);
				parse_project ();
				build_tree_model ();
				return true;
			} else {
				GLib.warning ("Can't load project, no suitable backend found");
				return false;
			}
		}

		private void build_tree_model ()
		{
			TreeIter project_iter;
			TreeIter modules_iter;
			TreeIter groups_iter;

			_model = new Gtk.TreeStore (3, typeof(string), typeof(string), typeof(string));
			_model.append (out project_iter, null);
			_model.set (project_iter, 0, Gtk.STOCK_DIRECTORY, 1, name, 2, "project-root");
			_model.append (out modules_iter, project_iter);
			_model.set (modules_iter, 0, Gtk.STOCK_DIRECTORY, 1, _("References"), 2, "project-reference");
			foreach (ProjectModule module in modules) {
				TreeIter module_iter;
				_model.append (out module_iter, modules_iter);
				_model.set (module_iter, 0, Gtk.STOCK_DIRECTORY, 1, module.name, 2, module.id);
				foreach (ProjectPackage package in module.packages) {
					TreeIter package_iter;
					_model.append (out package_iter, module_iter);
					_model.set (package_iter, 0, Gtk.STOCK_FILE, 1, package.name, 2, package.id);
				}
			}
			_model.append (out groups_iter, project_iter);
			_model.set (groups_iter, 0, Gtk.STOCK_DIRECTORY, 1, _("Files"), 2, "project-files");
			foreach (ProjectGroup group in groups) {
				TreeIter group_iter;
				_model.append (out group_iter, groups_iter);
				_model.set (group_iter, 0, Gtk.STOCK_DIRECTORY, 1, group.name, 2, group.id);
				foreach (ProjectTarget target in group.targets) {
					if (target.simple || target.vala_sources) {
						foreach (ProjectSource source in target.sources) {
							if (source.name.has_prefix (".") ||
							    source.name.has_suffix (".c") ||
							    source.name.has_suffix (".h") ||
							    source.name.has_suffix (".stamp"))
								continue;

							TreeIter source_iter;
							_model.append (out source_iter, group_iter);
							_model.set (source_iter, 0, Gtk.STOCK_FILE, 1, source.name, 2, source.uri);
						}
					}
				}
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
