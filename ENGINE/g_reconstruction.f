      SUBROUTINE G_reconstruction(event,ABORT,err)
*----------------------------------------------------------------------
*-       Prototype hall C reconstruction routine
*- 
*-   Purpose and Methods : Given previously filled data structures,
*-                         reconstruction is performed and status returned
*- 
*-   Inputs:
*-       event      Pointer to the first word (length) of an event data bank.
*-
*-   Output: ABORT	- success or failure
*-         : err	- reason for failure, if any
*- 
*-   Created  20-Oct-1993   Kevin B. Beard
*-   Modified 20-Nov-1993   KBB for new error routines
* $Log: g_reconstruction.f,v $
* Revision 1.13.24.9.2.7  2011/05/31 15:34:47  jones
* increment g_hel_pos and g_hel_neg for trigtype=1,2,3 or 4 .
* Before incremented just for trigtype=4
*
* Revision 1.13.24.9.2.6  2009/09/29 13:59:53  jones
* Add lines:
*             if(gen_event_trigtype(4).eq.1)then
*               if(gbeam_helicity_TS.eq.1)g_hel_pos = g_hel_pos+1
*               if(gbeam_helicity_TS.eq.-1)g_hel_neg = g_hel_neg+1
*             endif
* This is the number of T4 helicity plus and minus triggers
* Used to calculate the computer lifetime
*
* Revision 1.13.24.9.2.5  2009/09/15 20:39:59  jones
* Call gep_hysics for event_type = 1 and 6 instead of just 6
*
* Revision 1.13.24.9.2.4  2009/09/02 13:39:35  jones
* eliminate commented write statements
*
* Revision 1.13.24.9.2.3  2009/02/17 21:18:32  cdaq
* Changed so b_reconstruction always called
*
* Revision 1.13.24.9.2.2  2008/10/26 19:12:33  cdaq
* SEM
*
* Revision 1.13.24.9.2.1  2008/10/02 17:58:46  cdaq
* *** empty log message ***
*
* Revision 1.13.24.9  2008/01/08 22:43:13  cdaq
* *** empty log message ***
*
* Revision 1.13.24.8  2007/10/19 14:54:58  cdaq
* *** empty log message ***
*
* Revision 1.13.24.7  2007/10/19 14:49:41  cdaq
* *** empty log message ***
*
* Revision 1.13.24.6  2007/10/17 16:08:08  cdaq
* Changed if-block for beamline analysis. Now call for any event type 1-8 if flag is set
*
* Revision 1.13.24.5  2007/10/10 16:24:31  puckett
* *** empty log message ***
*
* Revision 1.13.24.4  2007/10/08 19:22:59  puckett
* Added bad channel list handling for BigCal
*
* Revision 1.13.24.3  2007/09/07 16:08:05  puckett
* put event type 3 option back in for call to h_reconstruction, just in case somebody wants to use it. Also added event type 7 and 8 for calls to b_reconstruction, for the case of the cosmic/light box trigger for bigcal
*
* Revision 1.13.24.2  2007/06/04 14:56:06  puckett
* changed hit array structure for trigger related signals
*
* Revision 1.13.24.1  2007/05/15 02:55:01  jones
* Start to Bigcal code
*
* Revision 1.13  1996/01/22 15:23:34  saw
* (SAW) Add calls to analyze beam position
*
* Revision 1.12  1995/10/09 18:28:41  cdaq
* (JRA) Only call spec analysis routines that correspond to trigger type
*
* Revision 1.11  1995/05/22 20:50:45  cdaq
* (SAW) Split gen_data_data_structures into gen, hms, sos, and coin parts"
*
* Revision 1.10  1995/04/01  19:50:22  cdaq
* (JRA) Add pedestal event handling
*
* Revision 1.9  1994/11/22  20:13:39  cdaq
* (SPB) Uncomment call to SOS code
*
* Revision 1.8  1994/10/11  20:03:27  cdaq
* (JRA) Comment out call to SOS
*
* Revision 1.7  1994/08/04  03:46:31  cdaq
* (SAW) Add call to Breuer's hack_anal
*
* Revision 1.6  1994/06/17  03:36:57  cdaq
* (KBB) Upgrade error reporting
*
* Revision 1.5  1994/04/15  20:37:41  cdaq
* (SAW) for ONLINE compatibility get event from argument instead of commmon.
*
* Revision 1.4  1994/02/02  19:58:47  cdaq
* Remove some damn nulls at the end of the file
*
* Revision 1.3  1994/02/02  18:53:43  cdaq
* Actually add call to g_decode_event_by_banks
*
* Revision 1.2  1994/02/01  21:28:48  cdaq
* Add call to G_decode_event_by_banks
*
*-
*- All standards are from "Proposal for Hall C Analysis Software
*- Vade Mecum, Draft 1.0" by D.F.Geesamn and S.Wood, 7 May 1993
*-
*--------------------------------------------------------
      IMPLICIT NONE
      SAVE
