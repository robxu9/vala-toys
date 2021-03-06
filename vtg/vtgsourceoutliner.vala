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
		private bool completion_setup = false;

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

						_outliner_view.clear_view ();
					}
					_active_view = value;
					_outliner_view.active_view = _active_view;
					if (_active_view != null) {
						var doc = (Document) _active_view.get_buffer ();
						setup_document (doc);
						if (Utils.is_vala_doc (doc)) {
							setup_completion_with_view (_active_view);
							update_source_outliner_view ();
						}
					}
				}
			}
		}
		
		public SourceOutliner (PluginInstance plugin_instance)
		{
			this._plugin_instance = plugin_instance;
			_outliner_view = new SourceOutlinerView (plugin_instance);
			_outliner_view.goto_source.connect (this.on_goto_source);
			_outliner_view.filter_changed.connect (this.on_filter_changed);
		}

		~SourceOutliner ()
		{
			if (_outliner_view != null) {
				_outliner_view.goto_source.disconnect (this.on_goto_source);
				_outliner_view.clear_view ();
				_outliner_view.deactivate ();
				_outliner_view = null;
			}
			if (_active_view != null)
			{
				cleanup_document ();
				if (completion_setup)
					cleanup_completion_with_view (_active_view);
				_active_view = null;
			}
			_active_doc = null;
		}

		private void on_filter_changed (SourceOutlinerView sender)
		{
			update_source_outliner_view ();
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
			doc.notify["language"].connect (this.on_notify_language);
			doc.notify["cursor-position"].connect (this.on_notify_cursor_position);
		}

		public void cleanup_document ()
		{
			if (_active_doc != null) {
				_active_doc.notify["language"].disconnect (this.on_notify_language);
				_active_doc.notify["cursor-position"].disconnect (this.on_notify_cursor_position);
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
			engine.file_parsed.connect (this.on_file_parsed);
			engine.file_removed.connect (this.on_file_removed);
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
			engine.file_parsed.disconnect (this.on_file_parsed);
			engine.file_removed.disconnect (this.on_file_removed);
			completion_setup = false;
		}
		
		private void on_notify_language (GLib.Object sender, ParamSpec pspec)
		{
			var doc = (Gedit.Document)sender;
			if (Utils.is_vala_doc (doc)) {
				update_source_outliner_view ();
				setup_completion_with_view (_active_view);
			}
		}

		private void on_notify_cursor_position (GLib.Object sender, ParamSpec pspec)
		{
			var doc = (Gedit.Document)sender;
			update_cursor_position (doc);
		}

		private void update_cursor_position (Gedit.Document doc)
		{
			if (Utils.is_vala_doc (doc)) {
				// get current line
				unowned TextMark mark = (TextMark) doc.get_insert ();
				TextIter start;
				doc.get_iter_at_mark (out start, mark);
				var line = start.get_line ();
				var column = start.get_line_index ();
				_outliner_view.set_current_position (line, column);
			}
		}

		private void on_file_removed (Afrodite.CompletionEngine sender, string filename)
		{
			var doc = (Gedit.Document) _active_view.get_buffer ();
			var name = Utils.get_document_name (doc);
			Utils.trace ("File removed: %s - current file: %s", filename, name);
			if (filename == name) {
				_outliner_view.clear_view ();
			}
		}

		private void on_file_parsed (Afrodite.CompletionEngine sender, string filename, Afrodite.ParseResult parse_result)
		{
			var doc = (Gedit.Document) _active_view.get_buffer ();
			var name = Utils.get_document_name (doc);
			Utils.trace ("File parsed: %s - current file: %s", filename, name);
			if (filename == name) {
				update_source_outliner_view ();
			}
		}

		private bool update_source_outliner_view ()
		{
			var scs = _plugin_instance.scs_find_from_view (_active_view);
 			if (scs == null || scs.completion_engine == null) {
 				Utils.trace ("symbol completion helper is null for view");
				return true;
			}
			
			var doc = (Gedit.Document) _active_view.get_buffer ();
			var name = Utils.get_document_name (doc);
			var result = scs.completion_engine.codedom.lookup_source_file (name);
			update_cursor_position (doc);
			_outliner_view.update_view (result);

			if (result == null) {
				_outliner_view.clear_view ();
			}
			return true;
		}
	}
}
