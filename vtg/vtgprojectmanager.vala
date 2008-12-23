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

namespace Vtg.ProjectManager
{
	public class PluginHelper : GLib.Object
	{
		/* UI Code */
		private string _ui_def = """<ui>
                                            <menubar name="MenuBar">
                                                <menu name="FileMenu" action="File">
                                                    <placeholder name="FileOps_2">
                                                        <separator />
                                                        <menuitem name="ProjectNew" action="ProjectNew"/>
                                                        <menuitem name="ProjectOpen" action="ProjectOpen"/>
                                                        <separator />
                                                        <menuitem name="ProjectClose" action="ProjectClose"/>
                                                        <separator />
                                                    </placeholder>
                                                </menu>
                                            </menubar>

                                            <menubar name="MenuBar">
                                              <menu name="EditMenu" action="Edit">
                                                 <placeholder name="EditOps_3">
                                                     <separator />
                                                     <menuitem name="ProjectCompleteWord" action="ProjectCompleteWord"/>
                                                 </placeholder>
                                              </menu>
                                            </menubar>

                                            <menubar name="MenuBar">
                                              <placeholder name="ExtraMenu_1">
                                                <menu name="BuildMenu" action="ProjectBuildMenuAction">
                                                    <placeholder name="BuildMenuOps_1">
                                                        <menuitem name="ProjectBuild" action="ProjectBuild"/>
                                                        <menuitem name="ProjectBuildClean" action="ProjectBuildClean"/>
                                                        <separator />
                                                        <menuitem name="ProjectBuildCleanStamps" action="ProjectBuildCleanStamps"/>
                                                        <separator />
                                                        <menuitem name="ProjectBuildConfigure" action="ProjectBuildConfigure"/>
                                                        <separator />
                                                        <menuitem name="ProjectBuildCompileFile" action="ProjectBuildCompileFile"/>
                                                    </placeholder>
                                                    <placeholder name="BuildMenuOps_2">
                                                        <separator />
                                                        <menuitem name="NextError" action="ProjectBuildNextError"/>
                                                        <menuitem name="PreviousError" action="ProjectBuildPreviousError"/>
                                                    </placeholder>
                                                    <placeholder name="BuildMenuOps_3">
                                                        <separator />
                                                        <menuitem name="Execute" action="ProjectBuildExecute"/>
                                                        <menuitem name="KillProcess" action="ProjectBuildKill"/>
                                                    </placeholder>
                                                </menu>
                                              </placeholder>                                              
                                            </menubar>
                                            
                                            <menubar name="MenuBar">
                                                <menu name="DocumentsMenu" action="Documents">
                                                    <placeholder name="DocumentsOps_3">
                                                        <menuitem name="GotoDocument" action="ProjectGotoDocument"/>
                                                        <separator />
                                                    </placeholder>
                                                </menu>
                                            </menubar>

                                             <menubar name="MenuBar">
                                                <menu name="SearchMenu" action="Search">
                                                    <placeholder name="SearchOps_8">
                                                    	<separator />
                                                        <menuitem name="GotoMethod" action="ProjectGotoMethod"/>

                                                    </placeholder>
                                                </menu>
                                            </menubar>
                                            
                                        </ui>""";
		private uint _ui_id;

