<?xml version="1.0"?>
<api version="1.0">
	<namespace name="Gedit">
		<function name="convert_error_quark" symbol="gedit_convert_error_quark">
			<return-type type="GQuark"/>
		</function>
		<function name="convert_from_utf8" symbol="gedit_convert_from_utf8">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="content" type="gchar*"/>
				<parameter name="len" type="gsize"/>
				<parameter name="encoding" type="GeditEncoding*"/>
				<parameter name="new_len" type="gsize*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="convert_to_utf8" symbol="gedit_convert_to_utf8">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="content" type="gchar*"/>
				<parameter name="len" type="gsize"/>
				<parameter name="encoding" type="GeditEncoding**"/>
				<parameter name="new_len" type="gsize*"/>
				<parameter name="error" type="GError**"/>
			</parameters>
		</function>
		<function name="debug" symbol="gedit_debug">
			<return-type type="void"/>
			<parameters>
				<parameter name="section" type="GeditDebugSection"/>
				<parameter name="file" type="gchar*"/>
				<parameter name="line" type="gint"/>
				<parameter name="function" type="gchar*"/>
			</parameters>
		</function>
		<function name="debug_init" symbol="gedit_debug_init">
			<return-type type="void"/>
		</function>
		<function name="debug_message" symbol="gedit_debug_message">
			<return-type type="void"/>
			<parameters>
				<parameter name="section" type="GeditDebugSection"/>
				<parameter name="file" type="gchar*"/>
				<parameter name="line" type="gint"/>
				<parameter name="function" type="gchar*"/>
				<parameter name="format" type="gchar*"/>
			</parameters>
		</function>
		<function name="dialog_add_button" symbol="gedit_dialog_add_button">
			<return-type type="GtkWidget*"/>
			<parameters>
				<parameter name="dialog" type="GtkDialog*"/>
				<parameter name="text" type="gchar*"/>
				<parameter name="stock_id" type="gchar*"/>
				<parameter name="response_id" type="gint"/>
			</parameters>
		</function>
		<function name="g_utf8_caselessnmatch" symbol="g_utf8_caselessnmatch">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="s1" type="char*"/>
				<parameter name="s2" type="char*"/>
				<parameter name="n1" type="gssize"/>
				<parameter name="n2" type="gssize"/>
			</parameters>
		</function>
		<function name="gdk_color_to_string" symbol="gedit_gdk_color_to_string">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="color" type="GdkColor"/>
			</parameters>
		</function>
		<function name="gtk_button_new_with_stock_icon" symbol="gedit_gtk_button_new_with_stock_icon">
			<return-type type="GtkWidget*"/>
			<parameters>
				<parameter name="label" type="gchar*"/>
				<parameter name="stock_id" type="gchar*"/>
			</parameters>
		</function>
		<function name="help_display" symbol="gedit_help_display">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="parent" type="GtkWindow*"/>
				<parameter name="file_name" type="gchar*"/>
				<parameter name="link_id" type="gchar*"/>
			</parameters>
		</function>
		<function name="metadata_manager_get" symbol="gedit_metadata_manager_get">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
				<parameter name="key" type="gchar*"/>
			</parameters>
		</function>
		<function name="metadata_manager_set" symbol="gedit_metadata_manager_set">
			<return-type type="void"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
				<parameter name="key" type="gchar*"/>
				<parameter name="value" type="gchar*"/>
			</parameters>
		</function>
		<function name="metadata_manager_shutdown" symbol="gedit_metadata_manager_shutdown">
			<return-type type="void"/>
		</function>
		<function name="prefs_manager_active_file_filter_can_set" symbol="gedit_prefs_manager_active_file_filter_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_app_init" symbol="gedit_prefs_manager_app_init">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_app_shutdown" symbol="gedit_prefs_manager_app_shutdown">
			<return-type type="void"/>
		</function>
		<function name="prefs_manager_auto_indent_can_set" symbol="gedit_prefs_manager_auto_indent_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_auto_save_can_set" symbol="gedit_prefs_manager_auto_save_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_auto_save_interval_can_set" symbol="gedit_prefs_manager_auto_save_interval_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_bottom_panel_active_page_can_set" symbol="gedit_prefs_manager_bottom_panel_active_page_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_bottom_panel_size_can_set" symbol="gedit_prefs_manager_bottom_panel_size_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_bottom_panel_visible_can_set" symbol="gedit_prefs_manager_bottom_panel_visible_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_bracket_matching_can_set" symbol="gedit_prefs_manager_bracket_matching_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_create_backup_copy_can_set" symbol="gedit_prefs_manager_create_backup_copy_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_display_line_numbers_can_set" symbol="gedit_prefs_manager_display_line_numbers_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_display_right_margin_can_set" symbol="gedit_prefs_manager_display_right_margin_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_editor_font_can_set" symbol="gedit_prefs_manager_editor_font_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_enable_search_highlighting_can_set" symbol="gedit_prefs_manager_enable_search_highlighting_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_enable_syntax_highlighting_can_set" symbol="gedit_prefs_manager_enable_syntax_highlighting_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_active_file_filter" symbol="gedit_prefs_manager_get_active_file_filter">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_auto_detected_encodings" symbol="gedit_prefs_manager_get_auto_detected_encodings">
			<return-type type="GSList*"/>
		</function>
		<function name="prefs_manager_get_auto_indent" symbol="gedit_prefs_manager_get_auto_indent">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_auto_save" symbol="gedit_prefs_manager_get_auto_save">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_auto_save_interval" symbol="gedit_prefs_manager_get_auto_save_interval">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_backup_extension" symbol="gedit_prefs_manager_get_backup_extension">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_bottom_panel_active_page" symbol="gedit_prefs_manager_get_bottom_panel_active_page">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_bottom_panel_size" symbol="gedit_prefs_manager_get_bottom_panel_size">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_bottom_panel_visible" symbol="gedit_prefs_manager_get_bottom_panel_visible">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_bracket_matching" symbol="gedit_prefs_manager_get_bracket_matching">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_create_backup_copy" symbol="gedit_prefs_manager_get_create_backup_copy">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_default_bottom_panel_size" symbol="gedit_prefs_manager_get_default_bottom_panel_size">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_default_print_font_body" symbol="gedit_prefs_manager_get_default_print_font_body">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_default_print_font_header" symbol="gedit_prefs_manager_get_default_print_font_header">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_default_print_font_numbers" symbol="gedit_prefs_manager_get_default_print_font_numbers">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_default_side_panel_size" symbol="gedit_prefs_manager_get_default_side_panel_size">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_default_window_size" symbol="gedit_prefs_manager_get_default_window_size">
			<return-type type="void"/>
			<parameters>
				<parameter name="width" type="gint*"/>
				<parameter name="height" type="gint*"/>
			</parameters>
		</function>
		<function name="prefs_manager_get_display_line_numbers" symbol="gedit_prefs_manager_get_display_line_numbers">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_display_right_margin" symbol="gedit_prefs_manager_get_display_right_margin">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_editor_font" symbol="gedit_prefs_manager_get_editor_font">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_enable_search_highlighting" symbol="gedit_prefs_manager_get_enable_search_highlighting">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_enable_syntax_highlighting" symbol="gedit_prefs_manager_get_enable_syntax_highlighting">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_highlight_current_line" symbol="gedit_prefs_manager_get_highlight_current_line">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_insert_spaces" symbol="gedit_prefs_manager_get_insert_spaces">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_lockdown" symbol="gedit_prefs_manager_get_lockdown">
			<return-type type="GeditLockdownMask"/>
		</function>
		<function name="prefs_manager_get_max_recents" symbol="gedit_prefs_manager_get_max_recents">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_print_font_body" symbol="gedit_prefs_manager_get_print_font_body">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_print_font_header" symbol="gedit_prefs_manager_get_print_font_header">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_print_font_numbers" symbol="gedit_prefs_manager_get_print_font_numbers">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_print_header" symbol="gedit_prefs_manager_get_print_header">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_print_line_numbers" symbol="gedit_prefs_manager_get_print_line_numbers">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_print_syntax_hl" symbol="gedit_prefs_manager_get_print_syntax_hl">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_print_wrap_mode" symbol="gedit_prefs_manager_get_print_wrap_mode">
			<return-type type="GtkWrapMode"/>
		</function>
		<function name="prefs_manager_get_restore_cursor_position" symbol="gedit_prefs_manager_get_restore_cursor_position">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_right_margin_position" symbol="gedit_prefs_manager_get_right_margin_position">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_shown_in_menu_encodings" symbol="gedit_prefs_manager_get_shown_in_menu_encodings">
			<return-type type="GSList*"/>
		</function>
		<function name="prefs_manager_get_side_pane_visible" symbol="gedit_prefs_manager_get_side_pane_visible">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_side_panel_active_page" symbol="gedit_prefs_manager_get_side_panel_active_page">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_side_panel_size" symbol="gedit_prefs_manager_get_side_panel_size">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_smart_home_end" symbol="gedit_prefs_manager_get_smart_home_end">
			<return-type type="GtkSourceSmartHomeEndType"/>
		</function>
		<function name="prefs_manager_get_source_style_scheme" symbol="gedit_prefs_manager_get_source_style_scheme">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_statusbar_visible" symbol="gedit_prefs_manager_get_statusbar_visible">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_system_font" symbol="gedit_prefs_manager_get_system_font">
			<return-type type="gchar*"/>
		</function>
		<function name="prefs_manager_get_tabs_size" symbol="gedit_prefs_manager_get_tabs_size">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_toolbar_buttons_style" symbol="gedit_prefs_manager_get_toolbar_buttons_style">
			<return-type type="GeditToolbarSetting"/>
		</function>
		<function name="prefs_manager_get_toolbar_visible" symbol="gedit_prefs_manager_get_toolbar_visible">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_undo_actions_limit" symbol="gedit_prefs_manager_get_undo_actions_limit">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_use_default_font" symbol="gedit_prefs_manager_get_use_default_font">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_get_window_size" symbol="gedit_prefs_manager_get_window_size">
			<return-type type="void"/>
			<parameters>
				<parameter name="width" type="gint*"/>
				<parameter name="height" type="gint*"/>
			</parameters>
		</function>
		<function name="prefs_manager_get_window_state" symbol="gedit_prefs_manager_get_window_state">
			<return-type type="gint"/>
		</function>
		<function name="prefs_manager_get_wrap_mode" symbol="gedit_prefs_manager_get_wrap_mode">
			<return-type type="GtkWrapMode"/>
		</function>
		<function name="prefs_manager_get_writable_vfs_schemes" symbol="gedit_prefs_manager_get_writable_vfs_schemes">
			<return-type type="GSList*"/>
		</function>
		<function name="prefs_manager_highlight_current_line_can_set" symbol="gedit_prefs_manager_highlight_current_line_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_init" symbol="gedit_prefs_manager_init">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_insert_spaces_can_set" symbol="gedit_prefs_manager_insert_spaces_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_print_font_body_can_set" symbol="gedit_prefs_manager_print_font_body_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_print_font_header_can_set" symbol="gedit_prefs_manager_print_font_header_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_print_font_numbers_can_set" symbol="gedit_prefs_manager_print_font_numbers_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_print_header_can_set" symbol="gedit_prefs_manager_print_header_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_print_line_numbers_can_set" symbol="gedit_prefs_manager_print_line_numbers_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_print_syntax_hl_can_set" symbol="gedit_prefs_manager_print_syntax_hl_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_print_wrap_mode_can_set" symbol="gedit_prefs_manager_print_wrap_mode_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_right_margin_position_can_set" symbol="gedit_prefs_manager_right_margin_position_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_set_active_file_filter" symbol="gedit_prefs_manager_set_active_file_filter">
			<return-type type="void"/>
			<parameters>
				<parameter name="id" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_auto_indent" symbol="gedit_prefs_manager_set_auto_indent">
			<return-type type="void"/>
			<parameters>
				<parameter name="ai" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_auto_save" symbol="gedit_prefs_manager_set_auto_save">
			<return-type type="void"/>
			<parameters>
				<parameter name="as" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_auto_save_interval" symbol="gedit_prefs_manager_set_auto_save_interval">
			<return-type type="void"/>
			<parameters>
				<parameter name="asi" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_bottom_panel_active_page" symbol="gedit_prefs_manager_set_bottom_panel_active_page">
			<return-type type="void"/>
			<parameters>
				<parameter name="id" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_bottom_panel_size" symbol="gedit_prefs_manager_set_bottom_panel_size">
			<return-type type="void"/>
			<parameters>
				<parameter name="ps" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_bottom_panel_visible" symbol="gedit_prefs_manager_set_bottom_panel_visible">
			<return-type type="void"/>
			<parameters>
				<parameter name="tv" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_bracket_matching" symbol="gedit_prefs_manager_set_bracket_matching">
			<return-type type="void"/>
			<parameters>
				<parameter name="bm" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_create_backup_copy" symbol="gedit_prefs_manager_set_create_backup_copy">
			<return-type type="void"/>
			<parameters>
				<parameter name="cbc" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_display_line_numbers" symbol="gedit_prefs_manager_set_display_line_numbers">
			<return-type type="void"/>
			<parameters>
				<parameter name="dln" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_display_right_margin" symbol="gedit_prefs_manager_set_display_right_margin">
			<return-type type="void"/>
			<parameters>
				<parameter name="drm" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_editor_font" symbol="gedit_prefs_manager_set_editor_font">
			<return-type type="void"/>
			<parameters>
				<parameter name="font" type="gchar*"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_enable_search_highlighting" symbol="gedit_prefs_manager_set_enable_search_highlighting">
			<return-type type="void"/>
			<parameters>
				<parameter name="esh" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_enable_syntax_highlighting" symbol="gedit_prefs_manager_set_enable_syntax_highlighting">
			<return-type type="void"/>
			<parameters>
				<parameter name="esh" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_highlight_current_line" symbol="gedit_prefs_manager_set_highlight_current_line">
			<return-type type="void"/>
			<parameters>
				<parameter name="hl" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_insert_spaces" symbol="gedit_prefs_manager_set_insert_spaces">
			<return-type type="void"/>
			<parameters>
				<parameter name="ai" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_print_font_body" symbol="gedit_prefs_manager_set_print_font_body">
			<return-type type="void"/>
			<parameters>
				<parameter name="font" type="gchar*"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_print_font_header" symbol="gedit_prefs_manager_set_print_font_header">
			<return-type type="void"/>
			<parameters>
				<parameter name="font" type="gchar*"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_print_font_numbers" symbol="gedit_prefs_manager_set_print_font_numbers">
			<return-type type="void"/>
			<parameters>
				<parameter name="font" type="gchar*"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_print_header" symbol="gedit_prefs_manager_set_print_header">
			<return-type type="void"/>
			<parameters>
				<parameter name="ph" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_print_line_numbers" symbol="gedit_prefs_manager_set_print_line_numbers">
			<return-type type="void"/>
			<parameters>
				<parameter name="pln" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_print_syntax_hl" symbol="gedit_prefs_manager_set_print_syntax_hl">
			<return-type type="void"/>
			<parameters>
				<parameter name="ps" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_print_wrap_mode" symbol="gedit_prefs_manager_set_print_wrap_mode">
			<return-type type="void"/>
			<parameters>
				<parameter name="pwm" type="GtkWrapMode"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_right_margin_position" symbol="gedit_prefs_manager_set_right_margin_position">
			<return-type type="void"/>
			<parameters>
				<parameter name="rmp" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_shown_in_menu_encodings" symbol="gedit_prefs_manager_set_shown_in_menu_encodings">
			<return-type type="void"/>
			<parameters>
				<parameter name="encs" type="GSList*"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_side_pane_visible" symbol="gedit_prefs_manager_set_side_pane_visible">
			<return-type type="void"/>
			<parameters>
				<parameter name="tv" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_side_panel_active_page" symbol="gedit_prefs_manager_set_side_panel_active_page">
			<return-type type="void"/>
			<parameters>
				<parameter name="id" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_side_panel_size" symbol="gedit_prefs_manager_set_side_panel_size">
			<return-type type="void"/>
			<parameters>
				<parameter name="ps" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_smart_home_end" symbol="gedit_prefs_manager_set_smart_home_end">
			<return-type type="void"/>
			<parameters>
				<parameter name="smart_he" type="GtkSourceSmartHomeEndType"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_source_style_scheme" symbol="gedit_prefs_manager_set_source_style_scheme">
			<return-type type="void"/>
			<parameters>
				<parameter name="scheme" type="gchar*"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_statusbar_visible" symbol="gedit_prefs_manager_set_statusbar_visible">
			<return-type type="void"/>
			<parameters>
				<parameter name="sv" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_tabs_size" symbol="gedit_prefs_manager_set_tabs_size">
			<return-type type="void"/>
			<parameters>
				<parameter name="ts" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_toolbar_buttons_style" symbol="gedit_prefs_manager_set_toolbar_buttons_style">
			<return-type type="void"/>
			<parameters>
				<parameter name="tbs" type="GeditToolbarSetting"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_toolbar_visible" symbol="gedit_prefs_manager_set_toolbar_visible">
			<return-type type="void"/>
			<parameters>
				<parameter name="tv" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_undo_actions_limit" symbol="gedit_prefs_manager_set_undo_actions_limit">
			<return-type type="void"/>
			<parameters>
				<parameter name="ual" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_use_default_font" symbol="gedit_prefs_manager_set_use_default_font">
			<return-type type="void"/>
			<parameters>
				<parameter name="udf" type="gboolean"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_window_size" symbol="gedit_prefs_manager_set_window_size">
			<return-type type="void"/>
			<parameters>
				<parameter name="width" type="gint"/>
				<parameter name="height" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_window_state" symbol="gedit_prefs_manager_set_window_state">
			<return-type type="void"/>
			<parameters>
				<parameter name="ws" type="gint"/>
			</parameters>
		</function>
		<function name="prefs_manager_set_wrap_mode" symbol="gedit_prefs_manager_set_wrap_mode">
			<return-type type="void"/>
			<parameters>
				<parameter name="wp" type="GtkWrapMode"/>
			</parameters>
		</function>
		<function name="prefs_manager_shown_in_menu_encodings_can_set" symbol="gedit_prefs_manager_shown_in_menu_encodings_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_shutdown" symbol="gedit_prefs_manager_shutdown">
			<return-type type="void"/>
		</function>
		<function name="prefs_manager_side_pane_visible_can_set" symbol="gedit_prefs_manager_side_pane_visible_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_side_panel_active_page_can_set" symbol="gedit_prefs_manager_side_panel_active_page_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_side_panel_size_can_set" symbol="gedit_prefs_manager_side_panel_size_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_smart_home_end_can_set" symbol="gedit_prefs_manager_smart_home_end_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_source_style_scheme_can_set" symbol="gedit_prefs_manager_source_style_scheme_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_statusbar_visible_can_set" symbol="gedit_prefs_manager_statusbar_visible_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_tabs_size_can_set" symbol="gedit_prefs_manager_tabs_size_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_toolbar_buttons_style_can_set" symbol="gedit_prefs_manager_toolbar_buttons_style_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_toolbar_visible_can_set" symbol="gedit_prefs_manager_toolbar_visible_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_undo_actions_limit_can_set" symbol="gedit_prefs_manager_undo_actions_limit_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_use_default_font_can_set" symbol="gedit_prefs_manager_use_default_font_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_window_size_can_set" symbol="gedit_prefs_manager_window_size_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_window_state_can_set" symbol="gedit_prefs_manager_window_state_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="prefs_manager_wrap_mode_can_set" symbol="gedit_prefs_manager_wrap_mode_can_set">
			<return-type type="gboolean"/>
		</function>
		<function name="utils_activate_url" symbol="gedit_utils_activate_url">
			<return-type type="void"/>
			<parameters>
				<parameter name="about" type="GtkAboutDialog*"/>
				<parameter name="url" type="gchar*"/>
				<parameter name="data" type="gpointer"/>
			</parameters>
		</function>
		<function name="utils_drop_get_uris" symbol="gedit_utils_drop_get_uris">
			<return-type type="gchar**"/>
			<parameters>
				<parameter name="selection_data" type="GtkSelectionData*"/>
			</parameters>
		</function>
		<function name="utils_escape_search_text" symbol="gedit_utils_escape_search_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_escape_underscores" symbol="gedit_utils_escape_underscores">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text" type="gchar*"/>
				<parameter name="length" type="gssize"/>
			</parameters>
		</function>
		<function name="utils_format_uri_for_display" symbol="gedit_utils_format_uri_for_display">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_get_current_viewport" symbol="gedit_utils_get_current_viewport">
			<return-type type="void"/>
			<parameters>
				<parameter name="screen" type="GdkScreen*"/>
				<parameter name="x" type="gint*"/>
				<parameter name="y" type="gint*"/>
			</parameters>
		</function>
		<function name="utils_get_current_workspace" symbol="gedit_utils_get_current_workspace">
			<return-type type="guint"/>
			<parameters>
				<parameter name="screen" type="GdkScreen*"/>
			</parameters>
		</function>
		<function name="utils_get_glade_widgets" symbol="gedit_utils_get_glade_widgets">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="filename" type="gchar*"/>
				<parameter name="root_node" type="gchar*"/>
				<parameter name="error_widget" type="GtkWidget**"/>
				<parameter name="widget_name" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_get_stdin" symbol="gedit_utils_get_stdin">
			<return-type type="gchar*"/>
		</function>
		<function name="utils_get_window_workspace" symbol="gedit_utils_get_window_workspace">
			<return-type type="guint"/>
			<parameters>
				<parameter name="gtkwindow" type="GtkWindow*"/>
			</parameters>
		</function>
		<function name="utils_is_valid_uri" symbol="gedit_utils_is_valid_uri">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_make_canonical_uri_from_shell_arg" symbol="gedit_utils_make_canonical_uri_from_shell_arg">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="str" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_make_valid_utf8" symbol="gedit_utils_make_valid_utf8">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="name" type="char*"/>
			</parameters>
		</function>
		<function name="utils_menu_position_under_tree_view" symbol="gedit_utils_menu_position_under_tree_view">
			<return-type type="void"/>
			<parameters>
				<parameter name="menu" type="GtkMenu*"/>
				<parameter name="x" type="gint*"/>
				<parameter name="y" type="gint*"/>
				<parameter name="push_in" type="gboolean*"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</function>
		<function name="utils_menu_position_under_widget" symbol="gedit_utils_menu_position_under_widget">
			<return-type type="void"/>
			<parameters>
				<parameter name="menu" type="GtkMenu*"/>
				<parameter name="x" type="gint*"/>
				<parameter name="y" type="gint*"/>
				<parameter name="push_in" type="gboolean*"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</function>
		<function name="utils_replace_home_dir_with_tilde" symbol="gedit_utils_replace_home_dir_with_tilde">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_set_atk_name_description" symbol="gedit_utils_set_atk_name_description">
			<return-type type="void"/>
			<parameters>
				<parameter name="widget" type="GtkWidget*"/>
				<parameter name="name" type="gchar*"/>
				<parameter name="description" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_set_atk_relation" symbol="gedit_utils_set_atk_relation">
			<return-type type="void"/>
			<parameters>
				<parameter name="obj1" type="GtkWidget*"/>
				<parameter name="obj2" type="GtkWidget*"/>
				<parameter name="rel_type" type="AtkRelationType"/>
			</parameters>
		</function>
		<function name="utils_str_middle_truncate" symbol="gedit_utils_str_middle_truncate">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="string" type="gchar*"/>
				<parameter name="truncate_length" type="guint"/>
			</parameters>
		</function>
		<function name="utils_unescape_search_text" symbol="gedit_utils_unescape_search_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_uri_exists" symbol="gedit_utils_uri_exists">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="text_uri" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_uri_get_dirname" symbol="gedit_utils_uri_get_dirname">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="uri" type="char*"/>
			</parameters>
		</function>
		<function name="utils_uri_has_file_scheme" symbol="gedit_utils_uri_has_file_scheme">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_uri_has_writable_scheme" symbol="gedit_utils_uri_has_writable_scheme">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
			</parameters>
		</function>
		<function name="warning" symbol="gedit_warning">
			<return-type type="void"/>
			<parameters>
				<parameter name="parent" type="GtkWindow*"/>
				<parameter name="format" type="gchar*"/>
			</parameters>
		</function>
		<struct name="GeditApp">
			<method name="create_window" symbol="gedit_app_create_window">
				<return-type type="GeditWindow*"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
					<parameter name="screen" type="GdkScreen*"/>
				</parameters>
			</method>
			<method name="get_active_window" symbol="gedit_app_get_active_window">
				<return-type type="GeditWindow*"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
				</parameters>
			</method>
			<method name="get_default" symbol="gedit_app_get_default">
				<return-type type="GeditApp*"/>
			</method>
			<method name="get_documents" symbol="gedit_app_get_documents">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
				</parameters>
			</method>
			<method name="get_lockdown" symbol="gedit_app_get_lockdown">
				<return-type type="GeditLockdownMask"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
				</parameters>
			</method>
			<method name="get_views" symbol="gedit_app_get_views">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
				</parameters>
			</method>
			<method name="get_windows" symbol="gedit_app_get_windows">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
				</parameters>
			</method>
			<field name="object" type="GObject"/>
			<field name="priv" type="GeditAppPrivate*"/>
		</struct>
		<struct name="GeditAppClass">
			<field name="parent_class" type="GObjectClass"/>
		</struct>
		<struct name="GeditDocument">
			<method name="error_quark" symbol="gedit_document_error_quark">
				<return-type type="GQuark"/>
			</method>
			<method name="get_can_search_again" symbol="gedit_document_get_can_search_again">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_deleted" symbol="gedit_document_get_deleted">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_enable_search_highlighting" symbol="gedit_document_get_enable_search_highlighting">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_encoding" symbol="gedit_document_get_encoding">
				<return-type type="GeditEncoding*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_language" symbol="gedit_document_get_language">
				<return-type type="GtkSourceLanguage*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_mime_type" symbol="gedit_document_get_mime_type">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_readonly" symbol="gedit_document_get_readonly">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_search_text" symbol="gedit_document_get_search_text">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="flags" type="guint*"/>
				</parameters>
			</method>
			<method name="get_short_name_for_display" symbol="gedit_document_get_short_name_for_display">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_uri" symbol="gedit_document_get_uri">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_uri_for_display" symbol="gedit_document_get_uri_for_display">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="goto_line" symbol="gedit_document_goto_line">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="line" type="gint"/>
				</parameters>
			</method>
			<method name="insert_file" symbol="gedit_document_insert_file">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="iter" type="GtkTextIter*"/>
					<parameter name="uri" type="gchar*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
				</parameters>
			</method>
			<method name="is_local" symbol="gedit_document_is_local">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="is_untitled" symbol="gedit_document_is_untitled">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="is_untouched" symbol="gedit_document_is_untouched">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="load" symbol="gedit_document_load">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="uri" type="gchar*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="line_pos" type="gint"/>
					<parameter name="create" type="gboolean"/>
				</parameters>
			</method>
			<method name="load_cancel" symbol="gedit_document_load_cancel">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_document_new">
				<return-type type="GeditDocument*"/>
			</method>
			<method name="replace_all" symbol="gedit_document_replace_all">
				<return-type type="gint"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="find" type="gchar*"/>
					<parameter name="replace" type="gchar*"/>
					<parameter name="flags" type="guint"/>
				</parameters>
			</method>
			<method name="save" symbol="gedit_document_save">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="flags" type="GeditDocumentSaveFlags"/>
				</parameters>
			</method>
			<method name="save_as" symbol="gedit_document_save_as">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="uri" type="gchar*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="flags" type="GeditDocumentSaveFlags"/>
				</parameters>
			</method>
			<method name="search_backward" symbol="gedit_document_search_backward">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="start" type="GtkTextIter*"/>
					<parameter name="end" type="GtkTextIter*"/>
					<parameter name="match_start" type="GtkTextIter*"/>
					<parameter name="match_end" type="GtkTextIter*"/>
				</parameters>
			</method>
			<method name="search_forward" symbol="gedit_document_search_forward">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="start" type="GtkTextIter*"/>
					<parameter name="end" type="GtkTextIter*"/>
					<parameter name="match_start" type="GtkTextIter*"/>
					<parameter name="match_end" type="GtkTextIter*"/>
				</parameters>
			</method>
			<method name="set_enable_search_highlighting" symbol="gedit_document_set_enable_search_highlighting">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="enable" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_language" symbol="gedit_document_set_language">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="lang" type="GtkSourceLanguage*"/>
				</parameters>
			</method>
			<method name="set_search_text" symbol="gedit_document_set_search_text">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="text" type="gchar*"/>
					<parameter name="flags" type="guint"/>
				</parameters>
			</method>
			<field name="buffer" type="GtkSourceBuffer"/>
			<field name="priv" type="GeditDocumentPrivate*"/>
		</struct>
		<struct name="GeditDocumentClass">
			<field name="parent_class" type="GtkSourceBufferClass"/>
			<field name="cursor_moved" type="GCallback"/>
			<field name="load" type="GCallback"/>
			<field name="loading" type="GCallback"/>
			<field name="loaded" type="GCallback"/>
			<field name="save" type="GCallback"/>
			<field name="saving" type="GCallback"/>
			<field name="saved" type="GCallback"/>
			<field name="search_highlight_updated" type="GCallback"/>
		</struct>
		<struct name="GeditEncoding">
			<method name="copy" symbol="gedit_encoding_copy">
				<return-type type="GeditEncoding*"/>
				<parameters>
					<parameter name="enc" type="GeditEncoding*"/>
				</parameters>
			</method>
			<method name="free" symbol="gedit_encoding_free">
				<return-type type="void"/>
				<parameters>
					<parameter name="enc" type="GeditEncoding*"/>
				</parameters>
			</method>
			<method name="get_charset" symbol="gedit_encoding_get_charset">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="enc" type="GeditEncoding*"/>
				</parameters>
			</method>
			<method name="get_current" symbol="gedit_encoding_get_current">
				<return-type type="GeditEncoding*"/>
			</method>
			<method name="get_from_charset" symbol="gedit_encoding_get_from_charset">
				<return-type type="GeditEncoding*"/>
				<parameters>
					<parameter name="charset" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_from_index" symbol="gedit_encoding_get_from_index">
				<return-type type="GeditEncoding*"/>
				<parameters>
					<parameter name="index" type="gint"/>
				</parameters>
			</method>
			<method name="get_name" symbol="gedit_encoding_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="enc" type="GeditEncoding*"/>
				</parameters>
			</method>
			<method name="get_utf8" symbol="gedit_encoding_get_utf8">
				<return-type type="GeditEncoding*"/>
			</method>
			<method name="to_string" symbol="gedit_encoding_to_string">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="enc" type="GeditEncoding*"/>
				</parameters>
			</method>
		</struct>
		<struct name="GeditEncodingsOptionMenu">
			<method name="get_selected_encoding" symbol="gedit_encodings_option_menu_get_selected_encoding">
				<return-type type="GeditEncoding*"/>
				<parameters>
					<parameter name="menu" type="GeditEncodingsOptionMenu*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_encodings_option_menu_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="save_mode" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_selected_encoding" symbol="gedit_encodings_option_menu_set_selected_encoding">
				<return-type type="void"/>
				<parameters>
					<parameter name="menu" type="GeditEncodingsOptionMenu*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
				</parameters>
			</method>
			<field name="parent" type="GtkOptionMenu"/>
			<field name="priv" type="GeditEncodingsOptionMenuPrivate*"/>
		</struct>
		<struct name="GeditEncodingsOptionMenuClass">
			<field name="parent_class" type="GtkOptionMenuClass"/>
		</struct>
		<struct name="GeditFileChooserDialog">
			<method name="get_encoding" symbol="gedit_file_chooser_dialog_get_encoding">
				<return-type type="GeditEncoding*"/>
				<parameters>
					<parameter name="dialog" type="GeditFileChooserDialog*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_file_chooser_dialog_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="title" type="gchar*"/>
					<parameter name="parent" type="GtkWindow*"/>
					<parameter name="action" type="GtkFileChooserAction"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="first_button_text" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_encoding" symbol="gedit_file_chooser_dialog_set_encoding">
				<return-type type="void"/>
				<parameters>
					<parameter name="dialog" type="GeditFileChooserDialog*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
				</parameters>
			</method>
			<field name="parent_instance" type="GtkFileChooserDialog"/>
			<field name="priv" type="GeditFileChooserDialogPrivate*"/>
		</struct>
		<struct name="GeditFileChooserDialogClass">
			<field name="parent_class" type="GtkFileChooserDialogClass"/>
		</struct>
		<struct name="GeditMessageArea">
			<method name="add_action_widget" symbol="gedit_message_area_add_action_widget">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="child" type="GtkWidget*"/>
					<parameter name="response_id" type="gint"/>
				</parameters>
			</method>
			<method name="add_button" symbol="gedit_message_area_add_button">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="button_text" type="gchar*"/>
					<parameter name="response_id" type="gint"/>
				</parameters>
			</method>
			<method name="add_buttons" symbol="gedit_message_area_add_buttons">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="first_button_text" type="gchar*"/>
				</parameters>
			</method>
			<method name="add_stock_button_with_text" symbol="gedit_message_area_add_stock_button_with_text">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="text" type="gchar*"/>
					<parameter name="stock_id" type="gchar*"/>
					<parameter name="response_id" type="gint"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_message_area_new">
				<return-type type="GtkWidget*"/>
			</method>
			<method name="new_with_buttons" symbol="gedit_message_area_new_with_buttons">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="first_button_text" type="gchar*"/>
				</parameters>
			</method>
			<method name="response" symbol="gedit_message_area_response">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="response_id" type="gint"/>
				</parameters>
			</method>
			<method name="set_contents" symbol="gedit_message_area_set_contents">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="contents" type="GtkWidget*"/>
				</parameters>
			</method>
			<method name="set_default_response" symbol="gedit_message_area_set_default_response">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="response_id" type="gint"/>
				</parameters>
			</method>
			<method name="set_response_sensitive" symbol="gedit_message_area_set_response_sensitive">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_area" type="GeditMessageArea*"/>
					<parameter name="response_id" type="gint"/>
					<parameter name="setting" type="gboolean"/>
				</parameters>
			</method>
			<field name="parent" type="GtkHBox"/>
			<field name="priv" type="GeditMessageAreaPrivate*"/>
		</struct>
		<struct name="GeditMessageAreaClass">
			<field name="parent_class" type="GtkHBoxClass"/>
			<field name="response" type="GCallback"/>
			<field name="close" type="GCallback"/>
			<field name="_gedit_reserved1" type="GCallback"/>
			<field name="_gedit_reserved2" type="GCallback"/>
		</struct>
		<struct name="GeditNotebook">
			<method name="add_tab" symbol="gedit_notebook_add_tab">
				<return-type type="void"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
					<parameter name="tab" type="GeditTab*"/>
					<parameter name="position" type="gint"/>
					<parameter name="jump_to" type="gboolean"/>
				</parameters>
			</method>
			<method name="get_close_buttons_sensitive" symbol="gedit_notebook_get_close_buttons_sensitive">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
				</parameters>
			</method>
			<method name="get_tab_drag_and_drop_enabled" symbol="gedit_notebook_get_tab_drag_and_drop_enabled">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
				</parameters>
			</method>
			<method name="move_tab" symbol="gedit_notebook_move_tab">
				<return-type type="void"/>
				<parameters>
					<parameter name="src" type="GeditNotebook*"/>
					<parameter name="dest" type="GeditNotebook*"/>
					<parameter name="tab" type="GeditTab*"/>
					<parameter name="dest_position" type="gint"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_notebook_new">
				<return-type type="GtkWidget*"/>
			</method>
			<method name="remove_all_tabs" symbol="gedit_notebook_remove_all_tabs">
				<return-type type="void"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
				</parameters>
			</method>
			<method name="remove_tab" symbol="gedit_notebook_remove_tab">
				<return-type type="void"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<method name="reorder_tab" symbol="gedit_notebook_reorder_tab">
				<return-type type="void"/>
				<parameters>
					<parameter name="src" type="GeditNotebook*"/>
					<parameter name="tab" type="GeditTab*"/>
					<parameter name="dest_position" type="gint"/>
				</parameters>
			</method>
			<method name="set_always_show_tabs" symbol="gedit_notebook_set_always_show_tabs">
				<return-type type="void"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
					<parameter name="show_tabs" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_close_buttons_sensitive" symbol="gedit_notebook_set_close_buttons_sensitive">
				<return-type type="void"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
					<parameter name="sensitive" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_tab_drag_and_drop_enabled" symbol="gedit_notebook_set_tab_drag_and_drop_enabled">
				<return-type type="void"/>
				<parameters>
					<parameter name="nb" type="GeditNotebook*"/>
					<parameter name="enable" type="gboolean"/>
				</parameters>
			</method>
			<field name="notebook" type="GtkNotebook"/>
			<field name="priv" type="GeditNotebookPrivate*"/>
		</struct>
		<struct name="GeditNotebookClass">
			<field name="parent_class" type="GtkNotebookClass"/>
			<field name="tab_added" type="GCallback"/>
			<field name="tab_removed" type="GCallback"/>
			<field name="tab_detached" type="GCallback"/>
			<field name="tabs_reordered" type="GCallback"/>
			<field name="tab_close_request" type="GCallback"/>
		</struct>
		<struct name="GeditPanel">
			<method name="activate_item" symbol="gedit_panel_activate_item">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
					<parameter name="item" type="GtkWidget*"/>
				</parameters>
			</method>
			<method name="add_item" symbol="gedit_panel_add_item">
				<return-type type="void"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
					<parameter name="item" type="GtkWidget*"/>
					<parameter name="name" type="gchar*"/>
					<parameter name="image" type="GtkWidget*"/>
				</parameters>
			</method>
			<method name="add_item_with_stock_icon" symbol="gedit_panel_add_item_with_stock_icon">
				<return-type type="void"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
					<parameter name="item" type="GtkWidget*"/>
					<parameter name="name" type="gchar*"/>
					<parameter name="stock_id" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_n_items" symbol="gedit_panel_get_n_items">
				<return-type type="gint"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
				</parameters>
			</method>
			<method name="get_orientation" symbol="gedit_panel_get_orientation">
				<return-type type="GtkOrientation"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
				</parameters>
			</method>
			<method name="item_is_active" symbol="gedit_panel_item_is_active">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
					<parameter name="item" type="GtkWidget*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_panel_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="orientation" type="GtkOrientation"/>
				</parameters>
			</method>
			<method name="remove_item" symbol="gedit_panel_remove_item">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
					<parameter name="item" type="GtkWidget*"/>
				</parameters>
			</method>
			<field name="vbox" type="GtkVBox"/>
			<field name="priv" type="GeditPanelPrivate*"/>
		</struct>
		<struct name="GeditPanelClass">
			<field name="parent_class" type="GtkVBoxClass"/>
			<field name="item_added" type="GCallback"/>
			<field name="item_removed" type="GCallback"/>
			<field name="close" type="GCallback"/>
			<field name="focus_document" type="GCallback"/>
			<field name="_gedit_reserved1" type="GCallback"/>
			<field name="_gedit_reserved2" type="GCallback"/>
			<field name="_gedit_reserved3" type="GCallback"/>
			<field name="_gedit_reserved4" type="GCallback"/>
		</struct>
		<struct name="GeditPlugin">
			<method name="activate" symbol="gedit_plugin_activate">
				<return-type type="void"/>
				<parameters>
					<parameter name="plugin" type="GeditPlugin*"/>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="create_configure_dialog" symbol="gedit_plugin_create_configure_dialog">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="plugin" type="GeditPlugin*"/>
				</parameters>
			</method>
			<method name="deactivate" symbol="gedit_plugin_deactivate">
				<return-type type="void"/>
				<parameters>
					<parameter name="plugin" type="GeditPlugin*"/>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="is_configurable" symbol="gedit_plugin_is_configurable">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="plugin" type="GeditPlugin*"/>
				</parameters>
			</method>
			<method name="update_ui" symbol="gedit_plugin_update_ui">
				<return-type type="void"/>
				<parameters>
					<parameter name="plugin" type="GeditPlugin*"/>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<field name="parent" type="GObject"/>
		</struct>
		<struct name="GeditPluginClass">
			<field name="parent_class" type="GObjectClass"/>
			<field name="activate" type="GCallback"/>
			<field name="deactivate" type="GCallback"/>
			<field name="update_ui" type="GCallback"/>
			<field name="create_configure_dialog" type="GCallback"/>
			<field name="is_configurable" type="GCallback"/>
			<field name="_gedit_reserved1" type="GCallback"/>
			<field name="_gedit_reserved2" type="GCallback"/>
			<field name="_gedit_reserved3" type="GCallback"/>
			<field name="_gedit_reserved4" type="GCallback"/>
		</struct>
		<struct name="GeditProgressMessageArea">
			<method name="new" symbol="gedit_progress_message_area_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="stock_id" type="gchar*"/>
					<parameter name="markup" type="gchar*"/>
					<parameter name="has_cancel" type="gboolean"/>
				</parameters>
			</method>
			<method name="pulse" symbol="gedit_progress_message_area_pulse">
				<return-type type="void"/>
				<parameters>
					<parameter name="area" type="GeditProgressMessageArea*"/>
				</parameters>
			</method>
			<method name="set_fraction" symbol="gedit_progress_message_area_set_fraction">
				<return-type type="void"/>
				<parameters>
					<parameter name="area" type="GeditProgressMessageArea*"/>
					<parameter name="fraction" type="gdouble"/>
				</parameters>
			</method>
			<method name="set_markup" symbol="gedit_progress_message_area_set_markup">
				<return-type type="void"/>
				<parameters>
					<parameter name="area" type="GeditProgressMessageArea*"/>
					<parameter name="markup" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_stock_image" symbol="gedit_progress_message_area_set_stock_image">
				<return-type type="void"/>
				<parameters>
					<parameter name="area" type="GeditProgressMessageArea*"/>
					<parameter name="stock_id" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_text" symbol="gedit_progress_message_area_set_text">
				<return-type type="void"/>
				<parameters>
					<parameter name="area" type="GeditProgressMessageArea*"/>
					<parameter name="text" type="gchar*"/>
				</parameters>
			</method>
			<field name="parent" type="GeditMessageArea"/>
			<field name="priv" type="GeditProgressMessageAreaPrivate*"/>
		</struct>
		<struct name="GeditProgressMessageAreaClass">
			<field name="parent_class" type="GeditMessageAreaClass"/>
		</struct>
		<struct name="GeditStatusbar">
			<method name="clear_overwrite" symbol="gedit_statusbar_clear_overwrite">
				<return-type type="void"/>
				<parameters>
					<parameter name="statusbar" type="GeditStatusbar*"/>
				</parameters>
			</method>
			<method name="flash_message" symbol="gedit_statusbar_flash_message">
				<return-type type="void"/>
				<parameters>
					<parameter name="statusbar" type="GeditStatusbar*"/>
					<parameter name="context_id" type="guint"/>
					<parameter name="format" type="gchar*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_statusbar_new">
				<return-type type="GtkWidget*"/>
			</method>
			<method name="set_cursor_position" symbol="gedit_statusbar_set_cursor_position">
				<return-type type="void"/>
				<parameters>
					<parameter name="statusbar" type="GeditStatusbar*"/>
					<parameter name="line" type="gint"/>
					<parameter name="col" type="gint"/>
				</parameters>
			</method>
			<method name="set_overwrite" symbol="gedit_statusbar_set_overwrite">
				<return-type type="void"/>
				<parameters>
					<parameter name="statusbar" type="GeditStatusbar*"/>
					<parameter name="overwrite" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_window_state" symbol="gedit_statusbar_set_window_state">
				<return-type type="void"/>
				<parameters>
					<parameter name="statusbar" type="GeditStatusbar*"/>
					<parameter name="state" type="GeditWindowState"/>
					<parameter name="num_of_errors" type="gint"/>
				</parameters>
			</method>
			<field name="parent" type="GtkStatusbar"/>
			<field name="priv" type="GeditStatusbarPrivate*"/>
		</struct>
		<struct name="GeditStatusbarClass">
			<field name="parent_class" type="GtkStatusbarClass"/>
		</struct>
		<struct name="GeditTab">
			<method name="get_auto_save_enabled" symbol="gedit_tab_get_auto_save_enabled">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<method name="get_auto_save_interval" symbol="gedit_tab_get_auto_save_interval">
				<return-type type="gint"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<method name="get_document" symbol="gedit_tab_get_document">
				<return-type type="GeditDocument*"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<method name="get_from_document" symbol="gedit_tab_get_from_document">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_state" symbol="gedit_tab_get_state">
				<return-type type="GeditTabState"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<method name="get_view" symbol="gedit_tab_get_view">
				<return-type type="GeditView*"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<method name="set_auto_save_enabled" symbol="gedit_tab_set_auto_save_enabled">
				<return-type type="void"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
					<parameter name="enable" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_auto_save_interval" symbol="gedit_tab_set_auto_save_interval">
				<return-type type="void"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
					<parameter name="interval" type="gint"/>
				</parameters>
			</method>
			<field name="vbox" type="GtkVBox"/>
			<field name="priv" type="GeditTabPrivate*"/>
		</struct>
		<struct name="GeditTabClass">
			<field name="parent_class" type="GtkVBoxClass"/>
		</struct>
		<struct name="GeditView">
			<method name="copy_clipboard" symbol="gedit_view_copy_clipboard">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="GeditView*"/>
				</parameters>
			</method>
			<method name="cut_clipboard" symbol="gedit_view_cut_clipboard">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="GeditView*"/>
				</parameters>
			</method>
			<method name="delete_selection" symbol="gedit_view_delete_selection">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="GeditView*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_view_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="paste_clipboard" symbol="gedit_view_paste_clipboard">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="GeditView*"/>
				</parameters>
			</method>
			<method name="scroll_to_cursor" symbol="gedit_view_scroll_to_cursor">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="GeditView*"/>
				</parameters>
			</method>
			<method name="select_all" symbol="gedit_view_select_all">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="GeditView*"/>
				</parameters>
			</method>
			<method name="set_font" symbol="gedit_view_set_font">
				<return-type type="void"/>
				<parameters>
					<parameter name="view" type="GeditView*"/>
					<parameter name="def" type="gboolean"/>
					<parameter name="font_name" type="gchar*"/>
				</parameters>
			</method>
			<field name="view" type="GtkSourceView"/>
			<field name="priv" type="GeditViewPrivate*"/>
		</struct>
		<struct name="GeditViewClass">
			<field name="parent_class" type="GtkSourceViewClass"/>
			<field name="start_interactive_search" type="GCallback"/>
			<field name="start_interactive_goto_line" type="GCallback"/>
			<field name="reset_searched_text" type="GCallback"/>
			<field name="drop_uris" type="GCallback"/>
		</struct>
		<struct name="GeditWindow">
			<method name="close_all_tabs" symbol="gedit_window_close_all_tabs">
				<return-type type="void"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="close_tab" symbol="gedit_window_close_tab">
				<return-type type="void"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<method name="close_tabs" symbol="gedit_window_close_tabs">
				<return-type type="void"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="tabs" type="GList*"/>
				</parameters>
			</method>
			<method name="create_tab" symbol="gedit_window_create_tab">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="jump_to" type="gboolean"/>
				</parameters>
			</method>
			<method name="create_tab_from_uri" symbol="gedit_window_create_tab_from_uri">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="uri" type="gchar*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="line_pos" type="gint"/>
					<parameter name="create" type="gboolean"/>
					<parameter name="jump_to" type="gboolean"/>
				</parameters>
			</method>
			<method name="get_active_document" symbol="gedit_window_get_active_document">
				<return-type type="GeditDocument*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_active_tab" symbol="gedit_window_get_active_tab">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_active_view" symbol="gedit_window_get_active_view">
				<return-type type="GeditView*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_bottom_panel" symbol="gedit_window_get_bottom_panel">
				<return-type type="GeditPanel*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_documents" symbol="gedit_window_get_documents">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_group" symbol="gedit_window_get_group">
				<return-type type="GtkWindowGroup*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_side_panel" symbol="gedit_window_get_side_panel">
				<return-type type="GeditPanel*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_state" symbol="gedit_window_get_state">
				<return-type type="GeditWindowState"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_statusbar" symbol="gedit_window_get_statusbar">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_tab_from_uri" symbol="gedit_window_get_tab_from_uri">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="uri" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_ui_manager" symbol="gedit_window_get_ui_manager">
				<return-type type="GtkUIManager*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_unsaved_documents" symbol="gedit_window_get_unsaved_documents">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="get_views" symbol="gedit_window_get_views">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
				</parameters>
			</method>
			<method name="set_active_tab" symbol="gedit_window_set_active_tab">
				<return-type type="void"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="tab" type="GeditTab*"/>
				</parameters>
			</method>
			<field name="window" type="GtkWindow"/>
			<field name="priv" type="GeditWindowPrivate*"/>
		</struct>
		<struct name="GeditWindowClass">
			<field name="parent_class" type="GtkWindowClass"/>
			<field name="tab_added" type="GCallback"/>
			<field name="tab_removed" type="GCallback"/>
			<field name="tabs_reordered" type="GCallback"/>
			<field name="active_tab_changed" type="GCallback"/>
			<field name="active_tab_state_changed" type="GCallback"/>
		</struct>
		<enum name="GeditConvertError">
			<member name="GEDIT_CONVERT_ERROR_AUTO_DETECTION_FAILED" value="1100"/>
		</enum>
		<enum name="GeditDebugSection">
			<member name="GEDIT_NO_DEBUG" value="0"/>
			<member name="GEDIT_DEBUG_VIEW" value="1"/>
			<member name="GEDIT_DEBUG_SEARCH" value="2"/>
			<member name="GEDIT_DEBUG_PRINT" value="4"/>
			<member name="GEDIT_DEBUG_PREFS" value="8"/>
			<member name="GEDIT_DEBUG_PLUGINS" value="16"/>
			<member name="GEDIT_DEBUG_TAB" value="32"/>
			<member name="GEDIT_DEBUG_DOCUMENT" value="64"/>
			<member name="GEDIT_DEBUG_COMMANDS" value="128"/>
			<member name="GEDIT_DEBUG_APP" value="256"/>
			<member name="GEDIT_DEBUG_SESSION" value="512"/>
			<member name="GEDIT_DEBUG_UTILS" value="1024"/>
			<member name="GEDIT_DEBUG_METADATA" value="2048"/>
			<member name="GEDIT_DEBUG_WINDOW" value="4096"/>
			<member name="GEDIT_DEBUG_LOADER" value="8192"/>
			<member name="GEDIT_DEBUG_SAVER" value="16384"/>
		</enum>
		<enum name="GeditDocumentSaveFlags">
			<member name="GEDIT_DOCUMENT_SAVE_IGNORE_MTIME" value="1"/>
			<member name="GEDIT_DOCUMENT_SAVE_IGNORE_BACKUP" value="2"/>
			<member name="GEDIT_DOCUMENT_SAVE_PRESERVE_BACKUP" value="4"/>
		</enum>
		<enum name="GeditLockdownMask">
			<member name="GEDIT_LOCKDOWN_COMMAND_LINE" value="1"/>
			<member name="GEDIT_LOCKDOWN_PRINTING" value="2"/>
			<member name="GEDIT_LOCKDOWN_PRINT_SETUP" value="4"/>
			<member name="GEDIT_LOCKDOWN_SAVE_TO_DISK" value="8"/>
			<member name="GEDIT_LOCKDOWN_ALL" value="15"/>
		</enum>
		<enum name="GeditSearchFlags">
			<member name="GEDIT_SEARCH_DONT_SET_FLAGS" value="1"/>
			<member name="GEDIT_SEARCH_ENTIRE_WORD" value="2"/>
			<member name="GEDIT_SEARCH_CASE_SENSITIVE" value="4"/>
		</enum>
		<enum name="GeditTabState">
			<member name="GEDIT_TAB_STATE_NORMAL" value="0"/>
			<member name="GEDIT_TAB_STATE_LOADING" value="1"/>
			<member name="GEDIT_TAB_STATE_REVERTING" value="2"/>
			<member name="GEDIT_TAB_STATE_SAVING" value="3"/>
			<member name="GEDIT_TAB_STATE_PRINTING" value="4"/>
			<member name="GEDIT_TAB_STATE_PRINT_PREVIEWING" value="5"/>
			<member name="GEDIT_TAB_STATE_SHOWING_PRINT_PREVIEW" value="6"/>
			<member name="GEDIT_TAB_STATE_GENERIC_NOT_EDITABLE" value="7"/>
			<member name="GEDIT_TAB_STATE_LOADING_ERROR" value="8"/>
			<member name="GEDIT_TAB_STATE_REVERTING_ERROR" value="9"/>
			<member name="GEDIT_TAB_STATE_SAVING_ERROR" value="10"/>
			<member name="GEDIT_TAB_STATE_GENERIC_ERROR" value="11"/>
			<member name="GEDIT_TAB_STATE_CLOSING" value="12"/>
			<member name="GEDIT_TAB_STATE_EXTERNALLY_MODIFIED_NOTIFICATION" value="13"/>
			<member name="GEDIT_TAB_NUM_OF_STATES" value="14"/>
		</enum>
		<enum name="GeditToolbarSetting">
			<member name="GEDIT_TOOLBAR_SYSTEM" value="0"/>
			<member name="GEDIT_TOOLBAR_ICONS" value="1"/>
			<member name="GEDIT_TOOLBAR_ICONS_AND_TEXT" value="2"/>
			<member name="GEDIT_TOOLBAR_ICONS_BOTH_HORIZ" value="3"/>
		</enum>
		<enum name="GeditWindowState">
			<member name="GEDIT_WINDOW_STATE_NORMAL" value="0"/>
			<member name="GEDIT_WINDOW_STATE_SAVING" value="2"/>
			<member name="GEDIT_WINDOW_STATE_PRINTING" value="4"/>
			<member name="GEDIT_WINDOW_STATE_LOADING" value="8"/>
			<member name="GEDIT_WINDOW_STATE_ERROR" value="16"/>
			<member name="GEDIT_WINDOW_STATE_SAVING_SESSION" value="32"/>
		</enum>
		<constant name="GEDIT_BASE_KEY" type="char*" value="/apps/gedit-2"/>
		<constant name="GPM_DEFAULT_AUTO_INDENT" type="int" value="0"/>
		<constant name="GPM_DEFAULT_AUTO_SAVE" type="int" value="0"/>
		<constant name="GPM_DEFAULT_AUTO_SAVE_INTERVAL" type="int" value="10"/>
		<constant name="GPM_DEFAULT_BOTTOM_PANEL_VISIBLE" type="int" value="0"/>
		<constant name="GPM_DEFAULT_BRACKET_MATCHING" type="int" value="0"/>
		<constant name="GPM_DEFAULT_CREATE_BACKUP_COPY" type="int" value="1"/>
		<constant name="GPM_DEFAULT_DISPLAY_LINE_NUMBERS" type="int" value="0"/>
		<constant name="GPM_DEFAULT_DISPLAY_RIGHT_MARGIN" type="int" value="0"/>
		<constant name="GPM_DEFAULT_HIGHLIGHT_CURRENT_LINE" type="int" value="1"/>
		<constant name="GPM_DEFAULT_INSERT_SPACES" type="int" value="0"/>
		<constant name="GPM_DEFAULT_MAX_RECENTS" type="int" value="5"/>
		<constant name="GPM_DEFAULT_PRINT_HEADER" type="int" value="1"/>
		<constant name="GPM_DEFAULT_PRINT_LINE_NUMBERS" type="int" value="0"/>
		<constant name="GPM_DEFAULT_PRINT_SYNTAX" type="int" value="1"/>
		<constant name="GPM_DEFAULT_PRINT_WRAP_MODE" type="char*" value="GTK_WRAP_WORD"/>
		<constant name="GPM_DEFAULT_RESTORE_CURSOR_POSITION" type="int" value="1"/>
		<constant name="GPM_DEFAULT_RIGHT_MARGIN_POSITION" type="int" value="80"/>
		<constant name="GPM_DEFAULT_SEARCH_HIGHLIGHTING_ENABLE" type="int" value="1"/>
		<constant name="GPM_DEFAULT_SIDE_PANE_VISIBLE" type="int" value="0"/>
		<constant name="GPM_DEFAULT_SMART_HOME_END" type="char*" value="AFTER"/>
		<constant name="GPM_DEFAULT_SOURCE_STYLE_SCHEME" type="char*" value="classic"/>
		<constant name="GPM_DEFAULT_STATUSBAR_VISIBLE" type="int" value="1"/>
		<constant name="GPM_DEFAULT_SYNTAX_HL_ENABLE" type="int" value="1"/>
		<constant name="GPM_DEFAULT_TABS_SIZE" type="int" value="8"/>
		<constant name="GPM_DEFAULT_TOOLBAR_BUTTONS_STYLE" type="char*" value="GEDIT_TOOLBAR_SYSTEM"/>
		<constant name="GPM_DEFAULT_TOOLBAR_SHOW_TOOLTIPS" type="int" value="1"/>
		<constant name="GPM_DEFAULT_TOOLBAR_VISIBLE" type="int" value="1"/>
		<constant name="GPM_DEFAULT_UNDO_ACTIONS_LIMIT" type="int" value="2000"/>
		<constant name="GPM_DEFAULT_USE_DEFAULT_FONT" type="int" value="1"/>
		<constant name="GPM_DEFAULT_WRAP_MODE" type="char*" value="GTK_WRAP_WORD"/>
		<constant name="GPM_LOCKDOWN_DIR" type="char*" value="/desktop/gnome/lockdown"/>
		<constant name="GPM_SYSTEM_FONT" type="char*" value="/desktop/gnome/interface/monospace_font_name"/>
	</namespace>
</api>
