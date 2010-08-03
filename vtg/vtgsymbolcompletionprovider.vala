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
using Afrodite;

namespace Vtg
{
	internal class SymbolCompletionProvider : GLib.Object, Gtk.SourceCompletionProvider
	{
		private Gdk.Pixbuf _icon;
		private int _priority = 1;
		private List<Gtk.SourceCompletionItem> _proposals;
	
		private Afrodite.SourceItem _sb = null;
		
		private uint _timeout_id = 0;
		private uint _idle_id = 0;
		private bool _all_doc = false; //this is a hack!!!

		private int _prealloc_index = 0;

		private bool _cache_building = false;
		private bool _filter = false;
		private uint _sb_msg_id = 0;
		private uint _sb_context_id = 0;

		private Gtk.SourceCompletionInfo _calltip_window = null;
		private Gtk.Label _calltip_window_label = null;
		
		private int _last_line = -1;
		private bool _doc_changed = false;
		
		private unowned SymbolCompletion _symbol_completion = null;
		private unowned CompletionEngine _completion = null;
		
		public SymbolCompletionProvider (Vtg.SymbolCompletion symbol_completion)
		{
			_icon = this.get_icon ();

			_symbol_completion = symbol_completion;
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			string name = Utils.get_document_name (doc);

			_sb = new Afrodite.SourceItem ();
			_sb.path = name;
			_sb.content = doc.text;
			
			_symbol_completion.view.key_press_event.connect (this.on_view_key_press);
			_symbol_completion.view.focus_out_event.connect (this.on_view_focus_out);
			_symbol_completion.view.get_completion ().show.connect (this.on_completion_window_hide);
			
			doc.notify["text"] += this.on_text_changed;
			doc.notify["cursor-position"] += this.on_cursor_position_changed;
			Signal.connect (doc, "saved", (GLib.Callback) on_document_saved, this);
			
			var status_bar = (Gedit.Statusbar) _symbol_completion.plugin_instance.window.get_statusbar ();
			_sb_context_id = status_bar.get_context_id ("symbol status");
			
			_cache_building = true; 
			_all_doc = true;
			_symbol_completion.notify["completion-engine"].connect (this.on_completion_engine_changed);
			_completion = _symbol_completion.completion_engine;
		}

		~SymbolCompletionProvider ()
		{
			if (_timeout_id != 0) {
				Source.remove (_timeout_id);
			}
			if (_idle_id != 0) {
				Source.remove (_idle_id);
			}
			
			_symbol_completion.view.key_press_event.disconnect (this.on_view_key_press);
			_symbol_completion.view.focus_out_event.disconnect (this.on_view_focus_out);
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			_symbol_completion.notify["completion-engine"].disconnect (this.on_completion_engine_changed);
			doc.notify["text"] -= this.on_text_changed;
			doc.notify["cursor-position"] -= this.on_cursor_position_changed;
			SignalHandler.disconnect_by_func (doc, (void*)this.on_document_saved, this);
						
			if (_sb_msg_id != 0) {
				var status_bar = (Gedit.Statusbar) _symbol_completion.plugin_instance.window.get_statusbar ();
				status_bar.remove (_sb_context_id, _sb_msg_id);
			}
		}

		public string get_name ()
		{
			return _("Vala Toys Completion Provider");
		}

		public int get_priority ()
		{
			return _priority;
		}

		public bool match (Gtk.SourceCompletionContext context)
		{
			Utils.trace ("match");
			bool result = false;
			unowned Gtk.TextMark mark = (Gtk.TextMark) context.completion.view.get_buffer ().get_insert ();
			Gtk.TextIter start;
			Gtk.TextIter end;
			context.completion.view.get_buffer ().get_iter_at_mark (out start, mark);
			context.completion.view.get_buffer ().get_iter_at_mark (out end, mark);

			if (!start.starts_line ())
			start.set_line_offset (0);

			string text = start.get_text (end);
			if (text.has_suffix (".")) {
				result = true;
				_filter = false; // do a completion
			}
			
			return result;
		}

		private void on_completion_window_hide (Gtk.SourceCompletion sender)
		{
			_filter = false;
		}
		
