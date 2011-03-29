using GLib;
using Afrodite;

namespace AfroditeTests
{
	public class CompletionManager
	{
		private MainLoop _loop;
		private Afrodite.CompletionEngine _engine;
		private string _filename;

		public CompletionManager (string filename, bool absolute = false)
		{
			_filename = filename;
			if (!absolute) {
				string src_dir = Environment.get_variable ("srcdir");
				if (src_dir != null)
					_filename = Path.build_filename (src_dir, filename);
			}
		}

		private void on_begin_parsing (CompletionEngine engine)
		{
			print ("Afrodite engine is parsing sources...");
		}

		private void on_end_parsing (CompletionEngine engine)
		{
			print ("done\n");
			_loop.quit ();
		}

		public void parse ()
		{
			_loop = new MainLoop();

			_engine = new Afrodite.CompletionEngine ("afrodite-test-engine");
			_engine.begin_parsing.connect (this.on_begin_parsing);
			_engine.end_parsing.connect (this.on_end_parsing);
		
			_engine.queue_sourcefile (_filename);

			_loop.run();
		}
		
		public QueryResult lookup_symbol (string name, int at_line, int at_column)
		{
			QueryOptions options = QueryOptions.standard ();
			options.auto_member_binding_mode = true;
			options.compare_mode = CompareMode.EXACT;
			options.access = Afrodite.SymbolAccessibility.ANY;
			options.binding = Afrodite.MemberBinding.ANY;

			QueryResult sym = _engine.ast.get_symbol_type_for_name_and_path (options, name, _filename, at_line, at_column);
			return sym;
		}
	}
}

