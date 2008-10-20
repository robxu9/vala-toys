/*
 *  vtgprojectmanageroutputview.vala - Vala developer toys for GEdit
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
	public class OutputView : GLib.Object
	{
		protected Vtg.Plugin _plugin;
		//protected Project _project;

		private IOChannel _stdout = null;
		private IOChannel _stderr = null;
		private TextBuffer _messages;
		private TextView _textview;
		private uint _stdout_watch_id = 0;
		private uint _stderr_watch_id = 0;
		private Gtk.ScrolledWindow _ui = null;
		
 		//public Project project { get { return _project; } construct { _project = value; } default = null; }
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }

		public OutputView (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}

		construct 
		{
			var panel = _plugin.gedit_window.get_bottom_panel ();
			_messages = new TextBuffer (null);
			_textview = new TextView.with_buffer (_messages);
			_textview.set_editable (false);
			/* Change default font throughout the widget */
			weak Pango.FontDescription font_desc = Pango.FontDescription.from_string ("Monospace");
			_textview.modify_font (font_desc);

			_ui = new Gtk.ScrolledWindow (null, null);
			_ui.add (_textview);
			_ui.show_all ();
			panel.add_item (_ui, _("Output"), null);
		}

		public virtual void start_watch (int stdo, int stde)
		{
			try {
				_stdout = new IOChannel.unix_new (stdo);
				_stdout.add_watch (IOCondition.IN, this.on_messages);
				_stdout.set_flags (_stdout.get_flags () | IOFlags.NONBLOCK);
				_stderr = new IOChannel.unix_new (stde);
				_stderr.add_watch (IOCondition.IN, this.on_messages);
				_stderr.set_flags (_stderr.get_flags () | IOFlags.NONBLOCK);
			} catch (Error err) {
				GLib.warning ("error during watch setup: %s", err.message);
			}
		}

		public virtual void stop_watch ()
		{
			try {
				_stdout.flush ();
				_stderr.flush ();
				if (_stdout_watch_id != 0) {
					Source.remove (_stdout_watch_id);
				}
				if (_stderr_watch_id != 0) {
					Source.remove (_stderr_watch_id);
				}
				_stdout = null;
				_stderr = null;
			} catch (Error err) {
				GLib.warning ("error during stop_watch: %s", err.message);
			}
		}

		public void clean_output ()
		{
			_messages.set_text ("", 0);
		}

		private bool on_messages (IOChannel source, IOCondition condition)
		{
			try {
				string message;
				size_t len = 0;
				size_t term_pos = 0;
				source.read_line (out message, out len, out term_pos);
				while (len > 0) {
					if (message != null)
						log_message (message);
					source.read_line (out message, out len, out term_pos);
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
				_messages.insert_at_cursor (message, (int) message.length);
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