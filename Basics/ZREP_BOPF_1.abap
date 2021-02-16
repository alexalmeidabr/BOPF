*&---------------------------------------------------------------------*
*& Report ZREP_BOPF_1
*&---------------------------------------------------------------------*
*&
*& Basics of BOPF in SAP TM
*&
*&---------------------------------------------------------------------*
REPORT zrep_bopf_1.

FIELD-SYMBOLS: <ls_root> TYPE /scmtms/s_trq_root_k,
               <ls_item> TYPE /scmtms/s_trq_item_k,
               <ls_link> TYPE /bobf/s_frw_key_link,
               <ls_loc>  TYPE /scmtms/s_bo_loc_root_k,
               <ls_txc>  TYPE /bobf/s_txc_con_k,
               <ls_msg>  TYPE /bobf/s_frw_message_k.

DATA: lo_srv_trq           TYPE REF TO /bobf/if_tra_service_manager,
      ls_selpar            TYPE /bobf/s_frw_query_selparam,
      lt_selpar            TYPE /bobf/t_frw_query_selparam,
      lo_message           TYPE REF TO /bobf/if_frw_message,
      ls_query_inf         TYPE /bobf/s_frw_query_info,
      lt_key               TYPE /bobf/t_frw_key,
      lt_root              TYPE /scmtms/t_trq_root_k,
      lt_failed_key        TYPE /bobf/t_frw_key,
      lt_item              TYPE /scmtms/t_trq_item_k,
      lt_link              TYPE /bobf/t_frw_key_link,
      lt_item_key          TYPE /bobf/t_frw_key,
      lt_target_key        TYPE /bobf/t_frw_key,
      lt_loc_root          TYPE /scmtms/t_bo_loc_root_k,
      lv_text_assoc_key    TYPE /bobf/conf_key,
      lt_link_txctext      TYPE /bobf/t_frw_key_link,
      lt_txc_text_key      TYPE /bobf/t_frw_key,
      lv_text_node_key     TYPE /bobf/conf_key,
      lv_content_node_key  TYPE /bobf/conf_key,
      lv_content_assoc_key TYPE /bobf/conf_key,
      lt_txc_content       TYPE /bobf/t_txc_con_k,
      lo_change            TYPE REF TO /bobf/if_tra_change,
      lr_action_param      TYPE REF TO /scmtms/s_trq_a_confirm,
      lt_msg               TYPE /bobf/t_frw_message_k,
      lv_str               TYPE string,
      lo_msg               TYPE REF TO /bobf/cm_frw,
      lo_property          TYPE REF TO /bobf/if_frw_property,
      lt_trq_id            TYPE /scmtms/t_trq_id,
      lt_trq_root_key      TYPE /bobf/t_frw_key,
      lt_node_attribute    TYPE /bobf/t_frw_name,
      lo_tra               TYPE REF TO /bobf/if_tra_transaction_mgr,         "Transactional Manager
      lv_rejected          TYPE abap_bool,
      lt_rejecting_bo_key  TYPE /bobf/t_frw_key2,
      lv_trq_id            TYPE /scmtms/trq_id VALUE '00000000002100000000'. "FWO number

* Get an instance of a service manager for e.g. BO TRQ
lo_srv_trq = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( /scmtms/if_trq_c=>sc_bo_key ).

* Get an instance of a transactional manager
lo_tra = /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ).

*************************************************************************************************
* BOPF Query Example
*************************************************************************************************

* The query has as filter structure /SCMTMS/S_TRQ_Q_ATTRIBUTES
* All fields in this structure can be used in the query
* Here the field TRQ-ID is used
ls_selpar-attribute_name = /scmtms/if_trq_c=>sc_query_attribute-root-query_by_attributes-trq_id.
ls_selpar-option = 'EQ'.
ls_selpar-sign = 'I'.
ls_selpar-low = lv_trq_id.
APPEND ls_selpar TO lt_selpar.

* Use method QUERY of the service manager to start the query
lo_srv_trq->query(
 EXPORTING
 iv_query_key = /scmtms/if_trq_c=>sc_query-root-query_by_attributes
 it_selection_parameters = lt_selpar
 IMPORTING
 eo_message = lo_message
 es_query_info = ls_query_inf
 et_key = lt_key ).

* Use method RETRIEVE to retrieve ROOT data
lo_srv_trq->retrieve(
 EXPORTING
 iv_node_key = /scmtms/if_trq_c=>sc_node-root
 it_key = lt_key
 iv_edit_mode = /bobf/if_conf_c=>sc_edit_read_only
 IMPORTING
 eo_message = lo_message
 et_data = lt_root
 et_failed_key = lt_failed_key ).

*************************************************************************************************
* BOPF Retrieve by Association Example
*************************************************************************************************

* Use method Retrieve by Association to retrieve ITEM node data
lo_srv_trq->retrieve_by_association(
 EXPORTING
 iv_node_key = /scmtms/if_trq_c=>sc_node-root
 it_key = lt_key
 iv_association = /scmtms/if_trq_c=>sc_association-root-item
 iv_fill_data = abap_true
 iv_edit_mode = /bobf/if_conf_c=>sc_edit_read_only
 IMPORTING
 eo_message = lo_message
 et_data = lt_item
 et_key_link = lt_link
 et_target_key = lt_item_key
 et_failed_key = lt_failed_key ).

