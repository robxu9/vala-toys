using GLib;

namespace Tests
{
	public class Foo : Object
	{
		public void foo_test ()
		{
		}
	}

	public class Bar : Object
	{
		private string a = "";
		
		public string bar_name { get; set; }

		public bool bar_test ()
		{
			
			return false;
		}
	}
}
