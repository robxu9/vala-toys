/*
 *  vtgoutputview.vala - Vala developer toys for GEdit
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
	public enum OutputTypes
	{
		MESSAGE,
		ERROR,
		CHILD_PROCESS,
		BUILD,
		AUTO_BUILD,
		SEARCH
	}
	
	internal class OutputView : GLib.Object
	{
		protected unowned Vtg.PluginInstance _plugin_instance = null;

		private Vala.List<ProcessWatchInfo> _processes = new Vala.ArrayList<ProcessWatchInfo> ();
		private StringBuilder line = new StringBuilder ();
		private TextBuffer _messages;
		private TextView _textview;
		
		private Gtk.ScrolledWindow _ui = null;
		private string[] keywords = new string[] {
			"checking",
			"Checking",
			"Running",
			"  testing"
		};
		
		public OutputView (Vtg.PluginInstance plugin_instance)
		{
			this._plugin_instance = plugin_instance;
			var panel = _plugin_instance.window.get_bottom_panel ();
			_messages = new TextBuffer (null);
			_messages.create_tag ("keyword", "weight", Pango.Weight.BOLD, null);

			_textview = new TextView.with_buffer (_messages);
			_textview.key_press_event.connect (this.on_textview_key_press);

			/* Change default font throughout the widget */
			Pango.FontDescription font_desc = Pango.FontDescription.from_string ("Monospace");
			_textview.modify_font (font_desc);
			_textview.set_wrap_mode (Gtk.WrapMode.CHAR);

			_ui = new Gtk.ScrolledWindow (null, null);
			_ui.add (_textview);
			_ui.show_all ();
			panel.add_item (_ui, "Output", _("Output"), null);
		}

		~OutputView ()
		{
			var panel = _plugin_instance.window.get_bottom_panel ();
			panel.remove_item (_ui);
		}

		private bool on_textview_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			if (evt.keyval == Gdk.Key_Return) {
				string buffer;

				if (line.len == 0)
					buffer = "\n";
				else
					buffer = "%s\n".printf(line.str);

				//TODO: find a way to select the target process
				foreach (ProcessWatchInfo item in _processes) {
					if (item.stdin != null) {
						size_t bw;
						try {
							item.stdin.write_chars ((char[]) buffer, out bw);
							item.stdin.flush ();
						} catch (Error err) {
							GLib.warning ("on_textview_key_press - error: %s", err.message);
						}
					}
				}
				line.erase (0, -1);
			} else {
				unichar ch = Gdk.keyval_to_unicode (evt.keyval);
				line.append_unichar (ch);
			}

			return false;
		}

		private ProcessWatchInfo? find_process_by_id (uint id)
		{
			foreach (ProcessWatchInfo target in _processes) {
				if (target.id == id) {
					return target;
				}
			}

			return null;
		}


		private ProcessWatchInfo? find_process_by_io_channel (IOChannel chan)
		{
			foreach (ProcessWatchInfo target in _processes) {
				if (target.stdout == chan
				    || target.stderr == chan) {
					return target;
				}
			}

			return null;
		}

		private ProcessWatchInfo add_process_view (uint id)
		{
			var result = new ProcessWatchInfo (id);
			_processes.add (result);
			return result;
		}

		public virtual void start_watch (OutputTypes output_type, uint id, int stdo, int stde, int stdi = -1)
		{
			try {
				ProcessWatchInfo target = find_process_by_id (id);

				if (target != null) {
					stop_watch (id);
				}
				target = add_process_view (id);
				target.output_type = output_type;
				
				if (stdi != -1) {
					target.stdin = new IOChannel.unix_new (stdi);
				}
				target.stdout = new IOChannel.unix_new (stdo);
				target.stdout_watch_id =  target.stdout.add_watch (IOCondition.IN | IOCondition.PRI, this.on_messages);
				target.stdout.set_flags (target.stdout.get_flags () | IOFlags.NONBLOCK);
				
			        target.stderr = new IOChannel.unix_new (stde);
				target.stderr_watch_id = target.stderr.add_watch (IOCondition.IN | IOCondition.PRI, this.on_messages);
				target.stderr.set_flags (target.stderr.get_flags () | IOFlags.NONBLOCK);

				line.erase (0, -1);
				
				//activate bottom pane if not visible
				var panel = _plugin_instance.window.get_bottom_panel ();
				if (!panel.visible)
					panel.show_all ();
				
			} catch (Error err) {
				GLib.warning ("error during watch setup: %s", err.message);
			}
		}

		public virtual void stop_watch (uint id)
		{
			ProcessWatchInfo? target = find_process_by_id (id);
			
			if (target == null) {
				GLib.warning ("stop_watch: no target with id %u found", id);
				return;
			}
			target.cleanup ();
			_processes.remove_at (_processes.index_of (target));
		}

		public void clean_output ()
		{
			_messages.set_text ("", 0);
		}

		private void log_channel (IOChannel source) throws GLib.Error
		{
			GLib.StringBuilder message = new GLib.StringBuilder ();
			size_t len = 0;
			char[] buff = new char[4096];
			IOStatus res = IOStatus.NORMAL;
			
			while (res == IOStatus.NORMAL) {
				res = source.read_chars (buff, out len);
				if (len > 0) {
					message.append_len ((string) buff, (ssize_t) len);
				}
			}
			
			if (message.len > 0) {
				var process = find_process_by_io_channel (source);
				OutputTypes output_type;
				if (process != null) {
					output_type = process.output_type;
				} else {
					output_type = OutputTypes.CHILD_PROCESS;
				}
				log_message (output_type, message.str);
			}
		}
		
		private bool on_messages (IOChannel source, IOCondition condition)
		{
			try {
				if ((condition & (IOCondition.IN | IOCondition.PRI)) != 0) {
					log_channel (source);
				}
				return true;
			} catch (Error err) {
				GLib.warning ("Error reading from process %s", err.message);
				return false;
			}
		}

		public void log_message (OutputTypes output_type, string message)
		{
			string[] lines = message.split ("\n");
			TextIter iter;
			_messages.get_iter_at_mark (out iter, _messages.get_insert ());

			for (int count = 0; count < lines.length; count++) {
				string line = lines[count];
				
				if (!StringUtils.is_null_or_empty(line)) {
					foreach (string keyword in keywords) {
						if (line.has_prefix (keyword)) {
							_messages.insert_with_tags_by_name (iter, keyword, -1, "keyword");
							line = line.substring (keyword.length);
						}
					}

					line = StringUtils.replace (line, "[1m", "");
					line = StringUtils.replace (line, "[m", "");
					line = StringUtils.replace (line, "(B", "");
				}

				if (count < (lines.length -1)) {
					if (line == null)
						line = "\n";
					else if (!line.has_suffix ("\n"))
						line += "\n";
				}

				if (!StringUtils.is_null_or_empty(line))
				{
					_messages.insert (ref iter, line, -1);
				}
			}
			_textview.scroll_mark_onscreen (_messages.get_insert ());
			message_added (output_type, message);			
		}

		public void activate ()
		{
			var panel = _plugin_instance.window.get_bottom_panel ();
			panel.activate_item (_ui);
		}

		public signal void message_added (OutputTypes output_type, string message);
	}
}
