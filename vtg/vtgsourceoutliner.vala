/*
 *  vtgsourceoutliner.vala - Vala developer toys for GEdit
 *  
 *  Copyright (C) 2009 - Andrea Del Signore <sejerpz@tin.it>
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

namespace Vtg
{
	internal class SourceOutliner : GLib.Object
	{
		private unowned PluginInstance _plugin_instance = null;
 		private Gedit.View _active_view = null; // it's not unowned because we need to cleanup later
 		private Gedit.Document _active_doc = null; // it's not unowned because we need to cleanup later
		private SourceOutlinerView _outliner_view = null;
		private uint idle_id = 0;
		private bool completion_setup = false;
 
	 	public PluginInstance plugin_instance { get { return _plugin_instance; } construct { _plugin_instance = value; } }

		public View active_view {
			get {
				return _active_view;
			}
			set {
				if (_active_view != value) {
					if (_active_view != null) {
						cleanup_document ();
						if (completion_setup)
							cleanup_completion_with_view (_active_view);
					}
					_active_view = value;
					if (_active_view != null) {
						var doc = (Document) _active_view.get_buffer ();
						setup_document (doc);
						if (Utils.is_vala_doc (doc)) {
							update_source_outliner_view ();
							setup_completion_with_view (_active_view);
						}
					}
				}
			}
		}
		
		public SourceOutliner (PluginInstance plugin_instance)
		{
			GLib.Object (plugin_instance: plugin_instance);
			_outliner_view = new SourceOutlinerView (plugin_instance);
			_outliner_view.goto_source += this.on_goto_source;
		}

		~SourceOutliner ()
		{
			if (_outliner_view != null) {
				_outliner_view.goto_source -= this.on_goto_source;
				_outliner_view.clear_view ();
				_outliner_view.deactivate ();
				_outliner_view = null;
			}
			if (idle_id != 0) {
				GLib.Source.remove (idle_id);
			}
			if (_active_view != null)
			{
				cleanup_document ();
				if (completion_setup)
					cleanup_completion_with_view (_active_view);
				_active_view = null;
			}
		}

		private void on_goto_source (SourceOutlinerView sender, int line, int start_column, int end_column)		
		{
			Gedit.Document doc = (Gedit.Document) _active_view.get_buffer ();
			TextIter? iter;
			doc.get_iter_at_line_offset (out iter, line - 1, 0);
			if (iter != null) {
				doc.place_cursor (iter);
				_active_view.scroll_to_iter (iter, 0, true, 0, 0.5);
				_active_view.grab_focus ();
			}
		}

		private void setup_document (Gedit.Document doc)
		{
			_active_doc = doc;
			doc.notify["language"] += this.on_notify_language;
		}
	
		public void cleanup_document ()
		{
			if (_active_doc != null) {
				_active_doc.notify["language"] -= this.on_notify_language;
				_active_doc = null;
			}
		}
		
		private void setup_completion_with_view (View view)
		{
			var scs = _plugin_instance.scs_find_from_view (view);
 			if (scs == null || scs.completion_engine == null) {
 				//GLib.warning ("setup_completion: symbol completion helper is null for view");
				return;
			}
			setup_completion_engine (scs.completion_engine);
		}

		public void setup_completion_engine (Afrodite.CompletionEngine engine)
		{
			completion_setup = true;
			engine.end_parsing += this.on_end_parsing;			
		}

		private void cleanup_completion_with_view (View view)
		{
			var scs = _plugin_instance.scs_find_from_view (view);
 			if (scs == null || scs.completion_engine == null) {
 				//GLib.warning ("cleanup_completion: symbol completion helper is null for view");
				return;
			}
			cleanup_completion_engine (scs.completion_engine);
		}

		public void cleanup_completion_engine (Afrodite.CompletionEngine engine)
		{
			engine.end_parsing -= this.on_end_parsing;
			completion_setup = false;
		}
		
		private void on_notify_language (Gedit.Document sender, ParamSpec pspec)
		{
			if (Utils.is_vala_doc (sender)) {
				update_source_outliner_view ();
				setup_completion_with_view (_active_view);
			}
		}
		
		// this method is called from another thread context
		// for this reason the update is done in the idle handler
		private void on_end_parsing (Afrodite.CompletionEngine sender)
		{
			setup_idle ();
		}
		
		private void setup_idle ()
		{
			if (idle_id == 0) {
				idle_id =  Idle.add (this.on_idle_update, Priority.DEFAULT_IDLE);
			}
		}
		
		private bool on_idle_update ()
		{
			bool res = !update_source_outliner_view ();
			if (!res)
				idle_id = 0;
			return res;
		}
		
		private bool update_source_outliner_view ()
		{
			var scs = _plugin_instance.scs_find_from_view (_active_view);
 			if (scs == null || scs.completion_engine == null) {
 				//GLib.warning ("update_source_ouliner_view: symbol completion helper is null for view");
				return true;
			}
			
			var doc = (Gedit.Document) _active_view.get_buffer ();
			var name = Utils.get_document_name (doc);
			Afrodite.QueryResult result = null;
			Afrodite.Ast ast;
			bool res = scs.completion_engine.try_acquire_ast (out ast);
			if (res) {
				var options = Afrodite.QueryOptions.standard ();
				options.all_symbols = true;
				result = ast.get_symbols_for_path (options, name);
				_outliner_view.update_view (result);
				scs.completion_engine.release_ast (ast);
			}			
			if (result == null || result.is_empty) {
				_outliner_view.clear_view ();
			}
			
			return res;
		}
	}
}
