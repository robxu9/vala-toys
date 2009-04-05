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
				<parameter name="resized" type="gboolean*"/>
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
		<callback name="GscCompletionFilterFunc">
			<return-type type="gboolean"/>
			<parameters>
				<parameter name="proposal" type="GscProposal*"/>
				<parameter name="user_data" type="gpointer"/>
			</parameters>
		</callback>
		<struct name="GscCompletionPage">
			<field name="name" type="gchar*"/>
			<field name="tree" type="GscTree*"/>
		</struct>
		<struct name="GscCompletionPriv">
			<field name="info_window" type="GtkWidget*"/>
			<field name="info_button" type="GtkWidget*"/>
			<field name="notebook" type="GtkWidget*"/>
			<field name="tab_label" type="GtkWidget*"/>
			<field name="next_page_button" type="GtkWidget*"/>
			<field name="prev_page_button" type="GtkWidget*"/>
			<field name="bottom_bar" type="GtkWidget*"/>
			<field name="pages" type="GList*"/>
			<field name="active_page" type="GscCompletionPage*"/>
			<field name="destroy_has_run" type="gboolean"/>
			<field name="manage_keys" type="gboolean"/>
			<field name="remember_info_visibility" type="gboolean"/>
			<field name="info_visible" type="gboolean"/>
			<field name="select_on_show" type="gboolean"/>
			<field name="view" type="GtkTextView*"/>
			<field name="triggers" type="GList*"/>
			<field name="prov_trig" type="GList*"/>
			<field name="active_trigger" type="GscTrigger*"/>
			<field name="active" type="gboolean"/>
			<field name="signals_ids" type="gulong[]"/>
		</struct>
		<struct name="GscTree">
			<field name="treeview" type="GtkTreeView*"/>
			<field name="list_store" type="GtkListStore*"/>
			<field name="model_filter" type="GtkTreeModelFilter*"/>
			<field name="filter_active" type="gboolean"/>
			<field name="filter_data" type="gpointer"/>
			<field name="filter_func" type="GscCompletionFilterFunc"/>
		</struct>
		<object name="GscCompletion" parent="GtkWindow" type-name="GscCompletion" get-type="gsc_completion_get_type">
			<implements>
				<interface name="AtkImplementor"/>
				<interface name="GtkBuildable"/>
			</implements>
			<method name="filter_proposals" symbol="gsc_completion_filter_proposals">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="func" type="GscCompletionFilterFunc"/>
					<parameter name="user_data" type="gpointer"/>
				</parameters>
			</method>
			<method name="finish_completion" symbol="gsc_completion_finish_completion">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
				</parameters>
			</method>
			<method name="get_active" symbol="gsc_completion_get_active">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
				</parameters>
			</method>
			<method name="get_active_trigger" symbol="gsc_completion_get_active_trigger">
				<return-type type="GscTrigger*"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
				</parameters>
			</method>
			<method name="get_bottom_bar" symbol="gsc_completion_get_bottom_bar">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
				</parameters>
			</method>
			<method name="get_from_view" symbol="gsc_completion_get_from_view">
				<return-type type="GscCompletion*"/>
				<parameters>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</method>
			<method name="get_info_widget" symbol="gsc_completion_get_info_widget">
				<return-type type="GscInfo*"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
				</parameters>
			</method>
			<method name="get_provider" symbol="gsc_completion_get_provider">
				<return-type type="GscProvider*"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="prov_name" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_trigger" symbol="gsc_completion_get_trigger">
				<return-type type="GscTrigger*"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="trigger_name" type="gchar*"/>
				</parameters>
			</method>
			<method name="get_view" symbol="gsc_completion_get_view">
				<return-type type="GtkTextView*"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
				</parameters>
			</method>
			<constructor name="new" symbol="gsc_completion_new">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</constructor>
			<method name="register_provider" symbol="gsc_completion_register_provider">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="provider" type="GscProvider*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="register_trigger" symbol="gsc_completion_register_trigger">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="set_active" symbol="gsc_completion_set_active">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="active" type="gboolean"/>
				</parameters>
			</method>
			<method name="trigger_event" symbol="gsc_completion_trigger_event">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="unregister_provider" symbol="gsc_completion_unregister_provider">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="provider" type="GscProvider*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<method name="unregister_trigger" symbol="gsc_completion_unregister_trigger">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="self" type="GscCompletion*"/>
					<parameter name="trigger" type="GscTrigger*"/>
				</parameters>
			</method>
			<property name="active" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="manage-completion-keys" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="remember-info-visibility" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="select-on-show" type="gboolean" readable="1" writable="1" construct="0" construct-only="0"/>
			<signal name="display-info" when="LAST">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="completion" type="GscCompletion*"/>
					<parameter name="proposal" type="gpointer"/>
				</parameters>
			</signal>
			<signal name="proposal-selected" when="LAST">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="completion" type="GscCompletion*"/>
					<parameter name="proposal" type="gpointer"/>
				</parameters>
			</signal>
		</object>
		<object name="GscInfo" parent="GtkWindow" type-name="GscInfo" get-type="gsc_info_get_type">
			<implements>
				<interface name="AtkImplementor"/>
				<interface name="GtkBuildable"/>
			</implements>
			<method name="get_custom" symbol="gsc_info_get_custom">
				<return-type type="GtkWidget*"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
				</parameters>
			</method>
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
			<method name="set_custom" symbol="gsc_info_set_custom">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
					<parameter name="custom_widget" type="GtkWidget*"/>
				</parameters>
			</method>
			<method name="set_markup" symbol="gsc_info_set_markup">
				<return-type type="void"/>
				<parameters>
					<parameter name="self" type="GscInfo*"/>
					<parameter name="markup" type="gchar*"/>
				</parameters>
			</method>
			<signal name="show-info" when="LAST">
				<return-type type="void"/>
				<parameters>
					<parameter name="object" type="GscInfo*"/>
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
			<property name="page-name" type="char*" readable="1" writable="1" construct="0" construct-only="0"/>
			<vfunc name="apply">
				<return-type type="gboolean"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
					<parameter name="view" type="GtkTextView*"/>
				</parameters>
			</vfunc>
			<vfunc name="get_info">
				<return-type type="gchar*"/>
				<parameters>
					<parameter name="proposal" type="GscProposal*"/>
				</parameters>
			</vfunc>
		</object>
		<object name="GscTriggerAutowords" parent="GObject" type-name="GscTriggerAutowords" get-type="gsc_trigger_autowords_get_type">
			<implements>
				<interface name="GscTrigger"/>
			</implements>
			<constructor name="new" symbol="gsc_trigger_autowords_new">
				<return-type type="GscTriggerAutowords*"/>
				<parameters>
					<parameter name="completion" type="GscCompletion*"/>
				</parameters>
			</constructor>
			<method name="set_delay" symbol="gsc_trigger_autowords_set_delay">
				<return-type type="void"/>
				<parameters>
					<parameter name="trigger" type="GscTriggerAutowords*"/>
					<parameter name="delay" type="guint"/>
				</parameters>
			</method>
			<property name="delay" type="gint" readable="1" writable="1" construct="0" construct-only="0"/>
			<property name="min-len" type="gint" readable="1" writable="1" construct="0" construct-only="0"/>
		</object>
		<object name="GscTriggerCustomkey" parent="GObject" type-name="GscTriggerCustomkey" get-type="gsc_trigger_customkey_get_type">
			<implements>
				<interface name="GscTrigger"/>
			</implements>
			<constructor name="new" symbol="gsc_trigger_customkey_new">
				<return-type type="GscTriggerCustomkey*"/>
				<parameters>
					<parameter name="completion" type="GscCompletion*"/>
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
		<constant name="GSC_TRIGGER_AUTOWORDS_NAME" type="char*" value="GscTriggerAutowords"/>
		<constant name="USER_REQUEST_TRIGGER_NAME" type="char*" value="user-request"/>
	</namespace>
</api>
