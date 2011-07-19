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
		DATA,
		COLUMNS_COUNT
	}
	
	private class Data : GLib.Object
	{
		public Afrodite.Symbol symbol;
		public Afrodite.SourceReference? source_reference;
		
		private Afrodite.SourceFile _file;
		
		public Data (Afrodite.Symbol symbol, Afrodite.SourceReference? source_reference = null)
		{
			this.symbol = symbol;
			this.source_reference = source_reference;
			if (source_reference != null)
				this._file = source_reference.file;
		}
		
		~Data ()
		{
			_file = null;
		}
	}
	
	internal class SourceOutlinerView : GLib.Object
	{
		private string[] qualifiers = new string[] {
				"public ", "private ", "internal ", "protected "
			};

		private unowned Vtg.PluginInstance _plugin_instance = null;
		private Gtk.TreeView _src_view;
		private Gtk.TreeModelSort _sorted;
		private Gtk.ToggleButton _check_show_private_symbols;
		private Gtk.ToggleButton _check_show_public_symbols;
		private Gtk.ToggleButton _check_show_protected_symbols;
		private Gtk.ToggleButton _check_show_internal_symbols;
		private TreeStore _model = null;

		private Gtk.Menu _popup_symbols;
		private bool _on_show_symbol_scope_toggled_flag =  false;
		private uint _popup_symbols_ui_id;
		private string _popup_symbols_ui_def = """
                                        <ui>
                                        <popup name='SourceOutlinerPopupGoto'>
                                            <menuitem action='source-outliner-goto'/>
                                        </popup>
                                        </ui>""";

		const ActionEntry[] _action_entries = {
			{"source-outliner-goto", Gtk.Stock.OPEN, N_("Goto definition..."), null, N_("Goto symbol definition"), on_source_outliner_goto}
		};

		private Gtk.ActionGroup _actions;
		private VBox _side_panel;
		private int _current_line = -1;
		private int _current_column = -1;
		private uint _idle_id = 0;

		public signal void goto_source (int line, int start_column, int end_column);
		public signal void filter_changed ();

		private Gedit.View _active_view = null; // it's not unowned because we need to cleanup later
		private Gtk.HBox _top_ui;
		private Gtk.ComboBox _combo_groups;
		private Gtk.ComboBox _combo_items;
		private string _current_source_path;
		private bool _updating_combos = false;

		public View active_view {
			get {
				return _active_view;
			}
			set {
				if (_active_view != value) {
					cleanup_view_ui ();
					_active_view = value;
					initialize_view_ui ();
				}
			}
		}

		public bool show_private_symbols {
			get {
				return _check_show_private_symbols.active;
			}
		}

		public int current_line {
			get { return _current_line; }
		}

		public int current_column {
			get { return _current_column; }
		}

		public void set_current_position (int line, int column)
		{
			_current_line = line;
			_current_column = column;
			idle_highlight_current_position ();
		}

		public SourceOutlinerView (Vtg.PluginInstance plugin_instance)
		{
			this._plugin_instance = plugin_instance;
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
			_src_view.row_activated.connect (this.on_source_outliner_view_row_activated);
			_src_view.button_press_event.connect (this.on_source_outliner_view_button_press);
			var scroll = new Gtk.ScrolledWindow (null, null);
			scroll.add (_src_view);
			_side_panel.pack_start (scroll, true, true, 4); // add scroll + treview

			var hbox = new Gtk.HBox(false, 0);
			_side_panel.pack_start (hbox, false, false, 4);

			var label = new Gtk.Label (_("Filter by scope:"));
			label.xalign = 0;
			hbox.pack_start (label, false, false, 4);

			_check_show_public_symbols = new Gtk.ToggleButton ();
			var image = new Gtk.Image.from_file (Utils.get_image_path ("public-symbols-22.png"));
			_check_show_public_symbols.set_image (image);
			_check_show_public_symbols.set_tooltip_text (_("Show public symbols"));
			_check_show_public_symbols.active = Vtg.Plugin.main_instance.config.outliner_show_public_symbols;
			_check_show_public_symbols.toggled.connect (this.on_show_symbol_scope_toggled);
			hbox.pack_start (_check_show_public_symbols, false, true, 4);

			_check_show_internal_symbols = new Gtk.ToggleButton (); //.with_label (_("internal"));
			image = new Gtk.Image.from_file (Utils.get_image_path ("internal-symbols-22.png"));
			_check_show_internal_symbols.set_image (image);
			_check_show_internal_symbols.set_tooltip_text (_("Show internal symbols"));
			_check_show_internal_symbols.active = Vtg.Plugin.main_instance.config.outliner_show_internal_symbols;
			_check_show_internal_symbols.toggled.connect (this.on_show_symbol_scope_toggled);
			hbox.pack_start (_check_show_internal_symbols, false, true, 4);

			_check_show_protected_symbols = new Gtk.ToggleButton ();
			image = new Gtk.Image.from_file (Utils.get_image_path ("protected-symbols-22.png"));
			_check_show_protected_symbols.set_image (image);
			_check_show_protected_symbols.set_tooltip_text (_("Show protected symbols"));
			_check_show_protected_symbols.active = Vtg.Plugin.main_instance.config.outliner_show_protected_symbols;
			_check_show_protected_symbols.toggled.connect (this.on_show_symbol_scope_toggled);
			hbox.pack_start (_check_show_protected_symbols, false, true, 4);

			_check_show_private_symbols = new Gtk.ToggleButton ();
			image = new Gtk.Image.from_file (Utils.get_image_path ("private-symbols-22.png"));
			_check_show_private_symbols.set_image (image);
			_check_show_private_symbols.set_tooltip_text (_("Show private symbols"));
			_check_show_private_symbols.active = Vtg.Plugin.main_instance.config.outliner_show_private_symbols;
			_check_show_private_symbols.toggled.connect (this.on_show_symbol_scope_toggled);
			hbox.pack_start (_check_show_private_symbols, false, true, 4);

			_side_panel.show_all ();
			var icon = new Gtk.Image.from_pixbuf (Utils.get_icon_for_type_name (MemberType.CLASS));
			panel.add_item (_side_panel, "Source", _("Source"), icon);
			panel.activate_item (_side_panel);

			_actions = new Gtk.ActionGroup ("SourceOutlinerActionGroup");
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
			_model = build_tree_model ();
			_sorted = build_sort_model (_model);
			_src_view.set_model (_sorted);

			_top_ui = new Gtk.HBox (true, 0);
			_combo_groups = new Gtk.ComboBox ();
			var model = build_combo_model ();
			model.set_sort_column_id (Columns.NAME, SortType.ASCENDING);
			_combo_groups.set_model (model);

			renderer = new CellRendererPixbuf ();
 			_combo_groups.pack_start (renderer, false);
			_combo_groups.add_attribute (renderer, "pixbuf", Columns.ICON);
			
			renderer = new CellRendererText ();
			_combo_groups.pack_start (renderer, true);
			_combo_groups.add_attribute (renderer, "markup", Columns.NAME);
			_combo_groups.changed.connect (this.on_combo_groups_changed);

			_combo_items = new Gtk.ComboBox ();
			model = build_combo_model ();
			model.set_sort_column_id (Columns.NAME, SortType.ASCENDING);
			_combo_items.set_model (model);

			renderer = new CellRendererPixbuf ();
			_combo_items.pack_start (renderer, false);
			_combo_items.add_attribute (renderer, "pixbuf", Columns.ICON);

			renderer = new CellRendererText ();
			_combo_items.pack_start (renderer, true);
			_combo_items.add_attribute (renderer, "markup", Columns.NAME);
			_combo_items.changed.connect (this.on_combo_items_changed);

			_top_ui.pack_start (_combo_groups, false, true, 2);
			_top_ui.pack_end (_combo_items, false, true, 2);
		}

		~SourceOutlinerView ()
		{
			Utils.trace ("SourceOutlinerView destroying");
			_src_view.set_model (null);
			// this method is never called? a leak?
			deactivate ();
			Utils.trace ("SourceOutlinerView destroyed");
		}

		public void deactivate ()
		{
			var manager = _plugin_instance.window.get_ui_manager ();
			manager.remove_ui (_popup_symbols_ui_id);
			manager.remove_action_group (_actions);
			var panel = _plugin_instance.window.get_side_panel ();
			panel.remove_item (_side_panel);
			cleanup_view_ui ();
			if (_idle_id != 0) {
				GLib.Source.remove (_idle_id);
				_idle_id = 0;
			}
			_combo_groups = null;
			_combo_items = null;
			_top_ui = null;
		}

		private void on_combo_groups_changed (Gtk.Widget sender)
		{
			populate_combo_items_model ();
		}

		private void on_combo_items_changed (Gtk.Widget sender)
		{
			if (_updating_combos)
				return;

			TreeIter iter;
			if (_combo_items.get_active_iter (out iter)) {
				Data data;
				_combo_items.get_model ().get (iter, Columns.DATA, out data);
				this.goto_source (data.source_reference.first_line,
					data.source_reference.first_column,
					data.source_reference.last_column);
			}
		}

		private void initialize_view_ui ()
		{
			if (_active_view == null)
				return;

			var doc = (Document) _active_view.get_buffer ();
			if (!Utils.is_vala_doc (doc))
				return;

			// add two combo on the top of the edit view
			var tab = Gedit.Tab.get_from_document (doc);

			_top_ui.show_all ();
			tab.pack_start (_top_ui, false, false, 2);
		}

		private void cleanup_view_ui ()
		{
			if (_active_view == null)
				return;

			var doc = (Document) _active_view.get_buffer ();
			if (!Utils.is_vala_doc (doc))
				return;

			// add two combo on the top of the edit view
			var tab = Gedit.Tab.get_from_document (doc);
			if (tab != null) {
				var combo_model = (ListStore) _combo_groups.get_model ();
				combo_model.clear ();
				combo_model = (ListStore) _combo_items.get_model ();
				combo_model.clear ();
				tab.remove (_top_ui);
			}
		}

		private TreeStore build_tree_model ()
		{
			return new Gtk.TreeStore (Columns.COLUMNS_COUNT, typeof(string), typeof(Gdk.Pixbuf), typeof(GLib.Object));
		}

		private ListStore build_combo_model ()
		{
			var model = new Gtk.ListStore (Columns.COLUMNS_COUNT, typeof(string), typeof(Gdk.Pixbuf), typeof(GLib.Object));
			model.set_sort_column_id (0, SortType.ASCENDING);
			model.set_sort_func (0, this.sort_model);
			model.set_default_sort_func (this.sort_model);
			return model;
		}
		
		private TreeModelSort build_sort_model (TreeStore child_model)
		{
			var sorted = new Gtk.TreeModelSort.with_model (child_model);
			sorted.set_sort_column_id (0, SortType.ASCENDING);
			sorted.set_sort_func (0, this.sort_model);
			sorted.set_default_sort_func (this.sort_model);

			return sorted;
		}

		public void clear_view ()
		{
			_model.clear ();
		}

		public void update_view (Afrodite.SourceFile? source)
		{
			var model = build_tree_model ();
			var sorted = build_sort_model (model);
			var combo_model = (ListStore) _combo_groups.get_model ();


			_current_source_path = source.filename;
			_updating_combos = true;
			_combo_groups.set_model (null);
			combo_model.clear ();

			if (source != null) {
				populate_treeview_model (model, source, source.symbols);
				populate_combo_groups_model (combo_model, source);
			}

			// build combos
			_model = model;
			_sorted = sorted;
			_src_view.set_model (_sorted);
			_src_view.expand_all ();
			_updating_combos = false;
			_combo_groups.set_model (combo_model);
			_combo_groups.queue_draw ();
			_combo_items.queue_draw ();
			idle_highlight_current_position ();
		}

		private void populate_combo_items_model ()
		{
			int count = 0;
			TreeIter iter;
			Data data;

			var model = (ListStore) _combo_items.get_model ();

			model.clear ();
			_combo_items.set_model (null);
			if (_combo_groups.get_active_iter (out iter)) {
				_combo_groups.get_model ().get (iter, Columns.DATA, out data);
				if (data.symbol != null && data.symbol.has_children) {
					foreach (Afrodite.Symbol child in data.symbol.children) {
						if (!child.name.has_prefix ("!")) {
							Afrodite.SourceReference sr = child.lookup_source_reference_filename (_current_source_path);
							if (sr != null) {
								model.append (out iter);
								model.set (iter,
									Columns.NAME, child.name,
									Columns.ICON, Utils.get_icon_for_type_name (child.member_type),
									Columns.DATA, new Data(child, sr));
							}
							count++;
						}
					}
				}
			}
			_combo_items.set_model (model);
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

		private void on_show_symbol_scope_toggled (Widget sender)
		{
			if (_on_show_symbol_scope_toggled_flag)
				return;
			
			Gdk.Event event = Gtk.get_current_event ();
			if ((event.button.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
				bool active = ((Gtk.ToggleButton) sender).active;
				_on_show_symbol_scope_toggled_flag =  true;
				if (_check_show_internal_symbols != sender) {
					_check_show_internal_symbols.active = !active;
				}
				if (_check_show_private_symbols != sender) {
					_check_show_private_symbols.active = !active;
				}
				if (_check_show_protected_symbols != sender) {
					_check_show_protected_symbols.active = !active;
				}
				if (_check_show_public_symbols != sender) {
					_check_show_public_symbols.active = !active;
				}
				_on_show_symbol_scope_toggled_flag =  false;
			}
			Vtg.Plugin.main_instance.config.outliner_show_private_symbols = _check_show_private_symbols.active;
			Vtg.Plugin.main_instance.config.outliner_show_public_symbols = _check_show_public_symbols.active;
			Vtg.Plugin.main_instance.config.outliner_show_protected_symbols = _check_show_protected_symbols.active;
			Vtg.Plugin.main_instance.config.outliner_show_internal_symbols = _check_show_internal_symbols.active;
			this.filter_changed ();
		}

		private void on_source_outliner_view_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			var tw = (TreeView) sender;
			TreeModelSort model = (TreeModelSort) tw.get_model ();
			TreeIter iter;
			
			if (model.get_iter (out iter, path)) {
				Data data;
				model.get (iter, Columns.DATA, out data);
				goto_line (data.symbol);
			}
		}
		
		private void on_source_outliner_goto (Gtk.Action action)
		{
			TreeIter iter;
			TreeModel model;
			if (_src_view.get_selection ().get_selected (out model, out iter))
			{
				Data data;
				model.get (iter, Columns.DATA, out data);
				goto_line (data.symbol);
			}
		}
		
		private bool on_source_outliner_view_button_press (Gtk.Widget sender, Gdk.EventButton event)
		{
			if (event.button == 3) {
				weak TreeModel model;

				var rows =  _src_view.get_selection ().get_selected_rows (out model);
				if (rows.length () == 1) {
					TreeIter iter;
					Data obj;
					weak TreePath path = rows.nth_data (0);
					model.get_iter (out iter, path);
					model.get (iter, Columns.DATA, out obj);
					if (obj.symbol is Afrodite.Symbol) {
						_popup_symbols.popup (null, null, null, event.button, event.time);
					}
				}
			}
			return false;
		}

		private Afrodite.SymbolAccessibility get_symbol_accessibility (Afrodite.Symbol symbol)
		{
			Afrodite.SymbolAccessibility sym_access;

			if (symbol.has_children && !symbol.name.has_prefix ("!")
			    && (symbol.member_type == MemberType.CLASS || symbol.member_type == MemberType.STRUCT || symbol.member_type == MemberType.NAMESPACE)) {
				sym_access = symbol.access;
				
				foreach (Afrodite.Symbol child in symbol.children) {
					sym_access |= get_symbol_accessibility (child);
					if (sym_access == Afrodite.SymbolAccessibility.ANY)
						break;
				}
			} else {
				sym_access = symbol.access;
			}
			return sym_access;
		}

		private void populate_combo_groups_model (ListStore combo_model, Afrodite.SourceFile source)
		{
			bool root_namespace_added = false;
			foreach (Afrodite.Symbol symbol in source.symbols) {
				TreeIter iter_group;

				if (symbol.member_type == MemberType.NAMESPACE
				    || symbol.member_type == MemberType.CLASS
				    || symbol.member_type == MemberType.INTERFACE
				    || symbol.member_type == MemberType.STRUCT
				    || symbol.member_type == MemberType.ENUM) {
					Afrodite.SourceReference sr = symbol.lookup_source_reference_sourcefile (source);

					if (sr != null) {
						combo_model.append (out iter_group);
						combo_model.set (iter_group,
							Columns.NAME, symbol.fully_qualified_name, 
							Columns.ICON, Utils.get_icon_for_type_name (symbol.member_type),
							Columns.DATA, new Data (symbol, sr));
					}

					
				} else if (root_namespace_added == false && symbol.parent != null && symbol.parent.is_root) {
					// add a special root symbols
					combo_model.append (out iter_group);
					combo_model.set (iter_group,
						Columns.NAME, _("(none)"),
						Columns.ICON, Utils.get_icon_for_type_name (MemberType.NAMESPACE),
						Columns.DATA, new Data (symbol.parent, null));
					root_namespace_added = true;
				}
			}
		}
		
		private void populate_treeview_model (TreeStore model, Afrodite.SourceFile source, Vala.List<unowned Afrodite.Symbol>? symbols, TreeIter? parent_iter = null)
		{
			if (symbols == null || symbols.size == 0)
				return;

			Afrodite.SymbolAccessibility accessibility = 0;
			if (_check_show_private_symbols.active) {
				accessibility = Afrodite.SymbolAccessibility.PRIVATE;
			}
			if (_check_show_public_symbols.active) {
				accessibility |= Afrodite.SymbolAccessibility.PUBLIC;
			}
			if (_check_show_protected_symbols.active) {
				accessibility |= Afrodite.SymbolAccessibility.PROTECTED;
			}
			if (_check_show_internal_symbols.active) {
				accessibility |= Afrodite.SymbolAccessibility.INTERNAL;
			}

			foreach (unowned Afrodite.Symbol symbol in symbols) {
				// skip some simbols
				if (symbol.member_type == MemberType.NONE
				    || symbol.member_type == MemberType.LOCAL_VARIABLE
				    || symbol.member_type == MemberType.SCOPED_CODE_NODE
				    || symbol.member_type == MemberType.VOID
				    || symbol.name.has_prefix ("!")) {
					continue;
				}
				
				// this will include root symbols is parent_iter == null
				if (parent_iter == null && !symbol.parent.is_root)
					continue;
					
				TreeIter iter;
				Afrodite.SymbolAccessibility sym_access = get_symbol_accessibility (symbol);

				if ((sym_access & accessibility) != 0) {
					var sr = symbol.lookup_source_reference_sourcefile (source);
				
					if (sr != null) // a child can be defined in a different source too
					{
						string des = symbol.markup_description;
						//remove the access qualifier
						foreach(string qualifier in qualifiers) {
							if (des.has_prefix (qualifier)) {
								des = des.substring (qualifier.length);
								break;
							}
						}
						model.append (out iter, parent_iter);
						model.@set (iter,
							Columns.NAME, des,
							Columns.ICON, Utils.get_icon_for_type_name (symbol.member_type),
							Columns.DATA, new Data (symbol, sr));

						if ((symbol.member_type == MemberType.CLASS
						     || symbol.member_type == MemberType.STRUCT
						     || symbol.member_type == MemberType.INTERFACE
						     || symbol.member_type == MemberType.NAMESPACE
						     || symbol.member_type == MemberType.ENUM
						     || symbol.member_type == MemberType.ERROR_DOMAIN)
						    && symbol.has_children) {
							populate_treeview_model (model, source, symbol.children, iter);
						}
					}
				}
			}
		}

		private int sort_model (TreeModel model, TreeIter a, TreeIter b)
		{
			Data vala = null;
			Data valb = null;
			
			model.@get (a, Columns.DATA, out vala);
			model.@get (b, Columns.DATA, out valb);

			var sa = vala == null ? null : vala.symbol;
			var sb = valb == null ? null : valb.symbol;
			var result = Utils.symbol_type_compare (sa, sb);
			return result;
		}

		private void idle_highlight_current_position ()
		{
			if (_idle_id == 0)
				_idle_id = Idle.add_full (Priority.LOW, this.highlight_current_position);
		}

		private bool highlight_current_position ()
		{
			Afrodite.Symbol symbol = null;
			var model = _combo_groups.get_model ();
			TreeIter iter;

			_updating_combos = true;
			if (model.get_iter_first (out iter)) {
				TreeIter? found = null;
				do {
					Data data;
					model.get (iter, Columns.DATA, out data);
					if (data.symbol.has_children) {
						foreach (Afrodite.Symbol child in data.symbol.children) {
							Afrodite.SourceReference sr = child.lookup_source_reference_filename (_current_source_path);
							if (sr != null && sr.contains_position (_current_line + 1, _current_column)) {
								symbol = child;
								found = iter;
								break;
							}
						}
					}
				} while (symbol == null && model.iter_next (ref iter));
				if (found == null) {
					_combo_groups.set_active (-1);
				} else {
					_combo_groups.set_active_iter (found);
				}
			}
			
			if (symbol != null) {
				model = _combo_items.get_model ();
				if (model.get_iter_first (out iter)) {
					do {
						Data data;
						model.get (iter, Columns.DATA, out data);
						if (data.symbol == symbol) {
							_combo_items.set_active_iter (iter);
							break;
						}
					} while (model.iter_next (ref iter));
				}
			}
			_updating_combos = false;

			_idle_id = 0;
			return false;
		}
	}
}
