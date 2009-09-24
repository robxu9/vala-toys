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
	internal class SymbolCompletionProvider : GLib.Object, Gsc.Provider
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
		private uint idle_id = 0;
		private bool all_doc = false; //this is a hack!!!

		private int prealloc_index = 0;
		private int counter = 0;

		private bool cache_building = false;
		private bool prev_cache_building = false;
		private bool tooltip_is_visible = false;

		private SymbolCompletionTrigger _last_trigger = null;
		private uint sb_msg_id = 0;
		private uint sb_context_id = 0;

		private Vtg.PluginInstance _plugin_instance;
		private Gsc.Info _calltip_window = null;

		private bool need_parse = true;
		private int current_edited_line = -1;
		
		public SymbolCompletion completion { construct { _completion = value;} }
		public Gedit.View view { construct { _view = value; } }
 		public Vtg.PluginInstance plugin_instance { construct { _plugin_instance = value; } default = null; }


		public SymbolCompletionProvider (Vtg.PluginInstance plugin_instance, Gedit.View view, SymbolCompletion completion)
		{
			this.plugin_instance = plugin_instance;
			this.completion = completion;
			this.view = view;
		}

		~SymbolCompletionProvider ()
		{
			_view.key_press_event -= this.on_view_key_press;
			this._completion.parser.caches_building -= this.on_cache_building;
			this._completion.parser.caches_builded -= this.on_cache_builded;
			
			if (sb_msg_id != 0) {
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				status_bar.remove (sb_context_id, sb_msg_id);
			}
			if (timeout_id != 0) {
				Source.remove (timeout_id);
			}
			if (idle_id != 0) {
				Source.remove (idle_id);
			}
			
			_completion.parser.remove_source_buffer (_sb);
		}
		
		construct { 
			try {
				var doc = (Gedit.Document) _view.get_buffer ();
				string name = Utils.get_document_name (doc);

				_sb = new Vsc.SourceBuffer (name, null);

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
				
				this._completion.parser.caches_building += this.on_cache_building;
				this._completion.parser.caches_builded += this.on_cache_builded;

				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				sb_context_id = status_bar.get_context_id ("symbol status");
				
				cache_building = true; 
				this.all_doc = true;
				this.parse (doc);
			} catch (Error err) {
				GLib.warning ("an error occourred: %s", err.message);
			}
		}


		private void on_cache_building (Vsc.ParserManager sender)
		{
			if (cache_building == false) {
				cache_building = true; 
				idle_id = Idle.add (this.on_idle);
			}			
		}
		
		private void on_cache_builded (Vsc.ParserManager sender)
		{
			if (cache_building == true) {
				cache_building = false;
				if (idle_id == 0)
					idle_id = Idle.add (this.on_idle);
			}
		}
		
		private bool on_idle ()
		{
			if (_plugin_instance == null)
				return false;
				
			if (cache_building && !tooltip_is_visible && prev_cache_building == false) {
				prev_cache_building = cache_building;
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				if (sb_msg_id != 0) {
					status_bar.remove (sb_context_id, sb_msg_id);
				}
				sb_msg_id = status_bar.push (sb_context_id, "rebuilding symbol cache...");
			} else if (cache_building == false && prev_cache_building == true) {
				prev_cache_building = false;
				//hide tip, show proposal list
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				status_bar.remove (sb_context_id, sb_msg_id);
				sb_msg_id = 0;
				if (_last_trigger != null) {
					var trigger = (SymbolCompletionTrigger) _last_trigger;
					trigger.trigger_event (trigger.shortcut_triggered);
				}
			}
			idle_id = 0;
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
			weak Gedit.Document doc = (Gedit.Document) _view.get_buffer ();
			weak TextMark mark = (TextMark) doc.get_insert ();
			TextIter start;
			doc.get_iter_at_mark (out start, mark);
			int line = start.get_line ();
			unichar ch = Gdk.keyval_to_unicode (evt.keyval);
			
			if (ch == '(') {
				this.show_calltip ();
			} else if (evt.keyval == Gdk.Key_Escape || ch == ')' || ch == ';' ||
					(evt.keyval == Gdk.Key_Return && (evt.state & ModifierType.SHIFT_MASK) != 0)) {
				this.hide_calltip ();
			}
			if (counter <= 0) {
				if (evt.keyval == Gdk.Key_Return || ch == ';') {
					this.all_doc = true;
					counter = 0; //immediatly (0.1sec)
					current_edited_line = -1;
				} else if (ch.isprint () 
					   || evt.keyval == Gdk.Key_Delete
					   || evt.keyval == Gdk.Key_BackSpace) {
					need_parse = true;
				} else if (evt.keyval == Gdk.Key_Up
					   || evt.keyval == Gdk.Key_Down) {
					current_edited_line = -1; //moved so a parse buffer is needed
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
			
			if (need_parse && current_edited_line != line) {
				need_parse = false;
				current_edited_line = line;
				timeout_id = Timeout.add (25, this.on_timeout_parse);
			}
			return false;
		}
		
		private void show_calltip ()
		{
			SymbolCompletionItem? completion_result = get_current_symbol_completion_item ();
			if (completion_result != null) {
				if (_calltip_window == null) {
					initialize_calltip_window ();
				}
				string calltip_text = completion_result.info;
				if (calltip_text != null) {
					_calltip_window.set_markup (calltip_text);
					_calltip_window.move_to_cursor (_view);
					_calltip_window.show_all ();
				}
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
			//_calltip_window.set_info_type (InfoType.EXTENDED);
			_calltip_window.set_transient_for (_plugin_instance.window);
			_calltip_window.set_adjust_width (true, 800);
			_calltip_window.set_adjust_height (true, 600);
			_calltip_window.allow_grow = true;
			_calltip_window.allow_shrink = true;
			
			//this is an hack
			var child = _calltip_window.get_child ();
			while (child != null && !(child is Gtk.Label)) {
				if (child is Bin) {
					child = ((Bin) child).get_child ();
				} else {
					child = null;
				}
				 
			}
			if (child is Gtk.Label) {
				var l = (Label) child;
				l.xalign = 0;
				l.xpad = 8;
			}
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
			transform_result (get_completions ((SymbolCompletionTrigger) trigger));
			timer.stop ();
			if (list.length () == 0 && cache_building) {
				_last_trigger = (SymbolCompletionTrigger) trigger;
			} else {
				_last_trigger = null;
			}
			return (owned) list;
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
				if (result.error_domains.size > 0) {
					append_symbols (result.error_domains, _icon_struct);
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
		}

		private void parse_current_line (bool skip_leading_spaces, out string symbolname, out string last_symbolname, out string line, out int lineno, out int colno)
		{
 			weak Gedit.Document doc = (Gedit.Document) _view.get_buffer ();
			weak TextMark mark = (TextMark) doc.get_insert ();
			TextIter end;
			TextIter start;
			unichar ch;
			
			doc.get_iter_at_mark (out start, mark);
			lineno = start.get_line ();
			
			//go to the right word boundary
			ch = start.get_char ();
			while (ch.isalnum ()) {
				start.forward_char ();
				int cline = start.get_line ();
				if (lineno != cline) //changed line?
				{
					start.backward_char ();
					break;
				}
				ch = start.get_char ();
			}

			colno = start.get_line_offset ();
			symbolname = "";
			last_symbolname = "";
			line = "";

			end = start;
			start.set_line_offset (0);
			line = start.get_text (end);
			
			if (colno > 0) {
				var tmp = new StringBuilder ();
			
				int bracket_lev_1 = 0;
				int bracket_lev_2 = 0;
				int bracket_lev_3 = 0;
				int string_lev = 0;
				int status = (skip_leading_spaces ? 1 : 0);
				unichar prev_char = end.get_char ();

				while (true) {
					if (!end.backward_char ())
						break; // end of buffer
						
					if (end.get_line_offset () == 0 || end.get_line () < lineno)
						break;

					ch = end.get_char ();
					
					if (status == 1 && (ch != ' ' && ch != '\t')) {
						status = 0; //back to normal
					} if (status == 0 && (ch == ' ' || ch == '\t' || 
						(ch == '(' && bracket_lev_1 == 0) ||
						(ch == '[' && bracket_lev_2 == 0) ||
						(ch == '{' && bracket_lev_3 == 0)))
						break; //word interruption

					switch (status) {
						case 0: //normal state
							if (ch == ')') {
								status = 2;
								bracket_lev_1++;
							} else if (ch == ']') {
								status = 2;
								bracket_lev_2++;
							} else if (ch == '}') {
								status = 2;
								bracket_lev_3++;
							} else if (ch == '.' || (ch == '-' && prev_char == '>')) {
								if (last_symbolname == "")
									last_symbolname = tmp.str.reverse ();
								if (ch == '-' && prev_char == '>')
									tmp.append_unichar ('.'); //all dots
								else
									tmp.append_unichar (ch);
								status = 1; //skip spaces
							} else if (ch == '=') {
								if (last_symbolname == "")
									last_symbolname = tmp.str.reverse ();
									
								tmp.truncate (0);
								status = 1; //skip spaces								
							} else if (ch == '\"') {
								string_lev++;
								status = 3;
							} else if (ch != '\n') {
								tmp.append_unichar (ch);
							}
							break;
						case 1: //skip spaces
							break;
						case 2: //skip to close bracket
							if (bracket_lev_1 > 0 && ch == '(') {
								bracket_lev_1--;
							} else if (bracket_lev_2 > 0 && ch == '[') {
								bracket_lev_2--;
							} else if (bracket_lev_3 > 0 && ch == '{') {
								bracket_lev_3--;
							} else if (ch == ')') {
								bracket_lev_1++;
							} else if (ch == ']') {
								bracket_lev_2++;
							} else if (ch == '{') {
								bracket_lev_3++;
							}
							if (bracket_lev_1 <= 0 && bracket_lev_2 <= 0 && bracket_lev_3 <= 0) {
								status = 1; //back to skip spaces
							}
							break;
						case 3: //inside string literal
							if (ch == '\"') {
								tmp.append ("string".reverse ());
								string_lev--;
								if (string_lev <= 0) {
									status = 0;
								}
							}
							break;
					}
					prev_char = ch;
				}
				symbolname = tmp.str.reverse ();
				if (last_symbolname == "")
					last_symbolname = symbolname;
			}
			
		}

		public SymbolCompletionItem? get_current_symbol_completion_item ()
		{
			string line, word, last_part;
			int lineno, colno;

			parse_current_line (true, out word, out last_part, out line, out lineno, out colno);

			if (word == null || word == "")
				return null;

			/* 
			  strip last type part. 
			  eg. for demos.demo.demo_method obtains
			  demos.demo + demo_method
			*/
			string first_part;
			if (word != last_part) {
				first_part = word.substring (0, word.length - last_part.length - 1);
			} else {
				first_part = "this"; //HACK: this won't work for static methods
			}
			string symbol_name = last_part;
			
			//don't try to find method signature if is a: for, foreach, if, while etc...
			if (is_vala_keyword (symbol_name)) {
				return null;
			}
			
			SymbolCompletionResult completion_result = null;
			completion_result = complete (null, line, first_part, lineno, colno);
			if (completion_result != null && completion_result.count > 0) {
				SymbolCompletionItem? item = null;
				
				item = search_completion_item_by_name (symbol_name, completion_result.methods);
				if (item != null)
					return item;
				
				item = search_completion_item_by_name (symbol_name, completion_result.properties);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.classes);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.interfaces);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.structs);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.fields);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.signals);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.others);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.namespaces);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.enums);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.constants);
				if (item != null)
					return item;

				item = search_completion_item_by_name (symbol_name, completion_result.error_domains);
				if (item != null)
					return item;

			}
			return null;
		}
		
		private SymbolCompletionItem? search_completion_item_by_name (string name, Gee.List<SymbolCompletionItem> items)
		{
			foreach (SymbolCompletionItem item in items) {
				if (item.name == name) {
					return item;
				}
			}
			return null;			
		}

		private SymbolCompletionResult? get_completions (SymbolCompletionTrigger trigger)
		{
			string line, word, last_part;
			int lineno, colno;

			parse_current_line (false, out word, out last_part, out line, out lineno, out colno);

			if (word == null && word == "")
				return null;

			
			return complete (trigger, line, word, lineno, colno);
		}
		
		private SymbolCompletionResult? complete (SymbolCompletionTrigger? trigger, string line, string word, int lineno, int colno)
		{
			SymbolCompletionResult result = null;
			try {
				string typename = null;
				var timer = new Timer ();
				typename = _completion.get_datatype_name_for_name (word, _sb.name, lineno + 1, colno);
				SymbolCompletionFilterOptions options = new SymbolCompletionFilterOptions ();
				options.public_only ();
				if (line.str ("= new ") != null || line.str ("=new ") != null) {
					options.constructors = true;
					options.instance_symbols = false;
					options.static_symbols = false;
				}
				bool search_error_domains = false;
				bool search_error_base = false;
				if (line.str ("throws ") != null) {
					search_error_domains = true;
					search_error_base = true;
				} else if (line.str ("throw ") != null) {
					search_error_domains = true;
				}
				
				if (typename != null) {
					options.static_symbols = false;
					options.error_domains = search_error_domains;
					options.error_base = search_error_base;
					if (word == "this") {
						options.private_symbols = true;
						options.protected_symbols = true;
					} else if (word == "base") {
						options.protected_symbols = true;
					}
					options.exclude_type = typename;						
					timer.start ();
					result = _completion.get_completions_for_name (options, typename, _sb.name, lineno + 1, colno);
					timer.stop ();
				} else {
					if (word.has_prefix ("this.") == false && word.has_prefix ("base.") == false) {
						options.static_symbols = true;
						options.interface_symbols = false;
						options.error_domains = search_error_domains;
						options.error_base = search_error_base;
						timer.start ();
						result = _completion.get_completions_for_name (options, word, _sb.name, lineno + 1, colno);
						timer.stop ();
						if (result.is_empty && (trigger == null || trigger.shortcut_triggered)) {
							timer.start ();
							typename = _completion.get_datatype_name_for_name ("this", _sb.name, lineno + 1, colno);
							if (typename != null) {
								options.defaults ();
								options.public_only ();
								options.error_domains = search_error_domains;
								options.error_base = search_error_base;
								options.constructors = true;
								options.static_symbols = true;
								options.private_symbols = true;
								options.protected_symbols = true;
								options.local_variables = true;
								options.imported_namespaces = true;
								result = _completion.get_completions_for_name (options, typename, _sb.name, lineno + 1, colno);
							}
							timer.stop ();
						}
					}
				}
			} catch (GLib.Error err) {
				GLib.warning ("%s", err.message);
			}
			
			return result;
		}
		
		private bool is_vala_keyword (string keyword)
		{
			return (keyword == "if"
				|| keyword == "for"
				|| keyword == "foreach"
				|| keyword == "while"
				|| keyword == "switch");
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
