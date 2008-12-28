/*
 *  vtgchangelog.vala - Vala developer toys for GEdit
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
using Gee;
using Vtg.Vcs.Backends;

namespace Vtg
{
	internal class ChangeLog : GLib.Object
	{
		private Vtg.Plugin _plugin;
		
 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }
 		
		public ChangeLog (Vtg.Plugin plugin)
		{
			this.plugin = plugin;
		}
		
		public bool prepare (string? file = null) throws GLib.Error
		{
			var project = _plugin.project_manager.project_view.current_project;
			if (project == null)
				return false;
			
			string file_list = "";
			bool force_add_new = true;
			
			if (file != null) {
				file_list += "\t* %s:\n".printf (file);
				force_add_new = false;
			} else {
				IGeneric backend = vcs_backend_factory (project.vcs_type);
				if (backend == null)
					return false;

				Gee.List<Item> items = backend.get_items (project.filename);
				foreach (Item item in items) {
					file_list += "\t* %s:\n".printf (item.name);		
				}
			}
			
			if (file_list != "") {
				var tab = _plugin.activate_uri (project.changelog_uri);
				if (tab == null)
					return false;
				var doc = tab.get_document ();		
				if (doc == null)
					return false;

				var ctx = GLib.MainContext.default ();
				while (ctx.pending ())
					ctx.iteration (false);
				
				Gtk.TextIter iter;
				string author = _plugin.config.author;
				string email = _plugin.config.email_address;
				var today = Time.local (time_t ());
				
				if (StringUtils.is_null_or_empty (author))
					author = Environment.get_variable ("REAL_NAME");
				if (StringUtils.is_null_or_empty (email))
					email = Environment.get_variable ("EMAIL_ADDRESS");
				if (StringUtils.is_null_or_empty (author))
					author = _("Author Name");
				if (StringUtils.is_null_or_empty (email))
					email = _("Email Address");
					
				string date = "%04d-%02d-%02d".printf (today.year + 1900, today.month + 1, today.day);
				string header = "%s  %s  <%s>".printf (date, author, email);
				string current_header = null;
				string entry;
				int backward_chars_count = 2;
				doc.get_iter_at_offset (out iter, 0);
				if (!force_add_new) {
					Gtk.TextIter end = iter;
					if (end.forward_line ()) {
						end.backward_char ();
						current_header = iter.get_text (end);
					}
					
				}
				if (current_header != header) {
					entry = "%s\n\n%s\n\t\n\n".printf (header, file_list);
				} else {
					entry = "\n%s\n\t\n".printf (file_list);
					iter.forward_line ();
					backward_chars_count = 1;
				}
				
				doc.place_cursor (iter);
				doc.insert_interactive_at_cursor (entry, (int) entry.length, true);
				weak Gtk.TextMark mark = (Gtk.TextMark) doc.get_insert ();
				doc.get_iter_at_mark (out iter, mark);
				iter.backward_chars (backward_chars_count);
				doc.place_cursor (iter);
				return true;
			}
			return false;
		}
		
		private IGeneric? vcs_backend_factory (Vtg.ProjectManager.VcsTypes type)
		{
			IGeneric backend;
			
			switch (type) {
				case Vtg.ProjectManager.VcsTypes.GIT:
					backend = new Vtg.Vcs.Backends.Git ();
					break;
				case Vtg.ProjectManager.VcsTypes.BZR:
					backend = new Vtg.Vcs.Backends.Bzr ();
					break;
				case Vtg.ProjectManager.VcsTypes.SVN:
					backend = new Vtg.Vcs.Backends.Svn ();
					break;
				default:
					backend = null;
					break;
			}
			
			return backend;
		}
	}
}