		const ActionEntry[] _action_entries = {
			{"ProjectNew", null, N_("_New Project..."), null, N_("Create a new project"), on_project_new},
			{"ProjectOpen", null, N_("Op_en Project..."), "<control><alt>O", N_("Open an existing project"), on_project_open},
			{"ProjectClose", null, N_("_Close Current Project"), null, N_("Close current selected project"), on_project_close},
			{"ProjectBuildMenuAction", null, N_("Build"), null, N_("Build menu"), null},
			{"ProjectBuild", Gtk.STOCK_EXECUTE, N_("_Build Project"), "<control><shift>B", N_("Build the current project using 'make'"), on_project_build},
			{"ProjectBuildClean", Gtk.STOCK_CLEAR, N_("_Clean Project"), null, N_("Clean the current project using 'make clean'"), on_project_clean},
			{"ProjectBuildCleanStamps", null, N_("_Clean Project and Vala 'Stamp' Files"), null, N_("Clean the current project stamp files"), on_project_clean_stamps},
			{"ProjectBuildConfigure", null, N_("C_onfigure Project"), null, N_("Configure or reconfigure the current project"), on_project_configure},
			{"ProjectBuildCompileFile", null, N_("_Compile File"), "<control>B", N_("Compile the current file with the vala compiler"), on_standalone_file_compile},			
			{"ProjectBuildNextError", Gtk.STOCK_GO_FORWARD, N_("_Next Error"), "<control><shift>F12", N_("Go to next error source line"), on_project_error_next},
			{"ProjectBuildPreviousError", Gtk.STOCK_GO_BACK, N_("_Previuos Error"), null, N_("Go to previous error source line"), on_project_error_previuos},
			{"ProjectBuildExecute", Gtk.STOCK_EXECUTE, N_("_Execute"), "F5", N_("Excute target program"), on_project_execute_process},
			{"ProjectBuildKill", Gtk.STOCK_STOP, N_("_Stop process"), null, N_("Stop (kill) executing program"), on_project_kill_process},
			{"ProjectGotoDocument", Gtk.STOCK_JUMP_TO, N_("_Go To Document..."), "<control>J", N_("Open a document that belong to this project"), on_project_goto_document},
			{"ProjectGotoMethod", null, N_("_Go To Method..."), "<control>M", N_("Goto to a specific method in the current source document"), on_project_goto_method},
			{"ProjectCompleteWord", null, N_("Complete _Word"), "<control>space", N_("Try to complete the word in the current source document"), on_complete_word}
		};


		/* END UI */
		private Gee.List<Project> _projects = new Gee.ArrayList<Project> ();
		private ActionGroup _actions = null;
		private Vtg.Plugin _plugin;
		private ProjectManager.View _prj_view = null;
		private ProjectManager.Builder _prj_builder = null;
		private ProjectManager.Executer _prj_executer = null;

 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		//public signal void project_loaded (Project project);

		public PluginHelper (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}


		~PluginHelper ()
		{
			var manager = _plugin.gedit_window.get_ui_manager ();
			manager.remove_ui (_ui_id);
			manager.remove_action_group (_actions);
		}

		construct	
		{
			_prj_view = new ProjectManager.View (_plugin);
			_prj_view.notify["current-project"] += this.on_current_project_changed;
			_prj_builder = new ProjectManager.Builder (_plugin);
			_prj_executer = new ProjectManager.Executer (_plugin);
			
			_prj_executer.process_start += (sender) => {
				update_ui (_prj_view.current_project == null);
			};
			_prj_executer.process_exit += (sender, exit_status) => {
				update_ui (_prj_view.current_project == null);
			};
			_prj_builder.build_start += (sender) => {
				update_ui (_prj_view.current_project == null);
			};
			_prj_builder.build_exit += (sender, exit_status) => {
				update_ui (_prj_view.current_project == null);
			};
						
			initialize_ui ();
			update_ui (_prj_view.current_project == null);
		}

		public ProjectManager.View project_view 
		{
			get {
				return _prj_view;
			}
		}
		
		private void initialize_ui ()
		{
			_actions = new ActionGroup ("ProjectManagerActionGroup");
			_actions.set_translation_domain (Config.GETTEXT_PACKAGE);
			_actions.add_actions (_action_entries, this);
			var manager = plugin.gedit_window.get_ui_manager ();
			manager.insert_action_group (_actions, -1);
			try {
				_ui_id = manager.add_ui_from_string (_ui_def, -1);
			} catch (Error err) {
				GLib.warning ("Error %s", err.message);
			}
		}

		public void deactivate ()
		{
			GLib.debug ("prjm deactvate");			
			GLib.debug ("prjm deactvated");
		}


		private void on_complete_word (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			var project = _prj_view.current_project;
			return_if_fail (project != null);
			
			var view = _plugin.gedit_window.get_active_view ();
			if (view == null)
				return;
						
			var sch = _plugin.scs_find_from_view (view);
			if (sch == null)
				return;
				
			sch.trigger.complete_word ();			
		}
		
