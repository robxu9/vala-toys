/*
 *  vtgprojectmanager.vala - Vala developer toys for GEdit
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
using Vbf;

namespace Vtg
{
	public class ProjectManager : GLib.Object
	{
		private Project _project = null;
		private Gtk.TreeStore _model;
		private bool in_update = false;

		public virtual signal void updated ();
		public string filename = null;

		public Gee.List<string> exec_targets = new Gee.ArrayList<string> ();
		public Gee.List<Vbf.Source> all_vala_sources = new Gee.ArrayList<Vbf.Source> ();
		
		public Gtk.TreeModel model { get { return _model; } }
		public Vbf.Project project { get { return _project; } }
		
		public VcsTypes vcs_type = VcsTypes.NONE;
		public string changelog_uri = null;
		
		~ProjectManager ()
		{
			GLib.debug ("project manager destroyes");
		}
		
		public bool contains_source_file (string uri)
		{
			foreach (Group group in _project.get_groups ()) {
				foreach (Target target in group.get_targets ()) {
					foreach (Vbf.Source source in target.get_sources ()) {
						if (source.uri == uri) {
							return true;
						}
					}
				}
			}
			return false;
		}

		public Vbf.Source? get_source_file_from_uri (string uri)
		{
			foreach (Group group in _project.get_groups ()) {
				foreach (Target target in group.get_targets ()) {
					foreach (Vbf.Source source in target.get_sources ()) {
						if (source.uri == uri) {
							return source;
						}
					}
				}
			}
			return null;
		}

		public bool contains_vala_source_file (string uri)
		{
			foreach (Vbf.Source source in all_vala_sources) {
				if (source.uri == uri) {
					return true;
				}
			}

			return false;
		}
		
		public string? source_uri_for_name (string name)
		{
			string[] name_parts = name.split ("/");
			foreach (Group group in _project.get_groups ()) {
				foreach (Target target in group.get_targets ()) {
					foreach (Vbf.Source source in target.get_sources ()) {
						if (name_parts.length == 1) {
							if (source.name == name) {
								return source.uri;
							}
						} else if (source.uri != null) {
							string[] src_parts = source.uri.split ("/");
							
							if (name_parts.length <= src_parts.length) {
								bool equals = true;
								for(int idx=0; idx < name_parts.length; idx++) {
									if (src_parts[src_parts.length - idx] != name_parts[name_parts.length - idx]) {
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
			IProjectManager pm = new Am.ProjectManager (); 
			bool res = pm.probe (project_filename);
			if (res) {
				_project = pm.open (project_filename);
				if (_project == null)
					return false;
					
				parse_project ();
				build_tree_model ();
				vcs_test (project_filename);
				_project.updated += this.on_project_updated;
				return true;
			} else {
				throw new ProjectManagerError.NO_BACKEND (_("Can't load project, no suitable backend found"));
			}
		}


		private void vcs_test (string filename)
		{
			//test if the project is under some known revision control system
			Vtg.Vcs.Backends.IVcs backend = new Vtg.Vcs.Backends.Git ();
			vcs_type = VcsTypes.NONE;
			if (backend.test (filename)) {
				vcs_type = VcsTypes.GIT;
			} else {
				backend = new Vtg.Vcs.Backends.Bzr ();
				if (backend.test (filename)) {
					vcs_type = VcsTypes.BZR;
				} else {
					backend = new Vtg.Vcs.Backends.Svn ();
					if (backend.test (filename)) {
						vcs_type = VcsTypes.SVN;
					}
				}
			}
		}
		
		public void close ()
		{
			this.exec_targets.clear ();
			this.all_vala_sources.clear ();

			this._model = null;
			this._project = null;
		}

		private void on_project_updated (Vbf.Project sender)
		{
			if (in_update)
				return;

			in_update = true;
			parse_project ();
			build_tree_model ();
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
			_model.set (project_iter, 0, Gtk.STOCK_DIRECTORY, 1, _project.name, 2, "project-root", 4, "");
			_model.append (out modules_iter, project_iter);
			_model.set (modules_iter, 0, Gtk.STOCK_DIRECTORY, 1, _("References"), 2, "project-reference", 4, "1");
			foreach (Module module in _project.get_modules ()) {
				TreeIter module_iter;
				_model.append (out module_iter, modules_iter);
				_model.set (module_iter, 0, Gtk.STOCK_DIRECTORY, 1, module.name, 2, module.id, 3, module, 4, module.name);
				foreach (Package package in module.get_packages ()) {
					TreeIter package_iter;
					_model.append (out package_iter, module_iter);
					_model.set (package_iter, 0, Gtk.STOCK_FILE, 1, package.name, 2, package.id, 3, package, 4, package.name);
				}
			}
			_model.append (out groups_iter, project_iter);
			_model.set (groups_iter, 0, Gtk.STOCK_DIRECTORY, 1, _("Files"), 2, "project-files", 4, "2");
			foreach (Group group in _project.get_groups ()) {
				foreach (Target target in group.get_targets ()) {
					if (target.has_sources_of_type (SourceTypes.VALA)) {
						TreeIter target_iter = groups_iter;
						bool target_added = false;

						foreach (Vbf.Source source in target.get_sources ()) {
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
			_model.set_sort_column_id (4, Gtk.SortType.ASCENDING);
			_model.set_sort_func (4, this.sort_model);
		}

		private void parse_project ()
		{
			//this.modules.clear ();
			//this.groups.clear ();
			this.exec_targets.clear ();
			this.all_vala_sources.clear ();
			changelog_uri = null;
			
			foreach (Group group in _project.get_groups ()) {
				foreach (Target target in group.get_targets ()) {
					if (target.type == TargetTypes.PROGRAM) {
						exec_targets.add (target.name);
					}
					foreach (Vbf.Source source in target.get_sources ()) {
						if (source.type == SourceTypes.VALA) {
							all_vala_sources.add (source);
						}
					}								
				}
			}
			
			if (FileUtils.test (Path.build_filename ( _project.working_dir, "changelog"), FileTest.EXISTS)) {
				changelog_uri = "file://%s".printf (Path.build_filename ( _project.working_dir, "changelog"));
			} else if (FileUtils.test (Path.build_filename ( _project.working_dir, "ChangeLog"), FileTest.EXISTS)) {
				changelog_uri = "file://%s".printf (Path.build_filename ( _project.working_dir, "ChangeLog"));
			}
		}
		
		private int sort_model (TreeModel model, TreeIter a, TreeIter b)
		{
			string vala;
			string valb;
			
			model.get (a, 4, out vala);
			model.get (b, 4, out valb);
			
			return PathUtils.compare_vala_filenames (vala,valb);
		}
	}
}
