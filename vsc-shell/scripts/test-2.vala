using GLib;
using Gtk;

namespace Vtg
{
	public class Tests : GLib.Object
	{
		public string field;
		
	}
	
	public class Wnd : Gtk.Window
	{
		public void method_test ()
		{
			Tests t = new Tests ();
			
			var button = new Button.with_label ("");
			
		}
	}
}
