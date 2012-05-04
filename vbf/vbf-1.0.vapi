/* vbf-1.0.vapi generated by valac 0.16.0, do not modify. */

namespace Vbf {
	namespace Backends {
		[CCode (cheader_filename = "vbf.h")]
		public class Autotools : Vbf.IProjectBackend, GLib.Object {
			public Autotools ();
		}
		[CCode (cheader_filename = "vbf.h")]
		public class SmartFolder : Vbf.IProjectBackend, GLib.Object {
			public SmartFolder ();
		}
	}
	namespace Utils {
		[CCode (cheader_filename = "vbf.h")]
		public static string? guess_package_vapi (string using_name, string[]? vapi_dirs = null);
		[CCode (cheader_filename = "vbf.h")]
		public static bool is_autotools_project (string path);
		[CCode (cheader_filename = "vbf.h")]
		public static bool is_cmake_project (string path);
		[CCode (cheader_filename = "vbf.h")]
		public static bool is_simple_make_project (string path);
		[CCode (cheader_filename = "vbf.h")]
		public static bool is_waf_project (string path);
	}
	[CCode (cheader_filename = "vbf.h")]
	public abstract class ConfigNode : GLib.Object {
		public weak Vbf.ConfigNode parent;
		public ConfigNode ();
		public abstract string to_string ();
	}
	[CCode (cheader_filename = "vbf.h")]
	public class ConfigNodeList : Vbf.ConfigNode {
		protected Vala.List<Vbf.ConfigNode> values;
		public ConfigNodeList ();
		public void add_value (Vbf.ConfigNode val);
		public Vala.List<Vbf.ConfigNode> get_values ();
		public void replace_config_node (Vbf.ConfigNode source, Vbf.ConfigNode target);
		public override string to_string ();
	}
	[CCode (cheader_filename = "vbf.h")]
	public class ConfigNodePair : GLib.Object {
		public Vbf.ConfigNode? destination;
		public Vbf.ConfigNode source;
		public ConfigNodePair (Vbf.ConfigNode source, Vbf.ConfigNode? destination);
	}
	[CCode (cheader_filename = "vbf.h")]
	public class File : GLib.Object {
		public string filename;
		public string name;
		public weak Vbf.Target target;
		public Vbf.FileTypes type;
		public string uri;
		public File (Vbf.Target target, string filename);
		public void update_file_data (string filename);
		public File.with_type (Vbf.Target target, string filename, Vbf.FileTypes type);
	}
	[CCode (cheader_filename = "vbf.h")]
	public class Group : GLib.Object {
		public string id;
		public string name;
		public weak Vbf.Project project;
		public Group (Vbf.Project project, string id);
		public void add_target (Vbf.Target target);
		public bool contains_target (string id);
		public Vala.List<string> get_built_libraries ();
		public Vala.List<string> get_include_dirs ();
		public Vala.List<Vbf.Package> get_packages ();
		public Vala.List<Vbf.Group> get_subgroups ();
		public Vbf.Target? get_target_for_id (string id);
		public Vala.List<Vbf.Target> get_targets ();
		public Vala.List<Vbf.Variable> get_variables ();
		public bool has_sources_of_type (Vbf.FileTypes type);
	}
	[CCode (cheader_filename = "vbf.h")]
	public class Module : GLib.Object {
		public string id;
		public string name;
		public weak Vbf.Project project;
		public Module (Vbf.Project project, string id);
		public Vala.List<Vbf.Package> get_packages ();
	}
	[CCode (cheader_filename = "vbf.h")]
	public class Package : GLib.Object {
		public string constraint;
		public string id;
		public string name;
		public weak Vbf.Group parent_group;
		public weak Vbf.Module parent_module;
		public weak Vbf.Target parent_target;
		public Vbf.ConfigNode version;
		public Package (string id);
		public string uri { get; }
	}
	[CCode (cheader_filename = "vbf.h")]
	public class Project : Vbf.ConfigNode {
		public string id;
		public string name;
		public string url;
		public string version;
		public string working_dir;
		public Project (string id);
		public void add_group (Vbf.Group group);
		public string get_all_source_files ();
		public Vbf.Group? get_group (string id);
		public Vala.List<Vbf.Group> get_groups ();
		public Vala.List<Vbf.Module> get_modules ();
		public Vala.List<Vbf.Variable> get_variables ();
		public override string to_string ();
		public void update ();
		public string? build_command { owned get; }
		public string? clean_command { owned get; }
		public string? configure_command { owned get; }
		public signal void updated ();
	}
	[CCode (cheader_filename = "vbf.h")]
	public class Source : Vbf.File {
		public Source (Vbf.Target target, string filename);
		public Source.with_type (Vbf.Target target, string filename, Vbf.FileTypes type);
	}
	[CCode (cheader_filename = "vbf.h")]
	public class StringLiteral : Vbf.ConfigNode {
		public string data;
		public StringLiteral (string data);
		public override string to_string ();
	}
	[CCode (cheader_filename = "vbf.h")]
	public class Target : GLib.Object {
		public weak Vbf.Group group;
		public string id;
		public string name;
		public bool no_install;
		public Vbf.TargetTypes type;
		public Target (Vbf.Group group, Vbf.TargetTypes type, string id, string name);
		public void add_package (Vbf.Package package);
		public void add_source (Vbf.Source source);
		public bool contains_include_dir (string dir);
		public bool contains_package (string package_id);
		public Vala.List<string> get_built_libraries ();
		public Vala.List<Vbf.File> get_files ();
		public Vala.List<string> get_include_dirs ();
		public Vala.List<Vbf.Package> get_packages ();
		public Vbf.Source? get_source (string filename);
		public Vala.List<Vbf.Source> get_sources ();
		public bool has_file_of_type (Vbf.FileTypes type);
		public bool has_file_with_extension (string extension);
		public bool has_sources_of_type (Vbf.FileTypes type);
		public void remove_source (Vbf.Source source);
	}
	[CCode (cheader_filename = "vbf.h")]
	public class UnresolvedConfigNode : Vbf.ConfigNode {
		public string name;
		public UnresolvedConfigNode (string name);
		public override string to_string ();
	}
	[CCode (cheader_filename = "vbf.h")]
	public class Variable : Vbf.ConfigNode {
		public Vbf.ConfigNode? data;
		public string name;
		public Variable (string name, Vbf.ConfigNode parent);
		public void add_child (Vbf.Variable variable);
		public Vala.List<Vbf.Variable> get_childs ();
		public Vbf.ConfigNode get_value ();
		public override string to_string ();
	}
	[CCode (cheader_filename = "vbf.h")]
	public interface IProjectBackend : GLib.Object {
		public abstract Vbf.Project? open (string project_file);
		public abstract bool probe (string project_file);
		public abstract void refresh (Vbf.Project project);
		public abstract string? build_command { owned get; }
		public abstract string? clean_command { owned get; }
		public abstract string? configure_command { owned get; }
	}
	[CCode (cheader_filename = "vbf.h")]
	public enum FileTypes {
		UNKNOWN,
		DATA,
		VALA_SOURCE,
		OTHER_SOURCE
	}
	[CCode (cheader_filename = "vbf.h")]
	public enum TargetTypes {
		PROGRAM,
		LIBRARY,
		DATA,
		BUILT_SOURCES
	}
	[CCode (cheader_filename = "vbf.h")]
	public static bool probe (string path, out Vbf.IProjectBackend backend);
}
