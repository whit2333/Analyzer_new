* PROGRAM Engine
*--------------------------------------------------------
*-       Prototype C analysis routine
*-
*- This is the analysis shell for CEBAF hall C.
*  It gets all of its instructions via the CTP package
*- Loops through data until it encounters an error.
*-
*-   Created  18-Nov-1993   Kevin B. Beard, Hampton Univ.
* $Log: tengine.f,v $
* Revision 1.1  1998/12/01 20:55:32  saw
* Initial revision
*
* Revision 1.23  1996/11/08 15:40:09  saw
* (JRA) Add analysis of epics events.
*
* Revision 1.22  1996/09/04 15:33:43  saw
* (JRA) Assorted changes and diagnostics
*
* Revision 1.21  1996/04/29 19:19:04  saw
* (JRA) Corrections
*
* Revision 1.20  1996/01/24 16:11:10  saw
* (JRA) Change evtype to registered gen_event_type.  Refresh statistics
*       file at a time interval rather than event interval
*
* Revision 1.19  1996/01/16 21:12:41  cdaq
* (JRA) Add tcl run statistics display
*
* Revision 1.18  1995/10/09 19:59:00  cdaq
* (JRA) Improve event counting for periodic dumping.  Dump pedestal data
* at end of run.
*
* Revision 1.17  1995/09/22 19:39:13  cdaq
* (SAW) Move g_ctp_database from g_init_filenames to here.  Process all
* CTP command line vars after every ctp file read so that command line
* overrides everything.
*
* Revision 1.16  1995/07/27 19:45:40  cdaq
* (SAW) f2c compatibility changes.  Only shutdown ntuples at very end.
*       ctp command line variables override at every oportunity
*-
* Revision 1.15  1995/05/11  19:02:23  cdaq
* (SAW) Add ability to set CTP variables from the command line
*
* Revision 1.14  1995/04/01  20:12:58  cdaq
* (SAW) Call g_proper_shutdown instead of dump_hists for periodic hist dumps
*
* Revision 1.13  1995/03/13  18:11:05  cdaq
* (JRA) Write scaler report when histograms are dumped at intervals
*
* Revision 1.12  1995/01/31  21:12:17  cdaq
* (SAW) Add gen_run_hist_dump_interval for in run hist dumping.  Add commented
*           out code to query user for # of event and hist dump interval.
*
* Revision 1.11  1994/11/22  20:12:01  cdaq
* (SAW) Change "" to " " so this would compile under ultrix.
*
* Revision 1.10  1994/10/19  20:40:29  cdaq
* (SAW) Add handling of RPC requests
*
* Revision 1.9  1994/07/07  15:28:29  cdaq
* (SAW) Move check for scaler event to proper place
*
* Revision 1.8  1994/06/26  02:07:03  cdaq
* (KBB) Add ability to analyze selected subset of events.  Add evcount stats.
* (SAW) Add call to scaler analysis
*
* Revision 1.7  1994/06/17  03:35:00  cdaq
* (KBB) Upgrade error reporting
*
* Revision 1.6  1994/06/15  14:27:30  cdaq
* (SAW) Actually add call to g_examine_physics_event
*
* Revision 1.5  1994/06/07  18:22:58  cdaq
* (SAW) Add calls to g_examine_physics_event and g_examine_control_event
*
* Revision 1.4  1994/04/15  20:31:25  cdaq
* (SAW) Changes for ONLINE use
*
* Revision 1.3  1994/03/24  22:02:12  cdaq
* Reorganize for online compatibility
*
* Revision 1.2  1994/02/11  18:32:06  cdaq
* Split off CTP variables registration from initialize routines
*
* Revision 1.1  1994/02/04  21:04:59  cdaq
* Initial revision
*
*- 
*--------------------------------------------------------
      IMPLICIT NONE
      SAVE
*
      character*6 here
      parameter (here= 'Engine')
*
      logical ABORT,EoF
      character*800 err,mss
*
      include 'gen_filenames.cmn'
      include 'gen_craw.cmn'
      include 'gen_run_info.cmn'
      include 'gen_event_info.cmn'
      include 'gen_run_pref.cmn'
      include 'gen_routines.dec'
      include 'gen_scalers.cmn'
      include 'gen_data_structures.cmn'
      include 'hms_data_structures.cmn'
      include 't20_data_structures.cmn'