*
      integer*4 event(*)
*
      character*16 here
      parameter (here= 'G_reconstruction')
*     
      logical ABORT
      character*(*) err
*     
      INCLUDE 'gen_data_structures.cmn'
      INCLUDE 'gen_event_info.cmn'
      include 'gen_run_info.cmn'
      INCLUDE 'hack_.cmn'
      include 'bigcal_data_structures.cmn'
      include 'bigcal_bypass_switches.cmn'
      include 'gen_scalers.cmn'
*     
      logical FAIL
      character*1024 why
*
      logical update_peds               ! TRUE = There is new pedestal data
*--------------------------------------------------------
*
      ABORT= .FALSE.
      err= ' '                                  !erase any old errors
*

      call G_decode_event_by_banks(event,ABORT,err)

      IF(ABORT) THEN
         call G_add_path(here,err)
         RETURN
      ENDIF
C
C     SORTING F1 TRIGGERS BY COUNTERS 
C
      CALL f1trigger_sort_by_counter()

c            if(gen_event_trigtype(4).eq.1)then
c              if(gbeam_helicity_TS.eq.1)g_hel_pos = g_hel_pos+1
c              if(gbeam_helicity_TS.eq.-1)g_hel_neg = g_hel_neg+1
c            endif

            if(gen_event_trigtype(4).eq.1.or.
     ,           gen_event_trigtype(1).eq.1.or.
     ,           gen_event_trigtype(3).eq.1.or.
     ,           gen_event_trigtype(2).eq.1.)then
c               if(gen_event_trigtype(4).eq.1.and.nclust.eq.0)write(*,*)0
              if(gbeam_helicity_TS.eq.1)g_hel_pos= g_hel_pos+1
              if(gbeam_helicity_TS.eq.-1)g_hel_neg = g_hel_neg+1
            endif
c            write(*,*)g_hel_pos_tot,g_hel_pos,g_hel_neg_tot,g_hel_neg,
c     ,           gscaler_change(535),gscaler_change(536),gscaler_change(537),gscaler_change(538)

*
*
*  INTERRUPT ANALYSIS FOR PEDESTAL EVENTS.
*
*
!!!! Commenting out next 6 lines so peds go to data. - wra
c      IF(gen_event_type .eq. 4) then            !pedestal event
c         call g_analyze_pedestal(ABORT,err)
c
c        update_peds = .true.                    !need to recalculate pedestals
c        RETURN
c      ENDIF
!! added the following line - wra
*       update_peds = .true.

*
*  check to see if pedestals need to be recalculated.  Note that this is only
*  done if the event was NOT a scaler event, because of the 'return' at the
*  end of the pedestal handling call.
*
      IF(update_peds) then
         !write(*,*) 'calling g_calc_pedestal,evtype=',gen_event_type
        call g_calc_pedestal(ABORT,err)
        !write(*,*) 'g_calc_pedestal successful'
        update_peds = .false.
c        ncalls_calc_ped = ncalls_calc_ped + 1
      ENDIF



*
*-Beamline reconstruction
*-for GEp, avoid event types 2 and 3!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! (No SOS!)
c      IF(gen_event_type.ge.1 .and. gen_event_type.le.3) then  !HMS/SOS/COIN trig
c$$$      if((gen_event_type.eq.1 .or. gen_event_type.eq.5 .or. 
c$$$     $     gen_event_type.eq.6).and.gen_analyze_beamline.ne.0) then ! 1 = HMS singles, 5 = BigCal singles, 6 = HMS-BigCal coin.
        
      if(b_suppress_annoying_pulser.ne.0.and.bigcal_annoying_pulser_event) then