		private void on_project_open (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			var dialog = new Gtk.FileChooserDialog (_("Open Project"),
				      _plugin.gedit_window,
				      Gtk.FileChooserAction.SELECT_FOLDER,
				      Gtk.STOCK_CANCEL, ResponseType.CANCEL,
				      Gtk.STOCK_OPEN, ResponseType.ACCEPT,
				      null);

			if (dialog.run () == ResponseType.ACCEPT) {
				dialog.hide_all ();
				var foldername = dialog.get_filename ();
				open_project (foldername);				
			}
			dialog.destroy ();
		}

		private void on_project_close (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			var project = _prj_view.current_project;
			return_if_fail (project != null);

			bool save_required = false;
			foreach (Gedit.Document doc in _plugin.gedit_window.get_unsaved_documents ()) {
				if (project.contains_source_file (doc.get_uri ())) {
					save_required = true;
				}
			}
			
			//there are some files that require saving: ask it!
			if (save_required) {
				var dialog = new Gtk.MessageDialog (_plugin.gedit_window,
                                  DialogFlags.DESTROY_WITH_PARENT,
                                  MessageType.QUESTION,
                                  ButtonsType.NONE,
				    _("Project files need to be saved"));
				dialog.add_buttons (Gtk.STOCK_CLOSE, ResponseType.CLOSE,
				    Gtk.STOCK_CANCEL, ResponseType.CANCEL,
				    Gtk.STOCK_SAVE, ResponseType.ACCEPT);
				var response = dialog.run ();
				dialog.destroy ();
				if (response == ResponseType.CANCEL) {
					return;
				} else if (response == ResponseType.ACCEPT) {
					project_save_all (project);
				}
			}

			//close project
			close_project (project);
		}
			    
		private void on_project_new (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			//save dialog
			var dialog = new Gtk.FileChooserDialog (_("Save Project"),
				      _plugin.gedit_window,
				      Gtk.FileChooserAction.SELECT_FOLDER,
				      Gtk.STOCK_CANCEL, ResponseType.CANCEL,
				      Gtk.STOCK_SAVE, ResponseType.ACCEPT,
				      null);
			string foldername = null;

			if (dialog.run () == ResponseType.ACCEPT) {
				foldername = dialog.get_filename ();
			}
			dialog.destroy ();
			//HACK: need to going to async code in create_project
			while (MainContext.@default ().pending ()) {
				MainContext.@default ().iteration (false);
			}

			if (foldername != null) {
				create_project (foldername);
				open_project (foldername);
			}
		}
		
		private void on_project_goto_document (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			var project = _prj_view.current_project;
			return_if_fail (project != null);
			
			TreeIter iter;
			Gtk.ListStore model = new Gtk.ListStore (2, typeof(string), typeof (GLib.Object));
			foreach (ProjectSource src in project.all_vala_sources) {
				model.append (out iter);
				model.set (iter, 0, src.name, 1, src);
			}
						
			var dialog = new FilteredListDialog (model);
			if (dialog.run ()) {
				ProjectSource src;
				model.get (dialog.selected_iter , 1, out src);
				_plugin.activate_uri (src.uri);
			}
		}

		private void on_project_goto_method (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			
			var project = _prj_view.current_project;
			return_if_fail (project != null);
			
			var pdes = get_projectdescriptor_for_project (project);
			return_if_fail (pdes != null);
			
			var view = _plugin.gedit_window.get_active_view ();
			if (view == null)
				return;
				
			var doc = (Gedit.Document) view.get_buffer ();
			return_if_fail (doc != null);

			var uri = doc.get_uri ();
			if (uri == null)
				return;
				
			var methods = pdes.completion.get_methods_for_source (uri);
			if (methods.size <= 0)
				return;
				
			TreeIter iter;
			Gtk.ListStore model = new Gtk.ListStore (2, typeof(string), typeof (Vsc.SymbolCompletionItem));
			foreach (Vsc.SymbolCompletionItem method in methods) {
				model.append (out iter);
				model.set (iter, 0, method.name, 1, method);
			}
			
			var dialog = new FilteredListDialog (model);
			if (dialog.run ()) {
				Vsc.SymbolCompletionItem method;
				model.get (dialog.selected_iter , 1, out method);
				doc.goto_line (method.line - 1);
				view.scroll_to_cursor ();
			}
		}