*
      logical problems, finished_extracting
      integer total_event_count
      integer physics_events
      integer analyzed_events(0:gen_max_trigger_types)
      integer sum_analyzed
      integer recorded_events(0:gen_max_trigger_types)
      integer sum_recorded
      integer num_events_skipped
      integer i,since_cnt,lastdump
      integer rpc_pend                  ! # Pending asynchronous RPC requests
*
      character*80 g_config_environmental_var
      parameter (g_config_environmental_var= 'ENGINE_CONFIG_FILE')
*
      integer*4 jishft,jiand
*
      integer ierr
      integer*4 status
      integer*4 evclose
      character*132 file
      character*20 groupname
      character*132 system_string
*
*      real*4 ebeam,phms,thms,psos,tsos,ntarg
      real*4 ebeam,phms,thms,pt20,tt20,ntarg
*
      integer start_time,lasttime
      integer time
      integer*4 preprocessor_keep_event
      external time
*
*
*--------------------------------------------------------
*
      print *
      print *,'  Hall C Proudly Presents: PHYSICS Analysis Engine - Spring 1996'
*
      print *
*
      total_event_count= 0                      ! Need to register this
      lastdump=0
      do i=0,gen_max_trigger_types
        analyzed_events(i)=0
        recorded_events(i)=0
      enddo
      sum_analyzed=0
      sum_recorded=0
      num_events_skipped=0
*
      rpc_on=0                          ! RPC servicing off by default
      rpc_control=-1                    ! If RPC on, don't block by default
*
      call g_register_variables(ABORT,err)
      if(ABORT.or.err.ne.' ') then
         call G_add_path(here,err)
         call G_rep_err(ABORT,err)
         If(ABORT) STOP
         err= ' '
      ENDIF
*
      g_config_filename = ' '
*
      call engine_command_line(.false.) ! Set CTP vars from command line
*       
      call G_init_filenames(ABORT,err,g_config_environmental_var)
      if(ABORT.or.err.ne.' ') then
         call G_add_path(here,err)
         call G_rep_err(ABORT,err)
         If(ABORT) STOP
         err= ' '
      ENDIF
*
      call engine_command_line(.false.) ! Set CTP vars from command line
*
* If there is a g_ctp_database_filename set, pass the run number
* to it to set CTP variables
*
      if(.not.ABORT.and.g_ctp_database_filename.ne.' ') then
        call g_ctp_database(ABORT, err
     $       ,gen_run_number, g_ctp_database_filename)
        IF(ABORT) THEN
          call G_add_path(here,err)
        endif
      ENDIF
*       
      call engine_command_line(.false.) ! Set CTP vars from command line
*
      call G_decode_init(ABORT,err)
      if(ABORT.or.err.ne.' ') then
         call G_add_path(here,err)
         call G_rep_err(ABORT,err)
         If(ABORT) STOP
         err= ' '
      endif
*


      g_data_source_opened = .false.     !not opened yet
      g_data_source_in_hndl= 0           !none
      call G_open_source(ABORT,err)
      if(ABORT.or.err.ne.' ') then
         call G_add_path(here,err)
         call G_rep_err(ABORT,err)
         If(ABORT) STOP
         err= ' '
      endif
*
* if preprocessor on, open event file
*
      if(g_preproc_on.ne.0)then
        g_preproc_opened=.false. !not opened yet
        g_preproc_in_hndl=0      !none IO opened
        call g_preproc_open(ABORT,err)
        if (ABORT.or.err.ne.' ')then
          call G_add_path(here,err)
          call G_rep_err(ABORT,err)
          if (ABORT) STOP
          err=' '
        endif
        write(6,*)'Opened CODA event file for preprocessor output'
      endif

      finished_extracting = .false.
      finished_extracting = .true.      ! For t20 EEL detector tests
c The above line causes the following DO WHILE loop to be skipped for now.      
      DO WHILE(.NOT.problems .and. .NOT.ABORT .and. .NOT.EoF .and.
     &         .NOT.finished_extracting)
        mss= ' '
        g_replay_time=time()-start_time
*
        call G_clear_event(ABORT,err)   !clear out old data
        problems= problems .OR. ABORT
