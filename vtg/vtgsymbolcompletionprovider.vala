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
		private bool need_reparse = false;
		private uint timeout_id = 0;
		private bool all_doc = false; //this is a hack!!!

		private int prealloc_index = 0;
		private int counter = 0;

		private bool cache_building = false;
		private bool prev_cache_building = false;
		private bool tooltip_is_visible = false;

		private GLib.Object _last_trigger = null;
		private uint sb_msg_id = 0;
		private uint sb_context_id = 0;

		private Vtg.Plugin _plugin;

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
				GLib.debug ("source buffer is %s", name);
				_sb = new Vsc.SourceBuffer (name, null);
				_sb.data = (void *) doc;

				_view.key_press_event += this.on_view_key_press;

				this._completion.add_source_buffer (_sb);
				this._icon_generic = IconTheme.get_default().load_icon(Gtk.STOCK_FILE,16,IconLookupFlags.GENERIC_FALLBACK);
				this._icon_field = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-field-16.png"));
				this._icon_method = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-method-16.png"));
				this._icon_class = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-class-16.png"));
				this._icon_struct = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-structure-16.png"));
				this._icon_property = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-property-16.png"));
				this._icon_signal = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-event-16.png"));
				this._icon_iface = new Gdk.Pixbuf.from_file (Utils.get_image_path ("element-interface-16.png"));

				this.all_doc = true;
				this.parse (doc);
				//this.cache_proposal = new Gsc.Proposal ("cache is still building...", "", this._icon_generic);
				this._completion.cache_building += sender => { 
					cache_building = true; 
				};
				this._completion.cache_builded += sender => { 
					cache_building = false; 
				};
				//Timeout.add_seconds (1, this.on_idle);
				Idle.add_full (Priority.LOW, this.on_idle);
				var status_bar = (Gedit.Statusbar) _plugin.gedit_window.get_statusbar ();
				sb_context_id = status_bar.get_context_id ("symbol status");
			} catch (Error err) {
				GLib.warning ("an error occourred: %s", err.message);
			}
		}

		private bool on_idle ()
		{
			if (cache_building && !tooltip_is_visible && prev_cache_building == false) {
				GLib.debug ("show tooltip ");
				prev_cache_building = cache_building;
				var status_bar = (Gedit.Statusbar) _plugin.gedit_window.get_statusbar ();
				if (sb_msg_id != 0) {
					status_bar.remove (sb_context_id, sb_msg_id);
									}
				sb_msg_id = status_bar.push (sb_context_id, "rebuilding symbol cache...");
			} else if (cache_building == false && prev_cache_building == true) {
				GLib.debug ("delete tooltip ");
				prev_cache_building = false;
				//hide tip, show proposal list
				var status_bar = (Gedit.Statusbar) _plugin.gedit_window.get_statusbar ();
				status_bar.remove (sb_context_id, sb_msg_id);
				sb_msg_id = 0;
				if (_last_trigger != null) {
					((SymbolCompletionTrigger) _last_trigger).trigger_event ();
				}
			}

			return true;
		}

		private bool on_timeout_parse ()
		{
			if (counter == 0) {
				GLib.debug ("scheduling a reparse");
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
			if (counter <= 0) {
				if (evt.keyval == Gdk.Key_BackSpace || 
				    evt.keyval == Gdk.Key_Return ||
				    (ch != 0 && ch != '.' && ch != ':')) {
					if (evt.keyval == Gdk.Key_Return || ch == ';') {
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

		private void parse (Gedit.Document doc)
		{
			var buffer = this.get_document_text (doc, this.all_doc);
			//GLib.debug ("parse called:\n-------------------------------\n%s\n-------------------------------\n", buffer);
			_sb.source = buffer;
			_completion.reparse_source_buffers ();
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
				_last_trigger = (GLib.Object) trigger;
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

				if (prealloc_index < Utils.prealloc_count) {
					proposal = proposals [prealloc_index];
					prealloc_index++;

					proposal.label = symbol.name;
					proposal.info = symbol.info;
				        proposal.icon = icon;
				} else {
					proposal = new Proposal(symbol.name, symbol.info, icon);
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
				if (result.others.size > 0) {
					append_symbols (result.others, _icon_generic);
				}
			}

			timer.stop ();
			GLib.debug ("     TRASFORM TOTAL TIME ELAPSED: %f", timer.elapsed ());
		}

		private SymbolCompletionResult? find_proposals ()
		{
			SymbolCompletionResult result = null;

			weak Gedit.Document doc = (Gedit.Document) _view.get_buffer ();
			weak TextMark mark = (TextMark) doc.get_insert ();
			TextIter end;
			TextIter start;			
			string line;

			doc.get_iter_at_mark (out start, mark);
			int lineno = start.get_line ();
			int colno = start.get_line_offset ();
			end = start;
			start.set_line_offset (0);
			line = start.get_text (end);
			if (colno > 1) {
				start = end;
				start.backward_char ();
				unichar ch = start.get_char ();
				if (ch == '\"') {
					//find the string literal begin
					while (true) {
						start.backward_char ();
						if (start.starts_line ())
							break;

						ch = start.get_char ();
						if (ch == '\"')
							break;
					}
				} else {
					while (true) {
						start.backward_char ();
						if (start.starts_line ())
							break;
						ch = start.get_char ();
						if (!(ch.isalnum () ||
						      ch == '.' ||
						      ch == '_')) {
							start.forward_char ();
							break;
						}			
					}
				}

				string word = start.get_text (end).strip ();
				if (word != null) {
					try {
						string typename = null;
						var timer = new Timer ();
						timer.stop ();
						if (word.has_prefix ("\"") && word.has_suffix ("\"")) {
							typename = "string";
						} else {
							timer.start ();
							var dt = _completion.find_datatype_for_name (word, _sb.name, lineno + 1, colno);
							timer.stop ();
							GLib.debug ("find_datatype_for_name: %f", timer.elapsed ());
							if (dt != null) {
								if (dt is Vala.ClassType) {
									typename = ((Vala.ClassType) dt).class_symbol.name;
								} else {
									typename = dt.to_qualified_string ();
								}
								if (typename.has_suffix ("?")) {
									typename = typename.substring (0, typename.length - 1);
								}

							}
						}

						SymbolCompletionFilterOptions options = new SymbolCompletionFilterOptions ();
						if (line.str ("= new ") != null || line.str ("=new ") != null) {
							options.only_constructors = true;
						}
						if (typename != null) {
							GLib.debug ("datatype '%s' for: %s",typename, word);
							options.static_symbols = false;
							options.public_only ();
							if (word == "this") {
								options.private_symbols = true;
								options.protected_symbols = true;
							} else if (word == "base") {
								options.protected_symbols = true;
							}
							options.exclude_type = typename;
							timer.start ();
							result = _completion.find_by_name (options, "%s.".printf(typename));
							timer.stop ();
							GLib.debug ("find_by_name: %f", timer.elapsed ());
						} else {
							GLib.debug ("data type not found for: %s", word);
							if (word.has_prefix ("this.") == false && word.has_prefix ("base.") == false) {
								options.static_symbols = true;
								options.interface_symbols = false;
								options.public_only ();
								timer.start ();
								result = _completion.find_by_name (options, "%s.".printf(word));
								timer.stop ();
								GLib.debug ("find_by_name (static): %f", timer.elapsed ());
							}
						}
					} catch (GLib.Error err) {
						GLib.warning ("%s", err.message);
					}
				}
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
			if (all_doc) {
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