		public void populate (Gtk.SourceCompletionContext context)
		{
			Utils.trace ("populate");
			if (!_filter) {
				this.build_proposal_item_list ();
				context.add_proposals (this, _proposals, true);
				// subsequent call to populate should filter the proposals 
				// until the proposals window will be closed
				_filter = true;
			} else {
				string whole_line, word, last_part;
				int line, column;

				parse_current_line (false, out word, out last_part, out whole_line, out line, out column);
				Utils.trace ("filtering with: '%s' - '%s'", word, last_part);
				if (!StringUtils.is_null_or_empty (last_part) && word != last_part) {
					var filtered_proposals = new GLib.List<Gtk.SourceCompletionItem>();
					foreach (var proposal in _proposals) {
						if (proposal.get_label ().has_prefix (last_part)) {
							filtered_proposals.append (proposal);
						}
					}
				
					if (filtered_proposals.length () == 0) {
						// no matching add a dummy one to prevent proposal windows from closing
						var dummy_proposal = new Gtk.SourceCompletionItem (_("No matching proposal"), "", null, null);
						filtered_proposals.append (dummy_proposal);
					}
					context.add_proposals (this, filtered_proposals, true);
				} else {
					// match all optimization
					context.add_proposals (this, _proposals, true);
				}
			}

		}

		public unowned Gdk.Pixbuf get_icon ()
		{
			if (_icon == null)
			{
				try {
					Gtk.IconTheme theme = Gtk.IconTheme.get_default ();
					_icon = theme.load_icon (Gtk.STOCK_DIALOG_INFO, 16, 0);
				} catch (Error err) {
					critical ("error: %s", err.message);
				}
			}
			return _icon;
		}

		public bool activate_proposal (Gtk.SourceCompletionProposal proposal, Gtk.TextIter iter)
		{
			return false;
		}

		public Gtk.SourceCompletionActivation get_activation ()
		{
			return Gtk.SourceCompletionActivation.INTERACTIVE |
				Gtk.SourceCompletionActivation.USER_REQUESTED;
		}

		public unowned Gtk.Widget? get_info_widget (Gtk.SourceCompletionProposal proposal)
		{
			return null;
		}

		public int get_interactive_delay ()
		{
			return 10;
		}

		public bool get_start_iter (Gtk.SourceCompletionContext context, Gtk.SourceCompletionProposal proposal,	Gtk.TextIter iter)
		{
			return false;
		}

		public void update_info (Gtk.SourceCompletionProposal proposal, Gtk.SourceCompletionInfo info)
		{
		}
		private bool on_view_focus_out (Gtk.Widget sender, Gdk.EventFocus event)
		{
			hide_calltip ();
			return false;
		}
		
		[CCode(instance_pos=-1)]
		private void on_document_saved (Gedit.Document doc, void *arg1)
		{
			_doc_changed = true;
			_all_doc = true;
			this.schedule_reparse ();
		}
		
		private void on_completion_engine_changed (GLib.Object sender, ParamSpec pspec)
		{
			_completion = _symbol_completion.completion_engine;
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

		private bool on_timeout_parse ()
		{
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			parse (doc);
			_timeout_id = 0;
			_last_line = get_current_line_index (doc);
			return false;
		}

		private bool on_view_key_press (Gtk.Widget sender, Gdk.EventKey evt)
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
				show_calltip_info (completion_result.info);
			}
		}

