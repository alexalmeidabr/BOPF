*&---------------------------------------------------------------------*
*& Report ZREP_ADD_CONTAINER
*&---------------------------------------------------------------------*
*&
*& An example of how to use BOPF Actions
*&
*& The report addes a container line into a FO
*&
*&---------------------------------------------------------------------*
REPORT zrep_add_container.

DATA: lo_change           TYPE REF TO /bobf/if_tra_change,
      lo_message          TYPE REF TO /bobf/if_frw_message,
      lv_rejected         TYPE        abap_bool,
      ls_selpar           TYPE        /bobf/s_frw_query_selparam,
      lt_selpar           TYPE        /bobf/t_frw_query_selparam,
      ls_query_inf        TYPE        /bobf/s_frw_query_info,
      lt_rejecting_bo_key TYPE        /bobf/t_frw_key2,
      lt_key              TYPE        /bobf/t_frw_key,
      lt_failed_key       TYPE        /bobf/t_frw_key,
      lr_param_cont       TYPE REF TO /scmtms/s_tor_a_add_local_itm,
      lv_tor_id           TYPE        /scmtms/tor_id                  VALUE '00000000006100000050', "TOR ID
      lo_tra              TYPE REF TO /bobf/if_tra_transaction_mgr,
      lo_srv_tor          TYPE REF TO /bobf/if_tra_service_manager.

* Get an instance of a service manager for e.g. BO TOR
lo_srv_tor = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_tor_c=>sc_bo_key ).

* Get an instance of a transactional manager
lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

ls_selpar-attribute_name = /scmtms/if_tor_c=>sc_query_attribute-root-fo_data_by_attr-tor_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = lv_tor_id.
APPEND ls_selpar TO lt_selpar.

* Use method QUERY of the service manager to start the query
lo_srv_tor->query(
 EXPORTING
  iv_query_key = /scmtms/if_tor_c=>sc_query-root-fo_data_by_attr
  it_selection_parameters = lt_selpar
 IMPORTING
  eo_message = lo_message
  es_query_info = ls_query_inf
  et_key = lt_key ).

* added for Container
CREATE DATA lr_param_cont.
lr_param_cont->item_type =  'CONT'.

lo_srv_tor->do_action(
 EXPORTING
  iv_act_key = /scmtms/if_tor_c=>sc_action-root-add_container
  it_key = lt_key
  is_parameters = lr_param_cont
 IMPORTING
  eo_change = lo_change
  eo_message = lo_message
  et_failed_key = lt_failed_key ).

lo_tra->save(
  IMPORTING
    ev_rejected = lv_rejected
    eo_change = lo_change
    eo_message = lo_message
    et_rejecting_bo_key = lt_rejecting_bo_key
  ).

BREAK-POINT.