* Following XBO Association ITEM -> Location
lo_srv_trq->retrieve_by_association(
 EXPORTING
 iv_node_key = /scmtms/if_trq_c=>sc_node-item
 it_key = lt_item_key
 iv_association = /scmtms/if_trq_c=>sc_association-item-srcloc_root
 iv_fill_data = abap_true
 IMPORTING
 eo_message = lo_message
 et_data = lt_loc_root
 et_key_link = lt_link ).

*************************************************************************************************
* BOPF Retrieve by Association (To Dependent Object Nodes)
* Example: Retriving the FWO header text
*************************************************************************************************

* Do RbA to ROOT TEXT Collection TEXT CONTENT node
* Get Text Collection ROOT keys
lo_srv_trq->retrieve_by_association(
 EXPORTING
 iv_node_key = /scmtms/if_trq_c=>sc_node-root
 it_key = lt_key
 iv_association = /scmtms/if_trq_c=>sc_association-root-textcollection
 IMPORTING
 eo_message = lo_message
 et_key_link = lt_link
 et_target_key = lt_target_key ).

* Map TXC Meta model node keys into TRQ runtime node keys
* --> for all subnodes of DO ROOT we have to use this helper
* method to get the correct runtime node keys of the DO nodes
/scmtms/cl_common_helper=>get_do_keys_4_rba(
 EXPORTING
 iv_host_bo_key = /scmtms/if_trq_c=>sc_bo_key
 "Host BO DO Representation node (TRQ, node TEXTCOLLECTION)
 iv_host_do_node_key = /scmtms/if_trq_c=>sc_node-textcollection
"not needed here because source node of association is the DO ROOT
"node for which we can use the TRQ constant
* iv_do_node_key = DO Node
 "DO Meta Model Association Key
 iv_do_assoc_key = /bobf/if_txc_c=>sc_association-root-text
 IMPORTING
 "DO Runtime Model Association Key
 ev_assoc_key = lv_text_assoc_key ).

lo_srv_trq->retrieve_by_association(
 EXPORTING
 iv_node_key = /scmtms/if_trq_c=>sc_node-textcollection
 it_key = lt_target_key
 "DO runtime model association key
 iv_association = lv_text_assoc_key

 IMPORTING
 eo_message = lo_message
 et_key_link = lt_link_txctext
 et_target_key = lt_txc_text_key ).

* Map TXC Meta model node keys into TRQ runtime node keys
/scmtms/cl_common_helper=>get_do_keys_4_rba(
 EXPORTING
 iv_host_bo_key = /scmtms/if_trq_c=>sc_bo_key
 iv_host_do_node_key = /scmtms/if_trq_c=>sc_node-textcollection
 "DO Meta Model Source Node Key
 iv_do_node_key = /bobf/if_txc_c=>sc_node-text
 IMPORTING
 "DO Runtime Model Node Key
 ev_node_key = lv_text_node_key ).

/scmtms/cl_common_helper=>get_do_keys_4_rba(
EXPORTING
iv_host_bo_key = /scmtms/if_trq_c=>sc_bo_key
iv_host_do_node_key = /scmtms/if_trq_c=>sc_node-textcollection
"DO Meta Model Target Node key
iv_do_node_key = /bobf/if_txc_c=>sc_node-text_content
"DO Meta Model Association Key
iv_do_assoc_key = /bobf/if_txc_c=>sc_association-text-text_content
IMPORTING
"DO Runtime Model Node Key
ev_node_key = lv_content_node_key

"DO Runtime Model Association Key
ev_assoc_key = lv_content_assoc_key ).

lo_srv_trq->retrieve_by_association(
 EXPORTING
 "DO runtime model source node key
 iv_node_key = lv_text_node_key
 it_key = lt_txc_text_key
 "DO runtime model association key
 iv_association = lv_content_assoc_key
 iv_fill_data = abap_true
 IMPORTING
 eo_message = lo_message
 et_data = lt_txc_content ).

*************************************************************************************************
* BOPF Calling action CONFIRM of the TRQ Root node
* Example: Confirm a FWO
*************************************************************************************************

* fill the action parameters
CREATE DATA lr_action_param.
* Carry out check
lr_action_param->no_check = abap_true.
lr_action_param->automatic = abap_true.


lo_srv_trq->do_action(
 EXPORTING
 iv_act_key = /scmtms/if_trq_c=>sc_action-root-confirm
 it_key = lt_key
 is_parameters = lr_action_param
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

*************************************************************************************************
* BOPF Retrive property but not sure how to read the result! :(
*************************************************************************************************

CALL METHOD lo_srv_trq->retrieve_property
  EXPORTING
    iv_node_key                = /scmtms/if_trq_c=>sc_node-root
    it_key                     = lt_key "lt_trq_root_key
    iv_node_attribute_property = abap_true
    it_node_attribute          = lt_node_attribute
  IMPORTING
    eo_property                = lo_property
    eo_message                 = lo_message.
BREAK-POINT.