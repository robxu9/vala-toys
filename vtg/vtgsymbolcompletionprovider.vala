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
using Afrodite;

namespace Vtg
{
	internal class SymbolCompletionProvider : GLib.Object, Gsc.Provider
	{
		private Afrodite.SourceItem _sb = null;
		private unowned Afrodite.CompletionEngine _completion = null;
		private Gedit.View _view = null;
		private GLib.List<Gsc.Proposal> _list;
		/*
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
		*/
		private uint _timeout_id = 0;
		private uint _idle_id = 0;
		private bool _all_doc = false; //this is a hack!!!

		private int _prealloc_index = 0;

		private bool _cache_building = false;
		private bool _prev_cache_building = false;
		private bool _tooltip_is_visible = false;

		private SymbolCompletionTrigger _last_trigger = null;
		private uint _sb_msg_id = 0;
		private uint _sb_context_id = 0;

		private Vtg.PluginInstance _plugin_instance;
		private Gsc.Info _calltip_window = null;

		private int _last_line = -1;
		private bool _doc_changed = false;
		
		
		public Afrodite.CompletionEngine completion { construct { _completion = value;} }
		public Gedit.View view { construct { _view = value; } }
 		public Vtg.PluginInstance plugin_instance { construct { _plugin_instance = value; } default = null; }


		public SymbolCompletionProvider (Vtg.PluginInstance plugin_instance, Gedit.View view, Afrodite.CompletionEngine completion)
		{
			this.plugin_instance = plugin_instance;
			this.completion = completion;
			this.view = view;
		}

		~SymbolCompletionProvider ()
		{
			if (_timeout_id != 0) {
				Source.remove (_timeout_id);
			}
			if (_idle_id != 0) {
				Source.remove (_idle_id);
			}
			
			_view.key_press_event -= this.on_view_key_press;
			var doc = (Gedit.Document) _view.get_buffer ();
			doc.notify["text"] -= this.on_text_changed;
			doc.notify["cursor-position"] -= this.on_cursor_position_changed;
			
			if (_sb_msg_id != 0) {
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				status_bar.remove (_sb_context_id, _sb_msg_id);
			}
		}
		
		construct { 
			try {
				var doc = (Gedit.Document) _view.get_buffer ();
				string name = Utils.get_document_name (doc);

				_sb = new Afrodite.SourceItem ();
				_sb.path = name;
				_sb.content = null;
				
				_view.key_press_event += this.on_view_key_press;
				doc.notify["text"] += this.on_text_changed;
				doc.notify["cursor-position"] += this.on_cursor_position_changed;
				
				/*
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
				*/
				
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				_sb_context_id = status_bar.get_context_id ("symbol status");
				
				_cache_building = true; 
				_all_doc = true;
				if (_completion.is_parsing) {
					_idle_id = Idle.add (this.on_idle, Priority.DEFAULT_IDLE);
				}
				_completion.begin_parsing += this.on_begin_parsing;
				_completion.end_parsing += this.on_end_parsing;
				
			} catch (Error err) {
				GLib.warning ("an error occourred: %s", err.message);
			}
		}
		
		private void on_begin_parsing (CompletionEngine engine)
		{
			_cache_building = true;
			_idle_id = Idle.add (this.on_idle, Priority.DEFAULT_IDLE);
			
		}
		
		private void on_end_parsing (CompletionEngine engine)
		{
			_cache_building = false;
			_idle_id = Idle.add (this.on_idle, Priority.DEFAULT_IDLE);
		}
		
		private int get_current_line_index (Gedit.Document? doc = null)
		{
			if (doc == null) {
				doc = (Gedit.Document) _view.get_buffer ();
			}
			
			// get current line
			unowned TextMark mark = (TextMark) doc.get_insert ();
			TextIter start;
			doc.get_iter_at_mark (out start, mark);
			return start.get_line ();	
		}
		
		private void schedule_reparse ()
		{
			if (_timeout_id == 0 && _doc_changed) {
				_timeout_id = Timeout.add (250, this.on_timeout_parse);
			}	
		}
		
		private void on_text_changed (GLib.Object sender, ParamSpec pspec)
		{
			_doc_changed = true;
			// parse text only on init or line changes
			if (_last_line == -1 || _last_line != get_current_line_index ()) {
				schedule_reparse ();
			}
		}
		
		private void on_cursor_position_changed (GLib.Object sender, ParamSpec pspec)
		{
			// parse text only on init or line changes
			if (_last_line == -1 || _last_line != get_current_line_index ()) {
				_all_doc = true;
				schedule_reparse ();
			}
		}
		
