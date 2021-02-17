*&---------------------------------------------------------------------*
*& Report ZREP_BOPF_2
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zrep_bopf_2.

FIELD-SYMBOLS: <ls_root>    TYPE /scmtms/s_trq_root_k,
               <ls_trq_qdb> TYPE /scmtms/s_trq_q_result.

DATA: lo_srv_trq     TYPE REF TO /bobf/if_tra_service_manager,
      lt_mod         TYPE /bobf/t_frw_modification,
      ls_mod         TYPE /bobf/s_frw_modification,
      lv_trq_new_key TYPE /bobf/conf_key,
      lo_chg         TYPE REF TO /bobf/if_tra_change,
      lo_message     TYPE REF TO /bobf/if_frw_message,
      lo_msg_all     TYPE REF TO /bobf/if_frw_message,
      lo_tra         TYPE REF TO /bobf/if_tra_transaction_mgr,
      lv_rejected    TYPE abap_bool,
      lt_rej_bo_key  TYPE /bobf/t_frw_key2,
      ls_selpar      TYPE /bobf/s_frw_query_selparam,
      lt_selpar      TYPE /bobf/t_frw_query_selparam,
      lt_trq_qdb     TYPE /scmtms/t_trq_q_result,
      ls_query_inf   TYPE /bobf/s_frw_query_info,
      lt_key         TYPE /bobf/t_frw_key,
      ls_key         TYPE /bobf/s_frw_key,
      lt_root        TYPE /scmtms/t_trq_root_k,
      lt_failed_key  TYPE /bobf/t_frw_key,
      lv_trq_id      TYPE /scmtms/trq_id.


************************************************************************************************
*--- Selection Screen ---*
************************************************************************************************

SELECTION-SCREEN BEGIN OF BLOCK fwo_sel WITH FRAME TITLE TEXT-001.

SELECT-OPTIONS: p_trq_id FOR lv_trq_id.

SELECTION-SCREEN END OF BLOCK fwo_sel.

SELECTION-SCREEN BEGIN OF BLOCK team WITH FRAME TITLE TEXT-002.

PARAMETERS: p_create RADIOBUTTON GROUP grp1 DEFAULT 'X',
            p_delete RADIOBUTTON GROUP grp1.

SELECTION-SCREEN END OF BLOCK team.

START-OF-SELECTION.

* Get instance of service manager for TRQ
  lo_srv_trq = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_trq_c=>sc_bo_key ).

************************************************************************************************
*--- Creating a new TRQ instance node ---*
************************************************************************************************

  IF p_create = 'X'.

    ls_mod-node = /scmtms/if_trq_c=>sc_node-root.
    ls_mod-key = /bobf/cl_frw_factory=>get_new_key( ).
    ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_create.

    CREATE DATA ls_mod-data TYPE /scmtms/s_trq_root_k.

    ASSIGN ls_mod-data->* TO <ls_root>.
    <ls_root>-trq_type = 'FWO'.

    APPEND ls_mod TO lt_mod.
    lv_trq_new_key = ls_mod-key.

    lo_srv_trq->modify(
     EXPORTING
      it_modification = lt_mod
     IMPORTING
      eo_change = lo_chg
      eo_message = lo_message ).

*   Save transaction to get data persisted (NO COMMIT WORK!)
    lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

*   Call the SAVE method of the transaction manager
    lo_tra->save(
     IMPORTING
     ev_rejected = lv_rejected
     eo_change = lo_chg
     eo_message = lo_message
     et_rejecting_bo_key = lt_rej_bo_key ).

*  ***********************************************************************************************
*  --- Update the new FWO node with a MOT and Sales Org ---*
*  ***********************************************************************************************

    CLEAR lt_mod.

    ls_mod-node = /scmtms/if_trq_c=>sc_node-root.
    ls_mod-key = lv_trq_new_key.
    ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_update.

    CREATE DATA ls_mod-data TYPE /scmtms/s_trq_root_k.

    ASSIGN ls_mod-data->* TO <ls_root>.
    <ls_root>-mot = '01'.
    <ls_root>-sales_org_id = '50000613'.

    APPEND /scmtms/if_trq_c=>sc_node_attribute-root-mot TO ls_mod-changed_fields.
    APPEND /scmtms/if_trq_c=>sc_node_attribute-root-sales_org_id TO ls_mod-changed_fields.

    APPEND ls_mod TO lt_mod.
    lo_srv_trq->modify(
     EXPORTING
      it_modification = lt_mod
     IMPORTING
      eo_change = lo_chg
      eo_message = lo_message ).

    lo_tra->save(
     IMPORTING
      ev_rejected = lv_rejected
      eo_change = lo_chg
      eo_message = lo_message
      et_rejecting_bo_key = lt_rej_bo_key ).


*  ***********************************************************************************************
*  --- Display the new created FWO number Node ---*
*  ***********************************************************************************************

    CLEAR lt_key.

    ls_key-key = ls_mod-key.

    APPEND ls_key TO lt_key.

*   Use method RETRIEVE to retrieve ROOT data
    lo_srv_trq->retrieve(
     EXPORTING
      iv_node_key = /scmtms/if_trq_c=>sc_node-root
      it_key = lt_key
      iv_edit_mode = /bobf/if_conf_c=>sc_edit_read_only
     IMPORTING
      eo_message = lo_message
      et_data = lt_root
      et_failed_key = lt_failed_key ).

    READ TABLE lt_root ASSIGNING <ls_root> INDEX 1.

    WRITE:  'Forwarding Order number: ', <ls_root>-trq_id.

  ENDIF.

************************************************************************************************
*--- Delete FWO number Node ---*
************************************************************************************************

  IF p_delete = 'X'.

    CLEAR lt_key.

    ls_selpar-attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-query_by_attributes-trq_id.
    ls_selpar-option = 'EQ'.
    ls_selpar-sign = 'I'.
    ls_selpar-low = p_trq_id-low.
    APPEND ls_selpar TO lt_selpar.

* use method query of the service manager to start the query
    lo_srv_trq->query(
     EXPORTING
*      iv_query_key = /scmtms/if_trq_c=>sc_query-root-query_by_attributes
      iv_query_key = /scmtms/if_trq_c=>sc_query-root-qdb_query_by_attributes
      it_selection_parameters = lt_selpar
      iv_fill_data = abap_true
     IMPORTING
      eo_message = lo_message
      es_query_info = ls_query_inf
*      et_key = lt_key
      et_data = lt_trq_qdb ).

    READ TABLE lt_trq_qdb ASSIGNING <ls_trq_qdb> INDEX 1.

    CLEAR lt_mod.

    ls_mod-node = /scmtms/if_trq_c=>sc_node-root.
    ls_mod-key = <ls_trq_qdb>-db_key.
    ls_mod-change_mode = /bobf/if_frw_c=>sc_modify_delete.

    APPEND ls_mod TO lt_mod.

    lo_srv_trq->modify(
     EXPORTING
      it_modification = lt_mod
     IMPORTING
      eo_change = lo_chg
      eo_message = lo_message ).

    lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

*   Call the SAVE method of the transaction manager
    lo_tra->save(
     IMPORTING
      ev_rejected = lv_rejected
      eo_change = lo_chg
      eo_message = lo_message
      et_rejecting_bo_key = lt_rej_bo_key ).


    WRITE: 'Forwarding Order ', p_trq_id-low, 'Deleted'.

  ENDIF.