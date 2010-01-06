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
	public enum FilteredListDialogColumns
	{
		NAME = 0,
		MARKUP,
		VISIBILITY,
		OBJECT,
		ICON,
		SELECTABLE,
		COLUMNS_COUNT
	}
	
	public class FilteredListDialog : GLib.Object
	{
		public static TreeStore create_model ()
		{
			return new Gtk.TreeStore (FilteredListDialogColumns.COLUMNS_COUNT, 
					typeof(string), 
					typeof(string), 
					typeof(bool), 
					typeof (GLib.Object), 
					typeof (Gdk.Pixbuf),
					typeof(bool));
		}
		
		private Gtk.Dialog _dialog;
		private Gtk.TreeView _treeview;
		private Gtk.Entry _entry;
		private Gtk.TreeModelFilter _filtered_model;
		private Gtk.TreeModelSort _sorted_model;
		private Gtk.TreeModel _child_model;
		private PatternSpec _current_pattern = null;
		private string _current_filter = null;
		private Gtk.Button _button_ok;
		
		public TreeIter selected_iter;
		
		public FilteredListDialog (TreeStore model, Gtk.TreeIterCompareFunc? compare_func = null)
		{
			this._child_model = model;
			initialize_ui (compare_func);
		}

		private void initialize_ui (Gtk.TreeIterCompareFunc? compare_func)
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
			_filtered_model = new Gtk.TreeModelFilter (_child_model, null);
			_filtered_model.set_visible_column (FilteredListDialogColumns.VISIBILITY);
			_child_model.row_changed += this.on_row_changed;
			
			var column = new TreeViewColumn ();
			
			CellRenderer renderer = new CellRendererPixbuf ();
 			column.pack_start (renderer, false);
			column.add_attribute (renderer, "pixbuf", FilteredListDialogColumns.ICON);
			
 			renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "markup", FilteredListDialogColumns.MARKUP);
			
			_treeview.append_column (column);
			
			_sorted_model = new Gtk.TreeModelSort.with_model (_filtered_model);
			_sorted_model.set_sort_column_id (Columns.NAME, SortType.ASCENDING);
			if (compare_func == null)
				_sorted_model.set_sort_func (Columns.NAME, this.sort_model);
			else
				_sorted_model.set_sort_func (Columns.NAME, compare_func);
			
			_treeview.set_model (_sorted_model);
			_treeview.get_selection ().set_mode (SelectionMode.SINGLE);
			_treeview.get_selection ().changed.connect (this.on_tree_selection_changed);
			_treeview.key_press_event.connect (on_treeview_key_press);
			_treeview.row_activated.connect  (on_row_activated);
			_treeview.expand_all ();
			
			/* select first row */
			if (!_treeview.get_selection ().get_selected (null, null)) {
				TreePath path = new TreePath.from_indices (0);
				_treeview.get_selection ().select_path (path);
			}

			_button_ok.set_sensitive (can_select_current_row());
		}

		public void set_transient_for (Gtk.Window parent)
		{
			_dialog.set_transient_for (parent);
		}
		
		public bool run ()
		{
			_dialog.set_modal (true);
			_dialog.show_all ();
			int dialog_result = _dialog.run ();
			if (dialog_result > 0) {
				TreeIter iter;
				if (_treeview.get_selection ().get_selected (null, out iter)) {
					TreeIter sort;
					_sorted_model.convert_iter_to_child_iter (out sort, iter);
					_filtered_model.convert_iter_to_child_iter (out selected_iter, sort);
				} else
					dialog_result = 0;
			}
			_dialog.destroy ();
			
			return dialog_result > 0;
		}
		
		private void on_row_activated (Widget sender, TreePath path, TreeViewColumn column)
		{
			if (can_select_current_row ())
				_dialog.response (2);
		}

		private void on_tree_selection_changed (Gtk.TreeSelection sender)
		{
			_button_ok.set_sensitive (can_select_current_row ());
		}
		
		private void on_row_changed (Gtk.TreeModel tree_model, Gtk.TreePath path, Gtk.TreeIter iter)
		{
			if (!_treeview.get_selection ().get_selected (null, null)) {
				TreeIter sel;
				tree_model.get_iter_first (out sel);
				_treeview.get_selection ().select_iter (sel);
			}
			_button_ok.set_sensitive (can_select_current_row ());
		}
		
		public bool on_entry_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			if (evt.keyval == Gdk.Key_Down || evt.keyval == Gdk.Key_Up) {
				TreeIter curr;
				TreeIter target;
				TreeModel model;
				TreePath path;
				
				if (_treeview.get_selection ().get_selected (out model, out curr)) {
					if (evt.keyval == Gdk.Key_Down) {
						if (model.iter_has_child(curr)) {
							model.iter_children (out target, curr);
						} else {
							target = curr;
							if (!model.iter_next (ref target)) {
								model.iter_parent (out target, curr);
								model.iter_next (ref target);
							}
						}
					} else {
						path = model.get_path (curr);
						if (!path.prev ()) {
							path.up ();
							model.get_iter (out target, path);
						} else {
							model.get_iter (out curr, path);
							if (model.iter_has_child(curr)) {
								int nch = model.iter_n_children (curr);
								model.iter_nth_child (out target, curr, nch - 1);
							} else {
								target = curr;
							}
						}
					}
				} else {
					model = _treeview.get_model ();
					model.get_iter_first (out target);
					path = model.get_path (target);
				}
				path = model.get_path (target);
				_treeview.get_selection ().select_iter (target);
				_treeview.scroll_to_cell (path, null, false, 0, 0);
				return true;
			} 
			return false;
		}
		
		public bool on_treeview_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			if ((evt.state & ModifierType.MOD1_MASK) == 0 &&
			     evt.keyval == Gdk.Key_Return) {
			     	if (can_select_current_row ()) {
			     		_dialog.response (2);
			     	}
			}
			return false;
		}
		
		private void on_entry_text_changed (GLib.Object pspec, ParamSpec gobject)
		{
			_current_filter = _entry.get_text ();
			if (StringUtils.is_null_or_empty (_current_filter)) {
				_current_pattern = null;
			} else {
				_current_filter = StringUtils.replace (_current_filter, " ", "*");
				if (!_current_filter.has_suffix ("*"))
					_current_filter += "*";
				if (!_current_filter.has_prefix ("*"))
					_current_filter = "*" + _current_filter;
					
				_current_pattern = new PatternSpec (_current_filter);
			}
			
			filter_and_highlight_rows ();
			_filtered_model.refilter ();
			_sorted_model.set_sort_column_id (0, SortType.ASCENDING);
			
			_button_ok.set_sensitive (can_select_current_row());
		}

		private bool can_select_current_row ()
		{
			bool res = false;
			TreeIter iter;
			
			if (_treeview.get_selection ().get_selected (null, out iter)) {
				TreeIter sort;
				TreeIter curr;
				_sorted_model.convert_iter_to_child_iter (out sort, iter);
				_filtered_model.convert_iter_to_child_iter (out curr, sort);
				_child_model.get (curr, FilteredListDialogColumns.SELECTABLE, out res);
			}
			return res;
		}
		
		private bool filter_and_highlight_row (TreeIter iter)
		{
			string val;
			 _child_model.get (iter, FilteredListDialogColumns.NAME, out val);
			bool res = true;
			string markup;

			if (_current_pattern != null)
				res = _current_pattern.match_string (val);

			if (res && _current_pattern != null) {
				string[] words = _current_filter.split ("*");
				markup = "";
				foreach (string word in words) {
					if (!StringUtils.is_null_or_empty (word)) {
						string[] pieces = val.split (word, 2);
						markup = markup.concat (pieces[0]);
						if (pieces.length == 2 || val.has_suffix (word)) {
							markup = markup.concat ("<b>", word, "</b>");
							if (pieces.length == 2)
								val = pieces[1];
							else {
								val = null;
								break;
							}
						}
					}
				}
			
				if (val != null) {
					markup = markup.concat (val);
				}
			} else {
				markup = val;
			}
			((TreeStore)  _child_model).set (iter, FilteredListDialogColumns.MARKUP, markup);
			((TreeStore)  _child_model).set (iter, FilteredListDialogColumns.VISIBILITY, res);
			
			return res;
		}
		
		private int filter_and_highlight_item (TreeIter iter)
		{
			int res = 0;
			bool eof = false;
			while (!eof) {
				if (filter_and_highlight_row (iter))
					res++;
					
				if (_child_model.iter_has_child (iter)) {
					TreeIter child;
					_child_model.iter_children (out child, iter);
					if (filter_and_highlight_item (child) != 0) {
						res++;
						((TreeStore)  _child_model).set (iter, FilteredListDialogColumns.VISIBILITY, true); // show the parent node
					}
				}
				
				eof =  !_child_model.iter_next (ref iter);
			}
			
			return res;
		}
		
		private void filter_and_highlight_rows ()
		{
			_child_model.row_changed -= this.on_row_changed;
			
			TreeIter iter;
			if (_child_model.get_iter_first (out iter))
				filter_and_highlight_item (iter);
			
			_child_model.row_changed += this.on_row_changed;
			_filtered_model.refilter ();
			_treeview.expand_all ();
		}
		
		private int sort_model (TreeModel model, TreeIter a, TreeIter b)
		{
			string vala;
			string valb;
			
			model.get (a, FilteredListDialogColumns.NAME, out vala);
			model.get (b, FilteredListDialogColumns.NAME, out valb);
			
			return PathUtils.compare_vala_filenames (vala,valb);
		}
	}
}
