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
using Gee;
using Gtk;

namespace Vtg
{
	internal class SourceBookmarks : GLib.Object
	{
		private Vtg.Plugin _plugin;
		private ulong signal_id;
		private const int MAX_BOOKMARKS = 20;
		private Gee.List<SourceBookmark> _bookmarks = new Gee.ArrayList<SourceBookmark> ();
		private int _current_bookmark_index = -1;
		
		public signal void current_bookmark_changed ();
		public signal void move_wrapped ();		
		
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public SourceBookmarks (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
			var window = _plugin.gedit_window;
			signal_id = Signal.connect (window, "active_tab_changed", (GLib.Callback) on_tab_changed, this);
		}
		
		~SourceBookmarks ()		
		{
			SignalHandler.disconnect (this, signal_id);
		}
		
		private static void on_tab_changed (Gedit.Window sender, Gedit.Tab tab, Vtg.SourceBookmarks instance)
		{
			var doc = tab.get_document ();
			unowned TextMark mark = (TextMark) doc.get_insert ();
			TextIter start;
			doc.get_iter_at_mark (out start, mark);
						
			string uri = doc.get_uri ();
			var prj = instance._plugin.project_manager_ui.project_view.current_project;
			if (prj != null && prj.contains_vala_source_file (uri)) {
				int line = start.get_line ();
				int col = start.get_line_offset ();
				var book = new SourceBookmark ();
				book.uri = uri;
				book.line = line;
				book.column = col;
				instance.add_bookmark (book);
			}
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
					print ("   %d: %s - %d,%d\n", idx, item.uri, item.line, item.column);
					idx++;
				}
				print ("   current index is %d\n", _current_bookmark_index);
			}
		}
	*/		
		public void add_bookmark (SourceBookmark item)
		{
			if (_bookmarks.size > 0) {
				int index = _current_bookmark_index;
				if (index == -1)
					index = _bookmarks.size - 1;
				
				var prev = _bookmarks.get (index);
				
				if (prev.uri == item.uri)
					return; //avoid duplicate item
			}
			if (_bookmarks.size == MAX_BOOKMARKS) {
				_bookmarks.remove_at (0);
			}
			
			if (_current_bookmark_index == -1 || _current_bookmark_index == (_bookmarks.size - 1))
				_bookmarks.add (item);
			else {
				_current_bookmark_index++;
				_bookmarks.insert (_current_bookmark_index, item);
			}
			
			//debug_dump_list ();
		}

		public void remove_current_bookmark ()
		{
			var item = get_current_bookmark ();
			if (item != null) {
				_bookmarks.remove (item);
				if (_bookmarks.size <= _current_bookmark_index) {
					_current_bookmark_index = -1; //past the end
				}
			}
		}
		
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
			
			if (_current_bookmark_index == -1) {
				_current_bookmark_index = _bookmarks.size - 1;
			} else {
				if (_current_bookmark_index < (_bookmarks.size - 1))	{
					_current_bookmark_index++;
				} else {
					_current_bookmark_index = 0;
					wrap = true;
				}
			}
				
			current_bookmark_changed ();
			if (wrap)
				move_wrapped ();
		}
		
		public void move_previous ()
		{
			bool wrap = false;
			if (_bookmarks.size == 0) {
				return;
			}
			
			if (_current_bookmark_index == -1) {
				_current_bookmark_index = _bookmarks.size - 1;
			} else {
				if (_current_bookmark_index > 0) {
					_current_bookmark_index--;
				} else {
					_current_bookmark_index = _bookmarks.size - 1;
					wrap = true;
				}
			}
				
			current_bookmark_changed ();
			if (wrap)
				move_wrapped ();
		}

	}
}
