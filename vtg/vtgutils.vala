/*
 *  vtgutils.vala - Vala developer toys for GEdit
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
using Gsc;
using Gtk;
using Vsc;

namespace Vtg
{
	public class Utils : GLib.Object
	{
		private static bool _initialized = false;

		private static Proposal[] _proposals = null;
		public const int prealloc_count = 500;

		public static weak Proposal[] get_proposal_cache ()
		{
			if (!_initialized) {
				initialize ();
			}
			return _proposals;
		}

		public static string get_image_path (string id) {
			var result = Path.build_filename (Config.PACKAGE_DATA_DIR, "images", id);
			debug ("image: %s", result);
			return result;
		}

		private static void initialize ()
		{
			try {
				_proposals = new Proposal[prealloc_count];
				var _icon_generic = IconTheme.get_default().load_icon(Gtk.STOCK_FILE,16,IconLookupFlags.GENERIC_FALLBACK);
				for (int idx = 0; idx < prealloc_count; idx++) {
					_proposals[idx] = new Proposal ("", "", _icon_generic);
				}

				_initialized = true;
			} catch (Error err) {
				warning (err.message);
			}
		}
	}
}