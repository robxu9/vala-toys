using GLib;

namespace Tests
{
	public class Test : GLib.Object
	{
		public string field;

		public string property
		{
			owned get {
				return build_string ();
			}
		}

		public Test(string field)
		{
			this.field = field;
		}

		public string build_string ()
		{
			return "a".concat ("b");
		}

		public int do_computation ()
		{
			return 0;
		}

		public static Test factory(string field)
		{
			return new Test(field);
		}

	}

	public static void main()
	{
		var member_access_str = Test.factory (i).field.replace ("b", "c");
		var test = Test.factory ("field");
		
	}
}
