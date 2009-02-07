/*
 *  vbftest.vala - Vala Build Framework library
 *  
 *  Copyright (C) 2008 - Andrea Del Signore <sejerpz@tin.it>
 *  
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;
using Vbf;

namespace Vbf.Tests
{
	public class OpenTest
	{
		[NoArrayLength ()]
		static string[] projects;
		static bool dump_variables;
		
		const OptionEntry[] options = {
			{ "dump-variables", 'd', 0, OptionArg.INT, ref dump_variables, "Dump variables", "0 or 1" },
			{ "", 0, 0, OptionArg.FILENAME_ARRAY, ref projects, "Projects DIR", "PROJECT_DIR" },
			{ null }
		};
		
		public bool run (string project_name)
		{
			IProjectManager pm = new Am.ProjectManager (); 
			print ("Probing directory '%s' ...", project_name);
			bool res = pm.probe (project_name);
			print ("%s\n", res ? "OK" : "KO");
			if (res) {
				print ("Opening project\n");
				var project = pm.open (project_name);
				if (project != null) {
					print ("Dumping...\n");
					dump_project (project);
					return true;
				} else {
					print ("Error\n");
					return false;
				}

			}
			return false;
		}
		
		private void dump_project (Project project)
		{
			print ("PROJECT:\n");
			print ("  name.... %s\n", project.name);
			print ("  version. %s\n", project.version);
			print ("  url..... %s\n", project.url);
			print ("  MODULES\n");
			foreach (Module module in project.get_modules ()) {
				print ("    MODULE\n");
				print ("      name %s\n", module.name);
				print ("      PACKAGES\n");
				foreach (Package package in module.get_packages ()) {
					print ("        PACKAGE\n");
					print ("          name....... %s\n", package.name);
					print ("          constraint. %s\n", package.constraint);
					print ("          version.... %s\n", package.version.to_string ());
				}
			}
			print ("  GROUPS\n");
			foreach (Group group in project.get_groups ()) {
				print ("    GROUP\n");
				print ("      name %s\n", group.name);				
				print ("      TARGETS\n");
				foreach (Target target in group.get_targets ()) {
					print ("        TARGET\n");
					print ("          name %s\n", target.name);
					print ("          SOURCES\n");
					foreach (Source source in target.get_sources ()) {
						print ("            SOURCE filename %s\n", source.filename);
					}
					print ("          OTHER FILES\n");
					foreach (Vbf.File file in target.get_files ()) {
						print ("            FILES filename %s\n", file.filename);
					}
					print ("          REFERENCED PACKAGES\n");
					foreach (Package package in target.get_packages ()) {
						print ("            name....... %s\n", package.name);
					}

				}
				print ("      REFERENCED PACKAGES\n");
				foreach (Package package in group.get_packages ()) {
					print ("        PACAKGE: %s", package.name);
					print ("\n");
				}
				if (dump_variables) {
					print ("      GROUP VARIABLES\n");
					foreach (Variable variable in group.get_variables ()) {
						print ("        VARIABLE: %s", variable.to_string ());
						print ("\n");
					}
				}
			}
			
			if (dump_variables) {
				print ("  GLOBAL VARIABLES\n");
				foreach (Variable variable in project.get_variables ()) {
					print ("    VARIABLE: %s", variable.to_string ());
					print ("\n");
				}
			}
		}
	
		public static int main (string[] args)
		{
			try {
		                var opt_context = new OptionContext ("- Vala Build Framework Utility");
		                opt_context.set_help_enabled (true);
		                opt_context.add_main_entries (options, null);
		                opt_context.parse (ref args);
		        } catch (OptionError e) {
		                stdout.printf ("%s\n", e.message);
		                stdout.printf (_("Run '%s --help' to see a full list of available command line options.\n"), args[0]);
		                return 1;
		        }

			var test = new OpenTest ();
			return test.run (projects[0]) ? 0 : 1;
		}
	}
}
