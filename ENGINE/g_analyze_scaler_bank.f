      subroutine g_analyze_scaler_bank(event,roc,ABORT,err)
*     
*     $Log: g_analyze_scaler_bank.f,v $
*     Revision 1.4.14.2.2.6  2011/02/25 20:24:28  jones
*     Fix problem with scaler(503) . It should be 1MHz but before
*     run 72476 it was 0.998MHz.  This 0.998 Mhz clock was also
*     going into the helicity  plus and minus scalers ( 516 and 515).
*     To get the charge for plus and minus need the fraction of time
*     for each. Use the scaler(174) which is another 1MHz clock
*     for the absolute time. Then scale the time by ratio of
*     516/503 or 515/503 to get the time for the plus and minus
*     helicity.
*
*     Revision 1.4.14.2.2.5  2009/11/11 16:22:00  jones
*     Switch to
*     delta_time_help = max(gscaler_change(516)/gclock_rate,.0001D00)
*     delta_time_helm = max(gscaler_change(515)/gclock_rate,.0001D00)
*
*     Revision 1.4.14.2.2.4  2009/11/04 15:34:05  jones
*     Call scalers 514 and 518 helicity plus and 513 and 517 helicity minus
*
*     Revision 1.4.14.2.2.3  2009/11/04 15:10:38  jones
*     Fill new variable g_run_time_beam_on
*
*     Revision 1.4.14.2.2.2  2009/09/29 13:57:19  jones
*     1) Add variables for calculating charge asymmetry
*     2) For runs between 72476 to 72588 calculate the time for each helicity using 0.4926*(total time) instead of direct scaler measurement since there was a problem with the clock signal going to downstairs scalers.
*
*     Revision 1.4.14.2.2.1  2009/09/02 13:34:35  jones
*     add variable charge_ch
*
*     Revision 1.4.14.2  2007/11/09 17:17:09  cdaq
*      added ability to read roc21 scalers
*
*     Revision 1.4.14.1  2007/09/10 20:33:37  pcarter
*     Implemented changes to allow compilation on RHEL 3,4,5 and MacOSX
*
*     Revision 1.4  2004/05/11 18:31:22  jones
*     If using syncfilter and time between scaler reads is larger than 2.5 seconds
*     then set "skip_event" to true so that g_beam_on_run_time and g_beam_on_bcm_charge are not updated and events are skipped
*     in engine.
*
*     Revision 1.3  2003/09/05 20:54:28  jones
*     Merge in online03 changes (mkj)
*
*     Revision 1.2.2.3  2003/09/04 20:42:17  jones
*     Changes to run with syncfilter (mkj)
*
*     Revision 1.2.2.2  2003/08/14 00:40:09  cdaq
*     Modify so "beam on" scalers for both bcm1 and bcm2 (mkj)
*
*     Revision 1.2.2.1  2003/04/14 18:05:37  jones
*     Modified to skip first scaler event. gscaler is sum from first scaler event.
*
*     Revision 1.2  1999/11/04 20:35:14  saw
*     Linux/G77 compatibility fixes
*
*     Revision 1.1  1999/02/24 15:19:14  saw
*     Bring into CVS tree
*

      implicit none
      save
      external jishft, jiand, jieor
      integer*4 event(*)
      integer*4 roc
*     
      character*17 here
      parameter (here='g_analyze_scaler_bank')
*     
      logical ABORT
      character*(*) err
*     
      INCLUDE 'gen_scalers.cmn'
      INCLUDE 'gen_run_info.cmn'
      INCLUDE 'gen_filenames.cmn'
      INCLUDE 'sane_ntuple.cmn'
*     
      integer ind
      integer*4 cratenum        ! 1=hms,2=sos
      real*8 realscal
      logical update_bcms
      logical update_helicity_bcms
      integer analyzed_events(0:15)
      common /aevents/ analyzed_events
*     
      integer*4 jiand, jishft, jieor   ! Declare to help f2c
*     
*     Scaler events have a header in from of each scaler.  High 16 bits
*     will contain the address (the switch settings).  Address for hall C
*     will be of the form DANN, where NN is the scaler number.  The low 16
*     bits will contain the number of scaler values to follow (this should
*     be no larger than 16, but we will allow more.)
*     
*     
*     NOTE that the variables gscaler(i) is REAL!!!!!
*     this is so that we can record the correct value when the 
*     hardware scalers (32 bit <> I*4) overflow.
*     

      integer evtype, evnum, evlen, pointer
      integer scalid, countinmod, address, counter,ii
*     
*     Temporary variables for beam current and charge calculations
*     
      real*8 ave_current_unser
      real*8 delta_time,delta_time_help,delta_time_helm

