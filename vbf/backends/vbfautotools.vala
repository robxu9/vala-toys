/*
 *  vbfautotools.vala - Vala Build Framework library
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

namespace Vbf.Backends
{
	public class Autotools : IProjectBackend, GLib.Object
	{
		private unowned Project _project;
		private Vala.List<FileMonitor> file_mons = new Vala.ArrayList<FileMonitor> ();

		public string? configure_command {
			owned get {
				string result = null;

				if (_project != null && _project.working_dir != null) {
					foreach (string item in new string[] { "./configure", "./autogen.sh"}) {
						string file = Path.build_filename (_project.working_dir, item);
						if (FileUtils.test (file, FileTest.EXISTS)) {
							result = item;
							break;
						}
					}
				}

				return result;
			}
		}
		
		public string? build_command {
			owned get {
				return "make";
			}
		}
		
		public string? clean_command {
			owned get {
				return "make clean";
			}
		}

		/*
		 * check if the given directory is a base source dir
		 * of an autotool project.
		 */
		public bool probe (string project_file)
		{
			return Utils.is_autotools_project (project_file);
		}

		public Project? open (string project_file)
		{
			Project project = new Project(project_file);
			refresh (project);
			
			if (project.name == null)
				return null; //parse failed!
			else {
				_project = project;
				project.backend = this;
				return project;
			}
		}
		
		public void refresh (Project project)
		{
			cleanup_file_monitors ();
			try {
				string file = Path.build_filename (project.id, "configure.ac");
				string buffer;
				ulong length;

				if (!FileUtils.get_contents (file, out buffer, out length)) {
					return;
				}
				
				Regex reg = new GLib.Regex ("AC_INIT\\(([^\\,\\)]+)\\)");
				MatchInfo match;
				string name = null;
				string version = null;
				string url = null;
		
				if (reg.match (buffer, RegexMatchFlags.NEWLINE_ANY, out match)) {
					name = match.fetch (1);
				} else {
					reg = new GLib.Regex ("AC_INIT\\(([^\\,\\)]+),([^\\,\\)]+)\\)");
					if (reg.match (buffer, RegexMatchFlags.NEWLINE_ANY, out match)) {
						name = match.fetch (1);
						version = match.fetch (2);
					} else {
						reg = new GLib.Regex ("AC_INIT\\(([^\\,\\)]+),([^\\,\\)]+),([^\\,\\)]+)\\)");
						if (reg.match (buffer, RegexMatchFlags.NEWLINE_ANY, out match)) {
							name = match.fetch (1);
							version = match.fetch (2);
							url = match.fetch (3);
						} else {
							reg = new GLib.Regex ("AC_INIT\\(([^\\,\\)]+),([^\\,\\)]+),([^\\,\\)]+),([^\\,\\)]+)\\)");
							if (reg.match (buffer, RegexMatchFlags.NEWLINE_ANY, out match)) {
								name = match.fetch (1);
								version = match.fetch (2);
								url = match.fetch (3);
							} else {
								reg = new GLib.Regex ("AC_INIT\\s*\\(\\[(.*)\\],\\s*\\[(.*)\\],\\s*\\[(.*)\\],", GLib.RegexCompileFlags.MULTILINE);
								if (reg.match (buffer, RegexMatchFlags.NEWLINE_ANY, out match)) {
									name = match.fetch (1);
									version = match.fetch (2);
									url = match.fetch (3);
								}
							}
						}
					}
				}
			
				project.clear ();
				project.name = normalize_string (name);
				project.version = normalize_string (version);
				project.url = normalize_string (url);
				project.working_dir = project.id;
				
				parse_variables (project, buffer);
				resolve_variables (project, project.get_variables ());
				
				//Extract pkg-config packages
				reg = new GLib.Regex ("PKG_CHECK_MODULES\\([\\s\\[]*([^\\,\\)\\]]+)[\\s\\]]*\\,(.+?)\\)");
				if (reg.match (buffer, RegexMatchFlags.NEWLINE_CR, out match)) {
					while (match.matches ()) {
						string mod_name =  match.fetch (1);
						string pacs = "";
			
						string line = match.fetch (2);
						Regex mod = new Regex ("^[\\s\\]]*([^\\,\\]]+)[\\s\\]]*,([^\\,]+),([^\\,]+)$");
						MatchInfo pac;
						if (mod.match (line, RegexMatchFlags.NEWLINE_CR, out pac)) {
							pacs = pac.fetch (1);
						} else {
							mod = new Regex ("^[\\s\\]]*([^\\,\\]]+)[\\s\\]]*,([^\\,]+)$");
							if (mod.match (line, RegexMatchFlags.NEWLINE_CR, out pac)) {
								pacs = pac.fetch (1);
							} else {
								pacs = line;
							}
						}
						var module = new Module (project, mod_name);
						project.add_module (module);
						if (pacs != "") {
							string[] pkgs = normalize_string (pacs).split (" ");
							int idx = 0;
							while (pkgs[idx] != null) {
								string pkg = pkgs[idx];
								if (pkg == "\\") {idx++; continue;}
								string variable = pkg.str ("$");
								
								if (variable != null) {
									var var_name = variable.replace ("(", "").replace (")", "").substring (1);
									Utils.trace ("Resoving variables: %s", var_name);
									var res = this.resolve_variable (var_name, project.get_variables ());
									if (res != null) {
										Utils.trace ("resolved: %s", res.get_value ().to_string ());
										pkg = pkg.replace (variable, res.get_value ().to_string ());
									}
								}

								Package package = new Package (pkg);
								module.add_package (package);
								idx++;
								if (pkgs[idx] == ">=" ||
								    pkgs[idx] == ">" ||
	    							    pkgs[idx] == "=") {
	    							    	package.constraint = pkgs[idx];
	    								idx++;
	    								ConfigNode node;
	    								var val = pkgs[idx];
	    								if (val.has_prefix ("$")) {
	    									node = new UnresolvedConfigNode (pkgs[idx].substring (1, pkgs[idx].length -1));
	    								} else if (val != null){
	    									node = new StringLiteral (pkgs[idx]);
	    								} else {
	    									node = new StringLiteral ("");
	    								}
	    							    	package.version = node;
	    							    	idx++;
	  							}
							}
						}
						match.next ();
					}
				}
			

				resolve_package_variables (project);
			
				//Extract AC_CONFIG_FILES
				reg = new GLib.Regex ("AC_CONFIG_FILES\\(\\[([^\\]\\)]*)\\]\\)", RegexCompileFlags.MULTILINE);
				bool res = reg.match (buffer, RegexMatchFlags.NEWLINE_CR, out match);
				if (!res) {
					reg = new GLib.Regex ("AC_OUTPUT\\(\\[([^\\]\\)]*)\\]\\)", RegexCompileFlags.MULTILINE);
					res = reg.match (buffer, RegexMatchFlags.NEWLINE_CR, out match);
				}
				if (res) {
					string tmp = normalize_string (match.fetch (1));
					string[] makefiles = tmp.split(" ");
					foreach (string makefile in makefiles) {
						parse_makefile (project, project.id, makefile);
					}
				}
				if (project.name != null) {
					setup_file_monitors (project);
				}
			} catch (Error err) {
				critical ("open: %s", err.message);
				return;
			}
		}
		
		private FileTypes source_file_type (string name)
		{
			if (name.has_suffix (".vala") || name.has_suffix (".vapi") || name.has_suffix (".gs"))
				return FileTypes.VALA_SOURCE;
			else
				return FileTypes.OTHER_SOURCE;
		}
		
		private void add_source (Group group, Target target, ConfigNode source)
		{
			string src_path, src_filename;
			if (source is StringLiteral) {
				src_filename = ((StringLiteral) source).data;
				if (src_filename != null && src_filename != "") {
					src_path = Path.build_filename (group.id, src_filename);
					var src = new Source.with_type (target, src_path, source_file_type (src_path));
					target.add_source (src);
				}
			} else if (source is Variable) {
				add_source (group, target, ((Variable) source).get_value ());
			} else if (source is ConfigNodeList) {
				foreach (ConfigNode item in ((ConfigNodeList) source).get_values ()) {
					if (item is StringLiteral) {
						src_filename = ((StringLiteral) item).data;
						if (src_filename != null && src_filename != "") {
							src_path = Path.build_filename (group.id, src_filename);
							var src = new Source.with_type (target, src_path, source_file_type (src_path));
							target.add_source (src);
						}
					} else if (item is Variable) {
						add_source (group, target, ((Variable) item).get_value ());
					} else if (item is ConfigNodeList){
						add_source (group, target, item);
					}
				}
			} else {
				warning ("add_vala_source: unsupported source type %s", Type.from_instance (source).name ());
			}
		}
		
		private void add_vala_sources (Group group, Target target)
		{
			string source_primary_name = "%s_SOURCES".printf (convert_to_primary_name (target.id));
			string valasource_primary_name = "%s_VALASOURCES".printf (convert_to_primary_name (target.id));

			foreach (Variable variable in group.get_variables ()) {
				if (variable.name == target.id || variable.name == source_primary_name || variable.name == valasource_primary_name) {
					var val = variable.get_value ();
					add_source (group, target, val);
					break;
				}
			}
		}

		private void add_target (Group group, TargetTypes type, string target_id)
		{
			Target target;
			string normalized_id = normalize_target_id (target_id);
			if (!group.contains_target (normalized_id)) {
				string name = normalize_target_id_for_display (target_id);
				target = new Target (group, type, normalized_id, name);
				group.add_target (target);
				add_vala_sources (group, target);
			}
		}

		private void add_targets (Group group, ConfigNode node, TargetTypes type)
		{
			if (node is StringLiteral) {
				add_target (group, type, ((StringLiteral) node).data);
			} else {
				foreach (ConfigNode item in ((ConfigNodeList) node).get_values ()) {
					if (item is StringLiteral) {
						add_target (group, type, ((StringLiteral) item).data);
					} else if (item is ConfigNodeList) {
						add_targets (group, item, type);
					}
				}
			}
		}
		
		private void add_data_files (Group group, Target target, ConfigNode file)
		{
			string name;
			if (file is StringLiteral) {
				name = Path.build_filename (group.id, ((StringLiteral) file).data);
				var f = new File.with_type (target, name, FileTypes.DATA);
				target.add_file (f);
			} else if (file is Variable) {
				add_data_files (group, target, ((Variable) file).get_value ());
			} else if (file is ConfigNodeList) {
				foreach (ConfigNode item in ((ConfigNodeList) file).get_values ()) {
					if (item is StringLiteral) {
						name = Path.build_filename (group.id, ((StringLiteral) item).data);
						var f = new File.with_type (target, name, FileTypes.DATA);
						target.add_file (f);
					} else if (item is Variable) {
						add_data_files (group, target, ((Variable) item).get_value ());
					} else if (item is ConfigNodeList){
						add_data_files (group, target, item);
					}
				}
			} else {
				warning ("add_vala_source: unsupported source type");
			}
		}
		
		private void parse_targets (Group group)
		{
			foreach (Variable variable in group.get_variables ())	{
				if (variable.name.has_suffix ("_PROGRAMS")) {
					add_targets (group, variable.get_value (), TargetTypes.PROGRAM);
				} else if (variable.name.has_suffix ("_LTLIBRARIES") || 
					   variable.name.has_suffix ("_LIBRARIES")) {
					add_targets (group, variable.get_value (), TargetTypes.LIBRARY);
				} else if (variable.name.has_suffix ("_DATA")) {
					var target = new Target (group, TargetTypes.DATA, "data", "data");
					add_data_files (group, target, variable.get_value ());
					group.add_target (target);
				} else if (variable.name == "BUILT_SOURCES") {
					add_targets (group, variable.get_value (), TargetTypes.BUILT_SOURCES);
				}
			}
		}
		
		private void parse_variables (Project project, string buffer, Group? group = null) throws Error
		{
			string[] lines = buffer.split ("\n");
			string tmp = null;
			
			foreach (string line in lines) {
				if (tmp == null) {
					tmp = normalize_string (line);
				} else {
					tmp += " " + normalize_string (line);
				}
				
				if (tmp.has_suffix ("\\")) {
					tmp = tmp.substring (0, tmp.length - 1);
					continue; //line continuation grab the next line
				}
				
				if (tmp.has_prefix ("#") || tmp == "") {
					tmp = null;
					continue;
				}
				
				bool append = false;
				string[] toks = tmp.split ("=", 2);
				
				
				if (toks[1] == null) {
					toks = tmp.split (":", 2);
				}
				
				if (toks[1] == null) {
					tmp = null;
					continue; //unrecognized pattern
				}
				
				//check if is an append to var
				if (toks[0].has_suffix ("+")) {
					append = true;
					toks[0] = toks[0].substring (0, toks[0].length - 1);
				}
				string[] lhs = toks[0].split (" ");
				string[] rhs = toks[1].split (" ");

				foreach (string lh in lhs) {
					if (lh == null || lh == "")
						continue;
					
					string name = lh.strip ();
					
					var variable = new Variable(name, project);
					ConfigNode data;
				
					if (rhs[0] != null) {
						if (rhs[1] == null) {
							// single value
							string val = rhs[0].strip ();
			
							if (val.has_prefix ("$")) {
								val = val.substring (1, val.length - 1);
								val = val.replace ("(", "").replace (")", "");
								data = new UnresolvedConfigNode (val);
							} else if (val != null){
								data = new StringLiteral (val);
							} else {
								data = new StringLiteral ("");
							}
						} else {
							// list of values
							ConfigNodeList items = new ConfigNodeList ();
				
							foreach (string rh in rhs) {
								if (rh != null && rh.strip () != "") {
									ConfigNode node;
									string val = rh.strip ();
				
									if (val.has_prefix ("$")) {
										val = val.substring (1, val.length - 1);
										val = val.replace ("(", "").replace (")", "");
										node = new UnresolvedConfigNode (val);
									} else if (val != null){
										node = new StringLiteral (val);
									} else {
										critical ("%s is null", rh);
										node = new StringLiteral ("");
									}
							
									items.add_value (node);
								}
							}
							data = items;
						}
						variable.data = data;
					} else {
						// empty variable
						variable.data = new StringLiteral ("");
					}

					if (group != null) {
						group.add_variable (variable);
					} else {
						project.add_variable (variable);
					}
				}

				tmp = null; //restart from a new line
			}
		}
		
		private Variable? resolve_variable (string variable_name, Vala.List<Variable> variables)
		{
			Variable variable = null;
			foreach (Variable item in variables) {
				if (variable_name == item.name) {
					variable = item;
					break;
				}
			}
			
			return variable;
		}
		
		private void resolve_package_variables (Project project)
		{
			//resolve package version variables
			var variables = project.get_variables ();
			
			foreach (Module module in project.get_modules ()) {
				foreach (Package package in module.get_packages ()) {
					if (package.version is UnresolvedConfigNode) {
						var name = ((UnresolvedConfigNode) package.version).name;
						var target_variable = resolve_variable (name, variables);
						if (target_variable != null) {
							package.version = target_variable.data;
						}
					}
				}
			}
		}
		private void resolve_variables (Project project, Vala.List<Variable> variables)
		{
			Variable target_variable;
			string name;
			
			//resolve variables
			foreach (Variable variable in variables) {
				if (variable.data is UnresolvedConfigNode) {
					name = ((UnresolvedConfigNode) variable.data).name;
					target_variable = resolve_variable (name, variables);
					if (target_variable == null)
						target_variable = resolve_variable (name, project.get_variables ());
						
					if (target_variable != null) {
						variable.data = target_variable;
						variable.parent = target_variable;
						target_variable.add_child (variable);
					}
				} else if (variable.data is ConfigNodeList) {
					ConfigNodeList datas = ((ConfigNodeList)variable.data);
					Vala.List<ConfigNodePair> resolved_nodes = new Vala.ArrayList<ConfigNodePair> ();
					
					foreach (ConfigNode data in datas.get_values ()) {
						if (data is UnresolvedConfigNode) {
							name = ((UnresolvedConfigNode) data).name;
							target_variable = resolve_variable (name, variables);
							if (target_variable == null)
								target_variable = resolve_variable (name, project.get_variables ());

							if (target_variable != null) {
								if (target_variable.data != null) {
									var child = new Variable (name, target_variable);
									child.data = target_variable;
									target_variable.add_child (child);
									resolved_nodes.add (new ConfigNodePair (data, child));
								} else {
									resolved_nodes.add (new ConfigNodePair (data, null));
								}
							}
						}
					}
					
					//modify the references
					foreach (ConfigNodePair resolved_node in resolved_nodes) {
						datas.replace_config_node (resolved_node.source, resolved_node.destination);
					}
				}
			}
		}
		
		private string process_include_directives (string makefile, string buffer) throws Error
		{
			string res = buffer;
			string[] lines = buffer.split ("\n");
			foreach (string line in lines) {
				if (line == "")
					continue;
				line = normalize_string (line);
				string[] tmps = line.split (" ", 2);

				if (tmps[0] == "include") {
					string filename = normalize_string (tmps[1]);
					string include_filename = makefile.replace ("Makefile.am", filename);
					string included_file;
					try {
						if (FileUtils.test (include_filename, FileTest.EXISTS)) {
							if (FileUtils.get_contents (include_filename, out included_file)) {
								res = res.replace ("include %s".printf(filename), included_file);
							}
						}
					} catch (Error e) {
						warning ("Cannot include %s", filename);
 					}
				}
			}
			return res;
		}
		
		private void parse_makefile (Project project, string project_file, string makefile) throws Error
		{
			if (!makefile.has_suffix ("Makefile"))
				return;
				
			string buffer;
			string file = Path.build_filename (project_file, makefile) + ".am";
			
			if (FileUtils.get_contents (file, out buffer)) {
				var group = new Group (project, file.replace ("Makefile.am", ""));
				project.add_group (group);
				buffer = process_include_directives (file, buffer);
				parse_variables (project, buffer, group);
				resolve_variables (project, group.get_variables ());
				parse_targets (group);
				parse_group_extended_info (group, buffer);
			}
		}
		
		private void parse_group_extended_info (Group group, string buffer)
		{
			string[] lines = buffer.split ("\n");
			Target? target = null;
			
			foreach (string line in lines) {
				line = normalize_string (line);
				if (line == "")
				{
					if (target != null) {
						target = null;
					}
					continue; //skip this line
				}
				//try extract the the rule target name
				if (target == null) {
					string[] rule_parts = line.split ("=", 2);
					if (rule_parts.length >= 2 && rule_parts[0].chomp().has_suffix ("_VALAFLAGS")) {
						// automake 1.11 with vala support
						string target_id = "";
						
						string[] target_tmp = rule_parts[0].split ("_");
						for (int i=0; i < target_tmp.length - 1; i++) {
							target_id = target_id.concat (target_tmp[i], ".");
						}
						while (target_id.has_suffix ("."))
							target_id = target_id.substring (0, target_id.length - 1);

						target_id = normalize_target_id (target_id);
						target_id = convert_to_primary_name (target_id);
						foreach (var t in group.get_targets ()) {
							if (target_id == t.id) {
								target = t;
								break;
							}
						}
						Utils.trace ("group %s - target for: %s is %s", group.id, target_id, target == null ? "not found!" : target.id);
					} else {
						rule_parts = line.split (":", 2);
						if (rule_parts.length == 2) {
							string[] trgs = rule_parts[0].split (" ");
							//TODO: add support for multitarget rules if required
							foreach (string trg in trgs) {
								var id = normalize_target_id (trg);
								target = group.get_target_for_id (id);
								if (target != null) {
									break;
								}
							}
						}
					}
				}

				string[] tmps = line.split (" ");
				int count = tmps.length;
			
				for(int idx=0; idx < count; idx++) {
					if (tmps[idx] == "--vapidir" && (idx + 1) < count) {
						var tmp = tmps[idx+1];

						Utils.trace ("vapi: %s", tmp);
						if (tmp.has_prefix (".")) {
							tmp = Path.build_filename (group.project.id, group.name, tmp);
						} else if (tmp.has_prefix("$(srcdir)")) {
							tmp = tmp.replace ("$(srcdir)", Path.build_filename (group.project.id, group.name));
						} else if (tmp.has_prefix("$(top_srcdir)")) {
							tmp = tmp.replace ("$(top_srcdir)", group.project.id);
						} else {
							tmp = Path.build_filename (group.project.id, group.name, tmp);
						}

						if (target != null) {
							target.add_include_dir (tmp);
						} else {
							Utils.trace ("adding vapidir %s to group because target is null", tmp);
							group.add_include_dir (tmp);
						}
						idx++;
					} else if (tmps[idx] == "--pkg" && (idx + 1) < count) {
						var tmp = tmps[idx+1];
						string variable = tmp.str ("$");
						if (variable != null) {
							var var_name = variable.replace ("(", "").replace (")", "").substring (1);
							var res = this.resolve_variable (var_name, group.project.get_variables ());
							if (res != null) {
								tmp = tmp.replace (variable, res.get_value ().to_string ());
							}
						}
						if (target != null) {
							target.add_package (new Package (tmp));
						} else {
							Utils.trace ("adding package %s to group because target is null", tmp);
							group.add_package (new Package (tmp));
						}
						idx++;
					} else if (tmps[idx] == "--library") {
						var tmp = tmps[idx+1];
						if (target != null) {
							target.add_built_library (tmp);
						} else {
							group.add_built_library (tmp);
						}
						idx++;
					}
				}
			}
		}
		
		private string? normalize_string (string? data)
		{
			if (data == null) {
				return null;
			}
			string res = data.replace ("\n", " ");
			res = res.replace ("\t", " ");
			string old = null;
			while (old != res) {
				old = res;
				res = res.replace ("  ", " ");
			}
			res = res.strip ();
			
			if (res.has_prefix ("[")) {
				res = res.substring (1, res.length - 1);
			}
			if (res.has_suffix ("]")) {
				res = res.substring (0, res.length - 1);
			}
			return res;
		}

		private string normalize_target_id (string target_id)
		{
			var result = target_id;
			if (result.has_suffix ("_VALASOURCES")) {
				result = result.substring (0, result.length - "_VALASOURCES".length);
			} else if (result.has_suffix ("_SOURCES")) {
				result = result.substring (0, result.length - "_SOURCES".length);
			} else if (result.has_suffix (".stamp")) {
				result = result.substring (0, result.length - ".stamp".length);
				if (result.has_suffix (".vala")) {
					result = result.substring (0, result.length - ".vala".length);
				}
			}

			return convert_to_primary_name (result);
		}

		private string normalize_target_id_for_display (string target_id)
		{
			var result = target_id;
			if (result.has_suffix ("_VALASOURCES")) {
				result = result.substring (0, result.length - "_VALASOURCES".length);
			} else if (result.has_suffix ("_SOURCES")) {
				result = result.substring (0, result.length - "_SOURCES".length);
			} else if (result.has_suffix (".stamp")) {
				result = result.substring (0, result.length - ".stamp".length);
				if (result.has_suffix (".vala")) {
					result = result.substring (0, result.length - ".vala".length);
				}
			}

			if (result.has_suffix ("_la") || result.has_suffix ("_so")
			    || result.has_suffix (".la") || result.has_suffix (".so")) {
				result = result.substring(0, result.length - 3);
			}
			return result;
		}

		private string convert_to_primary_name (string data)
		{
			return data.replace (".", "_").replace ("-", "_");
		}

		private void setup_file_monitors (Project project)
		{
			try {
				string fname;
				GLib.File file;
				FileMonitor file_mon;

				foreach (Group group in project.get_groups ()) {
					fname = Path.build_filename (group.id, "Makefile.am");
					Utils.trace ("setup_file_monitors for: %s", fname);
					file = GLib.File.new_for_path (fname);
					file_mon = file.monitor_file (FileMonitorFlags.NONE);
					file_mon.changed.connect (this.on_project_file_changed);
					file_mons.add (file_mon);
				}
				fname = Path.build_filename (project.id, "configure.ac");
				file = GLib.File.new_for_path (fname);
				file_mon = file.monitor_file (FileMonitorFlags.NONE);
				file_mon.changed.connect (this.on_project_file_changed);
				file_mons.add (file_mon);

			} catch (Error err) {
				critical ("setup_file_monitors error: %s", err.message);
			}
		}

		private void cleanup_file_monitors ()
		{
			foreach (FileMonitor file_mon in file_mons) {
				file_mon.changed.disconnect(this.on_project_file_changed);
				file_mon.cancel ();
			}
			file_mons.clear ();
		}

		private void on_project_file_changed (FileMonitor sender, GLib.File file, GLib.File? other_file, GLib.FileMonitorEvent event_type)
		{
			if (!sender.is_cancelled ()) {
				if (event_type == FileMonitorEvent.CHANGES_DONE_HINT) {
					_project.update ();
				}
			}
		}

	}
}
