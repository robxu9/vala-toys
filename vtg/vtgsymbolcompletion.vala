/*
 *  vtgsymbolcompletionhelper.vala - Vala developer toys for GEdit
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
using Gsc;
using Afrodite;

namespace Vtg
{
	internal class SymbolCompletion : GLib.Object
	{
		private unowned Vtg.PluginInstance _plugin_instance = null;
		private unowned CompletionEngine _completion_engine = null;
		
		private Gedit.View _view = null;
		private SymbolCompletionProvider _provider;
		private Gsc.Completion _manager;
		private SymbolCompletionTrigger _trigger;
		
 		public Vtg.PluginInstance plugin_instance { get { return _plugin_instance; } construct { _plugin_instance = value; } }
		public Gedit.View view { get { return _view; } construct { _view = value; } }
		public CompletionEngine completion_engine { get { return _completion_engine; } construct set { _completion_engine = value; } }
		public SymbolCompletionTrigger trigger { get { return _trigger; } }
		
		public SymbolCompletion (Vtg.PluginInstance plugin_instance, Gedit.View view, CompletionEngine completion_engine)
		{
			GLib.Object (plugin_instance: plugin_instance, view: view, completion_engine: completion_engine);
		}

		construct
		{
			if (this._view.is_realized ()) {
				setup_gsc_completion (_view);
			} else {
				this.view.realize.connect (this.on_realized);
			}
		}
		
		private void on_realized (Gtk.Widget sender)
		{
			_view.realize.disconnect (this.on_realized);
			setup_gsc_completion (_view);
		}

		~SymbolCompletionHelper ()
		{
			if (_manager != null)
				deactivate ();
			_provider = null;
			_view = null;
		}

		public void deactivate ()
		{
			_trigger.deactivate ();
			_manager.unregister_provider (_provider, _trigger);
			_manager.unregister_trigger (_trigger);
			_manager.destroy ();
			_trigger = null;
			_manager = null;
		}

		private void setup_gsc_completion (Gedit.View view)
		{
			_manager = new Gsc.Completion (view);
			_manager.remember_info_visibility = true;
			_manager.select_on_show = true;
			_provider = new SymbolCompletionProvider (this);
			_trigger = new SymbolCompletionTrigger (_plugin_instance, _manager, "SymbolComplete");
			_manager.register_trigger (_trigger);
			_manager.register_provider (_provider, _trigger);
			_manager.set_active (true);
		}
		
		public void goto_definition ()
		{
			Afrodite.Symbol? item = _provider.get_current_symbol_item (500);
			
			if (item != null && item.has_source_references) {
				try {
					string uri = Filename.to_uri (item.source_references.get(0).file.filename);
					int line = item.source_references.get(0).first_line;
					int col = item.source_references.get(0).first_column;
					
					SourceBookmark bookmark;
					var view = _plugin_instance.window.get_active_view ();
					if (view != null) {
						var doc = (Gedit.Document) view.get_buffer ();
						unowned TextMark mark = (TextMark) doc.get_insert ();
						TextIter start;
						doc.get_iter_at_mark (out start, mark);
						
						// first create a bookmark with the current position
						bookmark = new SourceBookmark ();
						bookmark.uri = doc.get_uri ();
						bookmark.line = start.get_line () + 1;
						bookmark.column = start.get_line_offset () + 1;
						_plugin_instance.bookmarks.add_bookmark (bookmark); 
					}
					// create  another bookmark with the new position
					bookmark = new SourceBookmark ();
					bookmark.uri = uri;
					bookmark.line = line + 1;
					bookmark.column = col + 1;
					_plugin_instance.bookmarks.add_bookmark (bookmark);
					_plugin_instance.activate_uri (uri, line, col);
				} catch (Error e) {
					GLib.warning ("error %s converting file %s to uri", e.message, item.source_references.get(0).file.filename);
				}
			}
		}
	}
}
