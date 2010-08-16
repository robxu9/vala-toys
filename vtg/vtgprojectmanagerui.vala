/*
 *  vtgprojectmanagerui.vala - Vala developer toys for GEdit
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
	internal class ProjectManagerUi : GLib.Object
	{
		/* UI Code */
		private string _ui_def = """<ui>
                                            <menubar name="MenuBar">
                                                <menu name="FileMenu" action="File">
                                                    <placeholder name="FileOps_2">
                                                        <separator />
                                                        <menuitem name="ProjectNew" action="ProjectNew"/>
                                                        <menuitem name="ProjectOpen" action="ProjectOpen"/>
                                                        <menuitem name="ProjectRecent" action="ProjectRecent"/>
                                                        <separator />
                                                        <menuitem name="ProjectClose" action="ProjectClose"/>
                                                        <separator />
                                                        <menuitem name="ProjectChange" action="ProjectChange"/>
                                                        <separator />
                                                    </placeholder>
                                                    <placeholder name="FileOps_3">
                                                    	<menuitem name="ProjectSaveAll" action="ProjectSaveAll"/>
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
                                                        <menuitem name="ProjectBuildConfigure" action="ProjectBuildConfigure"/>
                                                        <separator />
                                                        <menuitem name="ProjectBuildCompileFile" action="ProjectBuildCompileFile"/>
                                                        <separator />
                                                        <menuitem name="ProjectBuildStopCompilation" action="ProjectBuildStopCompilation"/>
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
                                                        <menuitem name="GotoNextPosition" action="ProjectGotoNextPosition"/>
                                                        <menuitem name="GotoPrevPosition" action="ProjectGotoPrevPosition"/>
                                                        <separator />
                                                    </placeholder>
                                                </menu>
                                            </menubar>

                                             <menubar name="MenuBar">
                                                <menu name="SearchMenu" action="Search">
                                                    <placeholder name="SearchOps_1">
                                                    	<separator />                                                    
                                                        <menuitem name="ProjectSearch" action="ProjectSearch"/>
							<menuitem name="ProjectSearchPrevReult" action="ProjectSearchPrevResult"/>
							<menuitem name="ProjectSearchNextResult" action="ProjectSearchNextResult"/>
                                                    </placeholder>
                                                    <placeholder name="SearchOps_8">
                                                    	<separator />
                                                        <menuitem name="GotoSymbol" action="ProjectGotoSymbol"/>
                                                    	<separator />
                                                        <menuitem name="GotoDefinition" action="ProjectGotoDefinition"/>
                                                    </placeholder>
                                                </menu>
                                            </menubar>
                                            
                                            <menubar name="MenuBar">
                                            	 <menu name="ToolsMenu" action="Tools">
						 	<placeholder name="ToolsOps_1"> 
						 		<separator />
							 	<menuitem name="PrepareSingleFileChangeLog" action="ProjectPrepareSingleFileChangeLog"/>
							 	<menuitem name="PrepareChangeLog" action="ProjectPrepareChangeLog"/>
						 		<separator />							 	
                                                	</placeholder>
                                                 </menu>
                                            </menubar>
                                        </ui>""";
		private uint _ui_id;

		const ActionEntry[] _action_entries = {
			{"ProjectNew", null, N_("_New Project..."), null, N_("Create a new project"), on_project_new},
			{"ProjectOpen", null, N_("Op_en Project..."), "<control><alt>O", N_("Open an existing project"), on_project_open},
			{"ProjectSaveAll", null, N_("Save All"), null, N_("Save all project files"), on_project_save_all},			
			{"ProjectClose", null, N_("_Close Current Project"), null, N_("Close current selected project"), on_project_close},
			{"ProjectChange", null, N_("_Change Current Project"), null, N_("Change current selected project"), on_project_change},
			{"ProjectBuildMenuAction", null, N_("Build"), null, N_("Build menu"), null},
			{"ProjectBuild", Gtk.STOCK_EXECUTE, N_("_Build Project"), "<control><shift>B", N_("Build the current project"), on_project_build},
			{"ProjectBuildClean", Gtk.STOCK_CLEAR, N_("_Clean Project"), null, N_("Clean the current project"), on_project_clean},
			{"ProjectBuildConfigure", null, N_("C_onfigure Project"), null, N_("Configure or reconfigure the current project"), on_project_configure},
			{"ProjectBuildCompileFile", null, N_("_Compile File"), "<control>B", N_("Compile the current file with the vala compiler"), on_standalone_file_compile},
			{"ProjectBuildStopCompilation", Gtk.STOCK_STOP, N_("_Stop Compilation"), "<control>B", N_("Stop the running compilation"), on_stop_compilation},
			{"ProjectBuildNextError", Gtk.STOCK_GO_FORWARD, N_("_Next Error"), "<control><shift>F12", N_("Go to next error source line"), on_project_error_next},
			{"ProjectBuildPreviousError", Gtk.STOCK_GO_BACK, N_("_Previuos Error"), null, N_("Go to previous error source line"), on_project_error_previuos},
			{"ProjectBuildExecute", Gtk.STOCK_EXECUTE, N_("_Execute"), "F5", N_("Excute target program"), on_project_execute_process},
			{"ProjectBuildKill", Gtk.STOCK_STOP, N_("_Stop process"), null, N_("Stop (kill) executing program"), on_project_kill_process},
			{"ProjectSearch", Gtk.STOCK_FIND, N_("Find In _Project..."), "<control><shift>F", N_("Search for text in all the project files"), on_project_search},
			{"ProjectSearchNextResult", null, N_("Find N_ext In Project"), null, N_("Search forward for the same text in all the project files"), on_project_search_result_next},
			{"ProjectSearchPrevResult", null, N_("Find Previ_ous In Project"), null, N_("Search backward for the same text in all the project files"), on_project_search_result_previous},
			{"ProjectGotoDocument", Gtk.STOCK_JUMP_TO, N_("_Go To Document..."), "<control>J", N_("Open a document that belong to this project"), on_project_goto_document},
			{"ProjectGotoNextPosition", Gtk.STOCK_GO_FORWARD, N_("_Go To Next Source Position"), null, N_("Go to the next source position"), on_project_goto_next_position},
			{"ProjectGotoPrevPosition", Gtk.STOCK_GO_BACK, N_("_Go To Previous Source Position"), "<alt>Left", N_("Go to the previous or last saved source position"), on_project_goto_prev_position},
			{"ProjectGotoSymbol", null, N_("_Go To Symbol..."), "<control>M", N_("Goto to a specific symbol in the current source document"), on_project_goto_symbol},
			{"ProjectGotoDefinition", null, N_("_Go To Definition"), "F12", N_("Goto to a current symbol definition"), on_project_goto_definition},
			{"ProjectCompleteWord", null, N_("Complete _Word"), "<control>space", N_("Try to complete the word in the current source document"), on_complete_word},
			{"ProjectPrepareChangeLog", null, N_("_Prepare ChangeLog"), null, N_("Add an entry to the ChangeLog with all added/modified files"), on_prepare_changelog},
			{"ProjectPrepareSingleFileChangeLog", null, N_("_Add Current File To ChangeLog"), null, N_("Add the current file to the ChangeLog"), on_prepare_single_file_changelog}
		};


		/* END UI */
		private Vala.List<ProjectManager> _projects = new Vala.ArrayList<ProjectManager> ();
		private ActionGroup _actions = null;
		private unowned Vtg.PluginInstance _plugin_instance = null;
		private ProjectBuilder _prj_builder = null;
		private ProjectExecuter _prj_executer = null;
		private ProjectSearch _prj_search = null;		
		private ChangeLog _changelog = null;
		
		
		private int _cache_building_count = 0;
		private uint _sb_msg_id = 0;
		private uint _sb_context_id = 0;

 		public Vtg.PluginInstance plugin_instance { get { return _plugin_instance; } construct { _plugin_instance = value; } }

		//public signal void project_loaded (Project project);

		public ProjectManagerUi (Vtg.PluginInstance plugin_instance)
		{
			GLib.Object (plugin_instance: plugin_instance);
			var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
			_sb_context_id = status_bar.get_context_id ("symbol status");
		}


		~ProjectManagerUi ()
		{
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.remove_ui (_ui_id);
			manager.remove_action_group (_actions);
		}

		construct	
		{
			_plugin_instance.project_view.notify["current-project"] += this.on_current_project_changed;
			_prj_builder = new ProjectBuilder (_plugin_instance);
			_prj_executer = new ProjectExecuter (_plugin_instance);
			_prj_search = new ProjectSearch (_plugin_instance);
						
			_prj_executer.process_start.connect ((sender) => {
				var prj = _plugin_instance.project_view.current_project;
				update_ui (prj);
			});
			_prj_executer.process_exit.connect ((sender, exit_status) => {
				var prj = _plugin_instance.project_view.current_project;
				update_ui (prj);
			});
			_prj_builder.build_start.connect ((sender) => {
				var prj = _plugin_instance.project_view.current_project;
				update_ui (prj);
			});
			_prj_builder.build_exit.connect ((sender, exit_status) => {
				var prj = _plugin_instance.project_view.current_project;
				update_ui (prj);
			});
			_prj_search.search_start.connect ((sender) => {
				var prj = _plugin_instance.project_view.current_project;
				update_ui (prj);
			});
			_prj_search.search_exit.connect ((sender, exit_status) => {
				var prj = _plugin_instance.project_view.current_project;
				update_ui (prj);
			});
						
			initialize_ui ();
			_changelog = new ChangeLog (_plugin_instance);
			var prj = _plugin_instance.project_view.current_project;
			update_ui (prj);
		}

		private void initialize_ui ()
		{
			_actions = new ActionGroup ("ProjectManagerActionGroup");
			_actions.set_translation_domain (Config.GETTEXT_PACKAGE);
			_actions.add_actions (_action_entries, this);
			var recent_action = new Gtk.RecentAction ("ProjectRecent", "Open Recent Project", "", "");
			recent_action.set_show_private (true);
			var recent_filter = new Gtk.RecentFilter ();
			recent_filter.add_application ("vtg");
			recent_action.add_filter (recent_filter);
			recent_action.item_activated.connect (on_project_open_recent);
			
			_actions.add_action (recent_action);
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.insert_action_group (_actions, -1);
			try {
				_ui_id = manager.add_ui_from_string (_ui_def, -1);
			} catch (Error err) {
				GLib.warning ("Error %s", err.message);
			}
		}

		private void on_project_open_recent (RecentChooser sender)
		{
			try {
				string project_name = Filename.from_uri (sender.get_current_uri ()).replace ("/configure.ac", ""); //HACK
				open_project (project_name);
			} catch (Error e) {
				GLib.warning ("error %s converting project name file from uri", e.message);
			}
		}
		
		private void on_prepare_changelog (Gtk.Action action)
		{
			try {
				_changelog.prepare ();
			} catch (Error err) {
				Vtg.Interaction.error_message (_("Can't prepare the ChangeLog entry"), err);
			}
		}

		private void on_prepare_single_file_changelog (Gtk.Action action)
		{
			try {
				var doc = _plugin_instance.window.get_active_document ();
				if (doc != null) {
					var prj = _plugin_instance.project_view.current_project;
					string uri = doc.get_uri ();
					string file = doc.get_short_name_for_display ();
					if (prj != null) {
						var src = prj.get_source_file_from_uri (uri);
						if (src != null) {
							file = src.name;
						}
					}
					_changelog.prepare (file);
				}
			} catch (Error err) {
				Vtg.Interaction.error_message (_("Can't prepare the ChangeLog entry"), err);
			}
		}
		
		private void on_complete_word (Gtk.Action action)
		{
			var project = _plugin_instance.project_view.current_project;
			return_if_fail (project != null);
			
			var view = _plugin_instance.window.get_active_view ();
			if (view == null)
				return;
						
			var sch = _plugin_instance.scs_find_from_view (view);
			if (sch == null)
				return;
				
			sch.complete_word ();			
		}

		private void on_project_goto_definition (Gtk.Action action)
		{
			var project = _plugin_instance.project_view.current_project;
			return_if_fail (project != null);
			
			var view = _plugin_instance.window.get_active_view ();
			if (view == null)
				return;
						
			var sch = _plugin_instance.scs_find_from_view (view);
			if (sch == null)
				return;
				
			sch.goto_definition ();
		}
		
		private void on_project_open (Gtk.Action action)
		{
			var dialog = new Gtk.FileChooserDialog (_("Open Project"),
				      _plugin_instance.window,
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

		private void on_project_save_all (Gtk.Action action)
		{
			var project = _plugin_instance.project_view.current_project;
			Vtg.Plugin.main_instance.project_save_all (project);
		}
		
		private void on_project_close (Gtk.Action action)
		{
			var project = _plugin_instance.project_view.current_project;
			return_if_fail (project != null);

			//there are some files that require saving: ask it!
			if (Vtg.Plugin.main_instance.project_need_save (project)) {
				var dialog = new Gtk.MessageDialog (_plugin_instance.window,
                                  DialogFlags.DESTROY_WITH_PARENT,
                                  Gtk.MessageType.QUESTION,
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
					Vtg.Plugin.main_instance.project_save_all (project);
				}
			}

			//close project
			close_project (project);
		}

		private void on_project_change (Gtk.Action action)
		{
			var image = new Gtk.Image();
			TreeIter iter;
			Gtk.TreeStore model = FilteredListDialog.create_model ();
			
			foreach (ProjectManager prj in Vtg.Plugin.main_instance.projects.project_managers) {
				model.append (out iter, null);
				model.set (iter, 
					FilteredListDialogColumns.NAME, prj.project.name, 
					FilteredListDialogColumns.MARKUP, prj.project.name, 
					FilteredListDialogColumns.VISIBILITY, true, 
					FilteredListDialogColumns.OBJECT, prj,
					FilteredListDialogColumns.ICON, 
						image.render_icon (Gtk.STOCK_FILE, IconSize.BUTTON, ""),
					FilteredListDialogColumns.SELECTABLE, true);
			}
			
			var dialog = new FilteredListDialog (model);
			dialog.set_transient_for (_plugin_instance.window);
			if (dialog.run ()) {
				ProjectManager prj;
				model.get (dialog.selected_iter , FilteredListDialogColumns.OBJECT, out prj);
				if (prj != null) {
					_plugin_instance.project_view.current_project = prj;
				}
			}
		}
		
		private void on_project_new (Gtk.Action action)
		{
			//save dialog
			var dialog = new Gtk.FileChooserDialog (_("Save Project"),
				      _plugin_instance.window,
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

		private void on_project_search_result_next (Gtk.Action action)
		{
			_prj_search.next_match ();
		}
		
		private void on_project_search_result_previous (Gtk.Action action)
		{
			_prj_search.previous_match ();
		}

		private void on_project_search (Gtk.Action action)
		{
			if (_plugin_instance.project_view.current_project != null) {
				string proposed_text = "";
				var view = _plugin_instance.window.get_active_view ();
				if (view != null) {
					var doc = (Gtk.TextBuffer) view.get_buffer ();
					TextIter start, end;
					doc.get_selection_bounds (out start, out end);
					proposed_text = start.get_text (end);
				}
				var project = _plugin_instance.project_view.current_project;
				var exec_dialog = new ProjectSearchDialog (_plugin_instance.window, proposed_text);
				if (exec_dialog.run () == ResponseType.OK) {
					_prj_search.search (project, exec_dialog.search_text, exec_dialog.match_case);
				}
			}
		}
		
		private void on_project_goto_next_position (Gtk.Action action)
		{
			_plugin_instance.bookmarks.move_next ();
		}
		
		private void on_project_goto_prev_position (Gtk.Action action)
		{
			_plugin_instance.bookmarks.move_previous ();
		}
		
		private void on_project_goto_document (Gtk.Action action)
		{
			var project = _plugin_instance.project_view.current_project.project;
			return_if_fail (project != null);
			var image = new Gtk.Image();
			
			TreeIter iter;
			Gtk.TreeStore model = FilteredListDialog.create_model ();
			foreach (Vbf.Group group in project.get_groups ()) {
				foreach (Vbf.Target target in group.get_targets ()) {
					if (target.has_sources_of_type (FileTypes.VALA_SOURCE)) {
						TreeIter target_iter;
						model.append (out target_iter, null);
						model.set (target_iter, 
							FilteredListDialogColumns.NAME, target.name, 
							FilteredListDialogColumns.MARKUP, target.name, 
							FilteredListDialogColumns.VISIBILITY, true, 
							FilteredListDialogColumns.OBJECT, target,
							FilteredListDialogColumns.ICON, 
								image.render_icon (Utils.get_stock_id_for_target_type (target.type), IconSize.BUTTON, ""),
							FilteredListDialogColumns.SELECTABLE, false);
						foreach (Vbf.Source src in target.get_sources ()) {
							model.append (out iter, target_iter);
							model.set (iter, 
								FilteredListDialogColumns.NAME, src.name, 
								FilteredListDialogColumns.MARKUP, src.name, 
								FilteredListDialogColumns.VISIBILITY, true, 
								FilteredListDialogColumns.OBJECT, src,
								FilteredListDialogColumns.ICON, image.render_icon (Gtk.STOCK_FILE, IconSize.BUTTON, ""),
								FilteredListDialogColumns.SELECTABLE, true);
						}
					}
				}
			}						
			var dialog = new FilteredListDialog (model);
			dialog.set_transient_for (_plugin_instance.window);
			if (dialog.run ()) {
				Vbf.Source src;
				model.get (dialog.selected_iter , 3, out src);
				_plugin_instance.activate_uri (src.uri);
			}
		}

		private void build_goto_symbol_model (TreeStore model, Afrodite.ResultItem parent, TreeIter? parent_iter = null)
		{
			if (parent.children.size == 0)
				return;
			
			foreach (Afrodite.ResultItem item in parent.children) {
				TreeIter iter;
				
				model.append (out iter, parent_iter);
				model.set (iter, 
					FilteredListDialogColumns.NAME , item.symbol.display_name, 
					FilteredListDialogColumns.MARKUP, item.symbol.display_name,
					FilteredListDialogColumns.VISIBILITY, true, 
					FilteredListDialogColumns.OBJECT, item.symbol,
					FilteredListDialogColumns.ICON, Utils.get_icon_for_type_name (item.symbol.type_name),
					FilteredListDialogColumns.SELECTABLE, true);

				if (item.children.size > 0) {
					build_goto_symbol_model (model, item, iter);
				}
			}
		}

		private int sort_symbol_model (TreeModel model, TreeIter a, TreeIter b)
		{
			Afrodite.Symbol vala;
			Afrodite.Symbol valb;
			
			model.get (a, FilteredListDialogColumns.OBJECT, out vala);
			model.get (b, FilteredListDialogColumns.OBJECT, out valb);
			
			return Utils.symbol_type_compare (vala, valb);

		}
		
		private void on_project_goto_symbol (Gtk.Action action)
		{
			var project = _plugin_instance.project_view.current_project;
			return_if_fail (project != null);
			
			var view = _plugin_instance.window.get_active_view ();
			if (view == null)
				return;

			var scs = _plugin_instance.scs_find_from_view (view);
 			if (scs == null) {
 				GLib.warning ("on_project_goto_method: symbol completion helper is null for view");
				return;
			}
				
			var doc = (Gedit.Document) view.get_buffer ();
			return_if_fail (doc != null);

			var uri = doc.get_uri ();
			if (uri == null)
				return;

			try {
				uri = Filename.from_uri (uri);
				Gtk.TreeStore model = null;
				
				/* getting the symbols */
				var name = Utils.get_document_name (doc);
				Afrodite.QueryResult result = null;
				Afrodite.Ast ast;
				bool res = scs.completion_engine.try_acquire_ast (out ast, 1000);
				if (res) {
					var options = Afrodite.QueryOptions.standard ();
					options.all_symbols = true;
					result = ast.get_symbols_for_path (options, name);
					
					/* building the model */
					model = FilteredListDialog.create_model ();
					if (!result.is_empty) {
						var first = result.children.get (0);
						build_goto_symbol_model (model, first);
					}					
					scs.completion_engine.release_ast (ast);
				}
				if (result == null || result.is_empty)
					return;
			
			
				var dialog = new FilteredListDialog (model, this.sort_symbol_model);
				dialog.set_transient_for (_plugin_instance.window);
				if (dialog.run ()) {
					Afrodite.Symbol symbol;
					model.get (dialog.selected_iter , FilteredListDialogColumns.OBJECT, out symbol);
					Afrodite.SourceReference sr;
					if (symbol.has_source_references) {
						sr = symbol.source_references.get (0);
					
						doc.goto_line (sr.first_line - 1);
						view.scroll_to_cursor ();
					}
				}
			} catch (Error e) {
				GLib.warning ("error %s converting file %s to uri", e.message, uri);
			}
		}

/*
		private ProjectDescriptor? get_projectdescriptor_for_project (ProjectManager project)
		{
			foreach (ProjectDescriptor current in _plugin_instance.plugin.projects) {
				if (current.project == project)
					return current;
			}
			
			return null;
		}
*/

		private void on_standalone_file_compile (Gtk.Action action)
		{
			var doc = _plugin_instance.window.get_active_document ();
			if (doc != null) {
				string file = doc.get_uri ();
				var project = _plugin_instance.project_view.current_project;

				if (project != null && !project.is_default) {
					if (project.contains_vala_source_file (file)) {
						//TODO: we should get the group an issue a make in that subfolder
						GLib.warning ("Can't compile a project file (for now)");
						return;
					}
				}
				var cache = Vtg.Caches.get_compile_cache ();
				var params_dialog = new Vtg.Interaction.ParametersDialog (_("Compile File"), _plugin_instance.window, cache);
				if (params_dialog.run () == ResponseType.OK) {
					var params = params_dialog.parameters;
					if (!Vtg.Caches.cache_contains (cache, params)) {
						Vtg.Caches.cache_add (cache, params);
					}
					try {
						file = Filename.from_uri (file);
						if (!doc.is_untouched () && Vtg.Plugin.main_instance.config.save_before_build)
							Gedit.commands_save_document (_plugin_instance.window, doc);
						
						_prj_builder.compile_file (file, params);
					} catch (Error e) {
						GLib.warning ("error %s converting file %s from uri", e.message, file);
					}
				}
			}
		}
		
		private void on_stop_compilation (Gtk.Action action)
		{
			if (_prj_builder.is_building) {
				_prj_builder.stop_build ();
			}
		}
		
		private void on_project_build (Gtk.Action action)
		{
			if (_plugin_instance.project_view.current_project != null) {
				string pars = null;
				var cache = Vtg.Caches.get_build_cache ();
								
				if (_prj_builder.is_building) {
					//ask if stop the current build process and restart a new one
					var dialog = new MessageDialog (
						_plugin_instance.window,
						DialogFlags.MODAL,
						Gtk.MessageType.QUESTION,
						ButtonsType.YES_NO,
						_("Stop the current build process and restart a new one?"));
					dialog.secondary_text = _("Stop the current build process and start a new one with the same command line parameters");
					int res = dialog.run ();
					dialog.destroy ();
					if (res == ResponseType.YES) {
						_prj_builder.stop_build ();
						TreeIter iter;
						if (cache.get_iter_first (out iter)) {
							cache.get (iter, 0, out pars);
						}
					} else {
						return;
					}
				}

				if (pars == null) {
					var params_dialog = new Vtg.Interaction.ParametersDialog (_("Build Project"), _plugin_instance.window, cache);
					if (params_dialog.run () != ResponseType.OK)
						return;
						
					pars = params_dialog.parameters;
					Vtg.Caches.cache_remove (cache, pars);
					Vtg.Caches.cache_add (cache, pars);
				}
				
				var project = _plugin_instance.project_view.current_project;
				Vtg.Plugin.main_instance.project_save_all (project);
				_prj_builder.build (project, pars);
			}
		}

		private void on_project_configure (Gtk.Action action)
		{
			if (_plugin_instance.project_view.current_project != null) {
				var cache = Vtg.Caches.get_configure_cache ();
				var params_dialog = new Vtg.Interaction.ParametersDialog (_("Configure Project"), _plugin_instance.window, cache);
				if (params_dialog.run () == ResponseType.OK) {
					var project = _plugin_instance.project_view.current_project;
					var params = params_dialog.parameters;
					Vtg.Caches.cache_remove (cache, params);
					Vtg.Caches.cache_add (cache, params);
					Vtg.Plugin.main_instance.project_save_all (project);
					_prj_builder.configure (project, params);
				}
			}
		}

		private void on_project_clean (Gtk.Action action)
		{
			clean_project ();
		}

		private void on_project_execute_process (Gtk.Action action)
		{
			if (_plugin_instance.project_view.current_project != null) {
				var project = _plugin_instance.project_view.current_project;
				var exec_dialog = new ProjectExecuterDialog (_plugin_instance.window, project);
				if (exec_dialog.run () == ResponseType.OK) {
					var command_line = exec_dialog.command_line;
					_prj_executer.execute (project.project, command_line);
				}
				
			}
		}

		private void on_project_kill_process (Gtk.Action action)
		{
			//TODO: implement a kill (project);
			_prj_executer.kill_last ();
		}

		private void clean_project ()
		{
			if (_plugin_instance.project_view.current_project != null) {
				var project = _plugin_instance.project_view.current_project;
				_prj_builder.clean (project, true);
			}
		}

		private void on_project_error_next (Gtk.Action action)
		{
			_prj_builder.next_error ();
		}

		private void on_project_error_previuos (Gtk.Action action)
		{
			_prj_builder.previous_error ();
			
		}

		private void on_current_project_changed (GLib.Object sender, ParamSpec pspec)
		{
			ProjectView view = (ProjectView) sender;
			var prj = view.current_project;
			update_ui (prj);
		}
		
		private void update_ui (ProjectManager? pm)
		{
			bool default_project = pm == null || pm.is_default;
			bool can_build = pm != null && pm.project.build_command != null;
			bool can_clean = pm != null && pm.project.clean_command != null;
			bool can_configure = pm != null && pm.project.configure_command != null;
			
			var action = _actions.get_action ("ProjectClose");
			if (action != null)
				action.set_sensitive (!default_project);
			
			action = _actions.get_action ("ProjectChange");
			if (action != null)
				action.set_sensitive (Vtg.Plugin.main_instance.projects.project_managers.size > 1);

			action = _actions.get_action ("ProjectBuild");
			if (action != null)
				action.set_sensitive (!default_project && can_build);

			action = _actions.get_action ("ProjectBuildClean");
			if (action != null)
				action.set_sensitive (!default_project && !_prj_builder.is_building && can_clean);

			action = _actions.get_action ("ProjectBuildStopCompilation");
			if (action != null)
				action.set_sensitive (_prj_builder.is_building);
				
			var doc = _plugin_instance.window.get_active_document ();
			bool is_vala_source = (doc != null && doc.language != null && doc.language.id == "vala");
			action = _actions.get_action ("ProjectBuildCompileFile");
			if (action != null)
				action.set_sensitive (default_project && is_vala_source);
			action = _actions.get_action ("ProjectGotoMethod");
			if (action != null)
				action.set_sensitive (is_vala_source);
			
			action = _actions.get_action ("ProjectGotoDocument");
			if (action != null)
				action.set_sensitive (!default_project);

			action = _actions.get_action ("ProjectBuildConfigure");
			if (action != null)
				action.set_sensitive (!default_project && !_prj_builder.is_building && can_configure);
			
			bool has_errors = (_prj_builder.error_pane.error_count + _prj_builder.error_pane.warning_count) > 0;
			action = _actions.get_action ("ProjectBuildNextError");
			if (action != null)
				action.set_sensitive (has_errors);
			action = _actions.get_action ("ProjectBuildPreviousError");
			if (action != null)
				action.set_sensitive (has_errors);
			
			action = _actions.get_action ("ProjectBuildExecute");
			if (action != null)
				action.set_sensitive (!_prj_executer.is_executing && !default_project && !_prj_builder.is_building);
			action = _actions.get_action ("ProjectBuildKill");
			if (action != null)
				action.set_sensitive (_prj_executer.is_executing && !default_project);

			action = _actions.get_action ("ProjectSearch");
			if (action != null)
				action.set_sensitive (!_prj_search.is_searching);
			
			bool can_complete = false;
			var view = _plugin_instance.window.get_active_view ();
			if (view != null) {
				var sch = _plugin_instance.scs_find_from_view (view);
				can_complete = (sch != null);
			}
			action = _actions.get_action ("ProjectCompleteWord");
			if (action != null)
				action.set_sensitive (can_complete);
			
			bool has_changelog = false;
			bool has_vcs_backend = false;
			if (_plugin_instance.project_view.current_project != null 
			    && _plugin_instance.project_view.current_project.changelog_uri != null) {
				has_changelog = true;
				if (_plugin_instance.project_view.current_project.vcs_type != VcsTypes.NONE)
					has_vcs_backend = true;
			}
			action = _actions.get_action ("ProjectPrepareChangeLog");
			if (action != null)
				action.set_sensitive (has_changelog && has_vcs_backend);
			action = _actions.get_action ("ProjectPrepareSingleFileChangeLog");
			if (action != null)
				action.set_sensitive (has_changelog);
			action = _actions.get_action ("ProjectGotoNextPosition");
			if (action != null)
				action.set_sensitive (!_plugin_instance.bookmarks.is_empty);
			action = _actions.get_action ("ProjectGotoPrevPosition");
			if (action != null)
				action.set_sensitive (!_plugin_instance.bookmarks.is_empty);
		}
		
		private void on_symbol_cache_building (ProjectManager sender)
		{
			_cache_building_count++;
			if (_sb_msg_id == 0) {
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				_sb_msg_id = status_bar.push (_sb_context_id, _("building symbol cache..."));
			}
		}
		
		private void on_symbol_cache_builded (ProjectManager sender)
		{
			_cache_building_count--;
			if (_cache_building_count <= 0 && _sb_msg_id != 0) {
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				status_bar.remove (_sb_context_id, _sb_msg_id);
				_sb_msg_id = 0;
			}
		}
		
		private void open_project (string name)
		{
			try {
				var project = find_project_for_id (name);
				
				if (project != null) {
					// activate project
					_plugin_instance.project_view.current_project = project;
				} else {
					// open project
					project = new ProjectManager (Vtg.Plugin.main_instance.config.symbol_enabled);
					project.symbol_cache_building.connect (this.on_symbol_cache_building);
					project.symbol_cache_builded.connect (this.on_symbol_cache_builded);
					
					if (project.open (name)) {
						_projects.add (project);
						//HACK: why the signal isn't working?!?!
						//this.project_loaded (project);
						Vtg.Plugin.main_instance.on_project_loaded (this, project);
						_plugin_instance.project_view.add_project (project.project);
					}
				}
			} catch (Error err) {
				Vtg.Interaction.error_message (_("Error opening project %s").printf (name), err);
			}
		}

		internal void close_project (ProjectManager project)
		{
			project.symbol_cache_building.disconnect (this.on_symbol_cache_building);
			project.symbol_cache_builded.disconnect (this.on_symbol_cache_builded);
			_plugin_instance.project_view.remove_project (project.project);
			Vtg.Plugin.main_instance.on_project_closed (this, project);
			project.close ();
			_projects.remove (project);
		}

		private void create_project (string project_path)
		{
			try {
				var log = _plugin_instance.output_view;
				if (!is_dir_empty (project_path)) {
					log.log_message (OutputTypes.MESSAGE, "project directory %s not empty\n".printf (project_path));
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
						log.log_message (OutputTypes.MESSAGE, start_message);
						log.log_message (OutputTypes.MESSAGE, "%s\n\n".printf (string.nfill (start_message.length - 1, '-')));
						Process.spawn_async_with_pipes (project_path, new string[] { "./autogen.sh" }, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out child_pid, null, out stdo, out stde);
						if (child_pid != (Pid) null) {
							ChildWatch.add (child_pid, this.on_child_watch);
							log.start_watch (OutputTypes.CHILD_PROCESS, (uint) child_pid, stdo, stde);
							log.activate ();
						} else {
							log.log_message (OutputTypes.ERROR, "error spawning ./autogen.sh process\n");
						}
					} else {
						log.log_message (OutputTypes.ERROR, "error executing vala-gen-project process\n");
					}
				} else {
					log.log_message (OutputTypes.ERROR, "error spawning vala-gen-project process\n");
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
			var log = _plugin_instance.output_view;

			Process.close_pid (pid);

			log.stop_watch ((uint) pid);
			log.log_message (OutputTypes.MESSAGE, _("\nautogeneration end with exit status %d\n").printf(status));
		}
		
		public ProjectManager? find_project_for_id (string id)
		{
			foreach (ProjectManager project_manager in _projects) {
				if (project_manager.project.id == id) {
					return project_manager;
				}
			}
			
			return null;
		}
	}
}
