using GLib;

namespace AfroditeTests
{
	public class Basic
	{
		static AfroditeTests.CompletionManager _manager;

		public static void test_this_field_string ()
		{
			var s = _manager.lookup_symbol ("this.field", 19, 1);
			assert (s.is_empty == false);
			Assert.cmpint (s.children.size, Assert.Compare.EQUAL, 1);
			Assert.cmpstr (s.children[0].symbol.name, Assert.Compare.EQUAL, "string");
		}

		public static void test_this_property_string ()
		{
			var s = _manager.lookup_symbol ("this.property", 19, 1);
			assert (s.is_empty == false);
			Assert.cmpint (s.children.size, Assert.Compare.EQUAL, 1);
			Assert.cmpstr (s.children[0].symbol.name, Assert.Compare.EQUAL, "string");
		}

		public static void test_this_method_invocation_int ()
		{
			var s = _manager.lookup_symbol ("this.do_computation", 19, 1);
			assert (s.is_empty == false);
			Assert.cmpint (s.children.size, Assert.Compare.EQUAL, 1);
			Assert.cmpstr (s.children[0].symbol.name, Assert.Compare.EQUAL, "int");
		}

		public static void test_member_access_string ()
		{
			var s = _manager.lookup_symbol ("member_access_str", 41, 1);
			assert (s.is_empty == false);
			Assert.cmpint (s.children.size, Assert.Compare.EQUAL, 1);
			Assert.cmpstr (s.children[0].symbol.name, Assert.Compare.EQUAL, "string");
		}

		public static void test_static_factory_Test ()
		{
			var s = _manager.lookup_symbol ("test", 41, 1);
			assert (s.is_empty == false);
			Assert.cmpint (s.children.size, Assert.Compare.EQUAL, 1);
			Assert.cmpstr (s.children[0].symbol.name, Assert.Compare.EQUAL, "Test");
		}

		public static int main (string[] args)
		{
			Test.init (ref args);

			Test.add_func ("/afrodite/basic-test-this-field-string", test_this_field_string);
			Test.add_func ("/afrodite/basic-test-this-property-string", test_this_property_string);
			Test.add_func ("/afrodite/basic-test-this-method-invocation-int", test_this_method_invocation_int);
			Test.add_func ("/afrodite/basic-test-member-access-string", test_member_access_string);
			Test.add_func ("/afrodite/basic-test-static-factory-Test", test_static_factory_Test);
			
			_manager = new AfroditeTests.CompletionManager ("tests-basic-source.vala");
			_manager.parse ();

			return Test.run ();
		}
	}
}