		private bool on_idle ()
		{
			if (_plugin_instance == null)
				return false;
				
			if (_cache_building && !_tooltip_is_visible && _prev_cache_building == false) {
				_prev_cache_building = _cache_building;
				/*
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				if (_sb_msg_id != 0) {
					status_bar.remove (_sb_context_id, _sb_msg_id);
				}
				_sb_msg_id = status_bar.push (_sb_context_id, _("rebuilding symbol cache for %s...").printf (_completion.id));*/
			} else if (_cache_building == false && _prev_cache_building == true) {
				_prev_cache_building = false;
				//hide tip, show proposal list
				/*
				var status_bar = (Gedit.Statusbar) _plugin_instance.window.get_statusbar ();
				status_bar.remove (_sb_context_id, _sb_msg_id);
				_sb_msg_id = 0;
				*/
				if (_last_trigger != null) {
					var trigger = (SymbolCompletionTrigger) _last_trigger;
					trigger.trigger_event (trigger.shortcut_triggered);
				}
			}
			_idle_id = 0;
			return false;
		}

		private bool on_timeout_parse ()
		{
			var doc = (Gedit.Document) _view.get_buffer ();
			parse (doc);
			_timeout_id = 0;
			_last_line = get_current_line_index (doc);
			return false;
		}

		private bool on_view_key_press (Gtk.TextView view, Gdk.EventKey evt)
		{
			unichar ch = Gdk.keyval_to_unicode (evt.keyval);
			
			if (ch == '(') {
				this.show_calltip ();
			} else if (evt.keyval == Gdk.Key_Escape || ch == ')' || ch == ';' ||
					(evt.keyval == Gdk.Key_Return && (evt.state & ModifierType.SHIFT_MASK) != 0)) {
				this.hide_calltip ();
			}
			if (evt.keyval == Gdk.Key_Return || ch == ';') {
				_all_doc = true; // new line or eol, reparse all source buffer
			} else if (ch.isprint () 
				   || evt.keyval == Gdk.Key_Delete
				   || evt.keyval == Gdk.Key_BackSpace) {
				_all_doc = false; // a change so reparse the buffer minus the current line
				_doc_changed = true;
			}
			return false;
		}
		
		private void show_calltip ()
		{
			Afrodite.Symbol? completion_result = get_current_symbol_item ();
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
			var buffer = this.get_document_text (doc, _all_doc);
			_sb.content = buffer;
			_completion.queue_source (_sb);
			_doc_changed = false;
		}

		public void finish ()
		{
			_list = null;
		}

		public weak string get_name ()
		{
			return "SymbolCompletionProvider";
		}

		public GLib.List<Gsc.Proposal> get_proposals (Gsc.Trigger trigger)
		{
			transform_result (get_completions ((SymbolCompletionTrigger) trigger));
			if (_list.length () == 0 && _cache_building) {
				_last_trigger = (SymbolCompletionTrigger) trigger;
			} else {
				_last_trigger = null;
			}
			return (owned) _list;
		}

		private void append_symbols (Gee.List<Afrodite.Symbol> symbols, bool include_private_symbols = true)
		{
			unowned Proposal[] proposals = Utils.get_proposal_cache ();

			
			foreach (Afrodite.Symbol symbol in symbols) {
				if (!include_private_symbols && symbol.access == Afrodite.SymbolAccessibility.PRIVATE)
					continue;

				Proposal proposal;
				var name = (symbol.display_name != null ? symbol.display_name : "<null>");
				var info = (symbol.info != null ? symbol.info : "");
				Gdk.Pixbuf icon = Utils.get_icon_for_type_name (symbol.type_name);
	
				if (_prealloc_index < Utils.prealloc_count) {
					proposal = proposals [_prealloc_index];
					_prealloc_index++;

					proposal.label = name;
					proposal.info = info;
				        proposal.icon = icon;
				} else {
					proposal = new Proposal(name, info, icon);
				}
				_list.append (proposal);
			}
			//sort list
			_list.sort (this.proposal_sort);
		}

		private static int proposal_sort (void* a, void* b)
		{
			Proposal pa = (Proposal) a;
			Proposal pb = (Proposal) b;

			return strcmp (pa.get_label (), pb.get_label ());
		}

