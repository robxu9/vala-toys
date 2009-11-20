/*
 *  vtgvcsbackendsgit.vala - Vala developer toys for GEdit
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
using Vala;

namespace Vtg.Vcs.Backends
{
	public class Git : IVcs, GLib.Object
	{
		public Git ()
		{
			
		}
		
		public Vala.List<Item> get_items (string path) throws GLib.SpawnError
		{
			Vala.List<Item> results = new Vala.ArrayList<Item> ();
			string stdo, stde;
			int exit_status;
						
			if (Process.spawn_sync (path, new string[] { "git", "status" }, null, SpawnFlags.SEARCH_PATH, null, out stdo, out stde, out exit_status)) {
				int exit = Process.exit_status (exit_status);
				if (exit == 0 || exit == 1) {
					string[] lines = stdo.split ("\n");
					int idx = 0;
					PatternSpec modp = new PatternSpec ("#\tmodified:   *");
					PatternSpec newp = new PatternSpec ("#\tnew file:   *");
				
					while (lines[idx] != null) {
						string line = lines[idx];
						if (modp.match_string (line)) {
							Item item = new Item ();
							item.state = States.MODIFIED;
							item.name = line.replace ("#\tmodified:   ", "");
							results.add (item);
						} else if (newp.match_string (line)) {
							Item item = new Item ();
							item.state = States.ADDED;
							item.name = line.replace ("#\tnew file:   ", "");
							results.add (item);						
						}
						idx++;
					}
				} else {
					throw new VcsError.CommandFailed (_("error executing the git status command.\n%s").printf (stde));
				}
			}
			return results;
		}
		
		public bool test (string path)
		{
			string git_dir = Path.build_filename (path, ".git");
			
			if (FileUtils.test (git_dir, FileTest.IS_DIR)) {
				return true;
			}
			return false;
		}
	}
}
