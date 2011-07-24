using GLib;

namespace AfroditeTests
{
	public class Integrity
	{
		static AfroditeTests.CompletionManager _manager;

		public static void test_source_remove ()
		{
			var ast = _manager.engine.ast;

			var source = ast.lookup_source_file (_manager.filename);
			assert ( source == null );

			foreach (Afrodite.Symbol symbol in ast.symbols.get_values ()) {
				Assert.cmpint ((int) symbol.has_source_references, Assert.Compare.EQUAL, (int)true);
				var sr = symbol.lookup_source_reference_filename (_manager.filename);
				assert (sr == null);
			}
		}

		public static int main (string[] args)
		{
			Test.init (ref args);

			Test.add_func ("/afrodite/integrity-test-source-remove", test_source_remove);

			_manager = new AfroditeTests.CompletionManager ("tests-basic-source.vala");
			_manager.parse ();
			_manager.remove_source ();

			return Test.run ();
		}
	}
}
