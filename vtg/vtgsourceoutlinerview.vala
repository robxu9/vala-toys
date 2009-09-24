/*
 *  vtgprojectmanagerview.vala - Vala developer toys for GEdit
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
using Vsc;

namespace Vtg
{
	private enum Columns
	{
		NAME = 0,
		ICON_ID,
		SYMBOL,
		COLUMNS_COUNT
	}
	
	internal class SourceOutlinerView : GLib.Object
	{
		private Vtg.PluginInstance _plugin_instance = null;
		private Gtk.TreeView _src_view;
		private TreeStore _model = null;
		
		private Gtk.Menu _popup_symbols;
		private uint _popup_symbols_ui_id;
		private string _popup_symbols_ui_def = """
                                        <ui>
                                        <popup name='SourceOutlinerPopupGoto'>
                                            <menuitem action='source-outliner-goto'/>
                                        </popup>
                                        </ui>""";

		const ActionEntry[] _action_entries = {
			{"source-outliner-goto", Gtk.STOCK_OPEN, N_("Goto definition..."), null, N_("Goto symbol definition"), on_source_outliner_goto}
		};

		private Vsc.SymbolItem _last_selected_symbol = null;
		private ActionGroup _actions;
		private VBox _side_panel;
		
		public Vtg.PluginInstance plugin_instance { construct { _plugin_instance = value; } }

		public SourceOutlinerView (Vtg.PluginInstance plugin_instance)
		{
			this.plugin_instance = plugin_instance;
		}
		
		~SourceOutlinerView ()
		{
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.remove_action_group (_actions);
			var panel = _plugin_instance.window.get_side_panel ();
			panel.remove_item (_side_panel);
		}
		
		construct
		{
			var panel = _plugin_instance.window.get_side_panel ();
			_side_panel = new Gtk.VBox (false, 8);
			_src_view = new Gtk.TreeView ();
			CellRenderer renderer = new CellRendererPixbuf ();
			var column = new TreeViewColumn ();
 			column.pack_start (renderer, false);
			column.add_attribute (renderer, "stock-id", Columns.ICON_ID);
			renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", Columns.NAME);
			_src_view.append_column (column);
			_src_view.set_headers_visible (false);
			_src_view.row_activated += this.on_project_view_row_activated;
			_src_view.button_press_event += this.on_project_view_button_press;
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_src_view);
			_side_panel.pack_start (scroll, true, true, 4);
			_side_panel.show_all ();
			panel.add_item (_side_panel, _("Source"), null);
			panel.activate_item (_side_panel);

			_actions = new ActionGroup ("SourceOutlinerActionGroup");
			_actions.set_translation_domain (Config.GETTEXT_PACKAGE);
			_actions.add_actions (_action_entries, this);
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.insert_action_group (_actions, -1);
			try {
				_popup_symbols_ui_id = manager.add_ui_from_string (_popup_symbols_ui_def, -1);
				_popup_symbols = (Gtk.Menu) manager.get_widget ("/SourceOutlinerPopupGoto");
				assert (_popup_symbols != null);
			} catch (Error err) {
				GLib.warning ("Error %s", err.message);
			}
			
			/* initializing the model */
			_model = new Gtk.TreeStore (Columns.COLUMNS_COUNT, typeof(string), typeof(string), typeof(GLib.Object));
			_src_view.set_model (_model);
		}
		
		public void clear_view ()
		{
			_model.clear ();
		}

		public void update_view (Vsc.SymbolItem symbol)
		{
			clear_view ();
			rebuild_model (symbol);
			_src_view.expand_all ();
		}

		private void on_project_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var tw = (TreeView) sender;
			var model = tw.get_model ();
			TreeIter iter;
			if (model.get_iter (out iter, path)) {
				string name, id;
				model.get (iter, 1, out name, 2, out id);
				try {
					string file = Filename.from_uri (id);
					if (name != null && FileUtils.test (file, FileTest.EXISTS)) {
						_plugin_instance.activate_uri (id);
					}
				} catch (Error e) {
					GLib.warning ("on_project_view_row_activated error: %s", e.message);
				}

			}
		}
		
		private void on_source_outliner_goto (Gtk.Action action)
		{
			GLib.debug ("sourceoutliner: goto called");
		}
		
		private bool on_project_view_button_press (Gtk.Widget sender, Gdk.EventButton event)
		{
			if (event.button == 3) {
				weak TreeModel model;

				var rows =  _src_view.get_selection ().get_selected_rows (out model);
				if (rows.length () == 1) {
					TreeIter iter;
					GLib.Object obj;
					weak TreePath path = rows.nth_data (0);
					model.get_iter (out iter, path);
					model.get (iter, Columns.SYMBOL, out obj);
					if (obj is SymbolItem) {
						_last_selected_symbol = (SymbolItem) obj;
						_popup_symbols.popup (null, null, null, event.button, event.time);
					}
				}
			}
			return false;
		}
		
		private void rebuild_model (SymbolItem? parent, TreeIter? parentIter = null)
		{
			if (parent == null)
				return;
			
			TreeIter iter;
			_model.append (out iter, parentIter);
			_model.set (iter, 
				Columns.ICON_ID, get_icon_from_symbol_type (parent.symbol), 
				Columns.NAME, parent.name, 
				Columns.SYMBOL, parent);


			if (parent.children != null) {
				foreach (SymbolItem item in parent.children) {
					rebuild_model (item, iter);
				}
			}
		}
		
		private string get_icon_from_symbol_type (Vala.Symbol symbol)
		{
			return Gtk.STOCK_FILE;
		}
	}
}
