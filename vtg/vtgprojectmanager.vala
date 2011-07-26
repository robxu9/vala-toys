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
using Afrodite;

namespace Vtg
{
	public class ProjectManager : GLib.Object
	{
		private Project _project = null;
		private Gtk.TreeStore _model;
		private bool _enable_completion;
		private bool in_update = false;
		private Vala.HashMap<Vbf.Target, Afrodite.CompletionEngine> _completions = null;
		private int parser_thread_count = 0;
		private bool _sc_building = false;

		public signal void updated ();
		public string filename = null;
		public bool is_default = false;

		public Vala.List<Vbf.Target> exec_targets = new Vala.ArrayList<Vbf.Target> ();
		public Vala.List<Vbf.Source> all_vala_sources = new Vala.ArrayList<Vbf.Source> ();
		
		public Gtk.TreeModel model { get { return _model; } }
		public Vbf.Project project { get { return _project; } }

		// this project was opened automatically by vala toys
		public bool automanaged { get; set; }

		public VcsTypes vcs_type = VcsTypes.NONE;
		public string changelog_uri = null;

		public signal void symbol_cache_building (ProjectManager sender);
		public signal void symbol_cache_builded (ProjectManager sender);
		
		public signal void completion_begin_parsing (ProjectManager sender, CompletionEngine completion);
		public signal void completion_end_parsing (ProjectManager sender, CompletionEngine completion);
		
		private uint _idle_id;

		public bool enable_completion 
		{
			get {
				return _enable_completion;
			}
			set {
				if (_enable_completion != value) {
					_enable_completion = value;
					if (_enable_completion)
						setup_completions ();
					else
						cleanup_completions ();
				}
			}
		}

		public Vala.HashMap<Vbf.Target, Afrodite.CompletionEngine> completions
		{
			get {
				 return _completions;
			}
		}

		public ProjectManager (bool enable_completion)
		{
			_enable_completion = enable_completion;
		}
		
		~ProjectManager ()
		{
			cleanup_completions ();
		}

		public Afrodite.CompletionEngine? get_completion_for_file (string? uri)
		{
			if (uri != null && _completions != null) {
				foreach (Group group in _project.get_groups ()) {
					foreach (Target target in group.get_targets ()) {
						foreach (Vbf.Source source in target.get_sources ()) {
							if (source.uri == uri) {
								return get_completion_for_target (target);
							}
						}
					}
				}
			}
			return null;
		}

		public Afrodite.CompletionEngine? get_completion_for_target (Vbf.Target target)
		{
			if (_completions != null) {
				foreach (Vbf.Target key in _completions.get_keys ()) {
					if (key.id == target.id) {
						return _completions.@get (key);
					}
				}
			}

			return null;
		}
		
		public bool contains_filename (string? filename)
		{
			if (filename != null) {
				foreach (Group group in _project.get_groups ()) {
					foreach (Target target in group.get_targets ()) {
						foreach (Vbf.Source source in target.get_sources ()) {
							try {
								if (Filename.from_uri (source.uri) == filename) {
									return true;
								}
							} catch (GLib.ConvertError err) {
								GLib.warning ("error converting uri %s to filename: %s", source.uri, err.message);
							}
						}
						foreach (Vbf.File file in target.get_files ()) {
							try {
								if (Filename.from_uri (file.uri) == filename) {
									return true;
								}
							} catch (GLib.ConvertError err) {
								GLib.warning ("error converting uri %s to filename: %s", file.uri, err.message);
							}
						}
					}
				}
			}
			return false;
		}

		public Vbf.Source? get_source_file_from_uri (string? uri)
		{
			if (uri != null) {
				foreach (Group group in _project.get_groups ()) {
					foreach (Target target in group.get_targets ()) {
						foreach (Vbf.Source source in target.get_sources ()) {
							if (source.uri == uri) {
								return source;
							}
						}
					}
				}
			}
			return null;
		}

		public Vbf.Source? get_source_file_for_filename (string? filename)
		{
			if (filename != null) {
				foreach (Group group in _project.get_groups ()) {
					foreach (Target target in group.get_targets ()) {
						foreach (Vbf.Source source in target.get_sources ()) {
							if (source.filename == filename) {
								return source;
							}
						}
					}
				}
			}
			return null;
		}