*
        if(mss.NE.' ' .and. err.NE.' ') then
          call G_append(mss,' & '//err)
        elseif(err.NE.' ') then
          mss= err
        endif
*
        If(.NOT.problems) Then
          call G_get_next_event(ABORT,err) !get and store 1 event 
          problems= problems .OR. ABORT 
          if(.NOT.ABORT) total_event_count= total_event_count+1
*     
        EndIf
*
        if(mss.NE.' ' .and. err.NE.' ') then
          call G_append(mss,' & '//err)
        elseif(err.NE.' ') then
          mss= err
        endif
*
* Check if this is a physics event or a CODA control event.
*
        if(.not.problems) then
          gen_event_type = jishft(craw(2),-16)
          if(gen_event_type.eq.1) gen_event_type = 2            ! T20 temporary hack for EEL runs
          if(gen_event_type.le.gen_MAX_trigger_types) then
            recorded_events(gen_event_type)=recorded_events(gen_event_type)+1
            sum_recorded=sum_recorded+1
            print *,gen_event_type
            write(6,*) "AAAAAAAAAAHHHHHHHHHHHHHHHHHHHHHHHHHHH!!!!!!!!!!"
            write(6,*) "Whew, I feel much bettter now"
            write(6,*) "However, you might want to know that I've hit a physics event"
            write(6,*) "In my run info event loop and THAT SHOULD NEVER HAPPEN!!!"
            write(6,*) "KILL ME!!! KILL ME NOW!!!!!"
          endif
*
* if preprocessor is on write all events of trig type > 16
*   (i.e. all non-physics events)
*
          if(gen_event_type.ge.(gen_max_trigger_types-1) .and.
     $         g_preproc_on.ne.0) then
            call g_write_event(ABORT,err)
          endif

          if (gen_event_type.eq.130) then !run info event (get e,p,theta)
            finished_extracting=.true.
            write(6,'(a)') 'COMMENTS FROM RUN INFO EVENT'
            call g_extract_kinematics(ebeam,phms,thms,pt20,tt20,ntarg)
            write(6,'(a)') 'KINEMATICS FROM RUN INFO EVENT'
c  beam energy no longer in runinfo event.
c            if (ebeam.gt.10.) ebeam=ebeam/1000. !usually in MeV
c            write(6,*) '   gpbeam     =',abs(ebeam),' GeV'
c            gpbeam=abs(ebeam)
            write(6,*) '   hpcentral  =',abs(phms),' GeV/c'
            hpcentral=abs(phms)
            write(6,*) '   htheta_lab =',abs(thms),' deg.'
            htheta_lab=abs(thms)
            write(6,*) '   tpcentral  =',abs(pt20),' GeV/c'
            tpcentral=abs(pt20)
            write(6,*) '   ttheta_lab =',abs(tt20),' deg.'
            ttheta_lab=abs(tt20)
            write(6,*) '   gtarg_num  =',abs(ntarg)
            gtarg_num=ntarg
          endif

          if (gen_event_type.eq.131.or.gen_event_type.eq.133) then !past run info event. must be missing
            write(6,*) "no run information event found"
            finished_extracting=.true.
          endif

        endif                           !if .not.problems
      enddo                             !do while .not.finished_extracting

      call G_initialize(ABORT,err)              !includes a total reset
      IF(ABORT.or.err.NE.' ') THEN
         call G_add_path(here,err)
         call G_rep_err(ABORT,err)
         If(ABORT) STOP
         err= ' '
      ENDIF
*
*-attempt to open FASTBUS-CODA file
*
c      g_data_source_opened = .false.     !not opened yet
c      g_data_source_in_hndl= 0           !none
c      call G_open_source(ABORT,err)
c      if(ABORT.or.err.ne.' ') then
c         call G_add_path(here,err)
c         call G_rep_err(ABORT,err)
c         If(ABORT) STOP
c         err= ' '
c      endif
*
      call engine_command_line(.false.) ! Set CTP vars from command line
*
* Print out the statistics report once...
      if(g_stats_blockname.ne.' '.and.
     $     g_stats_output_filename.ne.' ') then
         file = g_stats_output_filename
         call g_sub_run_number(file, gen_run_number)
         ierr = threp(g_stats_blockname,file)
      endif
*
* Comment out the following three lines if they cause trouble or
* if wish is unavailable.
*
      write(system_string,*) 'runstats ',file(1:index(file,' ')-1), ' ',
     $     gen_run_number, '> /dev/null 2>&1 &'
      call system(system_string)
*
*-zero entire event buffer
*
      DO i=1,LENGTH_CRAW
         CRAW(i)= 0
      ENDDO
*
      since_cnt= 0
      problems= .false.
      EoF = .false.
*
      if(rpc_on.ne.0) then
        print *,"*****************************************************"
        print *," "
        print *,"ENGINE is enabled to receive RPC requests"
        if(rpc_control.eq.0) then
          print *," "
          print *,"ENGINE will HANG waiting for RPC requests"
                else if(rpc_control.gt.0) then
          print *,"ENGINE will HANG to waitfor RPC requests after "
     $         ,rpc_control," events"
        endif
        if(rpc_control.ge.0) then
          print *,"If you don't want this to happen, put one of the"
          print *,"following in your CTP setup file"
          print *,"    rpc_on = 0 ; Turns off RPC handling"
          print *,"    rpc_control = -1 ; No Hanging, but RPC handled"
        endif
        print *," "
        print *,"*****************************************************"

        call thservset(0,0)             !prepare for RPC requests

      endif
      rpc_pend = 0
*
      start_time=time()
      lasttime=0.
*
      DO WHILE(.NOT.problems .and. .NOT.ABORT .and. .NOT.EoF)
        mss= ' '
        g_replay_time=time()-start_time
*
        call G_clear_event(ABORT,err)   !clear out old data
        problems= problems .OR. ABORT
*
        if(mss.NE.' ' .and. err.NE.' ') then
          call G_append(mss,' & '//err)
        elseif(err.NE.' ') then
          mss= err
        endif
*
        If(.NOT.problems) Then
          call G_get_next_event(ABORT,err) !get and store 1 event
          problems= problems .OR. ABORT
          if(.NOT.ABORT) total_event_count= total_event_count+1
*
        EndIf
*
        if(mss.NE.' ' .and. err.NE.' ') then
          call G_append(mss,' & '//err)
        elseif(err.NE.' ') then
          mss= err
        endif
*
* Check if this is a physics event or a CODA control event.
*
        if(.not.problems) then
          gen_event_type = jishft(craw(2),-16)
          if(gen_event_type.eq.1) gen_event_type = 2            ! T20 temporary hack for EEL runs
          if(gen_event_type.le.gen_MAX_trigger_types) then
            recorded_events(gen_event_type)=recorded_events(gen_event_type)+1
            sum_recorded=sum_recorded+1
          endif
*
*if preprocessor is on write all events of trig type > 16
*  (i.e. all non-physics events)
*
          if(gen_event_type.ge.(gen_max_trigger_types-1) .and.
     &         g_preproc_on.ne.0)then
            call g_write_event(ABORT,err)
          endif

          if (gen_event_type.eq.130) then       !run info event (get e,p,theta)
c            call g_extract_kinematics(ebeam,phms,thms,psos,tsos)
c            if (gpbeam .ge. 7. .and. ebeam.le.7.) then !sometimes ebeam in MeV
c              gpbeam=abs(ebeam)
c              write(6,*) 'gpbeam=',abs(ebeam),' GeV'
c            endif
c            if (hpcentral .ge. 7.) then
c              write(6,*) 'hpcentral=',abs(phms),' GeV/c'
c              hpcentral=abs(phms)
c            endif
c            if (htheta_lab .le. 0.) then
c              write(6,*) 'htheta_lab=',abs(thms),' deg.'
c              htheta_lab=abs(thms)*3.14159265/180.
c            endif
c            if (spcentral .ge. 7.) then
c              write(6,*) 'spcentral=',abs(psos),' GeV/c'
c              spcentral=abs(psos)
c            endif
c            if (stheta_lab .le. 0.) then
c              write(6,*) 'stheta_lab=',abs(tsos),' deg.'
c              stheta_lab=abs(tsos)*3.14159265/180.
c            endif
          endif


          if(jiand(CRAW(2),'FFFF'x).eq.'10CC'x) then ! Physics event
*
            if(gen_event_type.le.gen_MAX_trigger_types .and.
     $           gen_run_enable(gen_event_type-1).ne.0) then
                  
              call g_examine_physics_event(CRAW,ABORT,err)
              if(gen_event_type.eq.1) gen_event_type = 2 ! T20 temporary hack for EEL runs
              problems = problems .or.ABORT
*
              if(mss.NE.' ' .and. err.NE.' ') then
                call G_append(mss,' & '//err)
              elseif(err.NE.' ') then
                mss= err
              endif
*
*
              IF(num_events_skipped.lt.gen_run_starting_event .and.
     $             gen_event_type.ne.4) THEN ! always analyze peds.
                num_events_skipped = num_events_skipped + 1
              ELSE
                if(gen_run_starting_event.eq.gen_event_id_number)
     &               start_time=time()  !reset start time for analysis rate
                if(.NOT.problems) then
                  call G_reconstruction(CRAW,ABORT,err) !COMMONs
                  physics_events = physics_events + 1
                  analyzed_events(gen_event_type)=analyzed_events(gen_event_type)+1
                  sum_analyzed=sum_analyzed+1
                  problems= problems .OR. ABORT
                endif
*
                if(mss.NE.' ' .and. err.NE.' ') then
                  call G_append(mss,' & '//err)
                elseif(err.NE.' ') then
                  mss= err
                endif
*
                groupname=' '
                if (gen_event_type.eq.1) then
                  groupname='hms'
                else if (gen_event_type.eq.2) then
                  groupname='t20'
                else if (gen_event_type.eq.3) then
                  groupname='both'
                else if (gen_event_type.eq.4) then
                  start_time=time()     !reset start time for analysis rate
                  groupname='ped'
                else
                  write(6,*) 'gen_event_type= ',gen_event_type,' for call to g_keep_results'
                endif
*
                If(.NOT.problems .and. groupname.ne.' ') Then
                  call G_keep_results(groupname,ABORT,err) !file away results as
                  problems= problems .OR. ABORT !specified by interface
                EndIf
*
                if(mss.NE.' ' .and. err.NE.' ') then
                  call G_append(mss,' & '//err)
                elseif(err.NE.' ') then
                  mss= err
                endif

*
* if preprocessor is on check event for write criteria
*
                if(g_preproc_on.ne.0)then
                  if(.NOT.problems)then
                    call g_preproc_event(preprocessor_keep_event)
                    if(preprocessor_keep_event.eq.1)then
                      call g_write_event(ABORT,err)
                    endif
                  endif
                endif

*
*- Here is where we insert a check for an Remote Proceedure Call (RPC)
*- from another process for CTP to interpret
*
                if(rpc_on.ne.0) then
                  if(rpc_pend.eq.0.and.rpc_control.eq.0) then
                    do while(rpc_pend.eq.0.and.rpc_control.eq.0)
                      ierr = thservone(-1) !block until one RPC request serviced
                      rpc_pend = thcallback()
                    enddo
                  else
                    ierr = thservone(0)   !service one RPC requests
                    rpc_pend = thcallback()
                  endif
                  if(rpc_pend.lt.0) rpc_pend = 0 ! Last thcallback took care of all
                                        ! outstanding requests
                  if(rpc_control.gt.0) rpc_control = rpc_control - 1
                endif

              endif
            else if (gen_event_type.eq.131) then ! EPICS event
              call g_examine_epics_event
            endif

          Else
            if(gen_event_type.eq.129) then
              call g_analyze_scalers(CRAW,ABORT,err)
* Dump report at first scaler event AFTER hist_dump_interval to keep hardware
* and software scalers in sync.
              if((physics_events-lastdump).ge.gen_run_hist_dump_interval.and.
     &            gen_run_hist_dump_interval.gt.0) then
                lastdump=physics_events   ! Wait for next interval of dump_int.
                call g_proper_shutdown(ABORT,err)
                print 112,"Finished dumping histograms/scalers for first"
     &               ,physics_events," events"
 112            format (a,i8,a)
              endif
            else if (gen_event_type.eq.133) then  !SAW's new go_info events
              call g_examine_go_info(CRAW,ABORT,err)
            else
              call g_examine_control_event(CRAW,ABORT,err)
            endif
            mss = err
          EndIf
        endif
*
*Now write the statistics report every 2 sec...
*
         if (g_replay_time-lasttime.ge.2) then  !dump every 2 seconds
           lasttime=g_replay_time
           if(g_stats_blockname.ne.' '.and.
     $          g_stats_output_filename.ne.' ') then
              file = g_stats_output_filename
              call g_sub_run_number(file, gen_run_number)
              ierr = threp(g_stats_blockname,file)
           endif
        endif
*
        since_cnt= since_cnt+1
        if(since_cnt.GE.5000) then
          print *,' event#',total_event_count
          since_cnt= 0
        endif
*
        If(ABORT .or. mss.NE.' ') Then
          call G_add_path(here,mss)     !only if problems
          call G_rep_err(ABORT,mss)
        EndIf
*
        EoF= gen_event_type.EQ.20
*
        If(gen_run_stopping_event.GT.0 .and.
     &       gen_event_ID_number.GT.0) Then
          EoF= EoF .or. gen_run_stopping_event.LE.sum_analyzed-
     $         analyzed_events(4)
        EndIf
*
*- Here is where we insert a check for an Remote Proceedure Call (RPC)
*- from another process for CTP to interpret
*
      ENDDO                             !found a problem or end of run
*
      print *,'    -------------------------------------'
*
      IF(ABORT .or. mss.NE.' ') THEN
        call G_rep_err(ABORT,mss)       !report any errors or warnings
        err= ' '
      ENDIF
*
      if(rpc_on.ne.0) call thservunset(0,0)
*
      print *,'    -------------------------------------'
*
* Print out the statistics report one last time...
      if(g_stats_blockname.ne.' '.and.
     $     g_stats_output_filename.ne.' ') then
         file = g_stats_output_filename
         call g_sub_run_number(file, gen_run_number)
         ierr = threp(g_stats_blockname,file)
      endif
*
      call G_proper_shutdown(ABORT,err) !save files, etc.
      If(ABORT .or. err.NE.' ') Then
        call G_add_path(here,err)       !report any errors or warnings
        call G_rep_err(ABORT,err)
        err= ' '
      EndIf
*
      call g_ntuple_shutdown(ABORT,err)
      If(ABORT .or. err.NE.' ') Then
        call G_add_path(here,err)       !report any errors or warnings
        call G_rep_err(ABORT,err)
        err= ' '
      EndIf
*
* close charge scalers output file.
      if (g_charge_scaler_filename.ne.' ') close(unit=G_LUN_CHARGE_SCALER)
*
* close epics output file.
      if (g_epics_output_filename.ne.' ') close(unit=G_LUN_EPICS_OUTPUT)
*
      if (g_preproc_opened) then
        status= evclose(g_preproc_in_hndl)
        if (status.ne.0) write(6,*) 'status for evclose=',status
      endif
*
      call g_dump_peds
      call h_dump_peds
      call t_dump_peds
*
      print *,'Processed:'
      DO i=0,gen_MAX_trigger_types
        If(recorded_events(i).GT.0) Then
          write(mss,'(4x,i12," / ",i8," events of type",i3)')
     &             analyzed_events(i),recorded_events(i),i
          call G_log_message(mss)
        EndIf
      ENDDO
      write(mss,'(i12," / ",i8," total")') sum_analyzed,sum_recorded
      call G_log_message(mss)
      print *,'  for run#',gen_run_number
*
* Comment out the following two lines if they cause trouble
      call system
     &  ("kill `ps | grep runstats | awk '{ print $1}'` > /dev/null 2>&1")
*
      END

      subroutine engine_command_line(outputflag)
*
      implicit none
      integer iarg
      character*132 arg
      integer iargc
      external iargc
      logical outputflag
*
* Process command line args that set CTP variables
*
      do iarg=1,iargc()
        call getarg(iarg,arg)
        if(index(arg,'=').gt.0) then
          call thpset(arg)
          if (outputflag) write(6,'(4x,a70)') arg(1:70)
        endif
      enddo
*
      return
      end

      subroutine force
c
c     Force the linker to pull the following routines out of the first
c     library (libt20) on the link line.
c
      call g_decode_fb_bank
      return
      end
