      subroutine s_Ntuple_keep(ABORT,err)
*----------------------------------------------------------------------
*
*     Purpose : Add entry to the SOS Ntuple
*
*     Output: ABORT      - success or failure
*           : err        - reason for failure, if any
*
*     Created: 11-Apr-1994  K.B.Beard, Hampton U.
* $Log: s_ntuple_keep.f,v $
* Revision 1.8  2004/02/17 17:26:34  jones
* Changes to enable possiblity of segmenting rzdat files
*
* Revision 1.7.2.3  2003/08/12 17:35:34  cdaq
* Add variables for e00-108 (hamlet)
*
* Revision 1.7.2.2  2003/06/26 12:39:55  cdaq
* changes for e01-001  (mkj)
*
* Revision 1.7.2.1  2003/04/04 12:54:42  cdaq
* add beam parameters to ntuple
*
* Revision 1.7  1996/09/04 15:18:21  saw
* (JRA) Modify ntuple contents
*
* Revision 1.6  1996/01/16 16:40:31  cdaq
* (JRA) Modify ntuple contents
*
* Revision 1.5  1995/09/01 13:38:46  cdaq
* (JRA) Add Cerenkov photoelectron count to ntuple
*
* Revision 1.4  1995/05/22  20:50:48  cdaq
* (SAW) Split gen_data_data_structures into gen, hms, sos, and coin parts"
*
* Revision 1.3  1995/05/11  19:00:39  cdaq
* (SAW) Change SSDEDXn vars to an array.
*
* Revision 1.2  1994/06/17  02:42:33  cdaq
* (KBB) Upgrade
*
* Revision 1.1  1994/04/12  16:16:28  cdaq
* Initial revision
*
*
*----------------------------------------------------------------------
      implicit none
      save
*
      character*13 here
      parameter (here='s_Ntuple_keep')
*
      logical ABORT
      character*(*) err
*
      INCLUDE 's_ntuple.cmn'
      INCLUDE 'sos_data_structures.cmn'
      INCLUDE 'gen_data_structures.cmn'
      INCLUDE 'gen_event_info.cmn'
      INCLUDE 'sos_tracking.cmn'
      INCLUDE 'sos_physics_sing.cmn'
      INCLUDE 'sos_scin_tof.cmn'
      include 'sos_track_histid.cmn'
      include 'sos_aero_parms.cmn'
      include 'sos_scin_parms.cmn'
      INCLUDE 'sos_calorimeter.cmn'
*
      logical HEXIST    !CERNLIB function
*
      integer m

      real proton_mass
      parameter ( proton_mass = 0.93827247 ) ! [GeV/c^2]
      
      real Wsq
*
*--------------------------------------------------------
      err= ' '
      ABORT = .FALSE.
*
      IF(.NOT.s_Ntuple_exists) RETURN       !nothing to do
c
      if (s_Ntuple_max_segmentevents .gt. 0) then
       if (s_Ntuple_segmentevents .gt. s_Ntuple_max_segmentevents) then
        call s_ntuple_change(ABORT,err)
        s_Ntuple_segmentevents = 0
       else
        s_Ntuple_segmentevents = s_Ntuple_segmentevents +1
       endif
      endif
