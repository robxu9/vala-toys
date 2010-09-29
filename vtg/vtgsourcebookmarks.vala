/*
 *  vtgsourcebookmarks.vala - Vala developer toys for GEdit
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
using Gtk;

namespace Vtg
{
	internal class SourceBookmarks : GLib.Object
	{
		private unowned Vtg.PluginInstance _plugin_instance = null;
		private ulong signal_id;
		private const int MAX_BOOKMARKS = 20;
		private Vala.List<SourceBookmark> _bookmarks = new Vala.ArrayList<SourceBookmark> ();
		private int _current_bookmark_index = -1;
		private bool _in_move = false;
		private Gedit.Document _idle_add_doc = null;

		public signal void current_bookmark_changed ();
		public signal void move_wrapped ();

		public SourceBookmarks (Vtg.PluginInstance plugin_instance)
		{
			this._plugin_instance = plugin_instance;
			signal_id = Signal.connect (_plugin_instance.window, "active_tab_changed", (GLib.Callback) on_tab_changed, this);
		}
		
		~SourceBookmarks ()
		{
			Utils.trace ("SourceBoolmarks destroying");
			SignalHandler.disconnect (_plugin_instance.window, signal_id);
			Utils.trace ("SourceBoolmarks destroying");
		}
		
		private static void on_tab_changed (Gedit.Window sender, Gedit.Tab tab, Vtg.SourceBookmarks instance)
		{
			var doc = tab.get_document ();
			string uri = doc.get_uri ();
			var prj = instance._plugin_instance.project_view.current_project;
			if (prj != null && prj.contains_vala_source_file (uri)) {
				instance._idle_add_doc = doc;
				//HACK: add the bookmark on a idle hanlder to capture line e col values
				Idle.add (instance.on_idle_bookmark_add, Priority.LOW);
			} else {
				instance._idle_add_doc = null;
			}
		}

		public bool on_idle_bookmark_add ()
		{
			if (_idle_add_doc != null) {
				string uri = _idle_add_doc.get_uri ();
				var prj = _plugin_instance.project_view.current_project;
				if (prj != null && prj.contains_vala_source_file (uri)) {
					unowned TextMark mark = (TextMark) _idle_add_doc.get_insert ();
					TextIter start;
					_idle_add_doc.get_iter_at_mark (out start, mark);
						
					int line = start.get_line ();
					int col = start.get_line_offset ();
					var book = new SourceBookmark ();
					book.uri = uri;
					book.line = line + 1;
					book.column = col + 1;
					add_bookmark (book, true);
				}
			}
			return false;
		}
		/*
		private void debug_dump_list ()
		{
			print ("DUMP Bookmarks:\n");
			if (_bookmarks.size == 0) {
				print ("   the bookmark list is empty");
			} else {
				int idx = 0;
				foreach (SourceBookmark item in _bookmarks) {
					print ("%s%d: %s - %d,%d\n", idx == _current_bookmark_index ? "-->" : "   ", idx, item.uri, item.line, item.column);
					idx++;
				}
			}
		}
		*/
	
		public void add_bookmark (SourceBookmark item, bool auto = false)
		{
			if (_in_move)
				return;
			
			if (auto && !is_empty) {
				// if is an autobookmark search in the list and if found set it current
				int idx = 0;
				foreach (SourceBookmark book in _bookmarks) {
					if (book.uri == item.uri) {
						_current_bookmark_index = idx;
						// just update the position
						book.line = item.line;
						book.column = item.column;
						return;
					}
					idx++;
				}
			}
			
			if (_current_bookmark_index >= (_bookmarks.size - 1)) {
				if (_bookmarks.size == MAX_BOOKMARKS) {
					_bookmarks.remove_at (0);
				}
				_bookmarks.add (item);
				 _current_bookmark_index = _bookmarks.size - 1;
			} else {
				_current_bookmark_index++;
				if (_bookmarks.size == MAX_BOOKMARKS) {
					_bookmarks.remove_at (_current_bookmark_index);
				}

				_bookmarks.insert (_current_bookmark_index, item);
			}
			
			//debug_dump_list ();
		}

/*
		public void remove_current_bookmark ()
		{
			var item = get_current_bookmark ();
			if (item != null) {
				_bookmarks.remove (item);
				_current_bookmark_index = _bookmarks.size - 1;
			}
		}
*/

		public bool is_empty
		{
			get {
				return _bookmarks.size == 0;
			}
		}

		public SourceBookmark? get_current_bookmark ()
		{
			SourceBookmark? item = null;
			
			if (_bookmarks.size > 0 && _bookmarks.size > _current_bookmark_index) {
				item = _bookmarks.get (_current_bookmark_index);
			}
			
			return item;
		}
		
		public void move_next ()
		{
			bool wrap = false;
			if (_bookmarks.size == 0) {
				return;
			}
			
			if (_current_bookmark_index < (_bookmarks.size - 1))	{
				_current_bookmark_index++;
			} else {
				_current_bookmark_index = 0;
				wrap = true;
			}
			_in_move = true;
			current_bookmark_changed ();
			if (wrap)
				move_wrapped ();
			_in_move = false;
			
			//debug_dump_list ();
		}
		
		public void move_previous ()
		{
			bool wrap = false;
			if (_bookmarks.size == 0) {
				return;
			}

			if (_current_bookmark_index > 0) {
				_current_bookmark_index--;
			} else {
				_current_bookmark_index = _bookmarks.size - 1;
				wrap = true;
			}
			_in_move = true;
			current_bookmark_changed ();
			if (wrap)
				move_wrapped ();
			_in_move = false;
			
			//debug_dump_list ();
		}

	}
}
