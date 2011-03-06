/*
 *  vtgprojectsearchdialog.vala - Vala developer toys for GEdit
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
	public class ProjectSearchDialog : GLib.Object
	{
		private Gtk.Dialog _dialog;
		private Gtk.Entry _entry;
		private Gtk.Button _button_find;
		private Gtk.CheckButton _check_match_case;
				
		public string search_text = null;
		public bool match_case = false;
		
		public ProjectSearchDialog (Gtk.Window parent, string proposed_text = "")
		{
			initialize_ui (parent);
			_entry.set_text (proposed_text);
		}

		private void initialize_ui (Gtk.Window parent)
		{
			var builder = new Gtk.Builder ();
			try {
				builder.add_from_file (Utils.get_ui_path ("vtg.ui"));
			} catch (Error err) {
				GLib.warning ("initialize_ui: %s", err.message);
			}
			
			_dialog = (Gtk.Dialog) builder.get_object ("dialog-search");
			assert (_dialog != null);
			_dialog.set_transient_for (parent);			
			_button_find = (Gtk.Button) builder.get_object ("button_find");
			assert (_button_find != null);			
			_entry = (Gtk.Entry) builder.get_object ("entry_search");
			assert (_entry != null);
			_entry.notify["text"] += this.on_entry_text_changed;			
			_check_match_case = (Gtk.CheckButton) builder.get_object ("checkbutton_match_case");
			assert (_check_match_case != null);

			//defaults
			search_text = "";
			match_case = false;
			
			_entry.set_text (search_text);
			_check_match_case.set_active (match_case);
		}
		
		public int run ()
		{
			_dialog.set_modal (true);
			_dialog.show_all ();
			int dialog_result = _dialog.run ();
			if (dialog_result == ResponseType.OK) {
				search_text = _entry.get_text ();
				match_case = _check_match_case.get_active ();
			}
			_dialog.destroy ();
			
			return dialog_result;
		}		
		
		private void on_entry_text_changed (GLib.Object pspec, ParamSpec gobject)
		{
			_button_find.set_sensitive (_entry.get_text_length () > 0);
		}
	}
}
