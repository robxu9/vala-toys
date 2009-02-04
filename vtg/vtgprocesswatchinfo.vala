/*
 *  vtgprocesswatchinfo.vala - Vala developer toys for GEdit
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

namespace Vtg
{
	internal class ProcessWatchInfo
	{
		public uint id = 0;
		public IOChannel stdin = null;
		public IOChannel stdout = null;
		public IOChannel stderr = null;

		public uint stdout_watch_id = 0;
		public uint stderr_watch_id = 0;

		public ProcessWatchInfo (uint id)
		{
			this.id = id;
		}

		public void cleanup ()
		{
			try {
				if (stdin != null)
					stdin.flush ();      

				stdout.flush ();
				stderr.flush ();

				if (stdout_watch_id != 0) {
					Source.remove (stdout_watch_id);
				}
				if (stderr_watch_id != 0) {
					Source.remove (stderr_watch_id);
				}
				stdin = null;
				stdout = null;
				stderr = null;
			} catch (Error err) {
				GLib.warning ("cleanup - error: %s", err.message);
			}
		}
	}
}
