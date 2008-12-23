/*
 *  vtgsymbolcompletiontrigger.vala - Vala developer toys for GEdit
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
using Gsc;

namespace Vtg
{
	public class SymbolCompletionTrigger : GLib.Object, Gsc.Trigger
	{
		private Gsc.Manager _completion;
		private string _trigger_name;
		private Gsc.ManagerEventOptions _opts;

		public Gsc.Manager completion { get { return _completion; } construct { _completion = value; } }
		public bool shortcut_triggered = false;
		public string trigger_name { construct { _trigger_name = value; } }

		public bool activate ()
		{
			var view = _completion.get_view ();
			view.key_press_event += this.on_view_key_press;
			view.get_buffer ().changed += this.on_buffer_changed;
			return true;
		}

		public bool deactivate ()
		{
			var view = _completion.get_view ();
			view.key_press_event -= this.on_view_key_press;			
			return true;
		}

		public weak string get_name ()
		{
			return this._trigger_name;
		}

		private void on_buffer_changed (Gtk.TextBuffer sender)
		{
			if (_completion.is_visible ()) {
				string delimiter;
				string filter = get_filter_word (sender, out delimiter);
				if (delimiter != "." && delimiter != "") {
					GLib.debug ("trigger finish completion, delimiter '%s'", delimiter);
					
					_completion.finish_completion ();
				} else  {
					Gsc.ManagerEventOptions opts;
					_completion.get_current_event_options (out opts);
					opts.filter_text = filter;
					_completion.update_event_options (opts);
				}
			}
		}


		public void complete_word ()
		{
			trigger_event (true);
		}
		
		private bool on_view_key_press (Gtk.TextView view, Gdk.EventKey event)
		{
			if (!_completion.is_visible ()) {
				if (event.keyval == '.' && 
				    (event.state & (ModifierType.SHIFT_MASK | ModifierType.META_MASK | ModifierType.CONTROL_MASK)) == 0) {
					trigger_event (false);
				}
			}
			return false;
		}

		private string get_filter_word (Gtk.TextBuffer doc, out string delimiter)
		{
 			weak TextMark mark = (TextMark) doc.get_insert ();
			TextIter end;
			TextIter start;
			string result;
			doc.get_iter_at_mark (out start, mark);
			end = start;
			int col = start.get_line_offset ();
			delimiter = "";
			while (col > 0) {
				start.backward_char ();
				result = start.get_text (end).strip ();
				unichar ch = start.get_char ();
				if (is_word_delimiter (ch)) {
					TextIter delim = start;
					start.forward_char ();
					delimiter = delim.get_text (start);
					break;
				}
				
				col--;
			}
			if (!StringUtils.is_null_or_empty (delimiter)) {
				delimiter = delimiter.replace (" ", ""); //TODO: replace with trim!
				delimiter = delimiter.replace ("\t", ""); //TODO: replace with trim!
			}
			result = start.get_text (end).strip ();
			return (result == null ? "" : result);
		}
		
		private bool is_word_delimiter (unichar ch)
		{
			return !ch.isalnum () && ch != '_';
		}

		public void trigger_event (bool trigger_reason)
		{
			_opts.position_type = PopupPositionType.CURSOR;
			_opts.filter_type = PopupFilterType.TREE_HIDDEN;
			_opts.autoselect = trigger_reason;
			_opts.show_bottom_bar = true;
			this.shortcut_triggered = trigger_reason;			
			_completion.trigger_event_with_opts (this._trigger_name, _opts, null);
			
			//if completion was trigger explicitly set the filter
			if (trigger_reason) {
				var view = _completion.get_view ();
				var doc = view.get_buffer ();
				string delimiter;
				string filter = get_filter_word (doc, out delimiter);
				Gsc.ManagerEventOptions opts;
				_completion.get_current_event_options (out opts);
				opts.filter_text = filter;
				_completion.update_event_options (opts);
			}			
		}

		public SymbolCompletionTrigger (Gsc.Manager completion, string trigger_name)
		{
			this.completion = completion;
			this.trigger_name = trigger_name;
		}
	}
}