		public bool contains_vala_source_file (string? uri)
		{
			if (uri != null) {
				foreach (Vbf.Source source in all_vala_sources) {
					if (source.uri == uri) {
						return true;
					}
				}
			}

			return false;
		}
		
		public string? source_uri_for_name (string? name)
		{
			if (name != null) {
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
			}
			
			return null;
		}

		public void create_default_project  ()
		{
			_project = new Vbf.Project ("vtg-default-project");
			_project.name = _("default project");
			var group = new Vbf.Group (_project, "Sources");
			var target = new Vbf.Target (group, TargetTypes.PROGRAM, "Default", _("Default"));
			group.add_target (target);
			_project.add_group (group);
			_project.updated.connect (this.on_project_updated);
			is_default = true;
		}

		public bool open (string project_filename) throws GLib.Error
		{
			if (!FileUtils.test (project_filename, FileTest.IS_DIR | FileTest.IS_REGULAR | FileTest.EXISTS))
				throw new FileError.FAILED (_("Can't load project, file not found"));

			IProjectBackend backend;
			if (Vbf.probe (project_filename, out backend)) {
				_project = backend.open (project_filename);
				if (_project == null)
					return false;
					
				parse_project ();
				setup_completions ();
				build_tree_model ();
				vcs_test (project_filename);
				_project.updated.connect (this.on_project_updated);
				return true;
			} else {
				throw new ProjectManagerError.NO_BACKEND (_("Can't load project, no suitable backend found"));
			}
		}

		private bool target_has_vala_source (Vbf.Target target)
		{
			foreach (Vbf.Source source in target.get_sources ()) {
				if (source.type == FileTypes.VALA_SOURCE) {
					return true;
				}
			}
			return false;
		}

		private void setup_completions ()
		{
			if (!_enable_completion)
				return;

			_completions = new Vala.HashMap<Vbf.Target, CompletionEngine> ();
			foreach (Group group in _project.get_groups ()) {
				foreach (Vbf.Target target in group.get_targets ()) {
					if (!target_has_vala_source (target))
						continue;

					var completion = new CompletionEngine (target.name);
					completion.begin_parsing.connect (this.on_completion_engine_begin_parse);
					completion.end_parsing.connect (this.on_completion_engine_end_parse);
					completion.file_parsed.connect (this.on_completion_engine_file_parsed);
					_completions.@set (target, completion);

					foreach(string path in target.get_include_dirs ()) {
						completion.add_vapi_dir (path);
					}

					/* first adding all built packages */
					//foreach(string package in target.get_built_libraries ()) {
					//	GLib.debug ("adding built library %s for target %s", package, target.id);
					//	completion.parser.add_built_package (package);
					//}

					/* setup referenced packages */
					Vala.List<string> vapis = target.get_include_dirs ();
					Vala.List<string> group_vapis = group.get_include_dirs ();

					//TODO: duplicate entries should be removed
					string[] vapi_dirs = new string[vapis.size + group_vapis.size];
					int index = 0;
					foreach (string item in vapis)
						vapi_dirs[index++] = item;
					foreach (string item in group_vapis) {
						vapi_dirs[index++] = item;
					}

					foreach (Package package in group.get_packages ()) {
						Utils.trace ("setup_completions: group %s, referenced package: %s", group.id, package.id);
						var paths = Afrodite.Utils.get_package_paths (package.id, null, vapi_dirs);
						if (paths != null) {
							//foreach (string path in paths)
							//	GLib.debug ("     target %s, referenced package: %s -> %s", target.id, package.id, path);
							completion.queue_sourcefiles (paths, null, true);
						} else {
							Utils.trace ("setup_completions: group %s, no vapi found for: %s", group.id, package.id);
						}
					}
					
					foreach (Package package in target.get_packages ()) {
						Utils.trace ("setup_completions: target %s, referenced package: %s", target.id, package.id);
						var paths = Afrodite.Utils.get_package_paths (package.id, null, vapi_dirs);
						if (paths != null) {
							//foreach (string path in paths)
							//	GLib.debug ("     target %s, referenced package: %s -> %s", target.id, package.id, path);
							completion.queue_sourcefiles (paths, null, true);
						} else {
							Utils.trace ("setup_completions: target %s, no vapi found for: %s", target.id, package.id);
						}
					}

					/* setup source files */
					foreach (Vbf.Source source in target.get_sources ()) {
						if (source.type == FileTypes.VALA_SOURCE) {
							Utils.trace ("setup_completions: source %s", source.filename);
							if (FileUtils.test (source.filename, FileTest.EXISTS | FileTest.IS_SYMLINK | FileTest.IS_REGULAR)) {
								completion.queue_sourcefile (source.filename);
							}
						}
					}
					
					/* rebind the completion engine to the open views */
					foreach (PluginInstance instance in Vtg.Plugin.main_instance.instances) {
						instance.bind_completion_engine_with_target (target, completion);
					}
					

				}
			}
		}