		private void transform_result (Afrodite.Symbol? result)
		{
			var timer = new Timer ();
			_prealloc_index = 0;
			_list = new GLib.List<Proposal> ();

			if (result != null) {
				if (result.has_children) {
					append_symbols (result.children);
				}
				if (result.has_base_types 
				    && (result.type_name == "Class" || result.type_name == "Interface" || result.type_name == "Struct")) {
				    	GLib.debug ("base type for %s-%s", result.name, result.type_name);
					
					foreach (DataType type in result.base_types) {
						GLib.debug ("----> base type for %s-%s", type.name, type.type_name);
						if (!type.unresolved 
						    && (type.symbol.type_name == "Class" || type.symbol.type_name == "Interface")) {
							if (type.symbol.has_children) {
								// symbols of base types (classes or interfaces)
								append_symbols (type.symbol.children, false);
							}
						}
					}
				} else {
					GLib.debug ("NO base type for %s-%s", result.name, result.type_name);
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
				int bracket_lev_4 = 0;
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
					} if (status == 0 && (ch == ' ' || ch == '\t' || ch == '!' ||
						(ch == '(' && bracket_lev_1 == 0) ||
						(ch == '[' && bracket_lev_2 == 0) ||
						(ch == '{' && bracket_lev_3 == 0) ||
						(ch == '<' && bracket_lev_4 == 0)))
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
							} else if (ch != '-' && prev_char == '>') {
								status = 2;
								bracket_lev_4++;
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
							} else if (bracket_lev_4 > 0 && ch == '<') {
								bracket_lev_4--;
							} else if (ch == ')') {
								bracket_lev_1++;
							} else if (ch == ']') {
								bracket_lev_2++;
							} else if (ch == '{') {
								bracket_lev_3++;
							} else if (ch == '<') {
								bracket_lev_4++;
							}
							if (bracket_lev_1 <= 0 && bracket_lev_2 <= 0 && bracket_lev_3 <= 0 && bracket_lev_4 <= 0) {
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

		public Afrodite.Symbol? get_current_symbol_item ()
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
			
			GLib.debug ("get_current_symbol_item for %s, %s", first_part, symbol_name);
			
			Afrodite.Symbol? result = null;
			result = complete (null,  null, first_part, lineno, colno);
			if (result != null && result.has_children) {
				foreach (Symbol? symbol in result.children) {
					if (symbol.name == symbol_name) {
						GLib.debug ("get_current_symbol_item found %s", symbol_name);
						
						return symbol;
					}
				}
			}
			return null;
		}

		private Symbol? get_completions (SymbolCompletionTrigger trigger)
		{
			string whole_line, word, last_part;
			int line, column;

			parse_current_line (false, out word, out last_part, out whole_line, out line, out column);

			if (word == null && word == "")
				return null;

			
			return complete (trigger, whole_line, word, line, column);
		}
		
		private Afrodite.Symbol? complete (SymbolCompletionTrigger? trigger, string? whole_line, string word, int line, int column)
		{
			GLib.debug ("complete %s for %s in %d,%d", word, _sb.path, line, column);
			Afrodite.Symbol result = null;
			Afrodite.Ast ast;
			if (_completion.try_acquire_ast (out ast)) {
				var sym = ast.lookup_name_for_type_at (word, _sb.path, line, column, LookupCompareMode.EXACT);
				if (sym != null) {
					DetachCopyOptions options = null;
					
					if (whole_line != null) {
						if (whole_line.str ("= new ") != null || whole_line.str ("=new ") != null) {
							options = DetachCopyOptions.creation_methods ();
						} else if (whole_line.str ("=") != null) {
							options = DetachCopyOptions.factory_methods ();
						} else if (whole_line.str ("throws ") != null || whole_line.str ("throw ") != null) {
							options = DetachCopyOptions.error_domains ();
						}
					}
					
					if (options == null)
						options = DetachCopyOptions.standard ();

					result = sym.detach_copy (1, options);
				}
				_completion.release_ast (ast);
			}
			return result;
/*
			try {
				string typename = null;
				
				
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
					result = _completion.get_completions_for_name (options, typename, _sb.name, lineno + 1, colno);
				} else {
					if (!word.has_prefix ("this.") && !word.has_prefix ("base.")) {
						options.static_symbols = true;
						options.interface_symbols = false;
						options.error_domains = search_error_domains;
						options.error_base = search_error_base;
						result = _completion.get_completions_for_name (options, word, _sb.name, lineno + 1, colno);
						if (result.is_empty && (trigger == null || trigger.shortcut_triggered)) {
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
						}
					}
				}
			} catch (GLib.Error err) {
				GLib.warning ("%s", err.message);
			}
			
			return result;
*/
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