*     
*     Find if hms or sos scaler event (assumes first HMS scaler is DA01).
*     write(6,'("Scaler event: event(3)=",9z)') event(3)
      if (jieor(jiand(jishft(event(3),-16),'FFFF'X),'DA01'X).eq.0) then !first scaler
         cratenum=1             !hms
      else
         cratenum=2             !sos
      endif
*     
      evtype = jishft(event(2),-16)
      evnum = jiand(event(2),'FF'x) ! last 2 bytes give event number (mod 256)
*     
*     evnum is mod(256), so must reset lastevnum for rollover
c     Disable out of order detection since it should no longer happen.
c     if (evnum.eq.0 .and. gscal_lastevnum(cratenum).gt.200) then
c     gscal_lastevnum(cratenum)=0
c     else if (evnum.le.gscal_lastevnum(cratenum)) then
c     write(6,*) 'STATUS: skipping outoforder scaler event:',
c     &             ' crate,oldevnum,newevnum=',cratenum,
c     &             gscal_lastevnum(cratenum),evnum
c     return
c     endif
*     
      gscal_lastevnum(cratenum)=evnum
*     
*     Should check against list of known scaler events
*     
      evlen = event(1) + 1
      update_bcms = .false.
      update_helicity_bcms = .false.
      if(evlen.gt.3) then       ! We have a scaler bank
         pointer = 3
*     
         do while(pointer.lt.evlen)
*     
            scalid = jiand(jishft(event(pointer),-16),'FF'x)
            countinmod = jiand(event(pointer),'FFFF'x)
            if(jieor(jiand(event(pointer),'FF000000'x),'DA000000'x).eq.0) then
c     Old style header with scaler ID @ 00FF0000
               scalid = jiand(jishft(event(pointer),-16),'FF'x)
               address = scalid*16
*     
*     Might want to check that count is not to big.
*     
*     if(countinmod.gt.16) then
               if(countinmod.gt.32) then
                  err = 'Scaler module header word has count<>16'
                  ABORT = .true.
                  call g_add_path(here,err)
                  return        ! Safest action
               endif
            else
c     
c     New style header with scaler ID @ FFF?0000
c     (If ? is non zero, it means we are starting in the middle of a scaler)
c     Allows for non multiple of 16 address starts
c     
               address = jishft(event(pointer),-16)
               if (roc .eq. 21) address = address + 230
*     
*     Might want to check that count is not to big.
*     
*     if(countinmod.gt.16) then
               if(countinmod.gt.32) then
                  err = 'Scaler module header word has count >16'
                  ABORT = .true.
                  call g_add_path(here,err)
                  return        ! Safest action
               endif
            endif
*     
ccccc address = scalid*16
            do counter = 1,countinmod
               ind=address+counter
               realscal=dfloat(event(pointer+counter))
               if (ind.eq.gbcm1_index) update_bcms=.true. !assume bcms in same crate
c     
c     For Gen (7/1998) it is noticed that some scaler channels are randomly
c     clearing themselves.  The following is a lame hack to detect and correct
c     this random clearing.
c     
               if(gscalweirdcorrect_flag.eq.1) then ! Look for random clears
                  if(event(pointer+counter).gt.0) then ! Really saying < 2**31
                     if(gscalweird_lastval(ind).gt.event(pointer+counter)) then
                        gscalweird_nclears(ind) = gscalweird_nclears(ind) + 1
                        gscalweird_lostcounts(ind) = gscalweird_lostcounts(ind)
     $                       + gscalweird_lastval(ind)
c     
c     If the longint scaler value is negative, but close to 0 (which means that
c     it is really >> 2**31), then we will get to a point where we can't tell the
c     difference between an overflow and a random clear. But if a channel is
c     getting random clears too much, then the channel will never get to 2**31
c     anyway.  For now, let's assume that nothing counts faster than 5Mhz and that
c     scalers are read out every 5 seconds, and then round that up to
c     2^25=33554432.  So if a scaler apparantly overflows, but jumps by more than
c     2^25, we assume it was a false clear.  We could be cleverer and use some
c     intellegence to characterize the typical rate of each channel, but let's
c     not get carried away.
c     
                     else if (gscalweird_lastval(ind).lt.0 .and.
     $                       (event(pointer+counter)-gscalweird_lastval(ind))
     $                       .gt.33554432) then
                        gscalweird_nclears(ind) = gscalweird_nclears(ind) + 1
                        gscalweird_lostcounts(ind) = gscalweird_lostcounts(ind)
     $                       + gscalweird_lastval(ind)
                     endif
                  endif
                  gscalweird_lastval(ind) = event(pointer+counter)
               endif
*     Save scaler value from previous scaler event:

