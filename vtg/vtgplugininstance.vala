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
using Afrodite;
using Vbf;

namespace Vtg
{
	internal class PluginInstance : GLib.Object
	{
		public unowned Plugin plugin;
		
		private unowned Gedit.Window _window = null;
		private ProjectManagerUi _project_manager_ui = null;
		private SourceOutliner _source_outliner = null;
		private OutputView _output_view = null;
		private Vala.List<Vtg.SymbolCompletionHelper> _scs = new Vala.ArrayList<Vtg.SymbolCompletionHelper> ();
		private Vala.List<Vtg.BracketCompletion> _bcs = new Vala.ArrayList<Vtg.BracketCompletion> ();
		
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
	
		public Gedit.Window window
		{
			get { return _window; }
		}

		public PluginInstance (Plugin plugin, Gedit.Window window)
		{
			this.plugin = plugin;
			this._window = window;
			Signal.connect_after (this._window, "tab-added", (GLib.Callback) on_tab_added, this);
			Signal.connect_after (this._window, "tab-removed", (GLib.Callback) on_tab_removed, this);
			
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
			_window = null;
		}
		
		private static void on_tab_added (Gedit.Window sender, Gedit.Tab tab, Vtg.PluginInstance instance)
		{
			var doc = tab.get_document ();
			var project = instance.plugin.project_descriptor_find_from_document (doc);

			if (doc.language != null && doc.language.id == "vala") {
				var view = tab.get_view ();
				instance.initialize_view (project, view);
			}
			instance.initialize_document (doc);
		}

		private static void on_tab_removed (Gedit.Window sender, Gedit.Tab tab, Vtg.PluginInstance instance)
		{
			var view = tab.get_view ();
			var doc = tab.get_document ();

			instance.uninitialize_view (view);
			instance.uninitialize_document (doc);
		}

		public void initialize_views ()
		{
			foreach (Gedit.View view in _window.get_views ()) {
				var doc = (Gedit.Document) (view.get_buffer ());
				if (doc.language != null && doc.language.id == "vala") {
					var project = plugin.project_descriptor_find_from_document (doc);
					initialize_view (project, view);
				}
			}
			
			if (plugin.config.sourcecode_outliner_enabled && _source_outliner == null) {
				activate_sourcecode_outliner ();
			}

		}

		public void initialize_view (ProjectDescriptor project, Gedit.View view)
		{
			if (plugin.config.symbol_enabled && !scs_contains (view)) {
				activate_symbol (project, view);
			}

			if (plugin.config.bracket_enabled && !bcs_contains (view)) {
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
			_source_outliner = null;
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
		
		public void activate_symbol (ProjectDescriptor project, Gedit.View view)
		{
			var doc = (Gedit.Document) view.get_buffer ();
			return_if_fail (doc != null);

			var uri = doc.get_uri ();
			if (uri == null)
				return;

			var completion = project.project.get_completion_for_file (uri);
			if (completion == null) {
				GLib.warning ("No completion for file %s", uri);
				return;
			}
			var sc = new Vtg.SymbolCompletionHelper (this, view, completion);
			_scs.add (sc);
		}

 		public void deactivate_symbol (SymbolCompletionHelper sc)
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

		public Vtg.SymbolCompletionHelper? scs_find_from_view (Gedit.View view)
		{
			foreach (Vtg.SymbolCompletionHelper sc in _scs) {
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
			
			if (tab == null)
				tab = _window.create_tab_from_uri (uri, Encoding.get_utf8 (), line, true, true);
			else {
				_window.set_active_tab (tab);
				if (existing_doc != null && line > 0) {
					existing_doc.goto_line (line - 1);
					tab.get_view ().scroll_to_cursor ();
				}
			}
			return tab;		
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
					if (sender.language  == null || sender.language.id != "vala") {
						instance.uninitialize_view (view);
					} else {
						var project = instance.plugin.project_descriptor_find_from_document (sender);
						instance.initialize_view (project, view);
					}
					break;
				}
			}
		}
	}
}