		private void cleanup_completions ()
		{
			if (_completions != null) {
				foreach (CompletionEngine completion in _completions.get_values ()) {
					completion.begin_parsing.disconnect (this.on_completion_engine_begin_parse);
					completion.end_parsing.disconnect (this.on_completion_engine_end_parse);
					completion.file_parsed.disconnect (this.on_completion_engine_file_parsed);
					foreach (PluginInstance instance in Vtg.Plugin.main_instance.instances) {
						instance.unbind_completion_engine (completion);
					}
				}
				_completions.clear ();
				_completions = null;
			}
		}

		private void on_completion_engine_begin_parse (CompletionEngine sender)
		{
			this.completion_begin_parsing (this, sender);

			if (AtomicInt.exchange_and_add (ref parser_thread_count, 1) == 0)
				if (_idle_id == 0)
					_idle_id = Idle.add (this.on_idle);
		}
		
		private void on_completion_engine_end_parse (CompletionEngine sender)
		{
			this.completion_end_parsing (this, sender);

			if (AtomicInt.dec_and_test (ref parser_thread_count))
				if (_idle_id == 0)
					_idle_id = Idle.add (this.on_idle);
		}

		private void on_completion_engine_file_parsed (CompletionEngine sender, string filename, ParseResult parse_result)
		{
			foreach (PluginInstance instance in Plugin.main_instance.instances) {
				var view = instance.project_manager_ui.project_builder.error_pane;
				view.clear_messages_for_source (filename);
				view.update_parse_result (filename, parse_result);
			}
		}

		private bool on_idle ()
		{
			int val = AtomicInt.get (ref parser_thread_count);
			if (val > 0) {
				if (!_sc_building) {
					_sc_building = true;
					this.symbol_cache_building (this);
				}
			} else {
				if (_sc_building) {
					_sc_building = false;
					this.symbol_cache_builded (this);
				}
			}
			_idle_id = 0;
			return false;
		}

		private void vcs_test (string filename)
		{
			//test if the project is under some known revision control system
			Vtg.Vcs.Backends.VcsBase backend = new Vtg.Vcs.Backends.Git ();
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
			cleanup_completions ();
			parse_project ();
			build_tree_model ();
			setup_completions ();
			this.updated ();
			in_update = false;
		}