*     write(101,*) 'scaler index=',ind
c               gscaler_old(ind) = gscaler(ind)
c
               if ( analyzed_events(0) .eq. 1) then
                  gscaler_old(ind) = 0
                  gscaler(ind) = 0
               endif
c
               if (realscal.lt.-0.5) then
                  realscal=realscal+4294967296.
               endif
               if ( (realscal+dfloat(gscaler_nroll(ind))*4294967296.
     $              +gscalweird_lostcounts(ind)) .lt. gscaler(ind) ) then
                                ! 2**32 = 4.295e+9
                                !32 bit scaler rolled over.
                  gscaler_nroll(ind)=gscaler_nroll(ind)+1
               endif
c               gscaler(ind) = realscal + gscaler_nroll(ind)*4294967296.
c     $              + gscalweird_lostcounts(ind)
*     Calculate difference between current scaler value and previous value:
c               gscaler_change(ind) = gscaler(ind) - gscaler_old(ind)
               if ( analyzed_events(0) .gt. 1) then
                   gscaler_change(ind) =  realscal + gscaler_nroll(ind)*4294967296.
     $              + gscalweird_lostcounts(ind) - gscaler_old(ind)
                   gscaler(ind) = gscaler_change(ind) + gscaler(ind)
               endif
               gscaler_old(ind) = realscal + gscaler_nroll(ind)*4294967296.
     $              + gscalweird_lostcounts(ind)
            enddo
            pointer = pointer + countinmod + 1 ! Add 17 to pointer
         enddo
      else
c     err = 'Event not big enough to contain scalers'
c     ABORT = .true.
c     call g_add_path(here,err)
c     
c     Not all banks will have scaler data every event.  Don't generate the
c     error any more.  (saw 20.6.1998)
c     
         return
      endif
*     
*     Calculate beam current and charge between scaler events

      if (update_bcms .and. analyzed_events(0) .gt. 1) then   
c
       g_run_time = g_run_time + max(0.001D00,gscaler_change(gclock_index)/gclock_rate)
      delta_time = max(gscaler_change(gclock_index)/gclock_rate,.0001D00)
      delta_time_help = max(gscaler_change(516)/gclock_rate,.0001D00)
      delta_time_helm = max(gscaler_change(515)/gclock_rate,.0001D00)
      if (gen_run_number .lt. 72476) then
            delta_time_help =delta_time*gscaler_change(516)/gscaler_change(503)
            delta_time_helm =delta_time*gscaler_change(515)/gscaler_change(503)
            endif
       if ( gen_run_number .ge. 72476 .and. gen_run_number .le. 72588) then ! period when problem with clock signal
          delta_time_help = 0.4926*delta_time
          delta_time_helm = 0.4926*delta_time
       endif
c
               skip_events = .false.
               if (syncfilter_on .and. delta_time .gt. 2.5 ) then
                 write(*,*) ' Skip events for 
     >  this scaler read since delta_time = ',delta_time
                 skip_events = .true.
               endif
c
         ave_current_bcm(1) = gbcm1_gain*((gscaler_change(gbcm1_index)
     &        /delta_time) - gbcm1_offset)
         ave_current_bcm(2) = gbcm2_gain*((gscaler_change(gbcm2_index)
     &        /delta_time) - gbcm2_offset)
         ave_current_bcm_help(1) = gbcm1_gain*((gscaler_change(514)
     &        /delta_time_help) - gbcm1_offset)
         ave_current_bcm_help(2) = gbcm2_gain*((gscaler_change(518)
     &        /delta_time_help) - gbcm2_offset)
         ave_current_bcm_helm(1) = gbcm1_gain*((gscaler_change(513)
     &        /delta_time_helm) - gbcm1_offset)
         ave_current_bcm_helm(2) = gbcm2_gain*((gscaler_change(517)
     &        /delta_time_helm) - gbcm2_offset)
         ave_current_bcm(3) = gbcm3_gain*((gscaler_change(gbcm3_index)
     &        /delta_time) - gbcm3_offset)
         ave_current_unser = gunser_gain*((gscaler_change(gunser_index)
     &        /delta_time) - gunser_offset)


          charge_ch=.FALSE.
         if (delta_time.gt.0.0001) then
          charge_ch=.TRUE.

            gbcm1_charge = gbcm1_charge + ave_current_bcm(1)*delta_time
            gbcm2_charge = gbcm2_charge + ave_current_bcm(2)*delta_time
            gbcm1_charge_help = gbcm1_charge_help + ave_current_bcm_help(1)*delta_time_help
            gbcm2_charge_help = gbcm2_charge_help + ave_current_bcm_help(2)*delta_time_help
            gbcm1_charge_helm = gbcm1_charge_helm + ave_current_bcm_helm(1)*delta_time_helm
            gbcm2_charge_helm = gbcm2_charge_helm + ave_current_bcm_helm(2)*delta_time_helm
            gbcm3_charge = gbcm3_charge + ave_current_bcm(3)*delta_time
            gunser_charge = gunser_charge + ave_current_unser*delta_time

