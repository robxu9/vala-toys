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
	class SymbolCompletionTrigger : GLib.Object, Gsc.Trigger
	{
		private Vtg.PluginInstance _plugin;
		private Gsc.Completion _completion;
		private string _trigger_name;
		private string _filter_proposal;

		public Gsc.Completion completion { get { return _completion; } construct { _completion = value; } }

		public bool shortcut_triggered = false;

		public string trigger_name { construct { _trigger_name = value; } }

		public string filter_proposal
		{
			get {
				return _filter_proposal;
			}
			set {
				if (_filter_proposal != value) {
					_filter_proposal = value;
					apply_filter ();
				}
			}
			default = null;
		}

		private bool activate ()
		{
			var view = _completion.get_view ();
			view.key_press_event += this.on_view_key_press;
			view.get_buffer ().changed += this.on_buffer_changed;
			Gsc.Info info = _completion.get_info_widget ();
			info.notify["visible"] += this.on_info_visible_changed;
			return true;
		}

		public bool deactivate ()
		{
			var view = _completion.get_view ();
			view.key_press_event -= this.on_view_key_press;
			view.get_buffer ().changed -= this.on_buffer_changed;
			Gsc.Info info = _completion.get_info_widget ();
			info.notify["visible"] -= this.on_info_visible_changed;
			return true;
		}

		public weak string get_name ()
		{
			return this._trigger_name;
		}

		private void on_buffer_changed (Gtk.TextBuffer sender)
		{
			if (_completion.visible) {
				string delimiter;
				string filter = get_filter_word (sender, out delimiter);
				if (delimiter != "." && delimiter != "") {
					_completion.finish_completion ();
				} else  {
					filter_proposal = filter;
				}
			}
		}


		public void complete_word ()
		{
			trigger_event (true);
		}
		
		private bool on_view_key_press (Gtk.TextView view, Gdk.EventKey event)
		{
			if (!_completion.visible) {
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
			this.shortcut_triggered = trigger_reason;
			_completion.trigger_event (this);
			Gsc.Info info = _completion.get_info_widget ();
			
			if (_plugin.plugin.config.info_window_visible && _completion.visible) {
				info.show ();
			}
			
			//if completion was trigger explicitly set the filter
			if (trigger_reason) {
				var view = _completion.get_view ();
				var doc = view.get_buffer ();
				string delimiter;
				string filter = get_filter_word (doc, out delimiter);
				filter_proposal = filter;
			} else {
				filter_proposal = null;
			}
		}

		private void on_info_visible_changed (Gsc.Info sender, GLib.ParamSpec param)
		{
			//only store the visible state if completion popup is active
			if (_completion.visible) {
				_plugin.plugin.config.info_window_visible = sender.visible;
			}
		}
		
		public SymbolCompletionTrigger (Vtg.PluginInstance plugin, Gsc.Completion completion, string trigger_name)
		{
			GLib.Object (completion: completion, trigger_name: trigger_name);
			this._plugin = plugin;
		}
		
		private void apply_filter ()
		{
			_completion.filter_proposals (this.apply_filter_proposal);
		}

		private bool apply_filter_proposal (Gsc.Proposal proposal)
		{
			return _filter_proposal == null || proposal.label.has_prefix (_filter_proposal);
		}
	}
}
