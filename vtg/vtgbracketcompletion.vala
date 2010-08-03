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
	internal class BracketCompletion : GLib.Object 
	{
		private Vtg.PluginInstance _plugin_instance = null;
		private Gedit.View _view = null;
		private string tab_chars = "";

 		public Vtg.PluginInstance plugin_instance { get { return _plugin_instance; } construct { _plugin_instance = value; } }
		public Gedit.View view { get { return _view; } construct { _view = value; } }

		public BracketCompletion (Vtg.PluginInstance plugin_instance, Gedit.View view)
		{
			GLib.Object (plugin_instance: plugin_instance, view: view);
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
			disconnect_view (_view);
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

		private unowned string current_indentation_text (TextBuffer src)
		{
			weak TextMark mark = (TextMark) src.get_insert ();
			TextIter end;
			TextIter start;
			weak string text = "";
			int col;
			int line;
			
			src.get_iter_at_mark (out end, mark);
			col = end.get_line_offset ();
			if (col > 0) {
				line = end.get_line ();
				end.set_line_offset (0);

				start = end;
				unichar ch = end.get_char ();

				if (ch.isspace ()) {
					while (end.forward_char ()) {
						if (line != end.get_line ()) {
							end.backward_char ();
							break;
						} else if (end.starts_word ()) {
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
			}

			return text;
		}

		private void forward_skip_spaces (TextIter start)
		{
			if (start.get_char ().isspace ()) {
				while (start.forward_char ()) {
					if (!start.get_char ().isspace ()) {
						break;
					}
				}
			}
		}
		
		private void backward_skip_spaces (TextIter start)
		{
			while (start.backward_char ()) {
				if (!start.get_char ().isspace ()) {
					break;
				}
			}
		}
		
		private bool find_char (TextIter start, unichar char_to_find, unichar complementary_char, unichar[] stop_to_chars)
		{
			bool result = false;
			int level = 0;

			TextIter curr = start;
			do {
				unichar ch = curr.get_char ();
				bool stop_char_found = false;
				foreach (unichar stop_to_char in stop_to_chars) {
					if (ch == stop_to_char) {
						stop_char_found = true;
						break;
					}					
				}
				if (stop_char_found) {
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
					// check if I'm inside a  { } block 
					bool inside_block = false;
					TextIter start = pos;
					while (start.backward_char ()) {
						ch = start.get_char ();
 						if (ch == ';' || ch == '{') {
 							inside_block = true;
 							break;
 						} else if (ch == '}' || ch == '(' || ch == '|' || ch == '&') {
 							inside_block = false;
 							break;
 						}
 						
					}
					
					// check previous word
					if (inside_block) {
						start = pos;
						if (start.backward_word_start ()) {
							buffer = start.get_slice (pos);
							buffer = buffer.replace (" ", "").replace ("\t", "");
							// test if is a vala keyword
							if (buffer == "if" || buffer == "do" || buffer == "while"
							    || buffer.has_prefix ("for")) {
								inside_block = false;    	
							} else {
								// continue to move backward to really see if we are
								// inside a { } block
								while (start.backward_char ()) {
									ch = start.get_char ();
									if (ch == ';' || ch == '{' || ch == '=' || ch == '.') {
										break;
									} else if (ch != '\t' && ch != ' ' && ch != '\n' && ch != '\r') {
										inside_block = false;
										break;
									}
								}
							}
						}
					}

					bool prev_char_is_parenthesis = false;
					bool next_char_is_semicolon = false;
					
					start = pos;
					instance.backward_skip_spaces (start);
					prev_char_is_parenthesis = start.get_char () == '(';
					
					start = pos;
					instance.forward_skip_spaces (start);
					next_char_is_semicolon = start.get_char () == ';';
				
					if (src.has_selection) {
						if (instance.enclose_selection_with_delimiters (src, "(", ")")) {
							if (inside_block && !next_char_is_semicolon)
								instance.insert_chars (src, ";");
							src.get_iter_at_mark (out pos, mark);
							src.place_cursor (pos);
							result = true;
						}
					} else {
						if (prev_char_is_parenthesis || !instance.find_char (pos, ')', '(', new unichar[] {'}', ';'} )) {
							if (inside_block && !next_char_is_semicolon) {
								instance.insert_chars (src, ");");
								instance.move_backwards (src, 2);
							} else {
								instance.insert_chars (src, ")");
								instance.move_backwards (src, 1);
							}
						}
					}
				} else if (ch == '[') {
					if (!instance.find_char (pos, ']', '[', new unichar[] {'}', ';'})) {
						instance.insert_chars (src, "]");
						instance.move_backwards (src, 1);
					}
				} else if (ch == '*') {
					indent = instance.current_indentation_text (src);
					if (src.has_selection) {
						TextIter sel_start;
						TextIter sel_end;
					
						src.get_selection_bounds (out sel_start, out sel_end);
						sel_start.backward_char ();
						if (sel_start.get_char () == '/' && instance.enclose_selection_with_delimiters (src, "*", "*/")) {
							src.get_iter_at_mark (out pos, mark);
							src.place_cursor (pos);
							result = true;
						}
					} else {
						pos.backward_char ();
						if (pos.get_char () == '/') {

							buffer = "*  */";
							instance.insert_chars (src, buffer);
							sender.scroll_to_mark (mark, 0, false, 0, 0);
							instance.move_backwards (src, 3);
							result = true;
						}
					}
				} else if (ch == '{') {
					indent = instance.current_indentation_text (src);
					if (src.has_selection) {
						if (instance.enclose_selection_with_delimiters (src, "{", "\n%s}\n".printf (indent))) {
							src.get_iter_at_mark (out pos, mark);
							src.place_cursor (pos);
						}
						result = true;
					} else {
						buffer = "{";
						string line = null;
						if (pos.forward_line ()) {
							TextIter end = pos;
							end.forward_to_line_end ();
							line = pos.get_slice (end);
							line = line.replace (" ", "").replace ("\t", "");
						}
						if (StringUtils.is_null_or_empty (line) || line.has_prefix ("\n") || line.has_prefix ("}")) {
							buffer = "{\n%s%s\n%s}".printf(indent, instance.tab_chars, indent);	
							instance.insert_chars (src, buffer);
							sender.scroll_to_mark (mark, 0, false, 0, 0);
							instance.move_backwards (src, 2 + (int) indent.length);
							result = true;
						}
					}
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
							buffer = ";";
							TextIter tmp = pos;
							while (pos.backward_char ()) {
								ch = pos.get_char ();
								if (!ch.isspace ())
								{
									if (ch == ';') {
										buffer = ""; // line is already terminated with ;
									}
									pos.forward_char ();
									break;
								}
							}
							
							if (tmp.equal (pos)) {
								instance.insert_chars (src, "%s\n%s".printf(buffer, indent));
							} else {
								src.place_cursor (pos);
								if (buffer != "")
									instance.insert_chars (src, buffer);
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
						if (!instance.find_char (pos, '\"', '\"', new unichar[] {'}', ';'})) {
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