c         write(*,*) 'found annoying pulser event, skipping'
         return
      endif

      if(gen_event_type.ge.1.and.gen_event_type.le.8.and.gen_analyze_beamline
     $     .ne.0) then
         !write(*,*) 'calling g_trans_misc'
        call g_trans_misc(FAIL,why)
        !write(*,*) 'g_trans_misc successful'
        IF(err.NE.' ' .and. why.NE.' ') THEN
          call G_append(err,' & '//why)
        ELSEIF(why.NE.' ') THEN
          err= why
        ENDIF
        ABORT= ABORT .or. FAIL

        !write(*,*) 'calling g_analyze_misc' 
        call g_analyze_misc(FAIL,why) !UNCOMMENT WHEN WE GET IN HALL AND BEAM ON!
        !write(*,*) 'g_analyze_misc successful'
        IF(err.NE.' ' .and. why.NE.' ') THEN
          call G_append(err,' & '//why)
        ELSEIF(why.NE.' ') THEN
          err= why
        ENDIF
        ABORT= ABORT .or. FAIL
      ENDIF
c
c
c     SEM FILL
c     
c
      call sem_fill_tbpm()
      call sem_calc_sr_beampos()

*
*-HMS reconstruction
c      IF(gen_event_type.eq.1 .or. gen_event_type.eq.3) then  !HMS/COIN trig
      
      if(gen_event_type.eq.1 .or. gen_event_type .eq. 6 .or. 
     $     gen_event_type .eq. 3) then               !HMS/COIN trig

c         write(*,*) 'calling HMS reconstruction, gen_event_type=',gen_event_type

         call H_reconstruction(FAIL,why)
        IF(err.NE.' ' .and. why.NE.' ') THEN
          call G_append(err,' & '//why)
        ELSEIF(why.NE.' ') THEN
          err= why
        ENDIF
        ABORT= ABORT .or. FAIL
      ENDIF
*
*-SOS reconstruction
      IF(gen_event_type.eq.2 .or. gen_event_type.eq.3) then  !SOS/COIN trig
        call S_reconstruction(FAIL,why)
        IF(err.NE.' ' .and. why.NE.' ') THEN
          call G_append(err,' & '//why)
        ELSEIF(why.NE.' ') THEN
          err= why
        ENDIF
        ABORT= ABORT .or. FAIL
      ENDIF
*-BIGCAL reconstruction
c changed to always do pyb Feb. 17 2009
c      if((gen_event_type.ge.5 .and. 
c     >    gen_event_type.le.8).or.
c     >    gen_event_type.eq.13) then !5.BIGCAL/6.HMS-BIGCAL COIN/7.COSMIC/8.LIGHT BOX
      if(gen_event_type.ne.99999) then
         !write(*,*) 'calling b_reconstruction'
         
         call B_reconstruction(FAIL,why)

         !write(*,*) 'b_reconstruction successful'
         IF(err.NE.' ' .and. why.NE.' ') THEN
            call G_append(err,' & '//why)
         ELSEIF(why.NE.' ') THEN
            err= why
         ENDIF
         ABORT= ABORT .or. FAIL
      endif
*-GEP-COIN reconstruction
      if(gen_event_type.eq.6 .or. gen_event_type.eq.1) then !GEp-coin. trig
*         write(*,*) 'calling gep_reconstruction'
         call GEp_reconstruction(FAIL,why)
*         write(*,*) 'gep_reconstruction successful'
         if(err.ne.' '.and.why.ne.' ') then
            call G_append(err,' & '//why)
         else if(why.ne.' ') then
            err = why
         endif
         ABORT = ABORT.or.FAIL
      endif
*
*-COIN reconstruction
      IF(gen_event_type.eq.3) then  !COIN trig
        call C_reconstruction(FAIL,why)
        IF(err.NE.' ' .and. why.NE.' ') THEN
          call G_append(err,' & '//why)
        ELSEIF(why.NE.' ') THEN
          err= why
        ENDIF
        ABORT= ABORT .or. FAIL
      ENDIF
*
      IF(ABORT .or. err.NE.' ') call G_add_path(here,err)
*
      IF(hack_enable.ne.0) then
        call hack_anal(FAIL,why)
        IF(err.NE.' ' .and. why.NE.' ') THEN
          call G_append(err,' & '//why)
        ELSEIF(why.NE.' ') THEN
          err= why
        ENDIF
        ABORT= ABORT .or. FAIL
      ENDIF
*
      RETURN
      END
