/*
 * Simple completion test
 */

using GLib;

namespace Vsc.Tests
{
	public class Test01
	{
		public string public_string_field;
		private string private_string_field;
		
		public void public_void_method ()
		{
			this.private_void_method ();
			this.public_string_field = "test01";
		}
		
		private void private_void_method ()
		{
			this.private_string_field = "test01";
		}

		public Test01.with_data (string data)
		{
		}
	}
	
	public int main (string[] args)
	{
		var test_instance = new Test01 ();	
		test_instance.public_void_method ();
		return 0;
	}
}
