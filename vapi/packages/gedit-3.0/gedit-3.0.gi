<?xml version="1.0"?>
<api version="1.0">
	<namespace name="Gedit">
		<function name="commands_load_location" symbol="gedit_commands_load_location">
			<return-type type="void"/>
			<parameters>
				<parameter name="window" type="GeditWindow*"/>
				<parameter name="location" type="GFile*"/>
				<parameter name="encoding" type="GeditEncoding*"/>
				<parameter name="line_pos" type="gint"/>
				<parameter name="column_pos" type="gint"/>
			</parameters>
		</function>
		<function name="commands_load_locations" symbol="gedit_commands_load_locations">
			<return-type type="GSList*"/>
			<parameters>
				<parameter name="window" type="GeditWindow*"/>
				<parameter name="locations" type="GSList*"/>
				<parameter name="encoding" type="GeditEncoding*"/>
				<parameter name="line_pos" type="gint"/>
				<parameter name="column_pos" type="gint"/>
			</parameters>
		</function>
		<function name="commands_save_all_documents" symbol="gedit_commands_save_all_documents">
			<return-type type="void"/>
			<parameters>
				<parameter name="window" type="GeditWindow*"/>
			</parameters>
		</function>
		<function name="commands_save_document" symbol="gedit_commands_save_document">
			<return-type type="void"/>
			<parameters>
				<parameter name="window" type="GeditWindow*"/>
				<parameter name="document" type="GeditDocument*"/>
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
		<function name="gtk_button_new_with_stock_icon" symbol="gedit_gtk_button_new_with_stock_icon">
			<return-type type="GtkWidget*"/>
			<parameters>
				<parameter name="label" type="gchar*"/>
				<parameter name="stock_id" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_basename_for_display" symbol="gedit_utils_basename_for_display">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="location" type="GFile*"/>
			</parameters>
		</function>
		<function name="utils_can_read_from_stdin" symbol="gedit_utils_can_read_from_stdin">
			<return-type type="gboolean"/>
		</function>
		<function name="utils_decode_uri" symbol="gedit_utils_decode_uri">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="uri" type="gchar*"/>
				<parameter name="scheme" type="gchar**"/>
				<parameter name="user" type="gchar**"/>
				<parameter name="port" type="gchar**"/>
				<parameter name="host" type="gchar**"/>
				<parameter name="path" type="gchar**"/>
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
		<function name="utils_get_compression_type_from_content_type" symbol="gedit_utils_get_compression_type_from_content_type">
			<return-type type="GeditDocumentCompressionType"/>
			<parameters>
				<parameter name="content_type" type="gchar*"/>
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
		<function name="utils_get_ui_objects" symbol="gedit_utils_get_ui_objects">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="filename" type="gchar*"/>
				<parameter name="root_objects" type="gchar**"/>
				<parameter name="error_widget" type="GtkWidget**"/>
				<parameter name="object_name" type="gchar*"/>
			</parameters>
		</function>
		<function name="utils_get_window_workspace" symbol="gedit_utils_get_window_workspace">
			<return-type type="guint"/>
			<parameters>
				<parameter name="gtkwindow" type="GtkWindow*"/>
			</parameters>
		</function>
		<function name="utils_is_valid_location" symbol="gedit_utils_is_valid_location">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="location" type="GFile*"/>
			</parameters>
		</function>
		<function name="utils_location_get_dirname_for_display" symbol="gedit_utils_location_get_dirname_for_display">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="location" type="GFile*"/>
			</parameters>
		</function>
		<function name="utils_location_has_file_scheme" symbol="gedit_utils_location_has_file_scheme">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="location" type="GFile*"/>
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
		<function name="utils_str_end_truncate" symbol="gedit_utils_str_end_truncate">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="string" type="gchar*"/>
				<parameter name="truncate_length" type="guint"/>
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
		<function name="utils_uri_get_dirname" symbol="gedit_utils_uri_get_dirname">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="uri" type="char*"/>
			</parameters>
		</function>
		<function name="warning" symbol="gedit_warning">
			<return-type type="void"/>
			<parameters>
				<parameter name="parent" type="GtkWindow*"/>
				<parameter name="format" type="gchar*"/>
			</parameters>
		</function>
		<callback name="GeditMessageBusForeach">
			<return-type type="void"/>
			<parameters>
				<parameter name="message_type" type="GeditMessageType*"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</callback>
		<callback name="GeditMessageCallback">
			<return-type type="void"/>
			<parameters>
				<parameter name="bus" type="GeditMessageBus*"/>
				<parameter name="message" type="GeditMessage*"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</callback>
		<callback name="GeditMessageTypeForeach">
			<return-type type="void"/>
			<parameters>
				<parameter name="key" type="gchar*"/>
				<parameter name="type" type="GType"/>
				<parameter name="required" type="gboolean"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</callback>
		<callback name="GeditMountOperationFactory">
			<return-type type="GMountOperation*"/>
			<parameters>
				<parameter name="doc" type="GeditDocument*"/>
				<parameter name="userdata" type="gpointer"/>
			</parameters>
		</callback>
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
			<method name="set_window_title" symbol="gedit_app_set_window_title">
				<return-type type="void"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="title" type="gchar*"/>
				</parameters>
			</method>
			<method name="show_help" symbol="gedit_app_show_help">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="app" type="GeditApp*"/>
					<parameter name="parent" type="GtkWindow*"/>
					<parameter name="name" type="gchar*"/>
					<parameter name="link_id" type="gchar*"/>
				</parameters>
			</method>
			<field name="parent" type="GInitiallyUnowned"/>
			<field name="priv" type="GeditAppPrivate*"/>
		</struct>
		<struct name="GeditAppActivatable">
			<method name="activate" symbol="gedit_app_activatable_activate">
				<return-type type="void"/>
				<parameters>
					<parameter name="activatable" type="GeditAppActivatable*"/>
				</parameters>
			</method>
			<method name="deactivate" symbol="gedit_app_activatable_deactivate">
				<return-type type="void"/>
				<parameters>
					<parameter name="activatable" type="GeditAppActivatable*"/>
				</parameters>
			</method>
		</struct>
		<struct name="GeditAppActivatableInterface">
			<field name="g_iface" type="GTypeInterface"/>
			<field name="activate" type="GCallback"/>
			<field name="deactivate" type="GCallback"/>
		</struct>
		<struct name="GeditAppClass">
			<field name="parent_class" type="GObjectClass"/>
			<field name="last_window_destroyed" type="GCallback"/>
			<field name="show_help" type="GCallback"/>
			<field name="help_link_id" type="GCallback"/>
			<field name="set_window_title" type="GCallback"/>
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
			<method name="get_compression_type" symbol="gedit_document_get_compression_type">
				<return-type type="GeditDocumentCompressionType"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_content_type" symbol="gedit_document_get_content_type">
				<return-type type="gchar*"/>
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
			<method name="get_location" symbol="gedit_document_get_location">
				<return-type type="GFile*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_metadata" symbol="gedit_document_get_metadata">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="key" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_mime_type" symbol="gedit_document_get_mime_type">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="get_newline_type" symbol="gedit_document_get_newline_type">
				<return-type type="GeditDocumentNewlineType"/>
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
			<method name="goto_line_offset" symbol="gedit_document_goto_line_offset">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="line" type="gint"/>
					<parameter name="line_offset" type="gint"/>
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
					<parameter name="location" type="GFile*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="line_pos" type="gint"/>
					<parameter name="column_pos" type="gint"/>
					<parameter name="create" type="gboolean"/>
				</parameters>
			</method>
			<method name="load_cancel" symbol="gedit_document_load_cancel">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
				</parameters>
			</method>
			<method name="load_stream" symbol="gedit_document_load_stream">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="stream" type="GInputStream*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="line_pos" type="gint"/>
					<parameter name="column_pos" type="gint"/>
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
					<parameter name="location" type="GFile*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="newline_type" type="GeditDocumentNewlineType"/>
					<parameter name="compression_type" type="GeditDocumentCompressionType"/>
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
			<method name="set_content_type" symbol="gedit_document_set_content_type">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="content_type" type="gchar*"/>
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
			<method name="set_location" symbol="gedit_document_set_location">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="location" type="GFile*"/>
				</parameters>
			</method>
			<method name="set_metadata" symbol="gedit_document_set_metadata">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="first_key" type="gchar*"/>
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
			<method name="set_short_name_for_display" symbol="gedit_document_set_short_name_for_display">
				<return-type type="void"/>
				<parameters>
					<parameter name="doc" type="GeditDocument*"/>
					<parameter name="short_name" type="gchar*"/>
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
		<struct name="GeditEncodingsComboBox">
			<method name="get_selected_encoding" symbol="gedit_encodings_combo_box_get_selected_encoding">
				<return-type type="GeditEncoding*"/>
				<parameters>
					<parameter name="menu" type="GeditEncodingsComboBox*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_encodings_combo_box_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="save_mode" type="gboolean"/>
				</parameters>
			</method>
			<method name="set_selected_encoding" symbol="gedit_encodings_combo_box_set_selected_encoding">
				<return-type type="void"/>
				<parameters>
					<parameter name="menu" type="GeditEncodingsComboBox*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
				</parameters>
			</method>
			<field name="parent" type="GtkComboBox"/>
			<field name="priv" type="GeditEncodingsComboBoxPrivate*"/>
		</struct>
		<struct name="GeditEncodingsComboBoxClass">
			<field name="parent_class" type="GtkComboBoxClass"/>
		</struct>
		<struct name="GeditMessage">
			<method name="get" symbol="gedit_message_get">
				<return-type type="void"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<method name="get_key_type" symbol="gedit_message_get_key_type">
				<return-type type="GType"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
					<parameter name="key" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_message_type" symbol="gedit_message_get_message_type">
				<return-type type="struct _GeditMessageType*"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<method name="get_method" symbol="gedit_message_get_method">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<method name="get_object_path" symbol="gedit_message_get_object_path">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<method name="get_valist" symbol="gedit_message_get_valist">
				<return-type type="void"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
					<parameter name="var_args" type="va_list"/>
				</parameters>
			</method>
			<method name="get_value" symbol="gedit_message_get_value">
				<return-type type="void"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
					<parameter name="key" type="gchar*"/>
					<parameter name="value" type="GValue*"/>
				</parameters>
			</method>
			<method name="has_key" symbol="gedit_message_has_key">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
					<parameter name="key" type="gchar*"/>
				</parameters>
			</method>
			<method name="set" symbol="gedit_message_set">
				<return-type type="void"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<method name="set_valist" symbol="gedit_message_set_valist">
				<return-type type="void"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
					<parameter name="var_args" type="va_list"/>
				</parameters>
			</method>
			<method name="set_value" symbol="gedit_message_set_value">
				<return-type type="void"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
					<parameter name="key" type="gchar*"/>
					<parameter name="value" type="GValue*"/>
				</parameters>
			</method>
			<method name="set_valuesv" symbol="gedit_message_set_valuesv">
				<return-type type="void"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
					<parameter name="keys" type="gchar**"/>
					<parameter name="values" type="GValue*"/>
					<parameter name="n_values" type="gint"/>
				</parameters>
			</method>
			<method name="validate" symbol="gedit_message_validate">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<field name="parent" type="GObject"/>
			<field name="priv" type="GeditMessagePrivate*"/>
		</struct>
		<struct name="GeditMessageBus">
			<method name="block" symbol="gedit_message_bus_block">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="id" type="guint"/>
				</parameters>
			</method>
			<method name="block_by_func" symbol="gedit_message_bus_block_by_func">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
					<parameter name="callback" type="GeditMessageCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="connect" symbol="gedit_message_bus_connect">
				<return-type type="guint"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
					<parameter name="callback" type="GeditMessageCallback"/>
					<parameter name="user_data" type="gpointer"/>
					<parameter name="destroy_data" type="GDestroyNotify"/>
				</parameters>
			</method>
			<method name="disconnect" symbol="gedit_message_bus_disconnect">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="id" type="guint"/>
				</parameters>
			</method>
			<method name="disconnect_by_func" symbol="gedit_message_bus_disconnect_by_func">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
					<parameter name="callback" type="GeditMessageCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="foreach" symbol="gedit_message_bus_foreach">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="func" type="GeditMessageBusForeach"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="get_default" symbol="gedit_message_bus_get_default">
				<return-type type="GeditMessageBus*"/>
			</method>
			<method name="is_registered" symbol="gedit_message_bus_is_registered">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
				</parameters>
			</method>
			<method name="lookup" symbol="gedit_message_bus_lookup">
				<return-type type="GeditMessageType*"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_message_bus_new">
				<return-type type="GeditMessageBus*"/>
			</method>
			<method name="register" symbol="gedit_message_bus_register">
				<return-type type="GeditMessageType*"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
					<parameter name="num_optional" type="guint"/>
				</parameters>
			</method>
			<method name="send" symbol="gedit_message_bus_send">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
				</parameters>
			</method>
			<method name="send_message" symbol="gedit_message_bus_send_message">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<method name="send_message_sync" symbol="gedit_message_bus_send_message_sync">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="message" type="GeditMessage*"/>
				</parameters>
			</method>
			<method name="send_sync" symbol="gedit_message_bus_send_sync">
				<return-type type="GeditMessage*"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
				</parameters>
			</method>
			<method name="unblock" symbol="gedit_message_bus_unblock">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="id" type="guint"/>
				</parameters>
			</method>
			<method name="unblock_by_func" symbol="gedit_message_bus_unblock_by_func">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
					<parameter name="callback" type="GeditMessageCallback"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="unregister" symbol="gedit_message_bus_unregister">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="message_type" type="GeditMessageType*"/>
				</parameters>
			</method>
			<method name="unregister_all" symbol="gedit_message_bus_unregister_all">
				<return-type type="void"/>
				<parameters>
					<parameter name="bus" type="GeditMessageBus*"/>
					<parameter name="object_path" type="gchar*"/>
				</parameters>
			</method>
			<field name="parent" type="GObject"/>
			<field name="priv" type="GeditMessageBusPrivate*"/>
		</struct>
		<struct name="GeditMessageBusClass">
			<field name="parent_class" type="GObjectClass"/>
			<field name="dispatch" type="GCallback"/>
			<field name="registered" type="GCallback"/>
			<field name="unregistered" type="GCallback"/>
		</struct>
		<struct name="GeditMessageClass">
			<field name="parent_class" type="GObjectClass"/>
		</struct>
		<struct name="GeditMessageType">
			<method name="foreach" symbol="gedit_message_type_foreach">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
					<parameter name="func" type="GeditMessageTypeForeach"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="get_method" symbol="gedit_message_type_get_method">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
				</parameters>
			</method>
			<method name="get_object_path" symbol="gedit_message_type_get_object_path">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
				</parameters>
			</method>
			<method name="identifier" symbol="gedit_message_type_identifier">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
				</parameters>
			</method>
			<method name="instantiate" symbol="gedit_message_type_instantiate">
				<return-type type="GeditMessage*"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
				</parameters>
			</method>
			<method name="instantiate_valist" symbol="gedit_message_type_instantiate_valist">
				<return-type type="GeditMessage*"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
					<parameter name="va_args" type="va_list"/>
				</parameters>
			</method>
			<method name="is_supported" symbol="gedit_message_type_is_supported">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="type" type="GType"/>
				</parameters>
			</method>
			<method name="is_valid_object_path" symbol="gedit_message_type_is_valid_object_path">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="object_path" type="gchar*"/>
				</parameters>
			</method>
			<method name="lookup" symbol="gedit_message_type_lookup">
				<return-type type="GType"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
					<parameter name="key" type="gchar*"/>
				</parameters>
			</method>
			<method name="new" symbol="gedit_message_type_new">
				<return-type type="GeditMessageType*"/>
				<parameters>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
					<parameter name="num_optional" type="guint"/>
				</parameters>
			</method>
			<method name="new_valist" symbol="gedit_message_type_new_valist">
				<return-type type="GeditMessageType*"/>
				<parameters>
					<parameter name="object_path" type="gchar*"/>
					<parameter name="method" type="gchar*"/>
					<parameter name="num_optional" type="guint"/>
					<parameter name="var_args" type="va_list"/>
				</parameters>
			</method>
			<method name="ref" symbol="gedit_message_type_ref">
				<return-type type="GeditMessageType*"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
				</parameters>
			</method>
			<method name="set" symbol="gedit_message_type_set">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
					<parameter name="num_optional" type="guint"/>
				</parameters>
			</method>
			<method name="set_valist" symbol="gedit_message_type_set_valist">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
					<parameter name="num_optional" type="guint"/>
					<parameter name="var_args" type="va_list"/>
				</parameters>
			</method>
			<method name="unref" symbol="gedit_message_type_unref">
				<return-type type="void"/>
				<parameters>
					<parameter name="message_type" type="GeditMessageType*"/>
				</parameters>
			</method>
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
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
					<parameter name="item" type="GtkWidget*"/>
					<parameter name="id" type="gchar*"/>
					<parameter name="display_name" type="gchar*"/>
					<parameter name="image" type="GtkWidget*"/>
				</parameters>
			</method>
			<method name="add_item_with_stock_icon" symbol="gedit_panel_add_item_with_stock_icon">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="panel" type="GeditPanel*"/>
					<parameter name="item" type="GtkWidget*"/>
					<parameter name="id" type="gchar*"/>
					<parameter name="display_name" type="gchar*"/>
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
		<struct name="GeditProgressInfoBar">
			<method name="new" symbol="gedit_progress_info_bar_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="stock_id" type="gchar*"/>
					<parameter name="markup" type="gchar*"/>
					<parameter name="has_cancel" type="gboolean"/>
				</parameters>
			</method>
			<method name="pulse" symbol="gedit_progress_info_bar_pulse">
				<return-type type="void"/>
				<parameters>
					<parameter name="bar" type="GeditProgressInfoBar*"/>
				</parameters>
			</method>
			<method name="set_fraction" symbol="gedit_progress_info_bar_set_fraction">
				<return-type type="void"/>
				<parameters>
					<parameter name="bar" type="GeditProgressInfoBar*"/>
					<parameter name="fraction" type="gdouble"/>
				</parameters>
			</method>
			<method name="set_markup" symbol="gedit_progress_info_bar_set_markup">
				<return-type type="void"/>
				<parameters>
					<parameter name="bar" type="GeditProgressInfoBar*"/>
					<parameter name="markup" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_stock_image" symbol="gedit_progress_info_bar_set_stock_image">
				<return-type type="void"/>
				<parameters>
					<parameter name="bar" type="GeditProgressInfoBar*"/>
					<parameter name="stock_id" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_text" symbol="gedit_progress_info_bar_set_text">
				<return-type type="void"/>
				<parameters>
					<parameter name="bar" type="GeditProgressInfoBar*"/>
					<parameter name="text" type="gchar*"/>
				</parameters>
			</method>
			<field name="parent" type="GtkInfoBar"/>
			<field name="priv" type="GeditProgressInfoBarPrivate*"/>
		</struct>
		<struct name="GeditProgressInfoBarClass">
			<field name="parent_class" type="GtkInfoBarClass"/>
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
			<method name="set_info_bar" symbol="gedit_tab_set_info_bar">
				<return-type type="void"/>
				<parameters>
					<parameter name="tab" type="GeditTab*"/>
					<parameter name="info_bar" type="GtkWidget*"/>
				</parameters>
			</method>
			<field name="vbox" type="GtkVBox"/>
			<field name="priv" type="GeditTabPrivate*"/>
		</struct>
		<struct name="GeditTabClass">
			<field name="parent_class" type="GtkVBoxClass"/>
			<field name="drop_uris" type="GCallback"/>
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
		<struct name="GeditViewActivatable">
			<method name="activate" symbol="gedit_view_activatable_activate">
				<return-type type="void"/>
				<parameters>
					<parameter name="activatable" type="GeditViewActivatable*"/>
				</parameters>
			</method>
			<method name="deactivate" symbol="gedit_view_activatable_deactivate">
				<return-type type="void"/>
				<parameters>
					<parameter name="activatable" type="GeditViewActivatable*"/>
				</parameters>
			</method>
		</struct>
		<struct name="GeditViewActivatableInterface">
			<field name="g_iface" type="GTypeInterface"/>
			<field name="activate" type="GCallback"/>
			<field name="deactivate" type="GCallback"/>
		</struct>
		<struct name="GeditViewClass">
			<field name="parent_class" type="GtkSourceViewClass"/>
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
			<method name="create_tab_from_location" symbol="gedit_window_create_tab_from_location">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="location" type="GFile*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="line_pos" type="gint"/>
					<parameter name="column_pos" type="gint"/>
					<parameter name="create" type="gboolean"/>
					<parameter name="jump_to" type="gboolean"/>
				</parameters>
			</method>
			<method name="create_tab_from_stream" symbol="gedit_window_create_tab_from_stream">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="stream" type="GInputStream*"/>
					<parameter name="encoding" type="GeditEncoding*"/>
					<parameter name="line_pos" type="gint"/>
					<parameter name="column_pos" type="gint"/>
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
			<method name="get_message_bus" symbol="gedit_window_get_message_bus">
				<return-type type="GeditMessageBus*"/>
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
			<method name="get_tab_from_location" symbol="gedit_window_get_tab_from_location">
				<return-type type="GeditTab*"/>
				<parameters>
					<parameter name="window" type="GeditWindow*"/>
					<parameter name="location" type="GFile*"/>
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
		<struct name="GeditWindowActivatable">
			<method name="activate" symbol="gedit_window_activatable_activate">
				<return-type type="void"/>
				<parameters>
					<parameter name="activatable" type="GeditWindowActivatable*"/>
				</parameters>
			</method>
			<method name="deactivate" symbol="gedit_window_activatable_deactivate">
				<return-type type="void"/>
				<parameters>
					<parameter name="activatable" type="GeditWindowActivatable*"/>
				</parameters>
			</method>
			<method name="update_state" symbol="gedit_window_activatable_update_state">
				<return-type type="void"/>
				<parameters>
					<parameter name="activatable" type="GeditWindowActivatable*"/>
				</parameters>
			</method>
		</struct>
		<struct name="GeditWindowActivatableInterface">
			<field name="g_iface" type="GTypeInterface"/>
			<field name="activate" type="GCallback"/>
			<field name="deactivate" type="GCallback"/>
			<field name="update_state" type="GCallback"/>
		</struct>
		<struct name="GeditWindowClass">
			<field name="parent_class" type="GtkWindowClass"/>
			<field name="tab_added" type="GCallback"/>
			<field name="tab_removed" type="GCallback"/>
			<field name="tabs_reordered" type="GCallback"/>
			<field name="active_tab_changed" type="GCallback"/>
			<field name="active_tab_state_changed" type="GCallback"/>
		</struct>
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
			<member name="GEDIT_DEBUG_PANEL" value="32768"/>
		</enum>
		<enum name="GeditDocumentCompressionType">
			<member name="GEDIT_DOCUMENT_COMPRESSION_TYPE_NONE" value="0"/>
			<member name="GEDIT_DOCUMENT_COMPRESSION_TYPE_GZIP" value="1"/>
		</enum>
		<enum name="GeditDocumentNewlineType">
			<member name="GEDIT_DOCUMENT_NEWLINE_TYPE_LF" value="0"/>
			<member name="GEDIT_DOCUMENT_NEWLINE_TYPE_CR" value="1"/>
			<member name="GEDIT_DOCUMENT_NEWLINE_TYPE_CR_LF" value="2"/>
		</enum>
		<enum name="GeditDocumentSaveFlags">
			<member name="GEDIT_DOCUMENT_SAVE_IGNORE_MTIME" value="1"/>
			<member name="GEDIT_DOCUMENT_SAVE_IGNORE_BACKUP" value="2"/>
			<member name="GEDIT_DOCUMENT_SAVE_PRESERVE_BACKUP" value="4"/>
			<member name="GEDIT_DOCUMENT_SAVE_IGNORE_INVALID_CHARS" value="8"/>
		</enum>
		<enum name="GeditLockdownMask">
			<member name="GEDIT_LOCKDOWN_COMMAND_LINE" value="1"/>
			<member name="GEDIT_LOCKDOWN_PRINTING" value="2"/>
			<member name="GEDIT_LOCKDOWN_PRINT_SETUP" value="4"/>
			<member name="GEDIT_LOCKDOWN_SAVE_TO_DISK" value="8"/>
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
		<enum name="GeditWindowState">
			<member name="GEDIT_WINDOW_STATE_NORMAL" value="0"/>
			<member name="GEDIT_WINDOW_STATE_SAVING" value="2"/>
			<member name="GEDIT_WINDOW_STATE_PRINTING" value="4"/>
			<member name="GEDIT_WINDOW_STATE_LOADING" value="8"/>
			<member name="GEDIT_WINDOW_STATE_ERROR" value="16"/>
			<member name="GEDIT_WINDOW_STATE_SAVING_SESSION" value="32"/>
		</enum>
		<constant name="GEDIT_LOCKDOWN_ALL" type="int" value="15"/>
		<constant name="GEDIT_METADATA_ATTRIBUTE_ENCODING" type="char*" value="encoding"/>
		<constant name="GEDIT_METADATA_ATTRIBUTE_LANGUAGE" type="char*" value="language"/>
		<constant name="GEDIT_METADATA_ATTRIBUTE_POSITION" type="char*" value="position"/>
	</namespace>
</api>
