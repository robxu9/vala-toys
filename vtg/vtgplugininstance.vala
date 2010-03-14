/*
 *  vtgplugininstance.vala - Vala developer toys for GEdit
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
 *  MERCHANTABILITY or FITNaESS FOR A PARTICULAR PURPOSE.  See the
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
using Afrodite;
using Vbf;

namespace Vtg
{
	internal class PluginInstance : GLib.Object
	{
		private unowned Gedit.Window _window = null;
		private ProjectManagerUi _project_manager_ui = null;
		private SourceOutliner _source_outliner = null;
		private OutputView _output_view = null;
		private ProjectView _project_view = null;
		private SourceBookmarks _bookmarks = null;
		private Vala.List<Vtg.SymbolCompletion> _scs = new Vala.ArrayList<Vtg.SymbolCompletion> ();
		private Vala.List<Vtg.BracketCompletion> _bcs = new Vala.ArrayList<Vtg.BracketCompletion> ();
		
		private unowned Gedit.View _last_created_view = null; // workaround to a gedit scroll to cursor bug
		
		private ulong _tab_add_sig_id = 0;
		private ulong _tab_removed_sig_id = 0;
		
		public OutputView output_view 
		{ 
			get { return _output_view; }
		}
		
		public ProjectManagerUi project_manager_ui
		{ 
			get { return _project_manager_ui; }
		}

		public SourceOutliner source_outliner
		{
			get { return _source_outliner; }
		}

		public ProjectView project_view 
		{
			get {
				return _project_view;
			}
		}
		
		public Gedit.Window window
		{
			get { return _window; }
		}

		public SourceBookmarks bookmarks
		{
			get {
				return _bookmarks;
			}
		}
		
		public PluginInstance (Gedit.Window window)
		{
			this._window = window;
			_project_view = new ProjectView (this);
			
			foreach (ProjectManager prj in Vtg.Plugin.main_instance.projects.project_managers) {
				_project_view.add_project (prj.project);
			}
			
			_bookmarks = new SourceBookmarks (this);
			_bookmarks.current_bookmark_changed += this.on_current_bookmark_changed;
			_tab_add_sig_id = Signal.connect_after (this._window, "tab-added", (GLib.Callback) on_tab_added, this);
			_tab_removed_sig_id = Signal.connect (this._window, "tab-removed", (GLib.Callback) on_tab_removed, this);
			
			_output_view = new OutputView (this);
			_project_manager_ui = new ProjectManagerUi (this);
			//_prj_man.project_loaded += this.on_project_loaded;
			initialize_views ();
			foreach (Document doc in this._window.get_documents ()) {
				initialize_document (doc);
			}
		}

		~PluginInstance ()
		{
			if (_source_outliner != null)
				_source_outliner.active_view = null;
			_source_outliner = null;
			_project_manager_ui = null;
			_output_view = null;
			if (SignalHandler.is_connected (this, _tab_add_sig_id)) {
				SignalHandler.disconnect (this, _tab_add_sig_id);
				
			}
			if (SignalHandler.is_connected (this, _tab_removed_sig_id)) {
				SignalHandler.disconnect (this, _tab_removed_sig_id);
			}
			_window = null;
		}
		
		private void on_current_bookmark_changed (SourceBookmarks sender)
		{
			var book = sender.get_current_bookmark ();
			if (book != null) {
				activate_uri (book.uri, book.line, book.column);
			}
		}

		private static void check_vala_source_for_add (ProjectManager project_manager, Gedit.Document doc)
		{
			if (Utils.is_vala_doc (doc)) {
				// check if project contains this file, if not add it
				var group = project_manager.project.get_group("Sources");
				var target = group.get_target_for_id ("Default");
				var source = target.get_source (Utils.get_document_name (doc));
				if (source == null) {
					// add the source to the project
					target.add_source (new Vbf.Source.with_type (target, Utils.get_document_name (doc), FileTypes.VALA_SOURCE));
					project_manager.project.update ();
				}
			}
		}

		private static void check_vala_source_for_remove (ProjectManager project_manager, Gedit.Document doc)
		{
			// check if project contains this file, if not add it
			var group = project_manager.project.get_group("Sources");
			var target = group.get_target_for_id ("Default");
			var source = target.get_source (Utils.get_document_name (doc));
			if (source != null) {
				// add the source to the project
				target.remove_source (source);
				project_manager.project.update ();
			}	
		}
		
		private static void on_tab_added (Gedit.Window sender, Gedit.Tab tab, Vtg.PluginInstance instance)
		{
			var doc = tab.get_document ();
			var project_manager = Vtg.Plugin.main_instance.projects.get_project_manager_for_document (doc);

			if (project_manager != null && project_manager.project.id == "vtg-default-project") {
				check_vala_source_for_add (project_manager, doc);
			}
			
			if (doc.language != null && doc.language.id == "vala") {
				var view = tab.get_view ();
				instance.initialize_view (project_manager, view);
				if (instance.source_outliner != null) {
					GLib.debug ("setup outliner for %s", Utils.get_document_name (doc));
					instance.source_outliner.active_view = view;
				}

			}
			instance.initialize_document (doc);
		}

		private static void on_tab_removed (Gedit.Window sender, Gedit.Tab tab, Vtg.PluginInstance instance)
		{
			var view = tab.get_view ();
			var doc = tab.get_document ();

			instance.uninitialize_view (view);
			instance.uninitialize_document (doc);
			
			var project_manager = Vtg.Plugin.main_instance.projects.get_project_manager_for_document (doc);

			if (project_manager != null && project_manager.project.id == "vtg-default-project") {
				check_vala_source_for_remove (project_manager, doc);
			}
		}

		public void initialize_views ()
		{
			foreach (Gedit.View view in _window.get_views ()) {
				var doc = (Gedit.Document) (view.get_buffer ());
				if (doc.language != null && doc.language.id == "vala") {
					var project = Vtg.Plugin.main_instance.projects.get_project_manager_for_document (doc);
					initialize_view (project, view);
				}
			}
			if (Vtg.Plugin.main_instance.config.sourcecode_outliner_enabled && _source_outliner == null) {
				activate_sourcecode_outliner ();
			}			
		}

		public void initialize_view (ProjectManager project, Gedit.View view)
		{
			if (Vtg.Plugin.main_instance.config.symbol_enabled && !scs_contains (view)) {
				activate_symbol (project, view);
			}

			if (Vtg.Plugin.main_instance.config.bracket_enabled && !bcs_contains (view)) {
				activate_bracket (view);
			}
		}

		public void initialize_document (Gedit.Document doc)
		{
			Signal.connect (doc, "notify::language", (GLib.Callback) on_notify_language, this);
		}

		public void uninitialize_view (Gedit.View view)
		{
			var sc = scs_find_from_view (view);
			if (sc != null) {
				deactivate_symbol (sc);
			}

			var bc = bcs_find_from_view (view);
			if (bc != null) {
				deactivate_bracket (bc);
			}
		}
		
		public void activate_sourcecode_outliner ()
		{
			_source_outliner = new SourceOutliner (this);
			
		}
		
		public void deactivate_sourcecode_outliner ()
		{
			if (_source_outliner != null) {
				_source_outliner = null;
			}
		}

		public void activate_bracket (Gedit.View view)
		{
			var bc = new BracketCompletion (this, view);
			_bcs.add (bc);
		}
		
		public void deactivate_bracket (BracketCompletion bc)
		{
			bc.deactivate ();
			_bcs.remove (bc);
		}
		
		public void activate_symbol (ProjectManager project, Gedit.View view)
		{
			var doc = (Gedit.Document) view.get_buffer ();
			return_if_fail (doc != null);

			var uri = doc.get_uri ();
			if (uri == null)
				return;

			var completion = project.get_completion_for_file (uri);
			if (completion == null) {
				GLib.warning ("No completion for file %s", uri);
				return;
			}
			var sc = new Vtg.SymbolCompletion (this, view, completion);
			_scs.add (sc);
		}

 		public void deactivate_symbol (SymbolCompletion sc)
		{
			sc.deactivate ();
			_scs.remove (sc);
		}

		public void deactivate_symbols ()
		{
			int size = 0;
			while (_scs.size > 0 && _scs.size != size) {
				size = _scs.size;
				deactivate_symbol (_scs.get(0));					
			} 
		}

		public void deactivate_brackets ()		
		{
			int size = 0;
			while (_bcs.size > 0 && _bcs.size != size) {
				size = _bcs.size;
				deactivate_bracket (_bcs.get(0));
			}
		}
		
		public bool bcs_contains (Gedit.View view)
		{
			return (bcs_find_from_view (view) != null);
		}

		public BracketCompletion? bcs_find_from_view (Gedit.View view)
		{
			foreach (BracketCompletion bc in _bcs) {
				if (bc.view == view)
					return bc;
			}

			return null;
		}
		
		public bool scs_contains (Gedit.View view)
		{
			return (scs_find_from_view (view) != null);
		}

		public Vtg.SymbolCompletion? scs_find_from_view (Gedit.View view)
		{
			foreach (Vtg.SymbolCompletion sc in _scs) {
				if (sc.view == view)
					return sc;
			}
			return null;
		}

		public void uninitialize_document (Gedit.Document doc)
		{
			SignalHandler.disconnect_by_func (doc, (void*) on_notify_language, this);
		}

		public Gedit.Tab activate_uri (string uri, int line = 0, int col = 0)
		{
			Gedit.Tab tab = null;
			Document existing_doc = null;
			foreach (Document doc in _window.get_documents ()) {
				if (doc.get_uri () == uri) {
					tab = Tab.get_from_document (doc);
					existing_doc = doc;
					break;
				}
			}
			
			if (tab == null) {
				tab = _window.create_tab_from_uri (uri, Encoding.get_utf8 (), line, true, false);
				_window.set_active_tab (tab);
				_last_created_view = tab.get_view();
				Idle.add (this.on_idle_cursor_mode, Priority.DEFAULT_IDLE);
			} else {
				_window.set_active_tab (tab);
				if (existing_doc != null && line > 0) {
					if (!existing_doc.goto_line_offset (line - 1, col -1)) {
						existing_doc.goto_line (line-1);
					}
					
					tab.get_view ().scroll_to_cursor ();
				}
			}
			return tab;		
		}

		public bool on_idle_cursor_mode ()
		{
			if (_last_created_view != null)  {
				_last_created_view.scroll_to_cursor ();
				_last_created_view = null;
			}
			return false;
		}

		public void activate_display_name (string display_name, int line = 0, int col = 0)
		{
			foreach (Document doc in _window.get_documents ()) {
				if (doc.get_short_name_for_display () == display_name) {
					var tab = Tab.get_from_document (doc);
					_window.set_active_tab (tab);
					doc.goto_line (line - 1);
					tab.get_view ().scroll_to_cursor ();
				}
			}
		}

		private static void on_notify_language (Gedit.Document sender, ParamSpec pspec, Vtg.PluginInstance instance)
		{
			//search the view
			var app = App.get_default ();
			foreach (Gedit.View view in app.get_views ()) {
				if (view.get_buffer () == sender) {
					var project_manager = Vtg.Plugin.main_instance.projects.get_project_manager_for_document (sender);
					if (sender.language  == null || sender.language.id != "vala") {
						if (project_manager != null && project_manager.project.id == "vtg-default-project") {
							check_vala_source_for_remove (project_manager, sender);
						}
						instance.uninitialize_view (view);
					} else {
						if (project_manager != null && project_manager.project.id == "vtg-default-project") {
							check_vala_source_for_add (project_manager, sender);
						}
						instance.initialize_view (project_manager, view);
					}
					break;
				}
			}
		}
		
		public void unbind_completion_engine (Afrodite.CompletionEngine engine)
		{
			foreach (SymbolCompletion sc in _scs) {
				if (sc.completion_engine == engine) {
					sc.completion_engine = null;
				}
			}
			if (_source_outliner != null) {
				_source_outliner.cleanup_completion_engine (engine);
			}
		}
		
		public void bind_completion_engine_with_target (Vbf.Target target, Afrodite.CompletionEngine engine)
		{
			foreach (SymbolCompletion sc in _scs) {
				var doc = (Gedit.Document) sc.view.get_buffer ();
				
				if (Vtg.Plugin.main_instance.projects.get_target_for_document (doc) == target) {
					sc.completion_engine = engine;
				}
			}
			
			if (_source_outliner != null) {
				var view = _source_outliner.active_view;
				if (view != null) {
					var doc = (Gedit.Document) view.get_buffer ();
					
					if (Vtg.Plugin.main_instance.projects.get_target_for_document (doc) == target) {
						_source_outliner.setup_completion_engine (engine);
					}
				}
			}
		}
	}
}
