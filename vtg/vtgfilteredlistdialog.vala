/*
 *  vtgfilteredlistdialog.vala - Vala developer toys for GEdit
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
	public class FilteredListDialog : GLib.Object
	{
		private Gtk.Dialog _dialog;
		private Gtk.TreeView _treeview;
		private Gtk.Entry _entry;
		private Gtk.TreeModelFilter _model;
		private Gtk.TreeModelSort _sorted;
		private Gtk.TreeModel _child_model;
		private PatternSpec _current_pattern = null;
		private Gtk.Button _button_ok;
		
		public TreeIter selected_iter;
		
		public FilteredListDialog (TreeModel model)
		{
			this._child_model = model;
			initialize_ui ();
		}

		private void initialize_ui ()
		{
			var builder = new Gtk.Builder ();
			try {
				builder.add_from_file (Utils.get_ui_path ("vtg.ui"));
			} catch (Error err) {
				GLib.warning ("initialize_ui: %s", err.message);
			}
			
			_dialog = (Gtk.Dialog) builder.get_object ("dialog-db");
			assert (_dialog != null);
			_button_ok = (Gtk.Button) builder.get_object ("button-db-ok");
			assert (_button_ok != null);			
			_treeview = (Gtk.TreeView) builder.get_object ("treeview-db-docs");
			assert (_treeview != null);
			_entry = (Gtk.Entry) builder.get_object ("entry-db-filter");
			assert (_entry != null);
			_entry.key_press_event += this.on_entry_key_press;
			_entry.notify["text"] += this.on_entry_text_changed;
			_model = new Gtk.TreeModelFilter (_child_model, null);
			_model.set_visible_func (this.filter_model);
			_child_model.row_changed += this.on_row_changed;
			var column = new TreeViewColumn ();
 			CellRenderer renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", 0);
			_treeview.append_column (column);
			_sorted = new Gtk.TreeModelSort.with_model (_model);
			_sorted.set_sort_column_id (0, SortType.ASCENDING);
			_sorted.set_sort_func (0, this.sort_model);
			_treeview.set_model (_sorted);
			_treeview.get_selection ().set_mode (SelectionMode.SINGLE);
			_treeview.key_press_event += on_treeview_key_press;
			
			select_result ();
		}

		public bool run ()
		{
			_dialog.show_all ();
			int dialog_result = _dialog.run ();
			if (dialog_result > 0) {
				TreeIter iter;
				if (_treeview.get_selection ().get_selected (null, out iter)) {
					TreeIter sort;
					_sorted.convert_iter_to_child_iter (out sort, iter);
					_model.convert_iter_to_child_iter (out selected_iter, sort);
				} else
					dialog_result = 0;
			}
			_dialog.destroy ();
			
			return dialog_result > 0;
		}
		
		private void on_row_changed (Gtk.TreeModel tree_model, Gtk.TreePath path, Gtk.TreeIter iter)
		{
			if (!_treeview.get_selection ().get_selected (null, null)) {
				TreeIter sel;
				tree_model.get_iter_first (out sel);
				_treeview.get_selection ().select_iter (sel);
			}
		}
		
		public bool on_entry_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			if (evt.keyval == Gdk.Key_Down || evt.keyval == Gdk.Key_Up) {
				TreeIter sel;
				TreeModel model;
				TreePath path;
				if (_treeview.get_selection ().get_selected (out model, out sel)) {
					if (evt.keyval == Gdk.Key_Down) {
						model.iter_next (ref sel);
					} else {
						path = model.get_path (sel);
						if (path.prev ()) {
							model.get_iter (out sel, path);
						} else {
							_treeview.get_selection ().select_iter (sel);
						}
					}
				} else {
					model = _treeview.get_model ();
					model.get_iter_first (out sel);
				}
				path = model.get_path (sel);
				_treeview.get_selection ().select_iter (sel);
				_treeview.scroll_to_cell (path, null, false, 0, 0);
				return true;
			} 
			return false;
		}
		
		public bool on_treeview_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			if ((evt.state & ModifierType.MOD1_MASK) == 0 &&
			     evt.keyval == Gdk.Key_Return) {
			     	if (_treeview.get_selection ().get_selected (null, null)) {
			     		_dialog.response (2);
			     	}
			}
			return false;
		}
		
		private void on_entry_text_changed (GLib.Object pspec, ParamSpec gobject)
		{
			string filter = _entry.get_text ();
			if (StringUtils.is_null_or_empty (filter)) {
				_current_pattern = null;
			} else {
				filter = StringUtils.replace (filter, " ", "*");
				if (!filter.has_suffix ("*"))
					filter += "*";
				if (!filter.has_prefix ("*"))
					filter = "*" + filter;
					
				_current_pattern = new PatternSpec (filter);
			}
			_model.refilter ();
			_sorted.set_sort_column_id (0, SortType.ASCENDING);
			select_result ();
		}

		private void select_result ()		
		{
			if (!_treeview.get_selection ().get_selected (null, null)) {
				TreePath path = new TreePath.from_indices (0);
				_treeview.get_selection ().select_path (path);
			}
			
			_button_ok.set_sensitive (_treeview.get_selection ().get_selected (null, null));
		}
		
		private bool filter_model (TreeModel model, TreeIter iter)
		{
			if (_current_pattern == null)
				return true;
				
			string val;
			model.get (iter, 0, out val);		
			return _current_pattern.match_string(val);
		}
		
		private int sort_model (TreeModel model, TreeIter a, TreeIter b)
		{
			string vala;
			string valb;
			
			model.get (a, 0, out vala);
			model.get (b, 0, out valb);
			
			return PathUtils.compare_vala_filenames (vala,valb);
		}
	}
}