		private ProjectDescriptor? get_projectdescriptor_for_project (Project project)
		{
			foreach (ProjectDescriptor current in _plugin.projects) {
				if (current.project == project)
					return current;
			}
			
			return null;
		}

		private void on_standalone_file_compile (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			var doc = _plugin.gedit_window.get_active_document ();
			if (doc != null) {
				string file = doc.get_uri ();
				var project = _prj_view.current_project;
				if (project != null) {
					if (project.contains_source_file (file)) {
						//TODO: we should get the group an issue a make in that subfolder
						GLib.warning ("Can't compile a project file (for now)");
						return;
					}
				}
				file = file.replace ("file://", ""); //HACK
				GLib.debug ("compiling file %s", file);
				if (!doc.is_untouched () && _plugin.config.save_before_build)
					doc.save (Gedit.DocumentSaveFlags.IGNORE_MTIME);
						
				_prj_builder.compile_file (file);
			}
		}
		
		private void on_project_build (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			if (_prj_view.current_project != null) {
				var cache = Vtg.Caches.get_build_cache ();
				var params_dialog = new Vtg.Interaction.ParametersDialog (_("Build Project"), _plugin.gedit_window, cache);
				if (params_dialog.run () == ResponseType.OK) {
					var project = _prj_view.current_project;
					var params = params_dialog.parameters;
					if (!StringUtils.is_null_or_empty (params) && !Vtg.Caches.cache_contains (cache, params)) {
						Vtg.Caches.cache_append (cache, params);
					}
					project_save_all (project);
					_prj_builder.build (project, params);
				}
			}
		}

		private void on_project_configure (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			if (_prj_view.current_project != null) {
				var cache = Vtg.Caches.get_configure_cache ();
				var params_dialog = new Vtg.Interaction.ParametersDialog (_("Configure Project"), _plugin.gedit_window, cache);
				if (params_dialog.run () == ResponseType.OK) {
					var project = _prj_view.current_project;
					var params = params_dialog.parameters;
					if (!StringUtils.is_null_or_empty (params) && !Vtg.Caches.cache_contains (cache, params)) {
						Vtg.Caches.cache_append (cache, params);
					}
					project_save_all (project);
					_prj_builder.configure (project, params);
				}
			}
		}

		private void on_project_clean (Gtk.Action action)
		{
			clean_project ();
		}

		private void on_project_clean_stamps (Gtk.Action action)
		{
			clean_project (true);
		}

		private void on_project_execute_process (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			if (_prj_view.current_project != null) {
				var project = _prj_view.current_project;
				GLib.debug ("executing project %s", project.name);
				_prj_executer.execute (project);
			}
		}

		private void on_project_kill_process (Gtk.Action action)
		{
			GLib.debug ("killing last executed process");
			//TODO: implement a kill (project);
			_prj_executer.kill_last ();
		}

		private void clean_project (bool stamps = false)
		{
			if (_prj_view.current_project != null) {
				var project = _prj_view.current_project;
				_prj_builder.clean (project, stamps);
			}
		}

		private void on_project_error_next (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			_prj_builder.next_error ();
		}

		private void on_project_error_previuos (Gtk.Action action)
		{
			GLib.debug ("Action %s activated", action.name);
			_prj_builder.previous_error ();
		}

		private void on_current_project_changed (GLib.Object sender, ParamSpec pspec)
		{
			ProjectManager.View view = (ProjectManager.View) sender;
			update_ui (view.current_project == null);
		}
		
