/* gnome-build-1.0.vapi generated by vapigen, do not modify. */

[CCode (cprefix = "Gbf", lower_case_cprefix = "gbf_")]
namespace Gbf {
	[CCode (cprefix = "GBF_PROJECT_", cheader_filename = "gbf/gbf-project.h")]
	public enum ProjectCapabilities {
		CAN_ADD_NONE,
		CAN_ADD_GROUP,
		CAN_ADD_TARGET,
		CAN_ADD_SOURCE,
		CAN_PACKAGES
	}
	[CCode (cprefix = "GBF_TREE_NODE_", has_type_id = "0", cheader_filename = "gbf/gbf-tree-data.h")]
	public enum TreeNodeType {
		STRING,
		GROUP,
		TARGET,
		TARGET_SOURCE
	}
	[CCode (ref_function = "gbf_backend_ref", unref_function = "gbf_backend_unref", cheader_filename = "gbf/gbf-backend.h")]
	public class Backend {
		public weak string id;
		public weak string name;
		public weak string description;
		public static Gbf.Project new_project (string id);
		public Backend ();
		public static weak GLib.SList<Gbf.Backend> get_backends ();
		public static void init ();
	}
	[CCode (ref_function = "gbf_project_util_ref", unref_function = "gbf_project_util_unref", cheader_filename = "gbf/gbf-project-util.h")]
	public class ProjectUtil {
		public static weak string add_source (Gbf.ProjectModel model, Gtk.Window parent, string default_target, string default_group, string default_uri_to_add);
		public static weak GLib.List<string> add_source_multi (Gbf.ProjectModel model, Gtk.Window parent, string default_target, string default_group, GLib.List uris_to_add);
		public static weak string new_group (Gbf.ProjectModel model, Gtk.Window parent, string default_group, string default_group_name_to_add);
		public static weak string new_target (Gbf.ProjectModel model, Gtk.Window parent, string default_group, string default_target_name_to_add);
		public ProjectUtil ();
	}
	[Compact]
	[CCode (copy_function = "gbf_tree_data_copy", cheader_filename = "gbf/gbf-tree-data.h")]
	public class TreeData {
		public Gbf.TreeNodeType type;
		public weak string name;
		public weak string id;
		public weak string uri;
		public bool is_shortcut;
		public weak string mime_type;
		public weak Gbf.TreeData copy ();
		public TreeData.group (Gbf.Project project, Gbf.ProjectGroup group);
		public TreeData.source (Gbf.Project project, Gbf.ProjectTargetSource source);
		public TreeData.string (string str);
		public TreeData.target (Gbf.Project project, Gbf.ProjectTarget target);
	}
	[Compact]
	[CCode (copy_function = "gbf_project_group_copy", cheader_filename = "gbf/gbf-project-group.h")]
	public class ProjectGroup {
		public weak string id;
		public weak string parent_id;
		public weak string name;
		public weak GLib.List groups;
		public weak GLib.List targets;
		public weak Gbf.ProjectGroup copy ();
	}
	[Compact]
	[CCode (copy_function = "gbf_project_target_copy", cheader_filename = "gbf/gbf-project.h")]
	public class ProjectTarget {
		public weak string id;
		public weak string group_id;
		public weak string name;
		public weak string type;
		public weak GLib.List sources;
		public weak Gbf.ProjectTarget copy ();
	}
	[Compact]
	[CCode (copy_function = "gbf_project_target_source_copy", cheader_filename = "gbf/gbf-project.h")]
	public class ProjectTargetSource {
		public weak string id;
		public weak string target_id;
		public weak string source_uri;
		public weak Gbf.ProjectTargetSource copy ();
	}
	[Compact]
	[CCode (cheader_filename = "gnome-build-1.0.h")]
	public class ProjectTreeNodeData {
	}
	[CCode (cheader_filename = "gbf/gbf-project.h")]
	public class Project : GLib.Object {
		public static GLib.Quark error_quark ();
		public virtual weak string add_group (string parent_id, string name) throws GLib.Error;
		public virtual weak string add_source (string target_id, string uri) throws GLib.Error;
		public virtual weak string add_target (string group_id, string name, string type) throws GLib.Error;
		public virtual weak Gtk.Widget configure () throws GLib.Error;
		public virtual weak Gtk.Widget configure_group (string id) throws GLib.Error;
		public virtual weak Gtk.Widget configure_new_group () throws GLib.Error;
		public virtual weak Gtk.Widget configure_new_source () throws GLib.Error;
		public virtual weak Gtk.Widget configure_new_target () throws GLib.Error;
		public virtual weak Gtk.Widget configure_source (string id) throws GLib.Error;
		public virtual weak Gtk.Widget configure_target (string id) throws GLib.Error;
		public virtual weak GLib.List<string> get_all_groups () throws GLib.Error;
		public virtual weak GLib.List<string> get_all_sources () throws GLib.Error;
		public virtual weak GLib.List<string> get_all_targets () throws GLib.Error;
		public virtual Gbf.ProjectCapabilities get_capabilities () throws GLib.Error;
		public virtual weak GLib.List<string> get_config_modules () throws GLib.Error;
		public virtual weak GLib.List<string> get_config_packages (string module) throws GLib.Error;
		public virtual weak Gbf.ProjectGroup get_group (string id) throws GLib.Error;
		public virtual weak Gbf.ProjectTargetSource get_source (string id) throws GLib.Error;
		public virtual weak Gbf.ProjectTarget get_target (string id) throws GLib.Error;
		public virtual weak string get_types ();
		public virtual void load (string path) throws GLib.Error;
		public virtual weak string mimetype_for_type (string type);
		public virtual weak string name_for_type (string type);
		public virtual bool probe (string path) throws GLib.Error;
		public virtual void refresh () throws GLib.Error;
		public virtual void remove_group (string id) throws GLib.Error;
		public virtual void remove_source (string id) throws GLib.Error;
		public virtual void remove_target (string id) throws GLib.Error;
		public virtual signal void project_updated ();
	}
	[CCode (cheader_filename = "gbf/gbf-project-model.h")]
	public class ProjectModel : Gtk.TreeStore, Gtk.TreeModel, Gtk.TreeDragSource, Gtk.TreeDragDest, Gtk.TreeSortable, Gtk.Buildable {
		public bool find_id (Gtk.TreeIter iter, Gbf.TreeNodeType type, string id);
		public weak Gbf.Project get_project ();
		public weak Gtk.TreePath get_project_root ();
		public ProjectModel (Gbf.Project project);
		public void set_project (Gbf.Project project);
		public void* project { get; set; }
	}
	[CCode (cheader_filename = "gbf/gbf-project-view.h")]
	public class ProjectView : Gtk.TreeView, Gtk.Buildable, Atk.Implementor {
		public weak Gbf.TreeData find_selected (Gbf.TreeNodeType type);
		[CCode (type = "GtkWidget*")]
		public ProjectView ();
		public virtual signal void group_selected (string group_id);
		public virtual signal void target_selected (string target_id);
		public virtual signal void uri_activated (string uri);
	}
	[CCode (cheader_filename = "gbf/gbf-project.h")]
	public const string BUILD_ID_DEFAULT;
}