		private void show_calltip_info (string markup_text)
		{
			if (_calltip_window == null) {
				initialize_calltip_window ();
			}

			if (markup_text != null) {
				_calltip_window_label.set_markup (markup_text);
				_calltip_window.move_to_iter (_symbol_completion.view);
				_calltip_window.show_all ();
				_calltip_window.show ();
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
			_calltip_window = new Gtk.SourceCompletionInfo ();
			_calltip_window.set_transient_for (_symbol_completion.plugin_instance.window);
			_calltip_window.set_sizing (800, 400, true, true);
			_calltip_window_label = new Gtk.Label ("");
			_calltip_window.set_widget (_calltip_window_label);			
		}

		private void parse (Gedit.Document doc)
		{
			// automatically add package if this buffer
			// belong to the default project
			var current_project = _symbol_completion.plugin_instance.project_view.current_project; 
			if (current_project.is_default) {
				if (autoadd_packages (doc, current_project) > 0) {
					current_project.project.update ();
				}
			}
			
			// schedule a parse
			var buffer = this.get_document_text (doc, _all_doc);
			_sb.content = buffer;
			_completion.queue_source (_sb);
			_doc_changed = false;
		}

		private int autoadd_packages (Gedit.Document doc, Vtg.ProjectManager project_manager)
		{
		
			int added_count = 0;
			
			try {
				var text = this.get_document_text (doc, true);
				GLib.Regex regex = new GLib.Regex ("""^\s*(using)\s+(\w\S*)\s*;.*$""");
			
				foreach (string line in text.split ("\n")) {
					GLib.MatchInfo match;
					regex.match (line, RegexMatchFlags.NEWLINE_ANY, out match);
					while (match.matches ()) {
						string package_name = Afrodite.Utils.guess_package_name (match.fetch (2));
						Utils.trace ("guessing name for %s: %s", match.fetch (2), package_name);
						if (package_name != null) {
							var group = project_manager.project.get_group("Sources");
							var target = group.get_target_for_id ("Default");
							if (!target.contains_package (package_name))
							{
								target.add_package (new Vbf.Package (package_name));
								added_count++;
							}
						}
						match.next ();
					}
				}
			} catch (Error err) {
				critical ("error: %s", err.message);
			}

			return added_count;
		}
		
		private bool proposal_list_contains_name (string name)
		{
			foreach (Gtk.SourceCompletionItem proposal in _proposals) {
				if (proposal.get_label () == name) {
					return true;
				}
			}
			
			return false;
		}
		
		private void append_symbols (Afrodite.QueryOptions? options, Vala.List<Afrodite.Symbol> symbols, bool include_private_symbols = true)
		{
			unowned Gtk.SourceCompletionItem[] proposals = Utils.get_proposal_cache ();

			
			foreach (Afrodite.Symbol symbol in symbols) {
				if ((!include_private_symbols && symbol.access == Afrodite.SymbolAccessibility.PRIVATE)
					|| symbol.name == "new"
					|| (options != null && !symbol.check_options (options)))
					continue;


				string name;

				if (symbol.type_name == "CreationMethod") {
					name = symbol.name;
				} else {
					name = (symbol.display_name != null ? symbol.display_name : "<null>");
				}

				if (!symbol.overrides || (symbol.overrides && !this.proposal_list_contains_name (name))) {
					Gtk.SourceCompletionItem proposal;					
					var info = (symbol.info != null ? symbol.info : "");
					Gdk.Pixbuf icon = Utils.get_icon_for_type_name (symbol.type_name);

					if (_prealloc_index < Utils.prealloc_count) {
						proposal = proposals [_prealloc_index];
						_prealloc_index++;

						proposal.label = name;
						proposal.text = name;
						proposal.info = info;
						proposal.icon = icon;
					} else {
						proposal = new Gtk.SourceCompletionItem(name, name, icon, info);
					}
					_proposals.append (proposal);
				}
			}
			//sort list
			_proposals.sort (this.proposal_sort);
		}

		private static int proposal_sort (void* a, void* b)
		{
			Gtk.SourceCompletionItem pa = (Gtk.SourceCompletionItem) a;
			Gtk.SourceCompletionItem pb = (Gtk.SourceCompletionItem) b;

			return strcmp (pa.get_label (), pb.get_label ());
		}

		private void transform_result (Afrodite.QueryOptions? options, Afrodite.QueryResult? result)
		{
			_prealloc_index = 0;
			_proposals = new GLib.List<Gtk.SourceCompletionItem> ();
			var visited_interfaces = new Vala.ArrayList<Symbol> ();
			
			if (result != null && !result.is_empty) {
				foreach (ResultItem item in result.children) {
					var symbol = item.symbol;
					if (options == null || symbol.check_options (options)) {
						if (symbol.has_children) {
							append_symbols (options, symbol.children);
						}
						
						append_base_type_symbols (options, symbol, visited_interfaces);
					}
				}
			}
		}

		private void append_base_type_symbols (Afrodite.QueryOptions? options, Symbol symbol, Vala.List<Symbol> visited_interfaces)
		{
			if (symbol.has_base_types 
			    && (symbol.type_name == "Class" || symbol.type_name == "Interface" || symbol.type_name == "Struct")) {
				foreach (DataType type in symbol.base_types) {
					if (!type.unresolved 
					    && type.symbol.has_children
					    && (options == null || type.symbol.check_options (options))
					    && (type.symbol.type_name == "Class")) {
							// symbols of base types (classes or interfaces)
							if (!visited_interfaces.contains (type.symbol)) {
								visited_interfaces.add (type.symbol);
								append_symbols (options, type.symbol.children, false);
								append_base_type_symbols (options, type.symbol, visited_interfaces);
							}
					}
				}
			} else {
				Utils.trace ("NO base type for %s-%s", symbol.name, symbol.type_name);
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
				if (symbolname.has_suffix ("."))
					symbolname = symbolname.substring (0, symbolname.length -1);
				if (last_symbolname == "")
					last_symbolname = symbolname;
			}
		}

		public Afrodite.Symbol? get_current_symbol_item (int retry_count = 0)
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
				first_part = word; // "this"; //HACK: this won't work for static methods
			}
			
