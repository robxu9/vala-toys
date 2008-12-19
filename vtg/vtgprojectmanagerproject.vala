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
		private bool in_update = false;

		public virtual signal void updated ();
		public string name = null;
		public string filename = null;

		public Gee.List<string> exec_targets = new Gee.ArrayList<string> ();
		public Gee.List<ProjectModule> modules = new Gee.ArrayList<ProjectModule> ();
		public Gee.List<ProjectGroup> groups = new Gee.ArrayList<ProjectGroup> ();
		
		public Gee.List<ProjectSource> all_vala_sources = new Gee.ArrayList<ProjectSource> ();
		
		public Gtk.TreeModel model { get { return _model; } }
		public Gbf.Project gbf_project { get { return _gbf_project; } }

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
							return true;
						}
					}
				}
			}
			return false;
		}

		public bool contains_vala_source_file (string uri)
		{
			foreach (ProjectSource source in all_vala_sources) {
				if (source.uri == uri) {
					return true;
				}
			}

			return false;
		}
		
		public string? source_uri_for_name (string name)
		{
			string[] name_parts = name.split ("/");
			int name_count = 0;
			while (name_parts[name_count] != null)
				name_count++;

			foreach (ProjectGroup group in groups) {
				foreach (ProjectTarget target in group.targets) {
					foreach (ProjectSource source in target.sources) {
						if (name_count == 1) {
							if (source.name == name) {
								return source.uri;
							}
						} else {
							string[] src_parts = source.uri.split ("/");
							int src_count = 0;
							while (src_parts[src_count] != null)
								src_count++;
							
							if (name_count <= src_count) {
								bool equals = true;
								for(int idx=0; idx < name_count; idx++) {
									if (src_parts[src_count - idx] != name_parts[name_count - idx]) {
										equals = false;
										break;
									}
								}
								
								if (equals) {
									return source.uri;
								}
							}
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
				_gbf_project.project_updated += this.on_project_updated;
				return true;
			} else {
				GLib.warning ("Can't load project, no suitable backend found");
				return false;
			}
		}

		public void close ()
		{
			this.modules.clear ();
			this.groups.clear ();
			this.exec_targets.clear ();
			this.all_vala_sources.clear ();

			this._model = null;
			this._backend = null;
			this._gbf_project = null;
		}

		private void on_project_updated (Gbf.Project sender)
		{
			GLib.debug ("project updated");
			if (in_update)
				return;

			in_update = true;
			try {
				_gbf_project.refresh ();
			} catch (Error err) {
				GLib.warning ("on_project_upadted: error: %s", err.message);
			}
			GLib.debug ("project reloaded");
			parse_project ();
			GLib.debug ("project reparsed");
			build_tree_model ();
			GLib.debug ("project build model regenerated");
			this.updated ();
			in_update = false;
		}

		private void build_tree_model ()
		{
			TreeIter project_iter;
			TreeIter modules_iter;
			TreeIter groups_iter;

			_model = new Gtk.TreeStore (5, typeof(string), typeof(string), typeof(string), typeof(GLib.Object), typeof(string));
			_model.append (out project_iter, null);
			_model.set (project_iter, 0, Gtk.STOCK_DIRECTORY, 1, name, 2, "project-root", 4, "");
			_model.append (out modules_iter, project_iter);
			_model.set (modules_iter, 0, Gtk.STOCK_DIRECTORY, 1, _("References"), 2, "project-reference", 4, "1");
			foreach (ProjectModule module in modules) {
				TreeIter module_iter;
				_model.append (out module_iter, modules_iter);
				_model.set (module_iter, 0, Gtk.STOCK_DIRECTORY, 1, module.name, 2, module.id, 3, module, 4, module.name);
				foreach (ProjectPackage package in module.packages) {
					TreeIter package_iter;
					_model.append (out package_iter, module_iter);
					_model.set (package_iter, 0, Gtk.STOCK_FILE, 1, package.name, 2, package.id, 3, package, 4, package.name);
				}
			}
			_model.append (out groups_iter, project_iter);
			_model.set (groups_iter, 0, Gtk.STOCK_DIRECTORY, 1, _("Files"), 2, "project-files", 4, "2");
			foreach (ProjectGroup group in groups) {
				foreach (ProjectTarget target in group.targets) {
					if (target.simple || target.vala_sources) {
						TreeIter target_iter = groups_iter;
						bool target_added = false;

						foreach (ProjectSource source in target.sources) {
							if (source.name.has_prefix (".") ||
							    source.name.has_suffix (".c") ||
							    source.name.has_suffix (".h") ||
							    source.name.has_suffix (".stamp"))
								continue;

							if (!target_added) {
								_model.append (out target_iter, groups_iter);
								_model.set (target_iter, 0, Gtk.STOCK_DIRECTORY, 1, group.name, 2, target.id, 3, target, 4, group.name);
								target_added = true;
							}
							TreeIter source_iter;
							_model.append (out source_iter, target_iter);
							_model.set (source_iter, 0, Gtk.STOCK_FILE, 1, source.name, 2, source.uri, 3, source, 4, source.name);
						}
					}
				}
			}
			_model.set_sort_column_id (4, SortType.ASCENDING);
		}

		private void parse_project ()
		{
			try {
				this.modules.clear ();
				this.groups.clear ();
				this.exec_targets.clear ();
				this.all_vala_sources.clear ();
				
				foreach (string mod_id in _gbf_project.get_config_modules ()) {
					var module = new ProjectModule (this, mod_id);
					this.modules.add (module);
					foreach (string pkg_id in _gbf_project.get_config_packages (mod_id)) {
						module.packages.add (new ProjectPackage(pkg_id));
					}
				}
				
				foreach (string grp_id in _gbf_project.get_all_groups ()) {
					string grp_name = Vtg.PathUtils.normalize_path (grp_id);
					ProjectGroup group = this.find_group (grp_name);
					if (group == null) {
						group = new ProjectGroup (grp_name, this);
						this.groups.add (group);
						foreach (string tgt_id in _gbf_project.get_group (grp_id).targets) {
							var tgt_name = tgt_id.substring (grp_id.length, tgt_id.length - grp_id.length);
							string[] tgt_parts = tgt_name.split (":");
							tgt_name = tgt_parts[0];
							ProjectTarget target = group.find_target (tgt_name);
							if (target == null) {
								weak Gbf.ProjectTarget tgt = _gbf_project.get_target(tgt_id);
								target = new ProjectTarget (tgt_id, group);
								target.set_type_from_string (tgt.type);
								if (target.type == TargetTypes.EXECUTABLE) {
									string[] tmp = tgt_id.split (":");
									exec_targets.add (tmp[0]);
								}
								group.targets.add (target);
								foreach (string src_id in tgt.sources) {
									var src_name = src_id.substring (tgt_id.length + 1, src_id.length - tgt_id.length - 1);
									ProjectSource src = target.find_source (src_name);
									if (src == null) {
										src = new ProjectSource (src_name);
										if (src.is_vala_source && !contains_vala_source_file (src_name)) {
											all_vala_sources.add (src);
										}
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
