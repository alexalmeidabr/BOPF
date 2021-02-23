*&---------------------------------------------------------------------*
*& Report ZREP_DATA_CRAWLER
*&---------------------------------------------------------------------*
*&
*& Create a Data Crawler Profile /SCMTMS/TRQ -> ROOT
*& Path Step:                    /SCMTMS/TRQ -> ITEM_MAIN
*&
*&---------------------------------------------------------------------*
REPORT zrep_data_crawler.

DATA: ls_dc_prof_id  TYPE /scmtms/dc_profile_id,
      lt_dc_prof_id  TYPE /scmtms/t_dc_profile_id,
      ls_bo_inst_key TYPE /bobf/s_frw_key,
      lt_bo_inst_key TYPE /bobf/t_frw_key,
      lo_crawler     TYPE REF TO /scmtms/cl_data_crawler,
      lt_dc_data     TYPE /scmtms/cl_data_crawler=>tt_data,
      lo_message     TYPE REF TO /bobf/if_frw_message.

CLEAR: ls_dc_prof_id,
 lt_dc_prof_id.

* Secify the Data Crawler Profile to be used
ls_dc_prof_id = 'ZENH_TRA_ITEM'.
APPEND ls_dc_prof_id TO lt_dc_prof_id.

* Specify the key of an example BO instance (here: a TRQ instance)
ls_bo_inst_key-key = '000C29D50C981EDA97AB8E8EDCF981CF'.
APPEND ls_bo_inst_key TO lt_bo_inst_key.

* Create an instance of the Data Crawler class
CREATE OBJECT lo_crawler
  EXPORTING
    it_profile_id = lt_dc_prof_id.

* Call the Data Crawler with the given profile and BO instance
CALL METHOD lo_crawler->get_data
  EXPORTING
    it_profile_id = lt_dc_prof_id
    it_key        = lt_bo_inst_key
  IMPORTING
    et_data       = lt_dc_data
    eo_message    = lo_message.
* The resulting data can be found in LT_DC_DATA
BREAK-POINT.