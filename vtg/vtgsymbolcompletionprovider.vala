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
		public signal void completion_lock_failed ();
		
		private Gdk.Pixbuf _icon;
		private int _priority = 1;
		private List<Gtk.SourceCompletionItem> _proposals;
	
		private Afrodite.SourceItem _sb = null;
		
		private uint _timeout_id = 0;
		private uint _idle_id = 0;

		private int _prealloc_index = 0;

		private bool _cache_building = false;
		private bool _filter = false;
		private uint _sb_msg_id = 0;
		private uint _sb_context_id = 0;

		private Gtk.SourceCompletionInfo _calltip_window = null;
		private Gtk.Label _calltip_window_label = null;

		private unowned SymbolCompletion _symbol_completion = null;
		private unowned CompletionEngine _completion = null;

		private unichar[] _reparse_chars = new unichar[] { '\n', '}', ';' };

		private bool _doc_changed = false;
		private int _last_line = 0;

		public SymbolCompletionProvider (Vtg.SymbolCompletion symbol_completion)
		{
			_icon = this.get_icon ();

			_symbol_completion = symbol_completion;
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			string name = Utils.get_document_name (doc);
			Utils.trace ("initializing provider for document: %s", name);
			_sb = new Afrodite.SourceItem ();
			_sb.path = name;
			_sb.content = doc.text;
			
			_symbol_completion.view.key_press_event.connect (this.on_view_key_press);
			_symbol_completion.view.focus_out_event.connect (this.on_view_focus_out);
			_symbol_completion.view.get_completion ().show.connect (this.on_completion_window_hide);

			doc.notify["cursor-position"].connect (this.on_cursor_position_changed);
			Signal.connect (doc, "saved", (GLib.Callback) on_document_saved, this);
			
			var status_bar = (Gedit.Statusbar) _symbol_completion.plugin_instance.window.get_statusbar ();
			_sb_context_id = status_bar.get_context_id ("symbol status");
			
			_cache_building = true; 
			_symbol_completion.notify["completion-engine"].connect (this.on_completion_engine_changed);
			_completion = _symbol_completion.completion_engine;
			_last_line = this.get_current_line ();
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
			doc.notify["cursor-position"].disconnect (this.on_cursor_position_changed);
			SignalHandler.disconnect_by_func (doc, (void*)this.on_document_saved, this);
						
			if (_sb_msg_id != 0) {
				var status_bar = (Gedit.Statusbar) _symbol_completion.plugin_instance.window.get_statusbar ();
				status_bar.remove (_sb_context_id, _sb_msg_id);
			}
		}
