[CCode (cname="GbfProjectCapabilities", cprefix="GBF_PROJECT_", cheader_filename="gbf/gbf-project.h")]
public enum Gbf.ProjectCapabilities {
	CAN_ADD_NONE,
	CAN_ADD_GROUP,
	CAN_ADD_TARGET,
	CAN_ADD_SOURCE,
	CAN_PACKAGES
}

[CCode (cheader_filename="gbf/gbf-backend.h")]
public class Gbf.Backend {
	public static Gbf.Project new_project (string id);
}

[CCode (cheader_filename="gbf/gbf-project-util.h")]
public class Gbf.ProjectUtil {
	public static weak string add_source (Gbf.ProjectModel model, Gtk.Window parent, string default_target, string default_group, string default_uri_to_add);
	public static weak GLib.List<string> add_source_multi (Gbf.ProjectModel model, Gtk.Window parent, string default_target, string default_group, GLib.List uris_to_add);
	public static weak string new_group (Gbf.ProjectModel model, Gtk.Window parent, string default_group, string default_group_name_to_add);
	public static weak string new_target (Gbf.ProjectModel model, Gtk.Window parent, string default_group, string default_target_name_to_add);
}