		private void build_tree_model ()
		{
			TreeIter project_iter;
			TreeIter? modules_iter = null;
			TreeIter groups_iter;
			TreeIter? group_iter = null;
			var image = new Gtk.Image();

			_model = new Gtk.TreeStore (5, typeof(Gdk.Pixbuf), typeof(string), typeof(string), typeof(GLib.Object), typeof(string));
			_model.append (out project_iter, null);
			if (StringUtils.is_null_or_empty (_project.version)) {
				_model.set (project_iter, 0, Utils.icon_project, 1, "%s".printf (_project.name), 2, "project-root", 4, "");
			} else {
				_model.set (project_iter, 0, Utils.icon_project, 1, "%s - %s".printf (_project.name, _project.version), 2, "project-root", 4, "");
			}
			
			bool reference_added = false;
			
			foreach (Module module in _project.get_modules ()) {
				if (!reference_added) {
					_model.append (out modules_iter, project_iter);
					_model.set (modules_iter, 
						0, image.render_icon_pixbuf (Gtk.Stock.DIRECTORY, IconSize.MENU),
						1, _("References"), 2, "project-reference", 4, "1");
					reference_added = true;
				}
				TreeIter module_iter;
				_model.append (out module_iter, modules_iter);
				_model.set (module_iter, 
					0, Utils.icon_folder_packages, 
					1, module.name, 2, module.id, 3, module, 4, module.name);
				foreach (Package package in module.get_packages ()) {
					TreeIter package_iter;
					_model.append (out package_iter, module_iter);
					_model.set (package_iter, 0, Utils.icon_package, 1, package.name, 2, package.id, 3, package, 4, package.name);
				}
			}
			_model.append (out groups_iter, project_iter);
			_model.set (groups_iter, 0, image.render_icon_pixbuf (Gtk.Stock.DIRECTORY, IconSize.MENU), 1, _("Files"), 2, "project-files", 4, "2");
			foreach (Group group in _project.get_groups ()) {
				bool group_added = false;
				
				foreach (Target target in group.get_targets ()) {
					if (target.has_sources_of_type (FileTypes.VALA_SOURCE) || target.get_files ().size > 0) {
						TreeIter target_iter = groups_iter;
						TreeIter vapi_group_iter = target_iter;
						
						bool target_added = false;

						foreach (Vbf.Source source in target.get_sources ()) {
							if (source.name.has_prefix (".") ||
							    source.name.has_suffix (".c") ||
							    source.name.has_suffix (".h") ||
							    source.name.has_suffix (".stamp"))
								continue;

							if (!group_added) {
								_model.append (out group_iter, groups_iter);
								_model.set (group_iter, 0, image.render_icon_pixbuf (Gtk.Stock.DIRECTORY, IconSize.MENU), 1, group.name, 2, "group-targets", 3, group, 4, "2");
								group_added = true;
							}
							if (!target_added) {
								_model.append (out target_iter, group_iter);
								_model.set (target_iter, 
									0, Utils.get_small_icon_for_target_type (target.type), 
									1, target.name, 2, target.id, 3, target, 4, group.name);
								target_added = true;
							}
							TreeIter source_iter;
							_model.append (out source_iter, target_iter);
							_model.set (source_iter, 0, image.render_icon_pixbuf (Gtk.Stock.FILE, IconSize.MENU), 1, source.name, 2, source.uri, 3, source, 4, source.name);
						}
						foreach (Vbf.File file in target.get_files ()) {
							if (!group_added) {
								_model.append (out group_iter, groups_iter);
								_model.set (group_iter, 0, image.render_icon_pixbuf (Gtk.Stock.DIRECTORY, IconSize.MENU), 1, group.name, 2, "group-targets", 3, group, 4, "2");
								group_added = true;
							}
							if (!target_added) {
								_model.append (out target_iter, group_iter);
								_model.set (target_iter, 
									0, Utils.get_small_icon_for_target_type (target.type), 
									1, target.name, 2, target.id, 3, target, 4, group.name);
								target_added = true;
							}

							TreeIter file_iter;
							_model.append (out file_iter, target_iter);
							_model.set (file_iter, 0, image.render_icon_pixbuf (Gtk.Stock.FILE, IconSize.MENU), 1, file.name, 2, file.uri, 3, file, 4, file.name);
						}
						
						bool vapi_group_added = false;
						foreach (Vbf.Package package in target.get_packages ()) {
							if (!vapi_group_added) {
								_model.append (out vapi_group_iter, target_iter);
								_model.set (vapi_group_iter, 0, Utils.icon_folder_packages, 1, _("Referenced packages"), 2, "vapi-targets", 3, null, 4, "2");
								vapi_group_added = true;
							}
							
							TreeIter vapi_iter;
							_model.append (out vapi_iter, vapi_group_iter);
							_model.set (vapi_iter, 0, Utils.icon_package, 1, package.name, 2, package.uri, 3, package, 4, package.name);
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
					if (target.type == TargetTypes.PROGRAM ||
					    (target.type == TargetTypes.BUILT_SOURCES && !target.name.has_prefix ("lib")) ) {
						exec_targets.add (target);
					}
					foreach (Vbf.Source source in target.get_sources ()) {
						if (source.type == FileTypes.VALA_SOURCE) {
							all_vala_sources.add (source);
						}
					}
				}
			}
			
			try {
				if (FileUtils.test (Path.build_filename ( _project.working_dir, "changelog"), FileTest.EXISTS)) {
					changelog_uri = Filename.to_uri (Path.build_filename ( _project.working_dir, "changelog"));
				} else if (FileUtils.test (Path.build_filename ( _project.working_dir, "ChangeLog"), FileTest.EXISTS)) {
					changelog_uri = Filename.to_uri (Path.build_filename ( _project.working_dir, "ChangeLog"));
				}
			} catch (Error e) {
				GLib.warning ("error %s converting changelog file to uri", e.message);
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
