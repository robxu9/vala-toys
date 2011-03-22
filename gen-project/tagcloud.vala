/* tagcloud.vala
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

using Gtk;
using Cairo;

class Vala.TagCloud : Gtk.DrawingArea
{
	private GLib.List<TagCloudItem> _items = new GLib.List<TagCloudItem> ();
	
	public signal void selected_items_changed ();
	
	public TagCloud ()
	{
		GLib.Object ();
		this.add_events (Gdk.EventMask.BUTTON_MOTION_MASK 
			| Gdk.EventMask.BUTTON_PRESS_MASK
			| Gdk.EventMask.BUTTON_RELEASE_MASK
			| Gdk.EventMask.POINTER_MOTION_MASK);
	}
	
	public void add_item (TagCloudItem item)
	{
		_items.append (item);
		item.select_status_changed.connect (this.on_tag_item_selected_changed);
		this.queue_draw ();
	}

	/*
	public void remove_item_with_text (string text)
	{
		var item = get_item_with_text (text);
		if (item != null) {
			remove_item (item);
		}
	}
	
	public void remove_item (TagCloudItem item)
	{
		item.notify["selected"].disconnect (this.on_tag_item_selected_changed);
		_items.remove (item);
		this.queue_draw ();
	}
	*/

	public TagCloudItem? get_item_with_text (string text)
	{
		foreach (TagCloudItem item in _items) {
			if (item.text == text) {
				return item;
			}
		}
		
		return null;
	}
	
	private void on_tag_item_selected_changed (GLib.Object sender)
	{
		this.queue_draw ();
		this.selected_items_changed ();
	}

	public TagCloudItem? hit_test (double x, double y)
	{
		foreach (TagCloudItem item in _items) {
			//debug ("hit test %s: %f,%f - %f,%f vs %d,%d", item.text, item.x, item.y, item.width, item.height, x, y);
			if (item.x <= x && x <= (item.x + item.width)) {
				if (item.y <= y && y <= (item.y + item.height)) {
					return item;
				}
			}
		}
		
		return null;
	}
	
	protected override bool button_release_event (Gdk.EventButton e)
	{
		var i = hit_test (e.x, e.y);
		if (i != null) {
			if (i.select_status == SelectStatus.EXCLUDED)
				i.select_status = SelectStatus.SELECTED;
			else if (i.select_status == SelectStatus.SELECTED)
				i.select_status = SelectStatus.EXCLUDED;
			//else
			//	i.select_status = SelectStatus.NOT_SELECTED;
			this.queue_draw ();
		}
		
		return false;
	}
	
	protected override bool motion_notify_event (Gdk.EventMotion e)
	{
		foreach (var item in _items) {
			bool hitted = hit_test (e.x, e.y) == item;
			if (item.hilighted != hitted) {
				item.hilighted = hitted;
				this.queue_draw_area (item.x, item.y, item.width, item.height);
			}
		}
		return false;
	}
	protected override bool expose_event (Gdk.EventExpose e)
	{
		var c = Gdk.cairo_create (e.window);
		int w, h;
		e.window.get_size (out w, out h);

		Pango.Rectangle ink_rect;
		Pango.Rectangle logical_rect;
		
		c.set_source_rgb (1, 1, 1); // FIXME: use theme for this white background
		c.rectangle (0,0, w, h);
		c.fill ();

		Gtk.Style style = this.get_style ();
		
		string font_name = style.font_desc.get_family ();
		Pango.FontDescription font = new Pango.FontDescription ();
		font.set_family (font_name);
		font.set_weight (Pango.Weight.NORMAL);

		c.select_font_face (font_name, Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
		double x = 4, y = 4;
		
		var max_size = 24.0;
		var min_size = 12.0;
		var min_occ = 1;
		var max_occ = 8;
		
		var multiplier = (max_size - min_size) / (max_occ - min_occ);
		double last_height = 0;
		foreach (TagCloudItem item in _items) {
			var size = min_size + ((max_occ - (max_occ - (item.occourrences - min_occ))) * multiplier);
			font.set_absolute_size (size * Pango.SCALE);

			Pango.Layout layout = Pango.cairo_create_layout (c);
			layout.set_font_description (font);
			if (item.select_status == SelectStatus.EXCLUDED) {
				layout.set_markup ("<s>%s</s>".printf(item.text), -1);
			} else {
				layout.set_text (item.text, -1);
			}

			layout.get_pixel_extents (out ink_rect, out logical_rect);

			item.width = (int) Math.round (logical_rect.width) + 4 ;
			item.height = (int) Math.round (logical_rect.height) + 4;
			
			if ((x + item.width) >= w - 4) {
				x = 4;
				y += last_height + 8;
			}

			item.x = (int) Math.round (x);
			item.y = (int) Math.round (y);

			if (item.hilighted) {
				Gdk.cairo_set_source_color (c, 
					style.bg[Gtk.StateType.PRELIGHT]);
				
			} else {
				if (item.select_status == SelectStatus.SELECTED || item.select_status == SelectStatus.EXCLUDED) {
					Gdk.cairo_set_source_color (c, 
						style.bg[Gtk.StateType.SELECTED]);
				} else {
					Gdk.cairo_set_source_color (c, 
						style.bg[Gtk.StateType.NORMAL]);
				}
			}
			
			c.set_line_width (2);
			c.set_line_cap (LineCap.ROUND);
			c.set_line_join (LineJoin.ROUND);
			
			// draw rounded corner rectangle
			double radius = 5;
			c.move_to (item.x + radius, y);
			c.arc (item.x + item.width -radius, item.y + radius, radius, Math.PI * 1.5, Math.PI * 2);
			c.arc (item.x + item.width -radius, item.y + item.height - radius, radius, 0, Math.PI * 0.5);
			c.arc (item.x + radius, item.y + item.height - radius, radius, Math.PI * 0.5, Math.PI);
			c.arc (item.x + radius, item.y +radius, radius, Math.PI, Math.PI * 1.5);
			if (item.select_status == SelectStatus.SELECTED || item.select_status == SelectStatus.EXCLUDED)
				c.fill ();
			else
				c.stroke ();
			
			if (item.hilighted) {
				Gdk.cairo_set_source_color (c, 
					this.style.fg[Gtk.StateType.ACTIVE]);
			} else {
				Gdk.cairo_set_source_color (c, 
					this.style.fg[Gtk.StateType.NORMAL]);

			}
			c.move_to (item.x + 1, item.y + 1);
			Pango.cairo_show_layout (c, layout);
			x += logical_rect.width + 8;
			last_height = item.height;
		}

		return false;
	}
}

