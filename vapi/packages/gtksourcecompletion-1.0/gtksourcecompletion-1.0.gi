<?xml version="1.0"?>
<api version="1.0">
	<namespace name="Gsc">
		<function name="char_is_separator" symbol="gsc_char_is_separator">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="ch" type="gunichar"/>
			</parameters>
		</function>
		<function name="clear_word" symbol="gsc_clear_word">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="word" type="gchar*"/>
			</parameters>
		</function>
		<function name="compare_keys" symbol="gsc_compare_keys">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="key" type="guint"/>
				<parameter name="mods" type="guint"/>
				<parameter name="event" type="GdkEventKey*"/>
			</parameters>
		</function>
		<function name="compute_line_indentation" symbol="gsc_compute_line_indentation">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="view" type="GtkTextView*"/>
				<parameter name="cur" type="GtkTextIter*"/>
			</parameters>
		</function>
		<function name="get_cursor_pos" symbol="gsc_get_cursor_pos">
			<return-type type="void"/>
			<parameters>
				<parameter name="text_view" type="GtkTextView*"/>
				<parameter name="x" type="gint*"/>
				<parameter name="y" type="gint*"/>
			</parameters>
		</function>
		<function name="get_last_word" symbol="gsc_get_last_word">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text_view" type="GtkTextView*"/>
			</parameters>
		</function>
		<function name="get_last_word_and_iter" symbol="gsc_get_last_word_and_iter">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text_view" type="GtkTextView*"/>
				<parameter name="start_word" type="GtkTextIter*"/>
				<parameter name="end_word" type="GtkTextIter*"/>
			</parameters>
		</function>
		<function name="get_last_word_cleaned" symbol="gsc_get_last_word_cleaned">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text_view" type="GtkTextView*"/>
			</parameters>
		</function>
		<function name="get_text_with_indent" symbol="gsc_get_text_with_indent">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="content" type="gchar*"/>
				<parameter name="indent" type="gchar*"/>
			</parameters>
		</function>
		<function name="get_window_position_center_parent" symbol="gsc_get_window_position_center_parent">
			<return-type type="void"/>
			<parameters>
				<parameter name="window" type="GtkWindow*"/>
				<parameter name="parent" type="GtkWidget*"/>
				<parameter name="x" type="gint*"/>
				<parameter name="y" type="gint*"/>
			</parameters>
		</function>
		<function name="get_window_position_center_screen" symbol="gsc_get_window_position_center_screen">
			<return-type type="void"/>
			<parameters>
				<parameter name="window" type="GtkWindow*"/>
				<parameter name="x" type="gint*"/>
				<parameter name="y" type="gint*"/>
			</parameters>
		</function>
		<function name="get_window_position_in_cursor" symbol="gsc_get_window_position_in_cursor">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="window" type="GtkWindow*"/>
				<parameter name="view" type="GtkTextView*"/>
				<parameter name="x" type="gint*"/>
				<parameter name="y" type="gint*"/>
			</parameters>
		</function>
		<function name="gsv_get_text" symbol="gsc_gsv_get_text">
			<return-type type="gchar*"/>
			<parameters>
				<parameter name="text_view" type="GtkTextView*"/>
			</parameters>
		</function>
		<function name="insert_text_with_indent" symbol="gsc_insert_text_with_indent">
			<return-type type="void"/>
			<parameters>
				<parameter name="view" type="GtkTextView*"/>
				<parameter name="text" type="gchar*"/>
			</parameters>
		</function>
		<function name="is_valid_word" symbol="gsc_is_valid_word">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="current_word" type="gchar*"/>
				<parameter name="completion_word" type="gchar*"/>
			</parameters>
		</function>
		<function name="replace_actual_word" symbol="gsc_replace_actual_word">
			<return-type type="void"/>
			<parameters>
				<parameter name="text_view" type="GtkTextView*"/>
				<parameter name="text" type="gchar*"/>
			</parameters>
		</function>
		<struct name="GscManagerEventOptions">
			<field name="position_type" type="GscPopupPositionType"/>
			<field name="filter_type" type="GscPopupFilterType"/>
			<field name="filter_text" type="gchar*"/>
			<field name="autoselect" type="gboolean"/>
			<field name="show_bottom_bar" type="gboolean"/>
		</struct>
		<struct name="GscPopupPriv">
		</struct>
		<struct name="GscTreePriv">
		</struct>
		<enum name="GscDocumentwordsProviderSortType">
			<member name="GSC_DOCUMENTWORDS_PROVIDER_SORT_NONE" value="0"/>
			<member name="GSC_DOCUMENTWORDS_PROVIDER_SORT_BY_LENGTH" value="1"/>
		</enum>
		<enum name="GscInfoType">
			<member name="GSC_INFO_VIEW_SORT" value="0"/>
			<member name="GSC_INFO_VIEW_EXTENDED" value="1"/>
		</enum>
		<enum name="GscPopupFilterType">
			<member name="GSC_POPUP_FILTER_NONE" value="0"/>
			<member name="GSC_POPUP_FILTER_TREE" value="1"/>
			<member name="GSC_POPUP_FILTER_TREE_HIDDEN" value="2"/>
		</enum>
		<enum name="GscPopupPositionType">
			<member name="GSC_POPUP_POSITION_CURSOR" value="0"/>
			<member name="GSC_POPUP_POSITION_CENTER_SCREEN" value="1"/>
			<member name="GSC_POPUP_POSITION_CENTER_PARENT" value="2"/>
		</enum>
		<enum name="KeysType">
			<member name="KEYS_INFO" value="0"/>
			<member name="KEYS_PAGE_NEXT" value="1"/>
			<member name="KEYS_PAGE_PREV" value="2"/>
			<member name="KEYS_LAST" value="3"/>
		</enum>
		<object name="GscDocumentwordsProvider" parent="GObject" type-name="GscDocumentwordsProvider" get-type="gsc_documentwords_provider_get_type">
			<implements>
				<interface name="GscProvider"/>
			</implements>
			<method name="get_sort_type" symbol="gsc_documentwords_provider_get_sort_type">
				<return-type type="GscDocumentwordsProviderSortType"/>
				<parameters>
					<parameter name="prov" type="GscDocumentwordsProvider*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="gsc_documentwords_provider_new">
				<return-type type="GscDocumentwordsProvider*"/>
				<parameters>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</constructor>
			<method name="set_sort_type" symbol="gsc_documentwords_provider_set_sort_type">
				<return-type type="void"/>
				<parameters>
					<parameter name="prov" type="GscDocumentwordsProvider*"/>
					<parameter name="sort_type" type="GscDocumentwordsProviderSortType"/>
				</parameters>
			</method>
		</object>
		<object name="GscInfo" parent="GtkWindow" type-name="GscInfo" get-type="gsc_info_get_type">
			<implements>
				<interface name="GtkBuildable"/>
				<interface name="AtkImplementor"/>
			</implements>
			<method name="move_to_cursor" symbol="gsc_info_move_to_cursor">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="gsc_info_new">
				<return-type type="GscInfo*"/>
			</constructor>
			<method name="set_adjust_height" symbol="gsc_info_set_adjust_height">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
					<parameter name="adjust" type="gboolean"/>
					<parameter name="max_height" type="gint"/>
				</parameters>
			</method>
			<method name="set_adjust_width" symbol="gsc_info_set_adjust_width">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
					<parameter name="adjust" type="gboolean"/>
					<parameter name="max_width" type="gint"/>
				</parameters>
			</method>
			<method name="set_info_type" symbol="gsc_info_set_info_type">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
					<parameter name="type" type="GscInfoType"/>
				</parameters>
			</method>
			<method name="set_markup" symbol="gsc_info_set_markup">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
					<parameter name="markup" type="gchar*"/>
				</parameters>
			</method>
			<signal name="info-type-changed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="GscInfo*"/>
					<parameter name="p0" type="gint"/>
				</parameters>
			</signal>
		</object>
		<object name="GscManager" parent="GObject" type-name="GscManager" get-type="gsc_manager_get_type">
			<method name="activate" symbol="gsc_manager_activate">
				<return-type type="void"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
				</parameters>
			</method>
			<method name="deactivate" symbol="gsc_manager_deactivate">
				<return-type type="void"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
				</parameters>
			</method>
			<method name="finish_completion" symbol="gsc_manager_finish_completion">
				<return-type type="void"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
				</parameters>
			</method>
			<method name="get_active_trigger" symbol="gsc_manager_get_active_trigger">
				<return-type type="GscTrigger*"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
				</parameters>
			</method>
			<method name="get_current_event_options" symbol="gsc_manager_get_current_event_options">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscManager*"/>
					<parameter name="options" type="GscManagerEventOptions*"/>
				</parameters>
			</method>
			<method name="get_from_view" symbol="gsc_manager_get_from_view">
				<return-type type="GscManager*"/>
				<parameters>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</method>
			<method name="get_provider" symbol="gsc_manager_get_provider">
				<return-type type="GscProvider*"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="provider_name" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_trigger" symbol="gsc_manager_get_trigger">
				<return-type type="GscTrigger*"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="trigger_name" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_view" symbol="gsc_manager_get_view">
				<return-type type="GtkTextView*"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
				</parameters>
			</method>
			<method name="is_visible" symbol="gsc_manager_is_visible">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="gsc_manager_new">
				<return-type type="GscManager*"/>
				<parameters>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</constructor>
			<method name="register_provider" symbol="gsc_manager_register_provider">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="provider" type="GscProvider*"/>
					<parameter name="trigger_name" type="gchar*"/>
				</parameters>
			</method>
			<method name="register_trigger" symbol="gsc_manager_register_trigger">
				<return-type type="void"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="set_current_info" symbol="gsc_manager_set_current_info">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscManager*"/>
					<parameter name="info" type="gchar*"/>
				</parameters>
			</method>
			<method name="trigger_event" symbol="gsc_manager_trigger_event">
				<return-type type="void"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="trigger_name" type="gchar*"/>
					<parameter name="event_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="trigger_event_with_opts" symbol="gsc_manager_trigger_event_with_opts">
				<return-type type="void"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="trigger_name" type="gchar*"/>
					<parameter name="options" type="GscManagerEventOptions*"/>
					<parameter name="event_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="unregister_provider" symbol="gsc_manager_unregister_provider">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="provider" type="GscProvider*"/>
					<parameter name="trigger_name" type="gchar*"/>
				</parameters>
			</method>
			<method name="unregister_trigger" symbol="gsc_manager_unregister_trigger">
				<return-type type="void"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="update_event_options" symbol="gsc_manager_update_event_options">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscManager*"/>
					<parameter name="options" type="GscManagerEventOptions*"/>
				</parameters>
			</method>
			<property name="info-keys" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="next-page-keys" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="previous-page-keys" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
		</object>
		<object name="GscPopup" parent="GtkWindow" type-name="GscPopup" get-type="gsc_popup_get_type">
			<implements>
				<interface name="GtkBuildable"/>
				<interface name="AtkImplementor"/>
			</implements>
			<method name="add_data" symbol="gsc_popup_add_data">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="data" type="GscProposal*"/>
				</parameters>
			</method>
			<method name="bottom_bar_get_visible" symbol="gsc_popup_bottom_bar_get_visible">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="bottom_bar_set_visible" symbol="gsc_popup_bottom_bar_set_visible">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="visible" type="gboolean"/>
				</parameters>
			</method>
			<method name="clear" symbol="gsc_popup_clear">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="get_filter_text" symbol="gsc_popup_get_filter_text">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="get_filter_type" symbol="gsc_popup_get_filter_type">
				<return-type type="GscPopupFilterType"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="get_filter_widget" symbol="gsc_popup_get_filter_widget">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="get_key" symbol="gsc_popup_get_key">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="type" type="KeysType"/>
				</parameters>
			</method>
			<method name="get_num_active_pages" symbol="gsc_popup_get_num_active_pages">
				<return-type type="gint"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="get_selected_proposal" symbol="gsc_popup_get_selected_proposal">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="proposal" type="GscProposal**"/>
				</parameters>
			</method>
			<method name="has_proposals" symbol="gsc_popup_has_proposals">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="manage_key" symbol="gsc_popup_manage_key">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="event" type="GdkEventKey*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="gsc_popup_new">
				<return-type type="GtkWidget*"/>
			</constructor>
			<method name="page_next" symbol="gsc_popup_page_next">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="page_previous" symbol="gsc_popup_page_previous">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="select_first" symbol="gsc_popup_select_first">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="select_last" symbol="gsc_popup_select_last">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<method name="select_next" symbol="gsc_popup_select_next">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="rows" type="gint"/>
				</parameters>
			</method>
			<method name="select_previous" symbol="gsc_popup_select_previous">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="rows" type="gint"/>
				</parameters>
			</method>
			<method name="set_current_info" symbol="gsc_popup_set_current_info">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="info" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_filter_text" symbol="gsc_popup_set_filter_text">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="text" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_filter_type" symbol="gsc_popup_set_filter_type">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="filter_type" type="GscPopupFilterType"/>
				</parameters>
			</method>
			<method name="set_key" symbol="gsc_popup_set_key">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
					<parameter name="type" type="KeysType"/>
					<parameter name="keys" type="gchar*"/>
				</parameters>
			</method>
			<method name="show_or_update" symbol="gsc_popup_show_or_update">
				<return-type type="void"/>
				<parameters>
					<parameter name="widget" type="GtkWidget*"/>
				</parameters>
			</method>
			<method name="toggle_proposal_info" symbol="gsc_popup_toggle_proposal_info">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscPopup*"/>
				</parameters>
			</method>
			<signal name="display-info" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="GscPopup*"/>
					<parameter name="p0" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="proposal-selected" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="popup" type="GscPopup*"/>
					<parameter name="proposal" type="gpointer"/>
				</parameters>
			</signal>
		</object>
		<object name="GscProposal" parent="GObject" type-name="GscProposal" get-type="gsc_proposal_get_type">
			<method name="apply" symbol="gsc_proposal_apply">
				<return-type type="void"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</method>
			<method name="get_icon" symbol="gsc_proposal_get_icon">
				<return-type type="GdkPixbuf*"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
				</parameters>
			</method>
			<method name="get_info" symbol="gsc_proposal_get_info">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
				</parameters>
			</method>
			<method name="get_label" symbol="gsc_proposal_get_label">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
				</parameters>
			</method>
			<method name="get_page_name" symbol="gsc_proposal_get_page_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="gsc_proposal_new">
				<return-type type="GscProposal*"/>
				<parameters>
					<parameter name="label" type="gchar*"/>
					<parameter name="info" type="gchar*"/>
					<parameter name="icon" type="GdkPixbuf*"/>
				</parameters>
			</constructor>
			<method name="set_page_name" symbol="gsc_proposal_set_page_name">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscProposal*"/>
					<parameter name="page_name" type="gchar*"/>
				</parameters>
			</method>
			<property name="icon" type="gpointer" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="info" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="label" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<signal name="apply" when="LAST">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
					<parameter name="view" type="gpointer"/>
				</parameters>
			</signal>
			<vfunc name="get_info">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
				</parameters>
			</vfunc>
		</object>
		<object name="GscProviderFile" parent="GObject" type-name="GscProviderFile" get-type="gsc_provider_file_get_type">
			<implements>
				<interface name="GscProvider"/>
			</implements>
			<constructor name="new" symbol="gsc_provider_file_new">
				<return-type type="GscProviderFile*"/>
				<parameters>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</constructor>
			<method name="set_file" symbol="gsc_provider_file_set_file">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscProviderFile*"/>
					<parameter name="file" type="gchar*"/>
				</parameters>
			</method>
		</object>
		<object name="GscTree" parent="GtkScrolledWindow" type-name="GscTree" get-type="gsc_tree_get_type">
			<implements>
				<interface name="GtkBuildable"/>
				<interface name="AtkImplementor"/>
			</implements>
			<method name="add_data" symbol="gsc_tree_add_data">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
					<parameter name="data" type="GscProposal*"/>
				</parameters>
			</method>
			<method name="clear" symbol="gsc_tree_clear">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
				</parameters>
			</method>
			<method name="filter" symbol="gsc_tree_filter">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
					<parameter name="filter" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_num_proposals" symbol="gsc_tree_get_num_proposals">
				<return-type type="gint"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
				</parameters>
			</method>
			<method name="get_selected_proposal" symbol="gsc_tree_get_selected_proposal">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
					<parameter name="proposal" type="GscProposal**"/>
				</parameters>
			</method>
			<constructor name="new" symbol="gsc_tree_new">
				<return-type type="GtkWidget*"/>
			</constructor>
			<method name="select_first" symbol="gsc_tree_select_first">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
				</parameters>
			</method>
			<method name="select_last" symbol="gsc_tree_select_last">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
				</parameters>
			</method>
			<method name="select_next" symbol="gsc_tree_select_next">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
					<parameter name="rows" type="gint"/>
				</parameters>
			</method>
			<method name="select_previous" symbol="gsc_tree_select_previous">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTree*"/>
					<parameter name="rows" type="gint"/>
				</parameters>
			</method>
			<signal name="proposal-selected" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="tree" type="GscTree*"/>
					<parameter name="proposal" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="selection-changed" when="FIRST">
				<return-type type="void"/>
				<parameters>
					<parameter name="tree" type="GscTree*"/>
					<parameter name="proposal" type="gpointer"/>
				</parameters>
			</signal>
		</object>
		<object name="GscTriggerAutowords" parent="GObject" type-name="GscTriggerAutowords" get-type="gsc_trigger_autowords_get_type">
			<implements>
				<interface name="GscTrigger"/>
			</implements>
			<constructor name="new" symbol="gsc_trigger_autowords_new">
				<return-type type="GscTriggerAutowords*"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
				</parameters>
			</constructor>
			<method name="set_delay" symbol="gsc_trigger_autowords_set_delay">
				<return-type type="void"/>
				<parameters>
					<parameter name="trigger" type="GscTriggerAutowords*"/>
					<parameter name="delay" type="guint"/>
				</parameters>
			</method>
		</object>
		<object name="GscTriggerCustomkey" parent="GObject" type-name="GscTriggerCustomkey" get-type="gsc_trigger_customkey_get_type">
			<implements>
				<interface name="GscTrigger"/>
			</implements>
			<constructor name="new" symbol="gsc_trigger_customkey_new">
				<return-type type="GscTriggerCustomkey*"/>
				<parameters>
					<parameter name="completion" type="GscManager*"/>
					<parameter name="trigger_name" type="gchar*"/>
					<parameter name="keys" type="gchar*"/>
				</parameters>
			</constructor>
			<method name="set_keys" symbol="gsc_trigger_customkey_set_keys">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscTriggerCustomkey*"/>
					<parameter name="keys" type="gchar*"/>
				</parameters>
			</method>
			<method name="set_opts" symbol="gsc_trigger_customkey_set_opts">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscTriggerCustomkey*"/>
					<parameter name="options" type="GscManagerEventOptions*"/>
				</parameters>
			</method>
		</object>
		<interface name="GscProvider" type-name="GscProvider" get-type="gsc_provider_get_type">
			<method name="finish" symbol="gsc_provider_finish">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscProvider*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="gsc_provider_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="GscProvider*"/>
				</parameters>
			</method>
			<method name="get_proposals" symbol="gsc_provider_get_proposals">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="self" type="GscProvider*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<vfunc name="finish">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscProvider*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="GscProvider*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_proposals">
				<return-type type="GList*"/>
				<parameters>
					<parameter name="self" type="GscProvider*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</vfunc>
		</interface>
		<interface name="GscTrigger" type-name="GscTrigger" get-type="gsc_trigger_get_type">
			<method name="activate" symbol="gsc_trigger_activate">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="deactivate" symbol="gsc_trigger_deactivate">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="get_name" symbol="gsc_trigger_get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="GscTrigger*"/>
				</parameters>
			</method>
			<vfunc name="activate">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTrigger*"/>
				</parameters>
			</vfunc>
			<vfunc name="deactivate">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscTrigger*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_name">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="self" type="GscTrigger*"/>
				</parameters>
			</vfunc>
		</interface>
		<constant name="DEFAULT_PAGE" type="char*" value="Default"/>
		<constant name="GSC_DOCUMENTWORDS_PROVIDER_NAME" type="char*" value="GscDocumentwordsProvider"/>
		<constant name="GSC_PROPOSAL_DEFAULT_PAGE" type="char*" value="Default"/>
		<constant name="GSC_PROPOSAL_DEFAULT_PRIORITY" type="int" value="10"/>
		<constant name="GSC_PROVIDER_FILE_NAME" type="char*" value="GscProviderFile"/>
		<constant name="GSC_TRIGGER_AUTOWORDS_NAME" type="char*" value="GscTriggerAutowords"/>
		<constant name="USER_REQUEST_TRIGGER_NAME" type="char*" value="user-request"/>
	</namespace>
</api>
