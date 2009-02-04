/*
 *  vtgprojectexecuterdialog.vala - Vala developer toys for GEdit
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

namespace Vtg
{
	public class ProjectExecuterDialog
	{
		private Gtk.EntryCompletion _completion;
		private Gtk.Dialog _dialog;
		private TreeView _tree;
		private Button _button_exec;
		
		public ProjectExecuterDialog (Gtk.Window parent, ProjectManager project)
		{
			initialize_ui (parent, project);
		}
		
		~ProjectExecuterDialog ()
		{
			_dialog.destroy ();	
		}
		
		private void initialize_ui (Gtk.Window parent, ProjectManager project)
		{
			var completions = Vtg.Caches.get_executer_cache ();
			var builder = new Gtk.Builder ();
			try {
				builder.add_from_file (Utils.get_ui_path ("vtg.ui"));
			} catch (Error err) {
				GLib.warning ("initialize_ui: %s", err.message);
			}
			
			_dialog = (Gtk.Dialog) builder.get_object ("dialog-run");
			assert (_dialog != null);
			_dialog.set_transient_for (parent);
			_completion = new Gtk.EntryCompletion ();
			_completion.set_model (completions);
			_completion.set_text_column (0);
			var entry = (Gtk.Entry) builder.get_object ("entry-command-line");
			assert (entry != null);
			entry.set_completion (_completion);
			entry.key_press_event += this.on_entry_key_press;			
			entry.notify["text"] += this.on_command_line_changed;
			_button_exec = (Button) builder.get_object ("button-run-execute");
			assert (_button_exec != null);
			_tree = (Gtk.TreeView) builder.get_object ("treeview-executables");
			assert (_tree != null);
			var column = new TreeViewColumn ();
			var renderer = new CellRendererText ();
			column.pack_start (renderer, true);
			column.add_attribute (renderer, "text", 0);
			_tree.append_column (column);
			_tree.get_selection ().set_mode (SelectionMode.SINGLE);
			_tree.get_selection ().changed += this.on_tree_selection_changed;
			
			//initialize the project list
			var programs = project.exec_targets;
			TreeIter iter;
			ListStore list = new ListStore (2, typeof(string), typeof(string));
			foreach (string program in programs) {
				list.append (out iter);
				list.set (iter, 0, Path.get_basename (program), 1, program);
			}
			_tree.set_model (list);
			
			if (completions.get_iter_first (out iter)) {
				string val;
				completions.get (iter, 0, out val);
				entry.set_text (val);
				entry.set_position (-1);
			} else if (list.get_iter_first (out iter)) {
				string program;
				list.get (iter, 1, out program);
				entry.set_text (program);
				entry.set_position (-1);
			}
		}

		public string command_line		
		{
			get {
				var en = (Gtk.Entry) _completion.get_entry ();
				
				return en.get_text ();
			}
		}
		public int run ()
		{
			int res = _dialog.run ();
			string cmd = this.command_line;
			var cache = Vtg.Caches.get_executer_cache ();
			if (!StringUtils.is_null_or_empty (cmd) && !Vtg.Caches.cache_contains (cache, cmd)) {
				Vtg.Caches.cache_add (cache, cmd);
			}
			return res;
		}
		
		private void on_tree_selection_changed (TreeSelection treeselection)
		{
			ListStore model;
			TreeIter iter;
			
			if (treeselection.get_selected (out model, out iter)) {
				string program;
				model.get (iter, 1, out program);
				var entry = (Entry) _completion.get_entry ();
				entry.set_text (program);
				entry.set_position (-1);
			}
		}
		
		private void on_command_line_changed (GLib.Object pspec, ParamSpec gobject)
		{
			_button_exec.set_sensitive (!StringUtils.is_null_or_empty (((Entry) _completion.get_entry ()).get_text ()));
		}
		
		private bool on_entry_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			if (evt.keyval == Gdk.Key_Down || evt.keyval == Gdk.Key_Up) {
				TreeIter sel;
				TreeModel model;
				TreePath path;
				if (_tree.get_selection ().get_selected (out model, out sel)) {
					if (evt.keyval == Gdk.Key_Down) {
						model.iter_next (ref sel);
					} else {
						path = model.get_path (sel);
						if (path.prev ()) {
							model.get_iter (out sel, path);
						} else {
							_tree.get_selection ().select_iter (sel);
						}
					}
				} else {
					model = _tree.get_model ();
					model.get_iter_first (out sel);
				}
				path = model.get_path (sel);
				_tree.get_selection ().select_iter (sel);
				_tree.scroll_to_cell (path, null, false, 0, 0);
				return true;
			} 
			return false;
		}

	}
}