		private void update_ui (bool default_project)
		{
			var action = _actions.get_action ("ProjectClose");
			action.set_sensitive (!default_project);
			action = _actions.get_action ("ProjectBuild");
			action.set_sensitive (!default_project);
			action = _actions.get_action ("ProjectBuildClean");
			action.set_sensitive (!default_project);
			action = _actions.get_action ("ProjectBuildCleanStamps");
			action.set_sensitive (!default_project);
			
			var doc = _plugin.gedit_window.get_active_document ();
			bool is_vala_source = (doc != null && doc.language != null && doc.language.id == "vala");
			action = _actions.get_action ("ProjectBuildCompileFile");
			action.set_sensitive (default_project && is_vala_source);
			action = _actions.get_action ("ProjectGotoMethod");
			action.set_sensitive (is_vala_source);
			
			action = _actions.get_action ("ProjectGotoDocument");
			action.set_sensitive (!default_project);
			
			bool has_errors = _prj_builder.error_pane.error_count > 0;
			action = _actions.get_action ("ProjectBuildNextError");
			action.set_sensitive (has_errors);
			action = _actions.get_action ("ProjectBuildPreviousError");
			action.set_sensitive (has_errors);
			
			action = _actions.get_action ("ProjectBuildExecute");
			action.set_sensitive (!_prj_executer.is_executing && !default_project);
			action = _actions.get_action ("ProjectBuildKill");
			action.set_sensitive (_prj_executer.is_executing && !default_project);
			
			bool can_complete = false;
			var view = _plugin.gedit_window.get_active_view ();
			if (view != null) {
				var sch = _plugin.scs_find_from_view (view);
				can_complete = (sch != null);
			}
			action = _actions.get_action ("ProjectCompleteWord");
			action.set_sensitive (can_complete);
		}
		
		private void open_project (string name)
		{
			try {
				var project = new Project ();
				if (project.open (name)) {
					_projects.add (project);
					//HACK: why the signal isn't working?!?!
					//this.project_loaded (project);
					_plugin.on_project_loaded (this, project);
					_prj_view.add_project (project);
				}
			} catch (Error err) {
				Vtg.Interaction.error_message (_("Error opening project %s").printf (name), err);
			}
		}

		private void close_project (Project project)
		{
			foreach (Gedit.Document doc in _plugin.gedit_window.get_documents ()) {
				if (project.contains_source_file (doc.get_uri ())) {
					//close tab
					var tab = Tab.get_from_document (doc);
					_plugin.gedit_window.close_tab (tab);
				}
			}
			_prj_view.remove_project (project);
			_plugin.on_project_closed (this, project);
			project.close ();
			_projects.remove (project);
		}

		private void project_save_all (Project project)
		{
			foreach (Gedit.Document doc in _plugin.gedit_window.get_unsaved_documents ()) {
				if (project.contains_source_file (doc.get_uri ())) {
					doc.save (DocumentSaveFlags.IGNORE_MTIME);
				}
			}
		}

		private void create_project (string project_path)
		{
			try {
				var log = _plugin.output_view;
				if (!is_dir_empty (project_path)) {
					log.log_message ("project directory %s not empty\n".printf (project_path));
					return;
				}
				string process_file = "vala-gen-project";
				int status = 0;
				int stdo, stde;
				Pid child_pid;

				//vala-gen-project
				if (Process.spawn_sync (project_path, new string[] { process_file, "--projectdir", project_path }, null, 
					SpawnFlags.SEARCH_PATH,
					null, null, null, out status)) {
					if (Process.exit_status (status) == 0) {
						//autogen
						var start_message = _("Autogenerating project: %s\n").printf (project_path);
						log.log_message (start_message);
						log.log_message ("%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
						Process.spawn_async_with_pipes (project_path, new string[] { "./autogen.sh" }, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, null, out stdo, out stde);
						if (child_pid != (Pid) null) {
							ChildWatch.add (child_pid, this.on_child_watch);
							log.start_watch ((uint) child_pid, stdo, stde);
							log.activate ();
						} else {
							log.log_message ("error spawning ./autogen.sh process\n");
						}
					} else {
						log.log_message ("error executing vala-gen-project process\n");
					}
				} else {
					log.log_message ("error spawning vala-gen-project process\n");
				}
			} catch (Error err) {
				GLib.warning ("error creating project: %s", err.message);
			}
		}

		private bool is_dir_empty (string dir_path)
		{
			try {
				var dir = Dir.open (dir_path);
				return dir.read_name () == null;
			} catch (Error err) {
				GLib.warning ("cannot open directort %s", dir_path);
				return false;
			}
		}

		private void on_child_watch (Pid pid, int status)
		{
			var log = _plugin.output_view;

			Process.close_pid (pid);

			log.stop_watch ((uint) pid);
			log.log_message (_("\nautogeneration end with exit status %d\n").printf(status));
		}
	}
}
