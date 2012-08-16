      SUBROUTINE G_examine_go_info(buffer,ABORT,err)
*-----------------------------------------------------
*-
*-    Purpose and Methods : examine the go information and gather various
*-                          quantities
*- 
*-    Input: buffer             - raw data buffer
*-         : ABORT              - success or failure
*-         : err                - reason for failure, if any
*- 
*-   Created  30-Nov-1995   John Arrington, Caltech.
*-
* $Log: g_examine_go_info.f,v $
* Revision 1.1.24.1  2007/09/11 19:14:18  frw
* fixed FPP related arrays and limits
*
* Revision 1.1  1997/05/23 20:39:42  saw
* Initial revision
*
*
*--------------------------------------------------------
      IMPLICIT NONE
      SAVE
*
      character*18 here
      parameter (here= 'G_examine_go_info')
*     
      INTEGER buffer(*)
      LOGICAL ABORT
      CHARACTER*(*) err
*
      include 'gen_detectorids.par'
      include 'gen_decode_common.cmn'
      include 'gen_run_info.cmn'
*
      integer EvType
      integer*4 pointer,subpntr,ind
      integer*4 evlen,sublen,subheader,slotheader,numvals
      integer*4 roc,slot
      integer*4 jiand,jishft
      logical*4 found_thresholds,found_prescale
      character*80 prescale_string
      character*4 tmpstring
      integer*4 ilo,prescale_len
*     functions
      integer g_important_length
*
*----------------------------------------------------------------------
      err= ' '
*
      EvType = jISHFT(buffer(2),-16)
      if (evtype.ne.133) then
         err = 'Event is not a control event'
         ABORT = .true.
         call g_add_path(here,err)
         return
      endif
*     
      found_thresholds = .false.
      found_prescale = .false.
      prescale_string = ' '
      evlen = buffer(1)


c	write(6,*) 'evlen=',buffer(1)
      pointer = 3                     !1=#/words, 2=event type
      roc= (jiand(buffer(2),'FF'x))
c	write(6,*) 'roc=',roc,'evtype=',evtype

      do while (.not.found_thresholds .and. pointer.le.evlen)
        sublen=buffer(pointer)
c	write(6,*) '  sublen=',sublen
        subheader=buffer(pointer+1)
c	write(6,'(a,z10)') '  subheader=',subheader

        if (jishft(jiand(subheader,'FF0000'x),-16) .eq. '10'x) then !thresholds
          found_thresholds = .true.
c	  write(6,*) '  THRESHOLDS!'
          subpntr=2                            !skip past main subheader.
c	  write(6,*) '  subpntr=',subpntr
          do while (subpntr .lt. sublen)
            slotheader=buffer(pointer+subpntr)
            slot=jishft(jiand(slotheader,'FF000000'x),-24)
c	    write(6,'(a,z10)') '    slotheader=',slotheader
            numvals=jiand(slotheader,'FF'x)
c	    write(6,*) '    slot#',slot,' has ',numvals,' thresholds'
            do ind=1,numvals
              subpntr=subpntr+1
              g_threshold_readback(ind,roc,slot)=buffer(pointer+subpntr)
c            write(6,*) 'g_threshold_readback(',ind,roc,slot,')=',g_threshold_readback(ind,roc,slot)
            enddo
            subpntr=subpntr+1                  !skip to next slotheader
c	    write(6,*) 'subpntr=',subpntr
          enddo   !NEED CHECK FOR NEXT HEADER.
          pointer=pointer+subpntr
        else if (roc.eq.0 .and.
     &           jishft(jiand(subheader,'FF0000'x),-16).eq.'02'x) then
c        write(6,*) 'PRESCALE FACTORS'
          found_prescale=.true.
          do ind=2,sublen
c          write(6,'(3x,a,i4,2x,a4) ') 'ind=',ind,buffer(pointer+ind)
            write(tmpstring,'(a4)') buffer(pointer+ind)
            prescale_string(4*(ind-2)+1:4*(ind-1)) = tmpstring
          enddo
          prescale_len=4*(sublen-1)
          pointer=pointer+sublen+1
        else
c        write(6,*) '  NOT THRESHOLDS,NOT PS FACTORS.  WHO CARES.'
          pointer=pointer+sublen+1
        endif
      enddo
*
      if (found_prescale .and. prescale_len.ne.0) then
        prescale_len = g_important_length(prescale_string(1:prescale_len))
        if(ichar(prescale_string(prescale_len:prescale_len)).eq.10)
     $       prescale_len = prescale_len - 1
        ilo=index(prescale_string(1:prescale_len),'=')+1
        read(prescale_string(ilo:prescale_len),*,err=998) gps1
        ilo=index(prescale_string(ilo+1:prescale_len),'=')+ilo+1
        read(prescale_string(ilo:prescale_len),*,err=998) gps2
        ilo=index(prescale_string(ilo+1:prescale_len),'=')+ilo+1
        read(prescale_string(ilo:prescale_len),*,err=998) gps3
        ilo=index(prescale_string(ilo+1:prescale_len),'=')+ilo+1
        read(prescale_string(ilo:prescale_len),*,err=998) gps4
        ilo=index(prescale_string(ilo+1:prescale_len),'=')+ilo+1
        read(prescale_string(ilo:prescale_len),*,err=998) gps5

c        write(6,*) 'gps1=',gps1,'gps2=',gps2,'gps3=',gps3,'gps4=',gps4,'gps5='
c     $       ,gps5
      endif
*
      goto 999
998   write(6,*) 'WARNING: g_examine_go_info.f >>> error extracting prescale factors, giving up'
999   continue
      RETURN
      END