*     
*     Check for the beam on condition, and update beam on variables if needed.
*     
*     We will use bcm1 for now as it is zero seems more stable.  This could change.
*     
*     write(6,*) "Checking threshold..."
            if (ave_current_bcm(1) .ge. g_beam_on_thresh_cur(1) .and. insync .eq. 0 .and. .not. skip_events) then
               g_beam_on_run_time(1) = g_beam_on_run_time(1) + delta_time
               g_beam_on_bcm_charge(1) = g_beam_on_bcm_charge(1)
     $              + ave_current_bcm(1)*delta_time
               g_beam_on_run_time_help(1) = g_beam_on_run_time_help(1) + delta_time_help
               g_beam_on_bcm_charge_help(1) = g_beam_on_bcm_charge_help(1)
     $              + ave_current_bcm_help(1)*delta_time_help
               g_beam_on_run_time_helm(1) = g_beam_on_run_time_helm(1) + delta_time_helm
               g_beam_on_bcm_charge_helm(1) = g_beam_on_bcm_charge_helm(1)
     $              + ave_current_bcm_helm(1)*delta_time_helm
*     write(6,*) "above threshold (",ave_current_bcm1,")"
            endif
            if (ave_current_bcm(2) .ge. g_beam_on_thresh_cur(2) .and. insync .eq. 0 .and. .not. skip_events) then
               g_beam_on_run_time(2) = g_beam_on_run_time(2) + delta_time
               g_beam_on_bcm_charge(2) = g_beam_on_bcm_charge(2)
     $              + ave_current_bcm(2)*delta_time
               g_beam_on_run_time_help(2) = g_beam_on_run_time_help(2) + delta_time_help
               g_beam_on_bcm_charge_help(2) = g_beam_on_bcm_charge_help(2)
     $              + ave_current_bcm_help(2)*delta_time_help
               g_beam_on_run_time_helm(2) = g_beam_on_run_time_helm(2) + delta_time_helm
               g_beam_on_bcm_charge_helm(2) = g_beam_on_bcm_charge_helm(2)
     $              + ave_current_bcm_helm(2)*delta_time_helm
            endif
            g_run_time_beam_on = g_beam_on_run_time(bcm_for_threshold_cut)
*     
            gscaler_event_num = gscaler_event_num + 1

*     Write out pertinent charge scaler rates for each scaler event.

            if (g_charge_scaler_filename.ne.' ' .and. ave_current_bcm(1) .ge. g_beam_on_thresh_cur(1)) then
c              write(G_LUN_CHARGE_SCALER,1001) gscaler_event_num, !scaler event num
c    &              gscaler_change(gunser_index)/delta_time, !scaler rate(Hz)
c    &              gscaler_change(gbcm1_index)/delta_time, !scaler rate(Hz)
c    &              gscaler_change(gbcm2_index)/delta_time, !scaler rate(Hz)
c    &              gscaler_change(gbcm3_index)/delta_time, !scaler rate(Hz)
c    &              delta_time  !time since last scaler event (sec)
               write(G_LUN_CHARGE_SCALER,1001) gscaler_event_num, !scaler event num
     > g_beam_on_bcm_charge(1),g_beam_on_bcm_charge_help(1),g_beam_on_bcm_charge_helm(1),
     > (g_beam_on_bcm_charge_help(1)
     >   +g_beam_on_bcm_charge_helm(1))/g_beam_on_bcm_charge(1),
     > g_beam_on_bcm_charge_help(1)/g_beam_on_bcm_charge(1),
     > g_beam_on_bcm_charge_helm(1)/g_beam_on_bcm_charge(1),
     > ave_current_bcm(1)*delta_time, ave_current_bcm_help(1)*delta_time_help,
     > ave_current_bcm_helm(1)*delta_time_helm,
     > (ave_current_bcm_help(1)*delta_time_help
     >+ave_current_bcm_helm(1)*delta_time_helm)/(ave_current_bcm(1)*delta_time),
     > delta_time,delta_time_help,delta_time_helm,
     > (delta_time_help+delta_time_helm)/delta_time,
     > g_beam_on_run_time_help(1)/g_beam_on_run_time(1),g_beam_on_run_time_helm(1)/g_beam_on_run_time(1),
     > (g_beam_on_run_time_help(1)+g_beam_on_run_time_helm(1))/g_beam_on_run_time(1)
            endif
         endif

      endif



*     
* 1001 format(i6,4f13.2,f12.6)
 1001 format(i6,17(1x,f8.5))

      return
      end


