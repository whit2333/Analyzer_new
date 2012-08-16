      subroutine h_prt_tof(itrk)

*-------------------------------------------------------------------
* author: John Arrington
* created: 3/27/94
*
* h_prt_tof dumps the hms_scin_tof bank.
*
* modifications:
* $Log: h_prt_tof.f,v $
* Revision 1.5.26.1  2008/11/17 15:58:28  cdaq
* Changed from old to new tof offset
*
* Revision 1.5  1996/01/24 15:59:22  saw
* (JRA) Add scin.center column to output
*
* Revision 1.4  1995/05/22 19:39:24  cdaq
* (SAW) Split gen_data_data_structures into gen, hms, sos, and coin parts"
*
* Revision 1.3  1995/02/02  13:12:45  cdaq
* (JRA) Cosmetic changes
*
* Revision 1.2  1994/09/13  20:28:43  cdaq
* (JRA) Change output format, add missing variables
*
* Revision 1.1  1994/04/13  15:43:38  cdaq
* Initial revision
*
*-------------------------------------------------------------------

      implicit none

      include 'hms_data_structures.cmn'
      include 'hms_scin_parms.cmn'
      include 'hms_scin_tof.cmn'
      include 'hms_tracking.cmn'
      
*      logical abort
      integer*4 ihit, itrk
*      character*1024 errmsg
*      character*25 here
*      parameter (here = 'h_prt_tof')

      save

      write(hluno,'(''              ***H_SCIN_TOF BANK***'')')
      write(hluno,'(''        TRACK NUMBER'',i3)') itrk
      write(hluno,'(''POSITION/CALIBRATION VARIABLES:'')')
      write(hluno,'(''  +coord  -coord '',
     &     '' pos_dt  neg_dt  +sigma  -sigma  scin.center'')')
      do ihit=1,hscin_tot_hits
        write(hluno,'(f8.3,f8.3,2f8.3,2f8.3,f10.2)')
     &       hscin_pos_coord(ihit), hscin_neg_coord(ihit),
     &       hscin_pos_invadc_offset(ihit), 
     >       hscin_neg_invadc_offset(ihit),
     &       hscin_pos_sigma(ihit), hscin_neg_sigma(ihit),
     &       hscin_center_coord(ihit)
      enddo
      write(hluno,'(''HIT POSITION AND OTHER CALCULATED VARIABLES:'')')
      write(hluno,'(''  long_coord trans_coord    +time    -time'',
     &     '' scin_time scin_sig on_trk time@fp'')')
      do ihit=1,hscin_tot_hits
        write(hluno,'(2f12.4,2f9.3,f10.3,f8.3,l5,f10.3)')
     &       hscin_long_coord(ihit), hscin_trans_coord(ihit),
     &       hscin_pos_time(ihit), hscin_neg_time(ihit),
     &       hscin_time(ihit),  hscin_sigma(ihit),
     &       hscin_on_track(itrk,ihit),hscin_time_fp(ihit)
      enddo
      write(hluno,'(''  trk  beta     chisq_beta  fp_time '',
     &     ''num_scin_hit  num_pmt_hit'')')
      write(hluno,'(i4,f8.4,f14.3,f9.3,i8,i12)') itrk,
     &     hbeta(itrk), hbeta_chisq(itrk), htime_at_fp(itrk),
     &     hnum_scin_hit(itrk),hnum_pmt_hit(itrk)
      write(hluno,*)

      return
      end
