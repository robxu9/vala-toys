using GLib;

namespace AfroditeTests
{
	public class Integrity
	{
		static AfroditeTests.CompletionManager _manager;

		static GLib.HashTable<weak void*, string> _symbol_table;
		
		public static void test_source_remove ()
		{
			var ast = _manager.engine.ast;

			var source = ast.lookup_source_file (_manager.filename);
			assert ( source == null );

			foreach (unowned Afrodite.Symbol symbol in ast.symbols.get_values ()) {
				if (!(symbol is GLib.Object)) {
					error ("symbol disposed: %p %s", symbol, _symbol_table.lookup (symbol));
				}
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
			
			// DEBUG: copy the symbol table for future reference
			_symbol_table = new GLib.HashTable <weak void*, string> (GLib.direct_hash, GLib.direct_equal);
			foreach (unowned Afrodite.Symbol symbol in _manager.engine.ast.symbols.get_values ()) {
				_symbol_table.insert (symbol, symbol.fully_qualified_name);
			}
			
			_manager.remove_source ();

			return Test.run ();
		}
	}
}
