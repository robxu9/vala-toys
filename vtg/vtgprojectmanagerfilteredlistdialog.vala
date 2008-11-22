/*
 *  vtgprojectmanagerfilteredlistdialog.vala - Vala developer toys for GEdit
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

namespace Vtg.ProjectManager
{
	public class FilteredListDialog : GLib.Object
	{
		private Gtk.Dialog _dialog;
		private Gtk.TreeView _treeview;
		private Gtk.Entry _entry;
		private Gtk.TreeModelFilter _model;
		private Gtk.TreeModel _child_model;
		private PatternSpec _current_pattern = null;
		
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
			_treeview = (Gtk.TreeView) builder.get_object ("treeview-db-docs");
			assert (_treeview != null);
			_entry = (Gtk.Entry) builder.get_object ("entry-db-filter");
			assert (_entry != null);
			_entry.key_press_event += this.on_entry_key_press;
			_model = new Gtk.TreeModelFilter (_child_model, null);
			_model.set_visible_func (this.filter_model);
			var column = new TreeViewColumn ();
 			CellRenderer renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", 0);
			_treeview.append_column (column);
			_treeview.set_model (_model);
			_treeview.get_selection ().set_mode (SelectionMode.SINGLE);
			_treeview.key_press_event += on_treeview_key_press;
		}

		public bool run ()
		{
			int result = _dialog.run ();
			if (result > 0) {
				TreeIter iter;
				if (_treeview.get_selection ().get_selected (null, out iter))
					_model.convert_iter_to_child_iter (out selected_iter, iter);
				else
					result = 0;
			}
			_dialog.destroy ();
			
			return result > 0;
		}
		
		public bool on_entry_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			if ((evt.state & ModifierType.MOD1_MASK) == 0 &&
			     evt.keyval == Gdk.Key_Return) {
				string filter = _entry.get_text ();
				if (filter == null || filter == "") {
					_current_pattern = null;
				} else {
					if (!filter.has_suffix ("*"))
						filter = "*%s*".printf (filter);
						
					_current_pattern = new PatternSpec (filter);
				}
				_model.refilter ();					
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
		
		private bool filter_model (Gtk.TreeModel model, TreeIter iter)
		{
			if (_current_pattern == null)
				return true;
				
			string val;
			model.get (iter, 0, out val);		
			return _current_pattern.match_string(val);
		}
	}
}
