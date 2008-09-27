/*
 *  vtgsymbolcompletiontrigger.vala - Vala developer toys for GEdit
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

namespace Vtg
{
	public class SymbolCompletionTrigger : GLib.Object, Gsc.Trigger
	{
		private Gsc.Manager _completion;
		private string _trigger_name;
		private weak Gsc.ManagerEventOptions _opts = null;

		public Gsc.Manager completion { construct { _completion = value; } }

		public string trigger_name { construct { _trigger_name = value; } }


		public void set_opts (Gsc.ManagerEventOptions opts)
		{
			this._opts = opts;
		}

		public bool activate ()
		{
			var view = _completion.get_view ();
			view.key_press_event += this.on_view_key_press;
			return true;
		}

		public bool deactivate ()
		{
			var view = _completion.get_view ();
			view.key_press_event -= this.on_view_key_press;
			return true;
		}

		public weak string get_name ()
		{
			return this._trigger_name;
		}

		private bool on_view_key_press (Gtk.TextView view, Gdk.EventKey event)
		{
			if (event.keyval == '.' && 
			    (event.state & (ModifierType.SHIFT_MASK | ModifierType.META_MASK | ModifierType.CONTROL_MASK)) == 0) {
				trigger_event ();
			}
			return false;
		}

		public void trigger_event ()
		{
			if (_opts == null) {
				_completion.trigger_event (this._trigger_name, null);
			} else {
				_completion.trigger_event_with_opts (this._trigger_name, _opts, null);
			}
		}

		public SymbolCompletionTrigger (Gsc.Manager completion, string trigger_name)
		{
			this.completion = completion;
			this.trigger_name = trigger_name;
		}
	}
}