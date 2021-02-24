METHOD calculate_charges.

    DATA: lo_request          TYPE REF TO /sctm/cl_request,
          lo_tor_save_request TYPE REF TO /scmtms/cl_chaco_request,
          lt_failed_key       TYPE /bobf/t_frw_key,
          lo_message          TYPE REF TO /bobf/if_frw_message.

    LOOP AT it_request INTO lo_request.

      lo_tor_save_request = /scmtms/cl_tor_helper_chaco=>cast_request( lo_request ).
      CHECK lo_tor_save_request IS BOUND.

*********************************************************************
*    calc. the charges for the uncancelled and unfinalized instances
*********************************************************************

      CALL METHOD lo_tor_save_request->mo_tor_srvmgr->do_action(
        EXPORTING
          iv_act_key    = /scmtms/if_tor_c=>sc_action-root-calc_transportation_charges
          it_key        = lo_tor_save_request->mt_tor_key_active
        IMPORTING
          eo_message    = lo_message
          et_failed_key = lt_failed_key ).

      APPEND LINES OF lt_failed_key TO lo_tor_save_request->mt_failed_key.

*     add messages to change controller request
      /scmtms/cl_common_helper=>msg_helper_add_mo(
         EXPORTING
           io_new_message = lo_message
         CHANGING
           co_message = lo_tor_save_request->mo_message ).
    ENDLOOP.


  ENDMETHOD.