			Afrodite.Ast ast;
			Afrodite.Symbol? symbol = null;
			
			if (_completion.try_acquire_ast (out ast, retry_count)) {
				Afrodite.QueryResult? result = null;
				Afrodite.QueryOptions options = this.get_options_for_line (line);			
				
				if (word == symbol_name)
					result = get_symbol_for_name (options, ast, first_part, null,  lineno, colno);
				else
					result = get_symbol_type_for_name (options, ast, first_part, null,  lineno, colno);
					
				if (result != null && !result.is_empty) {
					var first = result.children.get (0);
					if (word == symbol_name) {
						symbol = first.symbol;
					} else {
						symbol = get_symbol_for_name_in_children (symbol_name, first.symbol);
						if (symbol == null)
							symbol =  get_symbol_for_name_in_base_types (symbol_name, first.symbol);
					}
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
				} else if (line.str ("=") != null || line.str (":") != null) {
					options = QueryOptions.standard ();
					options.binding |= Afrodite.MemberBinding.STATIC;
				} else if (line.str ("throws ") != null || line.str ("throw ") != null) {
					options = QueryOptions.error_domains ();
				}
			}
			if (options == null) {
				options = QueryOptions.standard ();
				options.auto_member_binding_mode = true;
			} else {
				options.auto_member_binding_mode = true;
			}
			options.compare_mode = CompareMode.EXACT;
			//options.dump_settings ();
			return options;
		}

		private void build_proposal_item_list ()
		{
			string whole_line, word, last_part;
			int line, column;

			parse_current_line (false, out word, out last_part, out whole_line, out line, out column);

			Afrodite.Ast ast = null;
			Utils.trace ("completing word: '%s'", word);
			if (!StringUtils.is_null_or_empty (word) 
			    && _completion.try_acquire_ast (out ast)) {
			        QueryOptions options = get_options_for_line (whole_line);
        			Afrodite.QueryResult result = null;
        			
				result = get_symbol_type_for_name (options, ast, word, whole_line, line, column);
				transform_result (options, result);
				_completion.release_ast (ast);
			} else {
				if (!StringUtils.is_null_or_empty (word)) {
					Utils.trace ("build_proposal_item_list: couldn't acquire ast lock");
					this.show_calltip_info (_("<i>symbol cache is still building...</i>"));
					Timeout.add_seconds (1, this.on_hide_calltip_timeout);
				}
				transform_result (null, null);
			}
		}
		
		private bool on_hide_calltip_timeout ()
		{
			this.hide_calltip ();
			return false;
		}
		
		private Afrodite.QueryResult? get_symbol_type_for_name (QueryOptions options, Afrodite.Ast ast, string word, string? whole_line, int line, int column)
		{
			Afrodite.QueryResult result = null;
			result = ast.get_symbol_type_for_name_and_path (options, word, _sb.path, line, column);
			return result;
		}

		private Afrodite.QueryResult? get_symbol_for_name (QueryOptions options, Afrodite.Ast ast,string word, string? whole_line, int line, int column)
		{
			Afrodite.QueryResult result = null;
			result = ast.get_symbol_for_name_and_path (options, word, _sb.path, line, column);
			
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
