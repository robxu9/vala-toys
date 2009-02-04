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
	public class OutputView : GLib.Object
	{
		protected Vtg.Plugin _plugin;

		private Gee.List<ProcessWatchInfo> _processes = new Gee.ArrayList<ProcessWatchInfo> ();
		private StringBuilder line = new StringBuilder ();
		private TextBuffer _messages;
		private TextView _textview;
		
		private Gtk.ScrolledWindow _ui = null;
		
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public OutputView (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}
		
		~OutputView ()
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			panel.remove_item (_ui);
		}
		
		construct 
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			_messages = new TextBuffer (null);
			_textview = new TextView.with_buffer (_messages);
			_textview.key_press_event += this.on_textview_key_press;

			/* Change default font throughout the widget */
			weak Pango.FontDescription font_desc = Pango.FontDescription.from_string ("Monospace");
			_textview.modify_font (font_desc);
			_textview.set_wrap_mode (Gtk.WrapMode.CHAR);
			
			_ui = new Gtk.ScrolledWindow (null, null);
			_ui.add (_textview);
			_ui.show_all ();
			panel.add_item (_ui, _("Output"), null);
		}


		private bool on_textview_key_press (Gtk.TextView sender, Gdk.EventKey evt)
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

		private ProcessWatchInfo add_process_view (uint id)
		{
			var result = new ProcessWatchInfo (id);
			_processes.add (result);
			return result;
		}

		public virtual void start_watch (uint id, int stdo, int stde, int stdi = -1)
		{
			try {
				ProcessWatchInfo? target = find_process_by_id (id);

				if (target != null) {
					stop_watch (id);
				}
				target = add_process_view (id);

				if (stdi != -1) {
					target.stdin = new IOChannel.unix_new (stdi);
				}
				target.stdout = new IOChannel.unix_new (stdo);
				target.stdout_watch_id =  target.stdout.add_watch (IOCondition.IN, this.on_messages);
				target.stdout.set_flags (target.stdout.get_flags () | IOFlags.NONBLOCK);
				//target.stdout.set_buffered (false);
			        target.stderr = new IOChannel.unix_new (stde);
				target.stderr_watch_id = target.stderr.add_watch (IOCondition.IN, this.on_messages);
				target.stderr.set_flags (target.stderr.get_flags () | IOFlags.NONBLOCK);
				//target.stderr.set_buffered (false);
				line.erase (0, -1);
				//activate bottom pane if not visible
				var panel = _plugin.gedit_window.get_bottom_panel ();
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

		private bool on_messages (IOChannel source, IOCondition condition)
		{
			try {
				if (condition == IOCondition.IN) {
					string message = null;
					size_t len = 0;
					char[] buff = new char[1024];
					source.read_chars (buff, out len);
					while (len > 0) {
						if (message == null) {
							message = (string) buff;
						} else {
							message = message.concat ((string) buff);
						}
						source.read_chars (buff, out len);
					}

					if (!StringUtils.is_null_or_empty(message)) {
						log_message (message);
					}
				}
				return true;
			} catch (Error err) {
				GLib.warning ("Error reading from process %s", err.message);
				return false;
			}
		}

		public void log_message (string message)
		{
			if (message != null && message_added (message)) {
				var str = StringUtils.replace (message, "[1m", "");
				str = StringUtils.replace (str, "[m", "");
				_messages.insert_at_cursor (str, (int) str.length);
				_textview.scroll_mark_onscreen (_messages.get_insert ());
			}					
		}

		public void activate ()
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			panel.activate_item (_ui);
		}

		public virtual signal bool message_added (string message);
	}
}
