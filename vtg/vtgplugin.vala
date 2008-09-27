/*
 *  vtgplugin.vala - Vala developer toys for GEdit
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

namespace Vtg
{
	public class Plugin : Gedit.Plugin
	{
		private Gedit.Window _window = null;
		private Gee.List<Vtg.BracketCompletion> bcs = new Gee.ArrayList<Vtg.BracketCompletion> ();
		private Gee.List<Vtg.SymbolCompletionHelper> scs = new Gee.ArrayList<Vtg.SymbolCompletionHelper> ();

		public override void activate (Gedit.Window window)
		{
			this._window = window;
			Signal.connect_after (this._window, "tab-added", (GLib.Callback) on_tab_added, this);
			Signal.connect_after (this._window, "tab-removed", (GLib.Callback) on_tab_removed, this);

			foreach (View view in this._window.get_views ()) {
				var doc = (Gedit.Document) (view.get_buffer ());
				if (doc.language != null && doc.language.id == "vala")
					initialize_view (view);
			}

			foreach (Document doc in this._window.get_documents ()) {
				initialize_document (doc);
			}
		}

		public override void deactivate (Gedit.Window window)
		{
			deactivate_plugins ();
			this._window = null;
		}
	  
		public override bool is_configurable ()
		{
			return false;
		}

		public Gedit.Window gedit_window
		{
			get { return _window; }
		}

		private void deactivate_plugins ()
		{
			GLib.debug ("deactvate");
			foreach (BracketCompletion bc in bcs) {
				bc.deactivate ();
			}
			foreach (Vtg.SymbolCompletionHelper sc in scs) {
				sc.deactivate ();
			}
			GLib.debug ("deactvated");
		}


		private static void on_tab_added (Gedit.Window sender, Gedit.Tab tab, Vtg.Plugin instance)
		{
			var doc = tab.get_document ();

			if (doc.language != null && doc.language.id == "vala") {
				var view = tab.get_view ();
				instance.initialize_view (view);
			}
			instance.initialize_document (doc);
		}

		private static void on_tab_removed (Gedit.Window sender, Gedit.Tab tab, Vtg.Plugin instance)
		{
			GLib.debug ("tab removed");
			var view = tab.get_view ();
			var doc = tab.get_document ();

			instance.uninitialize_view (view);
			instance.uninitialize_document (doc);
		}

		private bool scs_contains (Gedit.View view)
		{
			return (scs_find_from_view (view) != null);
		}

		private Vtg.SymbolCompletionHelper? scs_find_from_view (Gedit.View view)
		{
			foreach (Vtg.SymbolCompletionHelper sc in scs) {
				if (sc.view == view)
					return sc;
			}
			return null;
		}

		private bool bcs_contains (Gedit.View view)
		{
			return (bcs_find_from_view (view) != null);
		}

		private BracketCompletion? bcs_find_from_view (Gedit.View view)
		{
			foreach (BracketCompletion bc in bcs) {
				if (bc.view == view)
					return bc;
			}

			return null;
		}

		private void initialize_view (Gedit.View view)
		{
			if (!scs_contains (view)) {
				var sc = new Vtg.SymbolCompletionHelper (this, view);
				scs.add (sc);
			} else {
				GLib.warning ("sc already initialized for view");
			}

			if (!bcs_contains (view)) {
				var bc = new BracketCompletion (this, view);
				bcs.add (bc);
			} else {
				GLib.warning ("bc already initialized vor view");
			}
		}

		private void initialize_document (Gedit.Document doc)
		{
			Signal.connect (doc, "notify::language", (GLib.Callback) on_notify_language, this);
		}

		private void uninitialize_view (Gedit.View view)
		{
			var sc = scs_find_from_view (view);
			if (sc != null) {
				sc.deactivate ();
				scs.remove (sc);
			} else {
				GLib.warning ("sc not found");
			}

			var bc = bcs_find_from_view (view);
			if (bc != null) {
				bc.deactivate ();
				bcs.remove (bc);
			} else {
				GLib.warning ("bc not found");
			}
		}

		private void uninitialize_document (Gedit.Document doc)
		{
			SignalHandler.disconnect_by_func (doc, (void*) on_notify_language, this);
		}

		private static void on_notify_language (Gedit.Document sender, ParamSpec pspec, Vtg.Plugin instance)
		{
			//search the view
			var app = App.get_default ();
			foreach (View view in app.get_views ()) {
				if (view.get_buffer () == sender) {
					if (sender.language  == null || sender.language.id != "vala") {
						instance.uninitialize_view (view);
					} else {
						instance.initialize_view (view);
					}
					break;
				}
			}
		}

		~Plugin ()
		{
			GLib.debug ("destructor");
			deactivate_plugins ();
		}
	}
}

[ModuleInit]
public GLib.Type register_gedit_plugin (TypeModule module) 
{
	return typeof (Vtg.Plugin);
}
