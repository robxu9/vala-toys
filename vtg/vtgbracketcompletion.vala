/*
 *  vtgbracketcompletion.vala - Vala developer toys for GEdit
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
	public class BracketCompletion : GLib.Object 
	{
		private Vtg.Plugin _plugin;
		private Gedit.View _view;
		private string tab_chars = "";

 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }
		public Gedit.View view { get { return _view; } construct { _view = value; } default = null; }

		public BracketCompletion (Vtg.Plugin plugin, Gedit.View view)
		{
			this.plugin = plugin;
			this.view = view;
		}

		construct	
		{
			if (Gedit.prefs_manager_get_insert_spaces ())
				tab_chars = string.nfill (Gedit.prefs_manager_get_tabs_size (), ' ');
			else
				tab_chars = "\t";

			connect_view (_view);
		}

		public void deactivate ()
		{
			GLib.debug ("bc deactvate");
			disconnect_view (_view);
			GLib.debug ("bc deactvated");
		}

		private void connect_view (Gedit.View view)
		{
			Signal.connect (view, "key-press-event", (GLib.Callback) on_view_key_press, this);
		}

		private void disconnect_view (Gedit.View view)
		{
			SignalHandler.disconnect_by_func (view, (void*) on_view_key_press, this);
		}

		private bool enclose_selection_with_delimiters (TextBuffer src, string start_delimiter, string? end_delimiter = null)
		{
			TextIter sel_start;
			TextIter sel_end;
					
			src.get_selection_bounds (out sel_start, out sel_end);
			var text = src.get_text (sel_start, sel_end, true);
			if (end_delimiter == null)
				end_delimiter = start_delimiter;

			if (text.has_prefix (start_delimiter) == false && text.has_suffix (end_delimiter) == false) {
				weak TextMark mark = (TextMark) src.get_insert ();
				TextIter pos;

				text = "%s%s%s".printf (start_delimiter, text, end_delimiter);
				src.begin_user_action ();
				src.delete_selection (true, true);
				src.get_iter_at_mark (out pos, mark);
				src.insert (pos, text, (int) text.len ());
				src.end_user_action ();
				return true;
			}

			return false;
		}

		private void insert_chars (TextBuffer src, string chars)
		{
			weak TextMark mark = (TextMark) src.get_insert ();
			TextIter pos;

			src.get_iter_at_mark (out pos, mark);
			src.begin_user_action ();
			src.insert (pos, chars, (int) chars.len ());
			src.end_user_action ();
		}

		private void move_backwards (TextBuffer src, int count)
		{
			weak TextMark mark = (TextMark) src.get_insert ();
			TextIter pos;

			src.get_iter_at_mark (out pos, mark);
			pos.backward_chars (count);
			src.place_cursor (pos);
		}

		private weak string current_indentation_text (TextBuffer src)
		{
			weak TextMark mark = (TextMark) src.get_insert ();
			TextIter end;
			TextIter start;
			weak string text = "";
			int col;

			src.get_iter_at_mark (out end, mark);
			col = end.get_line_offset ();
			end.set_line_offset (0);

			start = end;
			unichar ch = end.get_char ();

			if (ch.isspace ()) {
				while (end.forward_char ()) {
					if (end.starts_word ()) {
						break;
					} else if (end.get_line_offset () >= col) {
						break;
					} else {
						ch = end.get_char ();
						if (ch.isspace () == false) {
							break;
						}
					}
				}
			}

			if (!start.equal(end)) {
				text = start.get_text (end);
			}
			return text;
		}

		private bool find_char (TextIter start, unichar char_to_find, unichar complementary_char, unichar stop_to_char)
		{
			bool result = false;
			int level = 0;

			TextIter curr = start;
			do {
				unichar ch = curr.get_char ();
				if (ch == stop_to_char) {
					break;
				} else if (ch == char_to_find) {
					if (level == 0) {
						result = true;
						break;
					} else {
						level--;
					}
				} else if (ch == complementary_char) {
					level++;
				}
			} while (curr.forward_char ());

			return result;
		}

		private static bool on_view_key_press (Gedit.View sender, Gdk.EventKey evt, BracketCompletion instance)
		{
			bool result = false;
	
			if ((evt.state & ( ModifierType.MOD1_MASK)) == 0) {
 				var src = sender.get_buffer ();
				weak TextMark mark = (TextMark) src.get_insert ();
				TextIter pos;
				weak string indent;
				string buffer;
				unichar ch = Gdk.keyval_to_unicode (evt.keyval);

				src.get_iter_at_mark (out pos, mark);
				if (ch == '(') {
					if (src.has_selection) {
						if (instance.enclose_selection_with_delimiters (src, "(", ")")) {
							src.get_iter_at_mark (out pos, mark);
							src.place_cursor (pos);
							result = true;
						}
					} else {
						if (!instance.find_char (pos, ')', '(', ';')) {
							instance.insert_chars (src, ")");
							instance.move_backwards (src, 1);
						}
					}

				} else if (ch == '[') {
					if (!instance.find_char (pos, ']', '[', ';')) {
						instance.insert_chars (src, "]");
						instance.move_backwards (src, 1);
					}
				} else if (ch == '*') {
					pos.backward_char ();
					if (pos.get_char () == '/') {
						indent = instance.current_indentation_text (src);
						buffer = "*\n%s \n%s*/".printf(indent, indent);
						instance.insert_chars (src, buffer);
						sender.scroll_to_mark (mark, 0, false, 0, 0);
						instance.move_backwards (src, 2 + (int) indent.length + 1);
						result = true;
					}
				} else if (ch == '{') {
				        indent = instance.current_indentation_text (src);
					buffer = "{\n%s%s\n%s}".printf(indent, instance.tab_chars, indent);
				        instance.insert_chars (src, buffer);
					sender.scroll_to_mark (mark, 0, false, 0, 0);
					instance.move_backwards (src, 2 + (int) indent.length);
					result = true;
				} else if (evt.keyval == Gdk.Key_Return) {
					indent = instance.current_indentation_text (src);
					if ((evt.state & ModifierType.SHIFT_MASK) != 0) {
						//move to end line
						if (!pos.ends_line ()) {
							pos.forward_to_line_end ();
							src.place_cursor (pos);
						}
						if ((evt.state & ModifierType.CONTROL_MASK) == 0) {
							//move backward to first non blank char
							TextIter tmp = pos;
							while (pos.backward_char ()) {
								ch = pos.get_char ();
								if (!ch.isspace ())
								{
									pos.forward_char ();
									break;
								}
							}
							if (tmp.equal (pos)) {
								instance.insert_chars (src, ";\n%s".printf(indent));
							} else {
								src.place_cursor (pos);
								instance.insert_chars (src, ";");
								src.get_iter_at_mark (out pos, mark);
								pos.forward_to_line_end ();
								src.place_cursor (pos);
								instance.insert_chars (src, "\n%s".printf(indent));
							}

							sender.scroll_to_mark (mark, 0, false, 0, 0);
							//place cursor to end
							src.get_iter_at_mark (out pos, mark);
							src.place_cursor (pos);

						} else {
						
							buffer = "\n%s{\n%s%s\n%s}".printf(indent, indent, instance.tab_chars, indent);
							instance.insert_chars (src, buffer);
							sender.scroll_to_mark (mark, 0, false, 0, 0);
							instance.move_backwards (src, 2 + (int) indent.length);
						} 
						result = true;
					} else if (indent != null && indent != "") {
						instance.insert_chars (src, "\n%s".printf(indent));
						result = true;
						sender.scroll_to_mark (mark, 0, false, 0, 0);
					}
				} else if (ch == '\"' ) {
					if (src.has_selection) {
						if (instance.enclose_selection_with_delimiters (src, "\"")) {
							src.get_iter_at_mark (out pos, mark);
							src.place_cursor (pos);
							result = true;
						}
					} else {
						if (!instance.find_char (pos, '\"', '\"', ';')) {
							instance.insert_chars (src, "\"");
							instance.move_backwards (src, 1);
						}
					}
				}
			}
			return result;
		}
	}
}
