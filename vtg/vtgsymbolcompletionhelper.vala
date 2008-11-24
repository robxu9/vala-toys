/*
 *  vtgsymbolcompletionhelper.vala - Vala developer toys for GEdit
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
	public class SymbolCompletionHelper : GLib.Object
	{
		private Vtg.Plugin _plugin;
		private Gedit.View _view;
		private SymbolCompletion _completion;
		private SymbolCompletionProvider _provider;
		private Manager _manager;

 		public Vtg.Plugin plugin { get { return _plugin; } construct { _plugin = value; } default = null; }
		public Gedit.View view { get { return _view; } construct { _view = value; } default = null; }
		public SymbolCompletion completion { get { return _completion; } construct { _completion = value; } default = null; }

		public SymbolCompletionHelper (Vtg.Plugin plugin, Gedit.View view, SymbolCompletion completion)
		{
			this.plugin = plugin;
			this.view = view;
			this.completion = completion;
		}

		construct	
		{
			try {
				_completion.parser.add_package_from_namespace ("GLib");
			} catch (Error err) {
				GLib.warning (err.message);
   			}

			setup_gsc_completion (view);
		}

		public void deactivate ()
		{
			GLib.debug ("sc deactvate");			
			GLib.debug ("sc deactvated");
		}

		private void setup_gsc_completion (Gedit.View view)
		{
			_manager = new Manager (view);
			_provider = new SymbolCompletionProvider (_plugin, view, _completion);

			var ck = new SymbolCompletionTrigger (_manager, "SymbolComplete");
			ManagerEventOptions *opt = new ManagerEventOptions ();
			opt->popup_options.position_type = PopupPositionType.CURSOR;
			opt->popup_options.filter_type = PopupFilterType.TREE;
			opt->autoselect = false;
			ck.set_opts (opt);
			_manager.register_trigger (ck);

			_manager.register_provider (_provider, "SymbolComplete");
			_manager.activate ();
		}
	}
}