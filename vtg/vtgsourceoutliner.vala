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
		private Gedit.View _active_view = null;
		private SourceOutlinerView _outliner_view = null;
		private PluginInstance _plugin_instance;
		private uint idle_id = 0;
		
	 	public PluginInstance plugin_instance { get { return _plugin_instance; } construct { _plugin_instance = value; } default = null; }

		public View active_view {
			get {
				return _active_view;
			}
			set {
				if (_active_view != value) {
					if (_active_view != null) {
						var doc = (Document) _active_view.get_buffer ();
						cleanup_document (doc);
						cleanup_completion (_active_view);
					}
					_active_view = value;
					if (_active_view != null) {
						var doc = (Document) _active_view.get_buffer ();
						setup_document (doc);
						if (Utils.is_vala_doc (doc)) {
							update_source_outliner_view ();
							setup_completion (_active_view);
						}
					}
				}
			}
		}
		
		public SourceOutliner (PluginInstance plugin_instance)
		{
			this.plugin_instance = plugin_instance;
			_outliner_view = new SourceOutlinerView (plugin_instance);
		}

		~SourceOutliner ()
		{
			if (idle_id != 0) {
				GLib.Source.remove (idle_id);
			}
			if (_active_view != null)
			{
				cleanup_completion (_active_view);
			}
		}
		
		private void setup_document (Gedit.Document doc)
		{
			//Signal.connect (doc, "notify::language", (GLib.Callback) on_notify_language, this);
			doc.notify["language"] += this.on_notify_language;
		}
	
		public void cleanup_document (Gedit.Document doc)
		{
			//SignalHandler.disconnect_by_func (doc, (void*) on_notify_language, this);
			doc.notify["language"] -= this.on_notify_language;
		}
		
		private void setup_completion (View view)
		{
			var scs = _plugin_instance.scs_find_from_view (view);
 			if (scs == null) {
 				GLib.warning ("setup_completion: symbol completion helper is null for view");
				return;
			}
			
			scs.completion.parser.sec_cache_builded += this.on_sec_cache_builded;
		}

		private void cleanup_completion (View view)
		{
			var scs = _plugin_instance.scs_find_from_view (view);
 			if (scs == null) {
 				GLib.warning ("setup_completion: symbol completion helper is null for view");
				return;
			}
			
			scs.completion.parser.sec_cache_builded -= this.on_sec_cache_builded;
		}

		private void on_notify_language (Gedit.Document sender, ParamSpec pspec)
		{
			if (Utils.is_vala_doc (sender)) {
				update_source_outliner_view ();
				setup_completion (_active_view);
			}
		}
		
		// this method is called from another thread context
		// for this reason the update is done in the idle handler
		private void on_sec_cache_builded (Vsc.ParserManager sender)
		{
			setup_idle ();
		}
		
		private void setup_idle ()
		{
			idle_id =  Idle.add (this.on_idle_update, Priority.DEFAULT_IDLE);
		}
		
		private bool on_idle_update ()
		{
			update_source_outliner_view ();
			idle_id = 0;
			return false;
		}
		
		private void update_source_outliner_view ()
		{
			var scs = _plugin_instance.scs_find_from_view (_active_view);
 			if (scs == null) {
 				GLib.warning ("update_source_ouliner_view: symbol completion helper is null for view");
				return;
			}
			
			var name = Utils.get_document_name ((Gedit.Document) _active_view.get_buffer ());
			var results = scs.completion.get_symbols_for_source (name);
			if (results == null) {
				_outliner_view.clear_view ();
			} else {
				_outliner_view.update_view (results);
			}
		}
	}
}
