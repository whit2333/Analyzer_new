      subroutine g_register_variables(ABORT,err)
*----------------------------------------------------------------------
*
*     CTP variable registration routine
*
*     Purpose : Register all variables that are to be used by CTP.  This
*     includes externally configured parameters/contants, event data that
*     can be a histogram source, and possible test results and scalers.
*
*     Method: 1. Register variables needed to use CTP to get various
*     filenames.  And register other common variables.
*             2. Call Register routines for HMS, Polder and coincidence.
*
*     Output: ABORT      - success or failure
*           : err        - reason for failure, if any
*
*     Created: 9-Feb-1994  Stephen A. Wood
*     Modified: 17-May-1994 Kevin B. Beard, Hampton U.
*     Modified: 24-May-1994 K.B.Beard
*
* $Log: g_register_variables.f,v $
* Revision 1.2  1997/05/23 19:48:43  saw
* (t20) Call r_gen_misc
*
* Revision 1.1  1997/05/23 19:47:04  saw
* Initial revision
*
*----------------------------------------------------------------------
      implicit none
      save
*
      character*20 here
      parameter (here='g_register_variables')
*
      logical ABORT
      character*(*) err
*
      include 'gen_routines.dec'
*
      include 'gen_run_info.cmn'
      include 'gen_run_pref.cmn'

      integer ierr,m,i
      logical FAIL
      character*1000 why
      character*30 msg
*
      include 'gen_run_info.dte'
      include 'gen_run_pref.dte'
*
*----------------------------------------------------------------------
*
*     Register the variables that contain the filenames and other
*     configuration variables.
*
      ABORT= .FALSE.
      err = ' '
*
      call r_gen_filenames

      call r_gen_run_info

      call r_gen_event_info

      call r_gen_scalers

      call r_gen_run_pref

      call r_gen_data_structures        ! Contains both HMS and Polder stuff

      call r_gen_misc      !(3/21/97) the t20 hms/polder coin timing/scaler cmn

*HDISPLAY      call r_one_ev_io
*
*     Need to change in parm files
*     hist_filename -> g_ctp_hist_filename
*     g_hist_rebook -> hist_rebook
*     parm_filename -> g_ctp_parm_filename
*     parm_rebook -> g_parm_rebook
*     test_filename -> g_ctp_test_filename
*     test_rebook -> g_test_rebook
*     report_rebook -> g_report_rebook
*     data_source_filename -> g_data_source_filename
*     alias_filename -> g_alias_filename
*     histout_filename -> g_histout_filename
*     decode_map_filename -> g_decode_map_filename
*     g_report_template_filename -> g_report_template_filename
*     g_report_output_filename -> g_report_output_filename
*     g_report_blockname -> g_report_blockname
*     max_events -> g_max_events
*     RUN_number -> gen_run_number
*     RUN_type -> gen_run_type
*     RUN_total_events -> gen_run_total_events
*     RUN_comment -> gen_run_comment
*     RUN_start_date -> gen_run_date_start
*     RUN_stop_date -> gen_run_date_stop
*     RUN_last_date -> gen_run_date_last
*     RUN_start_event -> gen_run_starting_event
*     RUN_stop_event -> gen_run_stopping_event
*     EVENT_id -> gen_event_ID_number
*     EVENT_type -> gen_event_type
*     EVENT_class -> gen_event_class
*     EVENT_sequenceN -> gen_event_sequence_N
*     SHOW_progress -> gen_show_progress
*     SHOW_interval -> gen_show_interval
*     PREF_muddleON -> gen_pref_muddleON

*
* Leave in these aliases
*
      Do m=0,gen_MAX_trigger_types
        write(msg,'("enable_EvType",i4)') m
        call squeeze(msg,i)
        ierr= regparmint(msg(1:i),gen_run_enable(m),0)
        if(ierr.ne.0) call G_append(err,',"'//msg(1:i)//'"')
        ABORT= ierr.ne.0 .or. ABORT
      EndDo
*
      Do m=0,gen_MAX_trigger_types
        write(msg,'("triggered_EvType",i4)') m
        call squeeze(msg,i)
        ierr= regparmint(msg(1:i),gen_run_triggered(m),0)
        if(ierr.ne.0) call G_append(err,',"'//msg(1:i)//'"')
        ABORT= ierr.ne.0 .or. ABORT
      EndDo
*
*
      call h_register_variables(FAIL,why) ! HMS
      IF(err.NE.' ' .and. why.NE.' ') THEN
         call G_append(err,' & '//why)
      ELSEIF(why.NE.' ') THEN
         err= why
      ENDIF
      ABORT= ABORT .or. FAIL 
*     
      call t_register_variables(FAIL,why) ! Polder
      IF(err.NE.' ' .and. why.NE.' ') THEN
         call G_append(err,' & '//why)
      ELSEIF(why.NE.' ') THEN
         err= why
      ENDIF
      ABORT= ABORT .or. FAIL 
*
      call c_register_variables(FAIL,why)
      IF(err.NE.' ' .and. why.NE.' ') THEN
         call G_append(err,' & '//why)
      ELSEIF(why.NE.' ') THEN
         err= why
      ENDIF
      ABORT= ABORT .or. FAIL 
*
      call hack_register_variables(FAIL,why)
      IF(err.NE.' ' .and. why.NE.' ') THEN
         call G_append(err,' & '//why)
      ELSEIF(why.NE.' ') THEN
         err= why
      ENDIF
      ABORT= ABORT .or. FAIL 

      if(ABORT .or. err.NE.' ') call g_add_path(here,err)
*
      return
      end
