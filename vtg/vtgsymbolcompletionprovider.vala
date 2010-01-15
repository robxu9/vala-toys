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
		private GLib.List<Gsc.Proposal> _list;
		
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

		private Gsc.Info _calltip_window = null;

		private int _last_line = -1;
		private bool _doc_changed = false;
		
		private unowned SymbolCompletion _symbol_completion = null;
		private unowned CompletionEngine _completion = null;
		
		public SymbolCompletionProvider (Vtg.SymbolCompletion symbol_completion)
		{
			_symbol_completion = symbol_completion;
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			string name = Utils.get_document_name (doc);

			_sb = new Afrodite.SourceItem ();
			_sb.path = name;
			_sb.content = doc.text;
			
			_symbol_completion.view.key_press_event += this.on_view_key_press;
			doc.notify["text"] += this.on_text_changed;
			doc.notify["cursor-position"] += this.on_cursor_position_changed;
			
			var status_bar = (Gedit.Statusbar) _symbol_completion.plugin_instance.window.get_statusbar ();
			_sb_context_id = status_bar.get_context_id ("symbol status");
			
			_cache_building = true; 
			_all_doc = true;
			_symbol_completion.notify["completion-engine"].connect (this.on_completion_engine_changed);
			_completion = _symbol_completion.completion_engine;
			if (_completion.is_parsing) {
				_idle_id = Idle.add (this.on_idle, Priority.DEFAULT_IDLE);
			}
			setup_completion (_completion);
		}

		~SymbolCompletionProvider ()
		{
			if (_timeout_id != 0) {
				Source.remove (_timeout_id);
			}
			if (_idle_id != 0) {
				Source.remove (_idle_id);
			}
			
			_symbol_completion.view.key_press_event -= this.on_view_key_press;
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			_symbol_completion.notify["completion-engine"].disconnect (this.on_completion_engine_changed);
			doc.notify["text"] -= this.on_text_changed;
			doc.notify["cursor-position"] -= this.on_cursor_position_changed;
			
			if (_sb_msg_id != 0) {
				var status_bar = (Gedit.Statusbar) _symbol_completion.plugin_instance.window.get_statusbar ();
				status_bar.remove (_sb_context_id, _sb_msg_id);
			}
		}
		
		private void setup_completion (CompletionEngine? engine)
		{
			if (engine == null)
				return;

			engine.begin_parsing += this.on_begin_parsing;
			engine.end_parsing += this.on_end_parsing;
		}
		
		private void cleanup_completion (CompletionEngine? engine)
		{
			if (engine != null)
				return;

			engine.begin_parsing += this.on_begin_parsing;
			engine.end_parsing += this.on_end_parsing;			
		}
		
		private void on_completion_engine_changed (GLib.Object sender, ParamSpec pspec)
		{
			// cleanup previous completion engine instance
			cleanup_completion (_completion);
			_completion = _symbol_completion.completion_engine;
			// setup new completion engine instance
			setup_completion (_completion);
		}
		
		private void on_begin_parsing (CompletionEngine engine)
		{
			_cache_building = true;
			if (_idle_id == 0)
				_idle_id = Idle.add (this.on_idle, Priority.DEFAULT_IDLE);
		}
		
		private void on_end_parsing (CompletionEngine engine)
		{
			_cache_building = false;
			if (_idle_id == 0)
				_idle_id = Idle.add (this.on_idle, Priority.DEFAULT_IDLE);
		}
		
		private int get_current_line_index (Gedit.Document? doc = null)
		{
			if (doc == null) {
				doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
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
				_all_doc = true;
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
			if (_symbol_completion.plugin_instance == null)
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
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
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
					_calltip_window.move_to_cursor (_symbol_completion.view);
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
			_calltip_window.set_transient_for (_symbol_completion.plugin_instance.window);
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
			build_proposal_item_list ((SymbolCompletionTrigger) trigger);

			if (_list.length () == 0 && _cache_building) {
				_last_trigger = (SymbolCompletionTrigger) trigger;
			} else {
				_last_trigger = null;
			}
			return (owned) _list;
		}

		private void append_symbols (Afrodite.QueryOptions? options, Vala.List<Afrodite.Symbol> symbols, bool include_private_symbols = true)
		{
			unowned Proposal[] proposals = Utils.get_proposal_cache ();

			
			foreach (Afrodite.Symbol symbol in symbols) {
				if ((!include_private_symbols && symbol.access == Afrodite.SymbolAccessibility.PRIVATE)
					|| symbol.name == "new")
					continue;

				if (options == null || symbol.check_options (options)) {
					Proposal proposal;
					string name;

					if (symbol.type_name == "CreationMethod") {
						name = symbol.name;
					} else {
						name = (symbol.display_name != null ? symbol.display_name : "<null>");
					}
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

		private void transform_result (Afrodite.QueryOptions? options, Afrodite.QueryResult? result)
		{
			_prealloc_index = 0;
			_list = new GLib.List<Proposal> ();

			if (result != null && !result.is_empty) {
				foreach (ResultItem item in result.children) {
					var symbol = item.symbol;
					if (options == null || symbol.check_options (options)) {
						if (symbol.has_children) {
							append_symbols (options, symbol.children);
						}
						
						append_base_type_symbols (options, symbol);
					}
				}
			}
		}

		private void append_base_type_symbols (Afrodite.QueryOptions? options, Symbol symbol)
		{
			if (symbol.has_base_types 
			    && (symbol.type_name == "Class" || symbol.type_name == "Interface" || symbol.type_name == "Struct")) {
				foreach (DataType type in symbol.base_types) {
					if (!type.unresolved 
					    && type.symbol.has_children
					    && (options == null || type.symbol.check_options (options))
					    && (type.symbol.type_name == "Class" || type.symbol.type_name == "Interface")) {
							// symbols of base types (classes or interfaces)
							append_symbols (options, type.symbol.children, false);
							append_base_type_symbols (options, type.symbol);
					}
				}
			} else {
				GLib.debug ("NO base type for %s-%s", symbol.name, symbol.type_name);
			}
		}

		private void parse_current_line (bool skip_leading_spaces, out string symbolname, out string last_symbolname, out string line, out int lineno, out int colno)
		{
 			weak Gedit.Document doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			weak TextMark mark = (TextMark) doc.get_insert ();
			TextIter end;
			TextIter start;
			unichar ch;
			
			doc.get_iter_at_mark (out start, mark);
			lineno = start.get_line ();
			
			//go to the right word boundary
			ch = start.get_char ();
			while (ch.isalnum () || ch == '_') {
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

			string symbol_name = last_part;
			
			//don't try to find method signature if is a: for, foreach, if, while etc...
			if (is_vala_keyword (symbol_name)) {
				return null;
			}
			
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
			
			GLib.debug ("get_current_symbol_item for %s, %s", first_part, symbol_name);
			Afrodite.Ast ast;
			Afrodite.Symbol? symbol = null;
			
			if (_completion.try_acquire_ast (out ast)) {
				Afrodite.QueryResult? result = null;
				Afrodite.QueryOptions options = this.get_options_for_line (line);			
				
				result = get_symbol_for_name (options, ast, null,  first_part, null,  lineno, colno);
				if (result != null && !result.is_empty) {
					var first = result.children.get (0);
					symbol = get_symbol_for_name_in_children (symbol_name, first.symbol);
					if (symbol == null)
						symbol =  get_symbol_for_name_in_base_types (symbol_name, first.symbol);
				}
				_completion.release_ast (ast);
			}
			return symbol;
		}

		private Afrodite.Symbol? get_symbol_for_name_in_children (string symbol_name, Symbol parent)
		{
			if (parent.has_children) {
				foreach (Symbol? symbol in parent.children) {
					if (symbol.name == symbol_name) {
						return symbol;
					}
				}
			}
			
			return null;
		}
		
		private Afrodite.Symbol? get_symbol_for_name_in_base_types (string symbol_name, Symbol parent) 
		{
			if (parent.has_base_types) {
				foreach  (DataType t in parent.base_types) {
					if (t.symbol != null)  {
						var base_symbol = get_symbol_for_name_in_children (symbol_name, t.symbol);
						if (base_symbol == null) {
							base_symbol = get_symbol_for_name_in_base_types (symbol_name, t.symbol);
						}
						
						if (base_symbol != null)
							return base_symbol;
					}
				}
			}			
			return null;
		}
		
		private QueryOptions get_options_for_line (string line)
		{
			QueryOptions options = null;
			
			if (line != null) {
				if (line.str ("= new ") != null || line.str ("=new ") != null) {
					options = QueryOptions.creation_methods ();
				} else if (line.str ("=") != null) {
					options = QueryOptions.standard ();
				} else if (line.str ("throws ") != null || line.str ("throw ") != null) {
					options = QueryOptions.error_domains ();
				}
			}
		
			if (options == null)
				options = QueryOptions.standard ();
				
			/*
			if (word == "base") {
				options.access = Afrodite.SymbolAccessibility.PUBLIC 
					| Afrodite.SymbolAccessibility.PROTECTED 
					| Afrodite.SymbolAccessibility.INTERNAL;
			} else if (word != "this") {
				options.access = Afrodite.SymbolAccessibility.PUBLIC 
					| Afrodite.SymbolAccessibility.INTERNAL;						
			}
			*/
			
			options.auto_member_binding_mode = true;
			options.compare_mode = CompareMode.EXACT;
			return options;
		}

		private void build_proposal_item_list (SymbolCompletionTrigger trigger)
		{
			string whole_line, word, last_part;
			int line, column;

			parse_current_line (false, out word, out last_part, out whole_line, out line, out column);

			Afrodite.Ast ast = null;			
			if (!StringUtils.is_null_or_empty (word) 
			    && _completion.try_acquire_ast (out ast)) {
			        QueryOptions options = get_options_for_line (whole_line);
        			Afrodite.QueryResult result = null;
        			
				result = get_symbol_for_name (options, ast, trigger, word, whole_line, line, column);
				transform_result (options, result);
				_completion.release_ast (ast);
			} else {
				if (!StringUtils.is_null_or_empty (word))
					GLib.debug ("build_proposal_item_list: couldn't acquire ast lock");
					
				transform_result (null, null);
			}
		}
		
		private Afrodite.QueryResult? get_symbol_for_name (QueryOptions options, Afrodite.Ast ast, SymbolCompletionTrigger? trigger, string word, string? whole_line, int line, int column)
		{
			GLib.debug ("get_symbol_for_name: %s for %s in %d,%d", word, _sb.path, line, column);
			Afrodite.QueryResult result = null;
			Timer timer = new Timer ();
			timer.start ();
			result = ast.get_symbol_type_for_name_and_path (options, word, _sb.path, line, column);
			timer.stop ();
			GLib.debug ("get_symbol_for_name: found %d symbols in %g", result.items_created, timer.elapsed ());
			
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
					end.set_line_offset (0);
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
