/* tagclouditem.vala
 *
 * Copyright (C) 2010  Andrea Del Signore
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Andrea Del Signore <sejerpz@tin.it>
 */

public enum Vala.SelectStatus
{
	SELECTED,
	EXCLUDED,
	NOT_SELECTED
}

class Vala.TagCloudItem : GLib.Object
{
	private string _text = "";
	private int _occourrences = 0;
	private SelectStatus _select_status = SelectStatus.NOT_SELECTED;
	
	private bool _hilighted = false;
	
	internal int x = 0;
	internal int y = 0;
	internal int width = 0;
	internal int height = 0;
	
	public signal void select_status_changed ();
	
	public string text {
		get {
			return _text;
		}
		set {
			_text = value;
		}
	}
	
	public int occourrences {
		get {
			return _occourrences;
		}
		set {
			_occourrences = value;
		}
	}
	
	public SelectStatus select_status {
		get {
			return _select_status;
		}
		set {
			if (_select_status != value) {
				_select_status = value;
				select_status_changed ();
			}
		}
	}
	
	public bool hilighted {
		get {
			return _hilighted;
		}
		set {
			_hilighted = value;
		}
	}

	public TagCloudItem (string text, int occourrences, SelectStatus select_status = SelectStatus.NOT_SELECTED)
	{
		_text = text;
		_occourrences = occourrences;
		_select_status = select_status;
	}
}