/*
		public unowned string get_name ()
		{
			// it's a bug in the vapi the get_name shouldn't be unwoned!
			string* hack = _("Vala Toys Completion Provider").dup();
			return hack; 
		}
*/
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
			var src = (Gtk.SourceBuffer) _symbol_completion.view.get_buffer ();
			weak TextMark mark = (TextMark) src.get_insert ();
			TextIter start;

			src.get_iter_at_mark (out start, mark);
			unichar ch = start.get_char ();
			bool result = true;
			
			TextIter pos = start;
			if (!Utils.is_inside_comment_or_literal (src, pos)) {
				pos = start;
				int line = pos.get_line ();
			
				if (pos.backward_char ()) {
					if (pos.get_line () == line) {
						unichar prev_ch = pos.get_char ();
						if (prev_ch == '(' || ch == '('
						    || prev_ch == '[' || ch == '['
						    || prev_ch == ' '
						    || prev_ch == '\t'
						    || prev_ch == ')'
						    || prev_ch == ']'
						    || prev_ch == ';'
						    || prev_ch == '?'
						    || prev_ch == '/' || ch == '/'
						    || prev_ch == ',') {
							result = false;
							Utils.trace ("not match current char: '%s', previous: '%s'", ch.to_string (), prev_ch.to_string ());
						} else {
							Utils.trace ("match current char: '%s', previous: '%s'", ch.to_string (), prev_ch.to_string ());
						}
					}
				} 
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
			unowned Gtk.TextMark mark = (Gtk.TextMark) context.completion.view.get_buffer ().get_insert ();
			Gtk.TextIter start;
			Gtk.TextIter end;
			context.completion.view.get_buffer ().get_iter_at_mark (out start, mark);
			context.completion.view.get_buffer ().get_iter_at_mark (out end, mark);

			if (!start.starts_line ())
				start.set_line_offset (0);

			string text = start.get_text (end);
			unichar prev_ch = 'a';
			if (end.backward_char ()) {
				prev_ch = end.get_char ();
				end.forward_char ();
			}
			
			bool symbols_in_scope_mode = false;
			string word = "";
			_filter = true;
			
			if (text.has_suffix (".") || (prev_ch != '_' && !prev_ch.isalnum())) {
				_filter = false;
			} else {
				bool dummy, is_declaration;
				ParserUtils.parse_line (text, out word, out dummy, out dummy, out is_declaration);
				
				if (!is_declaration && word != null && word.rstr(".") == null) {
					symbols_in_scope_mode = true;
					_filter = false;
				}
			}

			if (!_filter) {
				_proposals = new GLib.List<Gtk.SourceCompletionItem> ();
				if (symbols_in_scope_mode) {
					if (word != null) {
						this.lookup_visible_symbols_in_scope (word, CompareMode.START_WITH);
					}
				} else
					this.complete_current_word ();
				
				context.add_proposals (this, _proposals, true);
			} else if (word != null) {
				string[] tmp = word.split (".");
				string last_part = "";
				
				if (tmp.length > 0)
					last_part = tmp[tmp.length-1];
				
				Utils.trace ("filtering with: '%s' - '%s'", word, last_part);
				if (!StringUtils.is_null_or_empty (last_part)) {
					var filtered_proposals = new GLib.List<Gtk.SourceCompletionItem>();
					foreach (var proposal in _proposals) {
						if (proposal.get_label ().has_prefix (last_part)) {
							filtered_proposals.append (proposal);
						}
					}
				
					if (_proposals.length () > 0 && filtered_proposals.length () == 0) {
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

		public unowned Gdk.Pixbuf? get_icon ()
		{
			if (_icon == null)
			{
				try {
					Gtk.IconTheme theme = Gtk.IconTheme.get_default ();
					_icon = theme.load_icon (Gtk.Stock.DIALOG_INFO, 16, 0);
				} catch (Error err) {
					critical ("error: %s", err.message);
				}
			}
			return _icon;
		}

		public bool activate_proposal (Gtk.SourceCompletionProposal proposal, Gtk.TextIter iter)
		{
			_filter = false;
			return false;
		}

		public Gtk.SourceCompletionActivation get_activation ()
		{
			return Gtk.SourceCompletionActivation.INTERACTIVE |
				Gtk.SourceCompletionActivation.USER_REQUESTED;
		}

		/*public unowned Gtk.Widget get_info_widget (Gtk.SourceCompletionProposal proposal)
		{
			return null;
		}*/

		public int get_interactive_delay ()
		{
			return 10;
		}

		public bool get_start_iter (Gtk.SourceCompletionContext context, Gtk.SourceCompletionProposal proposal,	Gtk.TextIter iter)
		{
			return false;
		}

		/*public void update_info (Gtk.SourceCompletionProposal proposal, Gtk.SourceCompletionInfo info)
		{
		}*/

		private bool on_view_focus_out (Gtk.Widget sender, Gdk.EventFocus event)
		{
			hide_calltip ();
			return false;
		}
		
		[CCode(instance_pos=-1)]
		private void on_document_saved (Gedit.Document doc, void *arg1)
		{
			if (_sb.path != Utils.get_document_name (doc))
				_sb.path = Utils.get_document_name (doc);

			this.parse ();
		}

		private int get_current_line (Gedit.Document? doc = null)
		{
			int line, col;
			this.get_current_line_and_column (out line, out col);
			return line;
		}

		private void on_cursor_position_changed (GLib.Object sender, ParamSpec pspec)
		{
			int curr_line = get_current_line ();
			if (_doc_changed && _last_line != curr_line) {
				_last_line = curr_line;
				parse ();
			}
		}

		private void on_completion_engine_changed (GLib.Object sender, ParamSpec pspec)
		{
			_completion = _symbol_completion.completion_engine;
		}

		private bool on_view_key_press (Gtk.Widget sender, Gdk.EventKey evt)
		{
			unichar ch = Gdk.keyval_to_unicode (evt.keyval);

			if (ch == '(') {
				this.show_calltip ();
			} else if (evt.keyval == Gdk.Key_Escape || ch == ')' || ch == ';' || ch == '{' ||
					(evt.keyval == Gdk.Key_Return && (evt.state & ModifierType.SHIFT_MASK) != 0)) {
				this.hide_calltip ();
			}

			if (!_doc_changed && (ch.isalnum () || ch.isprint ())) {
				_doc_changed = true;
			}

			foreach (unichar reparse_char in _reparse_chars) {
				if (ch == reparse_char || (reparse_char == '\n' && evt.keyval == Gdk.Key_Return)) {
					idle_parse ();
					break;
				}
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

		private void idle_parse ()
		{
			if (_idle_id == 0) {
				_idle_id = Idle.add (this.parse, Priority.LOW);
			}
		}

		private bool parse ()
		{
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();

			// automatically add package if this buffer
			// belong to the default project
			var current_project = _symbol_completion.plugin_instance.project_view.current_project; 
			if (current_project.is_default) {
				if (autoadd_packages (doc, current_project) > 0) {
					current_project.project.update ();
				}
			}

			// request the parse to the completion engine
			_sb.content = doc.text;
			_completion.queue_source (_sb);
			_doc_changed = false;
			_idle_id = 0;
			return false;
		}

		private int autoadd_packages (Gedit.Document doc, Vtg.ProjectManager project_manager)
		{
			int added_count = 0;

			try {
				var text = doc.text;
				GLib.Regex regex = new GLib.Regex ("""^\s*(using)\s+(\w\S*)\s*;.*$""");

				foreach (string line in text.split ("\n")) {
					GLib.MatchInfo match;
					regex.match (line, RegexMatchFlags.NEWLINE_ANY, out match);
					while (match.matches ()) {
						string using_name = null;

						if (match.fetch (2) == "GLib") {
							// standard GLib are already merged by the completion engine
							// I'll add gio for the default project
							if (project_manager.is_default) {
								using_name = "gio";
							}
						} else {
							using_name = match.fetch (2);
						}
						string package_name = null;

						if (using_name != null)
							package_name = Vbf.Utils.guess_package_vapi (using_name);

						Utils.trace ("guessing name of using clause %s for package %s: %s", match.fetch (2), using_name, package_name);
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
			foreach (Afrodite.Symbol symbol in symbols) {
				if ((!include_private_symbols && symbol.access == Afrodite.SymbolAccessibility.PRIVATE)
					|| symbol.name == "new"
					|| (options != null && !symbol.check_options (options))) {
					//Utils.trace ("not append symbols: %s", symbol.name);
					continue;
				}

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

					/*if (false && _prealloc_index < Utils.prealloc_count) {
						proposal = proposals [_prealloc_index];
						_prealloc_index++;

						proposal.label = name;
						proposal.text = name;
						proposal.info = info;
						proposal.icon = icon;
					} else {*/
						proposal = new Gtk.SourceCompletionItem(name, name, icon, info);
					//}
					//Utils.trace ("append symbols: %s", symbol.name);
					_proposals.append (proposal);
				}
			}
			//sort list
			_proposals.sort (this.proposal_sort);
		}

		private static int proposal_sort (Gtk.SourceCompletionItem a, Gtk.SourceCompletionItem b)
		{
			return strcmp (a.get_label (), b.get_label ());
		}

		private void transform_result (Afrodite.QueryOptions? options, Afrodite.QueryResult? result)
		{
			_prealloc_index = 0;
			_proposals = new GLib.List<Gtk.SourceCompletionItem> ();
			var visited_interfaces = new Vala.ArrayList<Symbol> ();
			
			if (result != null && !result.is_empty) {
				options.dump_settings ();
				
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
					Utils.trace ("visiting base type: %s", type.type_name);
					if (!type.unresolved 
					    && type.symbol.has_children
					    && (options == null || type.symbol.check_options (options))
					    && (type.symbol.type_name == "Class" || type.symbol.type_name == "Interface" || type.symbol.type_name == "Struct")) {
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

		private void get_current_line_and_column (out int line, out int column)
		{
 			unowned Gedit.Document doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			unowned TextMark mark = (TextMark) doc.get_insert ();
			TextIter start;

			doc.get_iter_at_mark (out start, mark);
			line = start.get_line ();
			column = start.get_line_offset ();
		}
		

		private string get_current_line_text (bool align_to_right_word)
		{
 			unowned Gedit.Document doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			unowned TextMark mark = (TextMark) doc.get_insert ();
			TextIter end;
			TextIter start;
			unichar ch;
			
			doc.get_iter_at_mark (out start, mark);
			int line = start.get_line ();
			
			//go to the right word boundary
			ch = start.get_char ();
			while (ch.isalnum () || ch == '_') {
				start.forward_char ();
				int curr_line = start.get_line ();
				if (line != curr_line) //changed line?
				{
					start.backward_char ();
					break;
				}
				ch = start.get_char ();
			}

			end = start;
			start.set_line_offset (0);
			return start.get_text (end);
		}

		public Afrodite.Symbol? get_symbol_containing_cursor (int retry_count = 0)
		{
			int line, col;
			Afrodite.Ast ast;
			Afrodite.Symbol? symbol = null;
			var doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
			string name = Utils.get_document_name (doc);

			get_current_line_and_column (out line, out col);
			if (_completion.try_acquire_ast (out ast, retry_count)) {
				symbol = ast.lookup_symbol_at (name, line, col);
				_completion.release_ast (ast);
			}

			return symbol;
		}
	
		public Afrodite.Symbol? get_current_symbol_item (int retry_count = 0)
		{
			string text = get_current_line_text (true);
			string word;
			int line, col;
			bool is_assignment, is_creation, is_declaration;

			ParserUtils.parse_line (text, out word, out is_assignment, out is_creation, out is_declaration);

			if (word == null || word == "")
				return null;

			get_current_line_and_column (out line, out col);

			string[] tmp = word.split(".");
			string last_part = tmp[tmp.length - 1];
			string symbol_name = last_part;
			
			//don't try to find method signature if is a: for, foreach, if, while etc...
			if (Vtg.Utils.is_vala_keyword (symbol_name)) {
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
				Afrodite.QueryOptions options = this.get_options_for_line (text, is_assignment, is_creation);
				
				if (word == symbol_name)
					result = get_symbol_for_name (options, ast, first_part, null,  line, col);
				else
					result = get_symbol_type_for_name (options, ast, first_part, null,  line, col);
					
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
		
		private QueryOptions get_options_for_line (string line, bool is_assignment, bool is_creation)
		{
			QueryOptions options = null;
			
			if (is_creation) {
				options = QueryOptions.creation_methods ();
			} else if (is_assignment || (line != null && line.rstr (":") != null)) {
				options = QueryOptions.standard ();
				options.binding |= Afrodite.MemberBinding.STATIC;
			} else if (line != null && (line.str ("throws ") != null || line.str ("throw ") != null)) {
				options = QueryOptions.error_domains ();
			}
			if (options == null) {
				options = QueryOptions.standard ();
			}
			
			options.access = Afrodite.SymbolAccessibility.INTERNAL | Afrodite.SymbolAccessibility.PROTECTED | Afrodite.SymbolAccessibility.PUBLIC;
			options.auto_member_binding_mode = true;
			options.compare_mode = CompareMode.EXACT;
			//options.dump_settings ();
			return options;
		}

		private void complete_current_word ()
		{
			//string whole_line, word, last_part;
			//int line, column;

			//parse_current_line (false, out word, out last_part, out whole_line, out line, out column);
			string text = get_current_line_text (false);
			string word;
			
			bool is_assignment, is_creation, is_declaration;

			ParserUtils.parse_line (text, out word, out is_assignment, out is_creation, out is_declaration);

			Afrodite.Ast ast = null;
			Utils.trace ("completing word: '%s'", word);
			if (!StringUtils.is_null_or_empty (word) 
			    && _completion.try_acquire_ast (out ast)) {
			        QueryOptions options = get_options_for_line (text, is_assignment, is_creation);
				Afrodite.QueryResult result = null;
				int line, col;

				get_current_line_and_column (out line, out col);

				if (word.has_prefix ("\"") && word.has_suffix ("\"")) {
					word = "string";
				} else if (word.has_prefix ("\'") && word.has_suffix ("\'")) {
					word = "unichar";
				}
				result = get_symbol_type_for_name (options, ast, word, text, line, col);
				transform_result (options, result);
				_completion.release_ast (ast);
				
			} else {
				if (!StringUtils.is_null_or_empty (word)) {
					Utils.trace ("build_proposal_item_list: couldn't acquire ast lock");
					this.show_calltip_info (_("<i>source symbol cache is still updating...</i>"));
					Timeout.add_seconds (2, this.on_hide_calltip_timeout);
					this.completion_lock_failed ();
				}
				transform_result (null, null);
			}
		}

		private void lookup_visible_symbols_in_scope (string word, CompareMode mode)
		{
			Afrodite.Ast ast = null;
			Utils.trace ("lookup_all_symbols_in_scope: mode: %s word:'%s' ", 
				mode == CompareMode.EXACT ? "exact" : "start-with",
				word);
			if (!StringUtils.is_null_or_empty (word) 
			    && _completion.try_acquire_ast (out ast, 0)) {
        			Vala.List<Afrodite.Symbol> results = new Vala.ArrayList<Afrodite.Symbol> ();

				weak Gedit.Document doc = (Gedit.Document) _symbol_completion.view.get_buffer ();
				var source = ast.lookup_source_file (Utils.get_document_name (doc));
				if (source != null) {
					// get the source node at this position
					int line, column;
					get_current_line_and_column (out line, out column);
					
					var s = ast.get_symbol_for_source_and_position (source, line, column);
					if (s != null) {
						results = ast.lookup_visible_symbols_from_symbol (s, word, mode, CaseSensitiveness.CASE_SENSITIVE);
					}
				} else {
					Utils.trace ("no source file for: %s", Utils.get_document_name (doc));
				}
				
				if (results.size == 0) {
					Utils.trace ("no symbol visible");
					transform_result (null, null);
				} else {
					_proposals = new GLib.List<Gtk.SourceCompletionItem> ();
					append_symbols (null, results);
				}
				_completion.release_ast (ast);
			} else {
				if (!StringUtils.is_null_or_empty (word)) {
					Utils.trace ("build_proposal_item_list: couldn't acquire ast lock");
					this.completion_lock_failed ();
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
			Utils.trace ("symbol matched %d", result.children.size);
			return result;
		}

		private Afrodite.QueryResult? get_symbol_for_name (QueryOptions options, Afrodite.Ast ast,string word, string? whole_line, int line, int column)
		{
			Afrodite.QueryResult result = null;
			result = ast.get_symbol_for_name_and_path (options, word, _sb.path, line, column);
			
			return result;
		}
	}
}
