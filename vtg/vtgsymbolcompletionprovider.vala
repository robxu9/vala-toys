/*
 *  vtgsymbolcompletionprovider.vala - Vala developer toys for GEdit
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
using Vsc;

namespace Vtg
{
	public class SymbolCompletionProvider : GLib.Object, Gsc.Provider
	{
		private Vsc.SourceBuffer _sb = null;
		private SymbolCompletion _completion = null;
		private Gedit.View _view = null;
		private GLib.List<Gsc.Proposal> list;
		private Gdk.Pixbuf _icon_generic;
		private Gdk.Pixbuf _icon_field;
		private Gdk.Pixbuf _icon_method;
		private Gdk.Pixbuf _icon_class;
		private Gdk.Pixbuf _icon_struct;
		private Gdk.Pixbuf _icon_property;
		private Gdk.Pixbuf _icon_signal;
		private Gdk.Pixbuf _icon_iface;
		private Gdk.Pixbuf _icon_const;
		private Gdk.Pixbuf _icon_enum;
		private Gdk.Pixbuf _icon_namespace;
		private uint timeout_id = 0;
		private bool all_doc = false; //this is a hack!!!

		private int prealloc_index = 0;
		private int counter = 0;

		private bool cache_building = false;
		private bool prev_cache_building = false;
		private bool tooltip_is_visible = false;

		private SymbolCompletionTrigger _last_trigger = null;
		private uint sb_msg_id = 0;
		private uint sb_context_id = 0;

		private Vtg.Plugin _plugin;
		private Gsc.Info _calltip_window = null;

		public SymbolCompletion completion { construct { _completion = value;} }
		public Gedit.View view { construct { _view = value; } }
 		public Vtg.Plugin plugin { construct { _plugin = value; } default = null; }


		public SymbolCompletionProvider (Vtg.Plugin plugin, Gedit.View view, SymbolCompletion completion)
		{
			this.plugin = plugin;
			this.completion = completion;
			this.view = view;
		}

		construct { 
			try {
				var doc = (Gedit.Document) _view.get_buffer ();
				string name = doc.get_uri ();
				if (name == null) {
					name = doc.get_short_name_for_display ();
				}
				_sb = new Vsc.SourceBuffer (name, null);
				_sb.data = (void *) doc;

				_view.key_press_event += this.on_view_key_press;

				this._completion.parser.add_source_buffer (_sb);
				this._icon_generic = IconTheme.get_default().load_icon(Gtk.STOCK_FILE,16,IconLookupFlags.GENERIC_FALLBACK);
				this._icon_field = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-field-16.png"));
				this._icon_method = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-method-16.png"));
				this._icon_class = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-class-16.png"));
				this._icon_struct = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-structure-16.png"));
				this._icon_property = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-property-16.png"));
				this._icon_signal = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-event-16.png"));
				this._icon_iface = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-interface-16.png"));
				this._icon_enum = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-enumeration-16.png"));
				this._icon_const = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-literal-16.png"));
				this._icon_namespace = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-namespace-16.png"));
				
				this._completion.parser.cache_building += sender => { 
					if (cache_building == false) {
						cache_building = true; 
						Idle.add (this.on_idle);
					}
				};
				this._completion.parser.cache_builded += sender => { 
					if (cache_building == true) {
						cache_building = false; 
						Idle.add (this.on_idle);
					}
				};

				var status_bar = (Gedit.Statusbar) _plugin.gedit_window.get_statusbar ();
				sb_context_id = status_bar.get_context_id ("symbol status");
				
				cache_building = true; 
				this.all_doc = true;
				this.parse (doc);
			} catch (Error err) {
				GLib.warning ("an error occourred: %s", err.message);
			}
		}

		private bool on_idle ()
		{
			if (cache_building && !tooltip_is_visible && prev_cache_building == false) {
				prev_cache_building = cache_building;
				var status_bar = (Gedit.Statusbar) _plugin.gedit_window.get_statusbar ();
				if (sb_msg_id != 0) {
					status_bar.remove (sb_context_id, sb_msg_id);
				}
				sb_msg_id = status_bar.push (sb_context_id, "rebuilding symbol cache...");
			} else if (cache_building == false && prev_cache_building == true) {
				prev_cache_building = false;
				//hide tip, show proposal list
				var status_bar = (Gedit.Statusbar) _plugin.gedit_window.get_statusbar ();
				status_bar.remove (sb_context_id, sb_msg_id);
				sb_msg_id = 0;
				if (_last_trigger != null) {
					((SymbolCompletionTrigger) _last_trigger).trigger_event ();
				}
			}

			return false;
		}

		private bool on_timeout_parse ()
		{
			if (counter == 0) {
				this.parse ((Gedit.Document) _view.get_buffer ());
				this.timeout_id = 0;
				return false;
			} else {
				counter--;
				return true;
			}
		}

		private bool on_view_key_press (Gtk.TextView view, Gdk.EventKey evt)
		{
			unichar ch = Gdk.keyval_to_unicode (evt.keyval);
			if (ch == '(') {
				this.show_calltip ();
			} else if (evt.keyval == Gdk.Key_Escape) {
				this.hide_calltip ();
			}
			if (counter <= 0) {
				if (evt.keyval == Gdk.Key_BackSpace || 
				    evt.keyval == Gdk.Key_Return ||
				    (ch != 0 && ch != '.' && ch != ':')) {
					if (evt.keyval == Gdk.Key_Return || ch == ';') {
						this.hide_calltip ();
						this.all_doc = true;
						counter = 0; //immediatly (0.1sec)
					} else {
						this.all_doc = false;
						counter = 8; //0.8sec
					}
					timeout_id = Timeout.add (100, this.on_timeout_parse);
				}
			} else {
				if (evt.keyval == Gdk.Key_Return || ch == ';') {
					this.all_doc = true;
					counter = 0; //immediatly (0.1sec)
				} else {
					this.all_doc = false;
					counter = 5;
				}
			}
			return false;
		}

		private void show_calltip ()
		{
			SymbolCompletionItem result = find_method_signature ();
			if (result != null) {
				if (_calltip_window == null) {
					initialize_calltip_window ();
				}
				string calltip_text = result.info;
				if (calltip_text != null) {
					_calltip_window.set_markup (calltip_text);
					_calltip_window.move_to_cursor (_view);
					_calltip_window.show_all ();
				}
			} else {
				GLib.debug ("calltip no proposal found");
			}
		}

		private void hide_calltip ()
		{
			if (_calltip_window == null)
				return;

			_calltip_window.hide ();
		}

		private void initialize_calltip_window ()
		{
			_calltip_window = new Gsc.Info ();
			_calltip_window.set_info_type (InfoType.EXTENDED);
			_calltip_window.set_transient_for (_plugin.gedit_window);
			_calltip_window.set_adjust_width (true, 400);
			_calltip_window.set_adjust_height (true, 250);
		}

		private void parse (Gedit.Document doc)
		{
			var buffer = this.get_document_text (doc, this.all_doc);
			_sb.source = buffer;
			_completion.parser.reparse_source_buffers ();
		}

		public void finish ()
		{
			list = null;
		}

		public weak string get_name ()
		{
			return "SymbolCompletionProvider";
		}

		public GLib.List<Gsc.Proposal> get_proposals (Gsc.Trigger trigger)
		{
			var timer = new Timer ();
			transform_result (find_proposals ());
			timer.stop ();
			GLib.debug ("TOTAL TIME ELAPSED: %f", timer.elapsed ());
			if (list.length () == 0 && cache_building) {
				_last_trigger = (SymbolCompletionTrigger) trigger;
			} else {
				_last_trigger = null;
			}
			return #list;
		}

		private void append_symbols (Gee.List<SymbolCompletionItem> symbols, Gdk.Pixbuf icon)
		{
			weak Proposal[] proposals = Utils.get_proposal_cache ();

			foreach (SymbolCompletionItem symbol in symbols) {
				Proposal proposal;
				var name = (symbol.name != null ? symbol.name : "<null>");
				var info = (symbol.info != null ? symbol.info : "");
				
				if (prealloc_index < Utils.prealloc_count) {
					proposal = proposals [prealloc_index];
					prealloc_index++;

					proposal.label = name;
					proposal.info = info;
				        proposal.icon = icon;
				} else {
					proposal = new Proposal(name, info, icon);
				}
				this.list.append (proposal);
			}
			//sort list
			this.list.sort (this.proposal_sort);
		}

		private static int proposal_sort (void* a, void* b)
		{
			Proposal pa = (Proposal) a;
			Proposal pb = (Proposal) b;

			return strcmp (pa.get_label (), pb.get_label ());
		}

		private void transform_result (SymbolCompletionResult? result)
		{
			var timer = new Timer ();
			prealloc_index = 0;
			list = new GLib.List<Proposal> ();

			if (result != null && !result.is_empty) {
				if (result.fields.size > 0) {
					append_symbols (result.fields, _icon_field);
				}
				if (result.properties.size > 0) {
					append_symbols (result.properties, _icon_property);
				}
				if (result.methods.size > 0) {
					append_symbols (result.methods, _icon_method);
				}
				if (result.signals.size > 0) {
					append_symbols (result.signals, _icon_signal);
				}
				if (result.classes.size > 0) {
					append_symbols (result.classes, _icon_class);
				}
				if (result.interfaces.size > 0) {
					append_symbols (result.interfaces, _icon_iface);
				}
				if (result.structs.size > 0) {
					append_symbols (result.structs, _icon_struct);
				}
				if (result.enums.size > 0) {
					append_symbols (result.enums, _icon_enum);
				}
				if (result.constants.size > 0) {
					append_symbols (result.constants, _icon_const);
				}
				if (result.namespaces.size > 0) {
					append_symbols (result.namespaces, _icon_namespace);
				}				
				if (result.others.size > 0) {
					append_symbols (result.others, _icon_generic);
				}
			}

			timer.stop ();
			GLib.debug ("     TRANSFORM TOTAL TIME ELAPSED: %f", timer.elapsed ());
		}

		private void parse_current_line (bool skip_leading_spaces, out string word, out string line, out int lineno, out int colno)
		{
			var tmp = new StringBuilder ();
			
 			weak Gedit.Document doc = (Gedit.Document) _view.get_buffer ();
			weak TextMark mark = (TextMark) doc.get_insert ();
			TextIter end;
			TextIter start;

			doc.get_iter_at_mark (out start, mark);

			lineno = start.get_line ();
			colno = start.get_line_offset ();
			word = "";
			line = "";

			end = start;
			start.set_line_offset (0);
			line = start.get_text (end);

			if (colno > 1) {
				start = end;
				while (true) {
					start.backward_char ();
					if (start.starts_line ())
						break;

					unichar ch = start.get_char ();
					if (skip_leading_spaces && ch == ' ') {
						while (true) {
							start.backward_char ();
							if (start.starts_line ()) {
								break;								
							}
							ch = start.get_char ();
							if (ch != ' ')
								break;
						}
						start.forward_char ();
					} else if (ch == ')') {
						tmp.append_unichar (ch);
						//find where the method invocation begin
						while (true) {
							start.backward_char ();
							if (start.starts_line ())
								break;

							ch = start.get_char ();
							if (ch == '(') {
								tmp.append_unichar (ch);
								break;
							}
						}
						//skip spaces
						if (!start.starts_line ()) {
							while (true) {
								start.backward_char ();
								if (start.starts_line ())
									break;

								ch = start.get_char ();
								if (ch != ' ')
									break;
							}
						}
						if (!start.starts_line ()) {
							tmp.append_unichar (ch);
						}
					} else if (ch == '\"') {
						//find where the string literal begin
						tmp.append_unichar (ch);
						while (true) {
							start.backward_char ();
							if (start.starts_line ())
								break;

							ch = start.get_char ();
							tmp.append_unichar (ch);
							if (ch == '\"')
								break;
						}
					} else if (!(ch.isalnum () ||
					      ch == '.' ||
					      ch == '_')) {
						break;
					} else {
						tmp.append_unichar (ch);
					}
				}
				word = tmp.str.reverse ();
				GLib.debug ("word %s", word);
			}
		}

		private SymbolCompletionItem? find_method_signature ()
		{
			SymbolCompletionResult result = null;
			string line, word;
			int lineno, colno;

			parse_current_line (true, out word, out line, out lineno, out colno);

			if (word == null || word == "")
				return null;

			/* 
			  strip last type part. 
			  eg. for demos.demo.demo_method obtains
			  demos.demo + demo_method
			*/

			string[] tmp = word.split (".");
			int count = 0;
			string first_part = null;
			while (tmp[count] != null) {
				if (tmp [count+1] != null) {
					if (first_part == null)
						first_part = tmp[count];
					else
						first_part = first_part.concat (".", tmp[count]);
				}
				count++;
			}
			
			string method = tmp[count-1];
			if (first_part == null) {
				first_part = method;
			}
			
			try {			
				string typename = null;
				var dt = _completion.get_datatype_for_name (first_part, _sb.name, lineno + 1, colno);
				if (dt != null) {
					typename = _completion.get_qualified_name_for_datatype (dt);
				}

				SymbolCompletionFilterOptions options = new SymbolCompletionFilterOptions ();
				options.public_only ();				
				if (line.str ("= new ") != null || line.str ("=new ") != null) {
					options.only_constructors = true;
				}
				if (typename != null) {
					GLib.debug ("datatype '%s' for: %s",typename, word);
					options.static_symbols = false;
					if (word == "this") {
						options.private_symbols = true;
						options.protected_symbols = true;
					} else if (word == "base") {
						options.protected_symbols = true;
					}
					result = _completion.get_completions_for_name (options, typename, _sb.name);
				} else {
					if (first_part.has_prefix ("this.") == false && first_part.has_prefix ("base.") == false) {
						options.static_symbols = true;
						options.interface_symbols = false;
					
						result = _completion.get_completions_for_name (options, first_part, _sb.name);
					}
				}
			} catch (Error err) {
				GLib.warning ("error: %s", err.message);
			}
			if (result != null && result.methods.size > 0) {
				foreach (SymbolCompletionItem item in result.methods) {
					if (item.name == method) {
						return item;
					}
				}
			}
			return null;
		}

		private SymbolCompletionResult? find_proposals ()
		{
			SymbolCompletionResult result = null;
			string line, word;
			int lineno, colno;

			parse_current_line (false, out word, out line, out lineno, out colno);

			if (word == null && word == "")
				return null;

			try {
				string typename = null;
				var timer = new Timer ();
				if (word.has_prefix ("\"") && word.has_suffix ("\"")) {
					typename = "string";
				} else {
					typename = _completion.get_datatype_name_for_name (word, _sb.name, lineno + 1, colno);
				}
				
				SymbolCompletionFilterOptions options = new SymbolCompletionFilterOptions ();
				options.public_only ();
				if (line.str ("= new ") != null || line.str ("=new ") != null) {
					options.only_constructors = true;
				}
				if (typename != null) {
					GLib.debug ("datatype '%s' for: %s",typename, word);
					options.static_symbols = false;
					if (word == "this") {
						options.private_symbols = true;
						options.protected_symbols = true;
					} else if (word == "base") {
						options.protected_symbols = true;
					}
					options.exclude_type = typename;						

					timer.start ();
					//result = _completion.get_completions_for_name (options, "%s.".printf(typename), _sb.name);
					result = _completion.get_completions_for_name (options, typename, _sb.name);
					timer.stop ();
					GLib.debug ("find_by_name: %f", timer.elapsed ());
				} else {
					GLib.debug ("data type not found for: %s", word);
					if (word.has_prefix ("this.") == false && word.has_prefix ("base.") == false) {
						options.static_symbols = true;
						options.interface_symbols = false;
						timer.start ();
						//result = _completion.get_completions_for_name (options, "%s.".printf(word), _sb.name);
						result = _completion.get_completions_for_name (options, word, _sb.name);
						timer.stop ();
						GLib.debug ("find_by_name (static): %f, count %d", timer.elapsed (), result.count);
					}
				}
			} catch (GLib.Error err) {
				GLib.warning ("%s", err.message);
			}
			
			return result;
		}

		private string get_document_text (Gedit.Document doc, bool all_doc = false)
		{
			weak TextMark mark = (TextMark) doc.get_insert ();
			TextIter end;
			TextIter start;

			doc.get_iter_at_mark (out start, mark);
			string doc_text;
			if (all_doc || doc.is_untouched ()) {
				end = start;
				start.set_line_offset (0);
				while (start.backward_line ())
					;

				while (end.forward_line ())
					;
				
				doc_text = start.get_text (end);
			} else {
				end = start;
				end.set_line_offset (0);
				while (start.backward_line ())
					;

				string text1 = start.get_text (end);
				string text2 = "";
				//trick: jump the current edited row (there
				//are a lot of probability that this row will
				//cause a parser error)
				if (end.forward_line ()) {
					start = end;
					while (end.forward_line ())
						;

					text2 = start.get_text (end);
				}
				doc_text = "%s\n%s".printf (text1, text2);
			}
			
			return doc_text;
		}
	}

}
