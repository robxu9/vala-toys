/*
 *  vtgparametersdialog.vala - Vala developer toys for GEdit
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

namespace Vtg.Interaction
{
	public class ParametersDialog
	{
		private Gtk.EntryCompletion _completion;
		private Gtk.Dialog _dialog;
		
		public ParametersDialog (string title, Gtk.Window parent, Gtk.ListStore completions)
		{
			initialize_ui (title, parent, completions);
		}
		
		~ParametersDialog ()
		{
			_dialog.destroy ();	
		}
		
		private void initialize_ui (string title, Gtk.Window parent, Gtk.ListStore completions)
		{
			var builder = new Gtk.Builder ();
			try {
				builder.add_from_file (Utils.get_ui_path ("vtg.ui"));
			} catch (Error err) {
				GLib.warning ("initialize_ui: %s", err.message);
			}
			
			_dialog = (Gtk.Dialog) builder.get_object ("dialog-ask-params");
			assert (_dialog != null);
			_dialog.set_title (title);
			_dialog.set_transient_for (parent);
			_completion = new Gtk.EntryCompletion ();
			_completion.set_model (completions);
			_completion.set_text_column (0);
			var entry = (Gtk.Entry) builder.get_object ("entry-params");
			entry.set_completion (_completion);
			
			TreeIter iter;
			if (completions.get_iter_first (out iter)) {
				string val;
				completions.get (iter, 0, out val);
				entry.set_text (val);
			}
		}

		public string parameters		
		{
			get {
				var en = (Gtk.Entry) _completion.get_entry ();
				
				return en.get_text ();
			}
		}
		public int run ()
		{
			return _dialog.run ();
		}
	}
}