*
      m= 0
      m= m+1
      s_Ntuple_contents(m)= SSOMEGA !
      m= m+1
      s_Ntuple_contents(m)= SSBIGQ2 !
      m= m+1
      s_Ntuple_contents(m)= SSX_bj !
      m= m+1
      s_Ntuple_contents(m)= SSQ3 !
      Wsq=SINVMASS*SINVMASS
      m= m+1
      s_Ntuple_contents(m)= Wsq !
      m= m+1
      s_Ntuple_contents(m)= SSTHET_GAMMA !

      m= m+1
      s_Ntuple_contents(m)= SCER_NPE_SUM ! cerenkov photoelectron spectrum
      m= m+1
      s_Ntuple_contents(m)= SSP	! Lab momentum of chosen track in GeV/c
      m= m+1
      s_Ntuple_contents(m)= SSENERGY! Lab total energy of chosen track in GeV
      m= m+1
      s_Ntuple_contents(m)= SSDELTA	! Spectrometer delta of chosen track
      m= m+1
      s_Ntuple_contents(m)= SSTHETA	! Lab Scattering angle in radians
      m= m+1
      s_Ntuple_contents(m)= SSPHI	! Lab Azymuthal angle in radians
      m= m+1
      s_Ntuple_contents(m)= SINVMASS	! Invariant Mass of remaing hadronic system
      m= m+1
      s_Ntuple_contents(m)= SSZBEAM! Lab Z coordinate of intersection of beam
                                ! track with spectrometer ray
      m= m+1
      s_Ntuple_contents(m)= SSDEDX(1)	! DEDX of chosen track in 1st scin plane
      m= m+1
      s_Ntuple_contents(m)= SSBETA	! BETA of chosen track
      m= m+1
      s_Ntuple_contents(m)= SSSHTRK	! Total shower energy / momentum
      m= m+1
      s_Ntuple_contents(m)= SSTRACK_PRESHOWER_E	! preshower of chosen track
      m= m+1
      s_Ntuple_contents(m)= SSX_FP		! X focal plane position 
      m= m+1
      s_Ntuple_contents(m)= SSY_FP
      m= m+1
      s_Ntuple_contents(m)= SSXP_FP
      m= m+1
      s_Ntuple_contents(m)= SSYP_FP
      m= m+1
      s_Ntuple_contents(m)= SSY_TAR
      m= m+1
      s_Ntuple_contents(m)= SSXP_TAR
      m= m+1
      s_Ntuple_contents(m)= SSYP_TAR
      m= m+1
      s_Ntuple_contents(m)= float(gen_event_ID_number)
      m= m+1
      s_Ntuple_contents(m)= float(gen_event_type)
      m= m+1
      s_Ntuple_contents(m)= sstart_time
      m= m+1
      s_Ntuple_contents(m)= saer_npe_sum
c
      m= m+1
      s_Ntuple_contents(m)= gfrx_raw_adc
      m= m+1
      s_Ntuple_contents(m)= gfry_raw_adc
      m= m+1
      s_Ntuple_contents(m)= gbeam_x
      m= m+1
      s_Ntuple_contents(m)= gbeam_y
      m= m+1
      s_Ntuple_contents(m)= gbpm_x(1)
      m= m+1
      s_Ntuple_contents(m)= gbpm_y(1)
      m= m+1
      s_Ntuple_contents(m)= gbpm_x(2)
      m= m+1
      s_Ntuple_contents(m)= gbpm_y(2)
      m= m+1
      s_Ntuple_contents(m)= gbpm_x(3)
      m= m+1
      s_Ntuple_contents(m)= gbpm_y(3)
      m= m+1
      s_Ntuple_contents(m)= smisc_dec_data(2,2)
      m= m+1
      s_Ntuple_contents(m)= smisc_dec_data(3,2) 
      m= m+1
      s_Ntuple_contents(m)= smisc_dec_data(4,2) 
      m= m+1
c      s_Ntuple_contents(m)= smisc_dec_data(7,1) 
       s_Ntuple_contents(m)= scer_adc(1)
      m= m+1
c      s_Ntuple_contents(m)= smisc_dec_data(8,1) 
       s_Ntuple_contents(m)= scer_adc(2)
      m= m+1
c      s_Ntuple_contents(m)= smisc_dec_data(5,2) 
       s_Ntuple_contents(m)= scer_adc(3)
      m= m+1
c      s_Ntuple_contents(m)= smisc_dec_data(6,2) 
       s_Ntuple_contents(m)= scer_adc(4)


* Experiment dependent entries start here.


* Fill ntuple for this event
      ABORT= .NOT.HEXIST(s_Ntuple_ID)
      IF(ABORT) THEN
        call G_build_note(':Ntuple ID#$ does not exist',
     &                        '$',s_Ntuple_ID,' ',0.,' ',err)
        call G_add_path(here,err)
      ELSE
        call HFN(s_Ntuple_ID,s_Ntuple_contents)
      ENDIF
*
      RETURN
      END      
