/*
 *  vtgvcsbackendsbzr.vala - Vala developer toys for GEdit
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

namespace Vtg.Vcs.Backends
{
	public class Bzr : IVcs, GLib.Object
	{
		public Bzr ()
		{
			
		}
		
		public Gee.List<Item> get_items (string path) throws GLib.Error
		{
			Gee.List<Item> results = new Gee.ArrayList<Item> ();
			string stdo, stde;
			int exit_status;
						
			if (Process.spawn_sync (path, new string[] { "bzr", "status" }, null, SpawnFlags.SEARCH_PATH, null, out stdo, out stde, out exit_status)) {
				int exit = Process.exit_status (exit_status);
				if (exit == 0) {
					string[] lines = stdo.split ("\n");
					int idx = 0;
					int status = 0;
					
					while (lines[idx] != null) {
						string line = lines[idx];
						if (line.has_prefix("added:")) {
							status = 1;
						} else if (line.has_prefix ("modified:")) {
							status = 2;
						} else if (!line.has_prefix ("  ")) {
							status = 0;
						} else if (line.has_prefix ("  ")) {
							switch (status)	{
								case 1:
								case 2:
									Item item = new Item ();
									item.state = (status == 1 ? States.ADDED : States.MODIFIED);
									item.name = line.substring (2, line.length - 2);
									results.add (item);
									break;

							}
						}
						idx++;
					}
				} else {
					throw new VcsError.CommandFailed (_("error executing the bzr status command.\n%s").printf (stde));
				}
			}
			return results;		
		}
		
		public bool test (string path)
		{
			string bzr_dir = Path.build_filename (path, ".bzr");
			
			if (FileUtils.test (bzr_dir, FileTest.IS_DIR)) {
				return true;
			}
			return false;
		}

	}
}
