/* parseresult.vala
 *
 * Copyright (C) 2010  Andrea Del Signore
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Andrea Del Signore <sejerpz@tin.it>
 */

using GLib;
using Vala;

namespace Afrodite
{
	public class ParseResult : Vala.Report
	{
		public Vala.List<string> warnings = new Vala.ArrayList<string> ();
		public Vala.List<string> errors = new Vala.ArrayList<string> ();
		public Vala.List<string> notes = new Vala.ArrayList<string> ();

		public override void warn (Vala.SourceReference? source, string message)
		{
			base.warn (source, message);
			if (source != null)
				warnings.add ("%s: warning: %s\n".printf (source.to_string (), message));
		}

		public override void err (Vala.SourceReference? source, string message)
		{
			base.err (source, message);
			if (source != null)
				errors.add ("%s: error: %s\n".printf (source.to_string (), message));
		}

		public override void note (Vala.SourceReference? source, string message)
		{
			base.note (source, message);
			if (source != null)
				notes.add ("%s: note: %s\n".printf (source.to_string (), message));
		}
	}
}