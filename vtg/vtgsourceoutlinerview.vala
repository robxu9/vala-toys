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
using Afrodite;
using Vala;

namespace Vtg
{
	private enum Columns
	{
		NAME = 0,
		ICON,
		SYMBOL,
		COLUMNS_COUNT
	}
	
	internal class SourceOutlinerView : GLib.Object
	{
		private string[] qualifiers = new string[] {
				"public ", "private ", "internal ", "protected "
			};

		private unowned Vtg.PluginInstance _plugin_instance = null;
		private Gtk.TreeView _src_view;
		private Gtk.TreeModelSort _sorted;
		private Gtk.CheckButton _check_show_private_symbols;
		private TreeStore _model = null;
		private Vala.List<Afrodite.Symbol>? _last_symbols = null;


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

		private ActionGroup _actions;
		private VBox _side_panel;
		
		public signal void goto_source (int line, int start_column, int end_column);
		
		public Vtg.PluginInstance plugin_instance { construct { _plugin_instance = value; } }

		public SourceOutlinerView (Vtg.PluginInstance plugin_instance)
		{
			GLib.Object (plugin_instance: plugin_instance);
		}
		
		~SourceOutlinerView ()
		{
			// this method is never called? a leak?
			deactivate ();

		}
		
		public void deactivate ()
		{
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.remove_action_group (_actions);
			var panel = _plugin_instance.window.get_side_panel ();
			panel.remove_item (_side_panel);
			_last_symbols = null;
		}

		construct
		{
			var panel = _plugin_instance.window.get_side_panel ();
			_side_panel = new Gtk.VBox (false, 8);
			_src_view = new Gtk.TreeView ();
			
			var column = new TreeViewColumn ();
			
			CellRenderer renderer = new CellRendererPixbuf ();
 			column.pack_start (renderer, false);
			column.add_attribute (renderer, "pixbuf", Columns.ICON);
			
			renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "markup", Columns.NAME);
			
			_src_view.append_column (column);
			_src_view.set_headers_visible (false);
			_src_view.row_activated += this.on_source_outliner_view_row_activated;
			_src_view.button_press_event += this.on_source_outliner_view_button_press;
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_src_view);
			_side_panel.pack_start (scroll, true, true, 4); // add scroll + treview
			
			_check_show_private_symbols = new Gtk.CheckButton.with_label (_("Show also private symbols"));
			_check_show_private_symbols.active = Vtg.Plugin.main_instance.config.outliner_show_private_symbols;
			_check_show_private_symbols.toggled.connect (this.on_show_private_symbol_toggled);
			_side_panel.pack_start (_check_show_private_symbols, false, true, 8);
			
			_side_panel.show_all ();
			var icon = new Gtk.Image.from_pixbuf (Utils.get_icon_for_type_name ("Class"));
			panel.add_item (_side_panel, _("Source"), icon);
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
			_model = new Gtk.TreeStore (Columns.COLUMNS_COUNT, typeof(string), typeof(Gdk.Pixbuf), typeof(GLib.Object));
			
			_sorted = new Gtk.TreeModelSort.with_model (_model);
			_sorted.set_sort_column_id (0, SortType.ASCENDING);
			_sorted.set_sort_func (0, this.sort_model);			
			_src_view.set_model (_sorted);	
		}
		
		public void clear_view ()
		{
			_model.clear ();
		}

		public void update_view (Vala.List<Afrodite.Symbol>? symbols = null)
		{
			_src_view.set_model (null);
			clear_view ();
			if (symbols == null) {
				symbols = _last_symbols;
			}
			rebuild_model (symbols);
			_last_symbols = symbols;
			_src_view.set_model (_sorted);
			_src_view.expand_all ();
		}

		private void goto_line (Afrodite.Symbol symbol)
		{
			if (symbol.has_source_references) {
				var sr = symbol.source_references.get(0);
				
				int line = sr.first_line;
				int start_col = sr.first_column;
				int end_col = sr.last_column;
				this.goto_source (line, start_col, end_col);
			}
		}
		
		private void on_show_private_symbol_toggled (Widget sender)
		{
			update_view ();
			Vtg.Plugin.main_instance.config.outliner_show_private_symbols = _check_show_private_symbols.active;
		}

		private void on_source_outliner_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var tw = (TreeView) sender;
			TreeModelSort model = (TreeModelSort) tw.get_model ();
			TreeIter iter;
			
			if (model.get_iter (out iter, path)) {
				Afrodite.Symbol symbol;
				model.get (iter, Columns.SYMBOL, out symbol);
				goto_line (symbol);
			}
		}
		
		private void on_source_outliner_goto (Gtk.Action action)
		{
			TreeIter iter;
			TreeModel model;
			if (_src_view.get_selection ().get_selected (out model, out iter))
			{
				Afrodite.Symbol symbol;
				model.get (iter, Columns.SYMBOL, out symbol);
				goto_line (symbol);
			}
		}
		
		private bool on_source_outliner_view_button_press (Gtk.Widget sender, Gdk.EventButton event)
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
					if (obj is Afrodite.Symbol) {
						_popup_symbols.popup (null, null, null, event.button, event.time);
					}
				}
			}
			return false;
		}
		
		private void rebuild_model (Vala.List<Afrodite.Symbol>? symbols, TreeIter? parentIter = null)
		{
			if (symbols == null)
				return;
			
			foreach (Afrodite.Symbol symbol in symbols) {
				TreeIter iter;
				
				if (!symbol.name.has_prefix ("!") && _check_show_private_symbols.active
				    || (!_check_show_private_symbols.active && symbol.access != Afrodite.SymbolAccessibility.PRIVATE)) {
					string des = symbol.markup_description;
					//remove the access qualifier
					foreach(string qualifier in qualifiers) {
						if (des.has_prefix (qualifier)) {
							des = des.substring (qualifier.length);
							break;
						}
					}
					_model.append (out iter, parentIter);
					_model.set (iter, 
						Columns.NAME, des, 
						Columns.ICON, Utils.get_icon_for_type_name (symbol.type_name), 
						Columns.SYMBOL, symbol);

					if (symbol.has_children) {
						rebuild_model (symbol.children, iter);
					}
				}
			}
		}
		

		private int sort_model (TreeModel model, TreeIter a, TreeIter b)
		{
			Afrodite.Symbol vala;
			Afrodite.Symbol valb;
			
			model.get (a, Columns.SYMBOL, out vala);
			model.get (b, Columns.SYMBOL, out valb);
			
			return Utils.symbol_type_compare (vala, valb);
		}
	}
}
