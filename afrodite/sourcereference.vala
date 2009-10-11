/* sourcereference.vala
 *
 * Copyright (C) 2009  Andrea Del Signore
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

namespace Afrodite
{
	public class SourceReference
	{
		public unowned SourceFile file = null;
		public int first_line = 0;
		public int last_line = 0;
		public int first_column = 0;
		public int last_column = 0;
		
		public SourceReference copy ()
		{
			var new_copy = new SourceReference ();
			
			new_copy.file = this.file;
			new_copy.first_line = this.first_line;
			new_copy.last_line = this.last_line;
			new_copy.first_column = this.first_column;
			new_copy.last_column = this.last_column;
			
			return new_copy;
		}
	}
}
