
namespace Reflection
{
	[CCode (cname = "G_TYPE_FROM_INSTANCE")]
	public static GLib.Type get_type_from_instance (void* typeinstance);
}
