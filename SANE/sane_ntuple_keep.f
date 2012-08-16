      subroutine sane_ntuple_keep(ABORT,err)

      implicit none
      save

      character*13 here
      parameter(here='sane_ntuple_keep')

      logical abort
      character*(*) err
      integer i,j,status(100,100),k,m

      include 'b_ntuple.cmn'
      include 'bigcal_data_structures.cmn'
      include 'bigcal_tof_parms.cmn'
      include 'hms_data_structures.cmn'
      include 'bigcal_gain_parms.cmn'
      include 'gen_event_info.cmn'
      include 'gen_data_structures.cmn'
      include 'gep_data_structures.cmn'
      include 'sane_ntuple.cmn'
      include 'sane_data_structures.cmn'
      include 'sem_data_structures.cmn'
      INCLUDE 'h_ntuple.cmn'
      include 'f1trigger_data_structures.cmn'
      include 'hms_calorimeter.cmn'
      include 'gen_detectorids.par'
      include 'gen_scalers.cmn'
      include 'gen_run_info.cmn'
      logical HEXIST ! CERNLIB function
      integer t_sane,l_sane,cer_sane
      integer icycle,inum,ihit
      real*8 Eb,theta_big, phi_big!,ccx,ccy,ccz
      real P_el(4),p_e,WW2
      common/FAKEBIG/Eb,theta_big, phi_big
      real*8 tcharge_old,tcharge_help_old,tcharge_helm_old 
      real*8 charge2s_old,charge2s_help_old,charge2s_helm_old  
      real*8 polarea_old ,polarization_old
      integer*4 hel_p_scaler_old 
      integer*4 hel_n_scaler_old 
      integer*4 hel_p_trig_old 
      integer*4 hel_n_trig_old 
      real*8 dtime_p_old ,dtime_n_old 
      real*4 half_plate_old 
      common/SANEEV_old /
     $     tcharge_old ,
     $     charge2s_old ,
     $     tcharge_help_old,charge2s_help_old,
     $     tcharge_helm_old,charge2s_helm_old ,
     $     polarea_old ,polarization_old,
     $ 	   hel_p_scaler_old ,
     $	    hel_n_scaler_old ,
     $	    hel_p_trig_old ,
     $	    hel_n_trig_old ,
     $	    dtime_p_old ,dtime_n_old,half_plate_old 


      real Mp
      parameter(Mp=.938272)


      err=' '
      ABORT=.false.
c      write(*,*)'Starting sane'
c     INQUIRE(FILE="input.txt",EXIST=file_exist)
c     write(*,*)file_exist
      
      if(sane_ntuple_max_segmentevents.gt.0) then
         if(sane_ntuple_segmentevents.gt.sane_ntuple_max_segmentevents) then
            call sane_ntup_change(ABORT,err)
            sane_ntuple_segmentevents=0
         else 
            sane_ntuple_segmentevents = sane_ntuple_segmentevents + 1
         endif
      endif

      if(.not.sane_ntuple_exists) return
      if(.not.charge_data_open.and.charge_ch)then
         charge2s = gbcm1_charge-tcharge
         tcharge = gbcm1_charge
         charge2s_help = gbcm1_charge_help -tcharge_help 
         tcharge_help  = gbcm1_charge_help 
         charge2s_helm = gbcm1_charge_helm -tcharge_helm 
         tcharge_helm  = gbcm1_charge_helm 
c         write(*,*)'MMM'
c      endif
c      if(.not.charge_data_open.and.gscaler_change(538).ne.hel_p_scaler)then
        hel_p_scaler=gscaler_change(538)
c        hel_p_scaler= 0.985*gscaler_change(510)-gscaler_change(538)
        hel_p_trig= g_hel_pos
        dtime_p =1.
        if(abs(hel_p_scaler).gt.0)then
           dtime_p =float(g_hel_pos)/float(hel_p_scaler)
        endif
        call NANcheckF(dtime_p,0)
        g_hel_pos =0
c        write(*,*)'MMM P'
c      endif
c      if(.not.charge_data_open.and.gscaler_change(546).ne.hel_n_scaler)then

        hel_n_scaler= 0.985*gscaler_change(510)-gscaler_change(538)
        hel_n_trig= g_hel_neg
        dtime_n=1
        if(abs(hel_n_scaler).gt.0.0)then
           dtime_n = float(g_hel_neg)/float(hel_n_scaler)
        endif
        call NANcheckF(dtime_n,0)
        g_hel_neg =0
c        write(*,*)'MMM N'
      endif
      if(polarization_data_open)then
         polarea = polarea_old
         polarization =polarization_old
         half_plate =half_plate_old 
      endif
      if(charge_data_open)then
         charge2s = charge2s_old 
         tcharge = tcharge_old
         charge2s_help = charge2s_help_old 
         tcharge_help = tcharge_help_old
         charge2s_helm = charge2s_helm_old 
         tcharge_helm = tcharge_helm_old
         hel_p_scaler = hel_p_scaler_old
         hel_p_trig = hel_p_trig_old
         dtime_p = dtime_p 
         hel_n_scaler = hel_n_scaler_old
         hel_n_trig = hel_n_trig_old
         dtime_n = dtime_n_old
c         if(abs(gbcm1_charge-tcharge).lt.0.001)charge_ch = .TRUE.
      endif
      if(polarization_data_open.and.gen_event_ID_number.eq.pol_id_change)then
         read(polarization_data_unit,*,end=19)pol_id_change,polarea_old,polarization_old,half_plate_old 
c          write(*,*)'HELP ',polarea_old 
         polarea = polarea_old
         polarization=polarization_old
         half_plate =half_plate_old 
         polarization_ch = .FALSE.
      else if(.not.polarization_data_open.and.polarization_ch)then
          write(polarization_data_unit,*)gen_event_ID_number,polarea ,polarization ,half_plate
          polarization_ch = .FALSE.
      endif
      if(charge_data_open.and.gen_event_ID_number.eq.charge_id_change)then
c         write(*,*)'HELP charge Had',tcharge,gbcm1_charge
         read(charge_data_unit,*,end=18)
     ,           charge_id_change,charge2s_old,tcharge_old,
     ,           tcharge_help_old,charge2s_help_old,
     ,           tcharge_helm_old,charge2s_helm_old ,
     ,           hel_p_scaler_old,hel_p_trig_old,dtime_p_old,
     ,           hel_n_scaler_old,hel_n_trig_old,dtime_n_old

c         write(*,*)'HELP charge NOW',tcharge_old,gbcm1_charge
         charge2s = charge2s_old 
         tcharge = tcharge_old
         charge2s_help = charge2s_help_old 
         tcharge_help = tcharge_help_old
         charge2s_helm = charge2s_helm_old 
         tcharge_helm = tcharge_helm_old
         hel_p_scaler = hel_p_scaler_old
         hel_p_trig = hel_p_trig_old
         dtime_p = dtime_p_old 
         hel_n_scaler = hel_n_scaler_old
         hel_n_trig = hel_n_trig_old
         dtime_n = dtime_n_old
         charge_ch = .FALSE.
         
c        write(*,*)gbcm1_charge,tcharge
      else if(.not.charge_data_open.and.charge_ch)then
         write(charge_data_unit,*)
     ,        gen_event_ID_number,charge2s,tcharge,
     ,        tcharge_help,charge2s_help,
     ,        tcharge_helm,charge2s_helm ,
     >        hel_p_scaler,hel_p_trig,dtime_p,
     ,        hel_n_scaler,hel_n_trig,dtime_n
         charge_ch = .FALSE.
      endif
      call NANcheckF(polarization,3)

c      write(*,*)'HALF PLATE ',half_plate
      
c      if(charge_ch)then
c         write(*,*)polarea,charge2s,tcharge,hel_n_trig,hel_p_trig,hel_p_scaler
c      endif
c      if(polarization_ch)then
c         write(*,*)polarea,charge2s,tcharge,hel_n_trig,hel_p_trig,hel_p_scaler
c      endif
c      write(*,*)gbcm1_charge
      T_trgHMS     = gmisc_dec_data(11,1)
      call NANcheckF(T_trgHMS,3)
      T_trgBIG     = gmisc_dec_data(12,1) 
      call NANcheckF(T_trgBIG,3)
      T_trgPI0     = gmisc_dec_data(13,1)
      call NANcheckF(T_trgPI0,3)
      T_trgBETA    = gmisc_dec_data(14,1)
      call NANcheckF(T_trgBETA,3)
      T_trgCOIN1   = gmisc_dec_data(15,1)
      call NANcheckF(T_trgCOIN1,3)
      T_trgCOIN2   = gmisc_dec_data(16,1)
      call NANcheckF(T_trgCOIN2,3)



cccccccccc Lucite Hodoscope
      luc_hit = 0
c      write(*,*) LUCITE_SANE_RAW_TOT_HITS,LUCITE_SANE_RAW_TOT_HITS2,LUCITE_SANE_RAW_TOT_HITS3
c      write(*,*) LUCITE_SANE_RAW_TOT_HITS,LUCITE_SANE_RAW_TOT_HITS3
c      write(*,*) LUCITE_SANE_RAW_TDC_POS
c      write(*,*) LUCITE_SANE_RAW_TDC_POS


!      do i=1,LUCITE_SANE_RAW_TOT_HITS2 ! TDC hit counter for positive side
c         if(LUCITE_SANE_RAW_COUNTER_NUM2(i).eq.7)write(*,*)7
!         if(LUCITE_SANE_RAW_TDC_POS(i).gt.0)then
!            do j=1,LUCITE_SANE_RAW_TOT_HITS3 !TDC hit counter for negative side
c         if(LUCITE_SANE_RAW_COUNTER_NUM3(j).eq.7)write(*,*)72
!               if ( luc_hit .lt. 90) then  ! check hard coded array max
!               if(LUCITE_SANE_RAW_TDC_NEG(j).gt.0.and.
!     ,              LUCITE_SANE_RAW_COUNTER_NUM2(i).eq.LUCITE_SANE_RAW_COUNTER_NUM3(j))then
!                  luc_hit            =  luc_hit+1
!                  luc_row(luc_hit)   =  LUCITE_SANE_RAW_COUNTER_NUM2(i)
!                  ladc_pos(luc_hit)  =  LUCITE_SANE_RAW_ADC_POS(luc_row(luc_hit)) !- luc_ped_mean_pos(luc_row(luc_hit))
!                  ladc_neg(luc_hit)  =  LUCITE_SANE_RAW_ADC_NEG(luc_row(luc_hit)) !- luc_ped_mean_neg(luc_row(luc_hit))
!                  luc_y(luc_hit)     =  -82.35 + (luc_row(luc_hit)-1)*6.1
!                  call NANcheck(luc_hit,LUCITE_SANE_ID)
!                  call NANcheck(luc_row(luc_hit),LUCITE_SANE_ID)
!                  call NANcheck(ladc_neg(luc_hit),LUCITE_SANE_ID)
!                  call NANcheck(ladc_pos(luc_hit),LUCITE_SANE_ID)
!                  call NANcheck(ltdc_neg(luc_hit),LUCITE_SANE_ID)
!                  call NANcheck(ltdc_pos(luc_hit),LUCITE_SANE_ID)
!                  call CORRECT_RAW_TIME_SANE(LUCITE_SANE_RAW_TDC_POS(i),ltdc_pos(luc_hit))
!                  call CORRECT_RAW_TIME_SANE(LUCITE_SANE_RAW_TDC_NEG(j),ltdc_NEG(luc_hit))
c                  call HFILL(10121, float(luc_row(luc_hit)), float(ltdc_pos(luc_hit)), 1.)
c                  call HFILL(10122, float(luc_row(luc_hit)), float(ltdc_neg(luc_hit)), 1.)
c                  call HFILL(10125, float(luc_row(luc_hit)), float(ladc_pos(luc_hit)), 1.)
c                  call HFILL(10126, float(luc_row(luc_hit)), float(ladc_neg(luc_hit)), 1.)
!                  LUCITE_SANE_RAW_TDC_NEG(j) = 0
!               endif
!               endif
!            enddo
!            LUCITE_SANE_RAW_TDC_POS(i) = 0

!         endif
!      enddo
c      write(*,*)'LUC sane done'
      do i=1,LUCITE_SANE_RAW_TOT_HITS2
         if(LUCITE_SANE_RAW_TDC_POS(i).gt.0)then
                luc_hit            =  luc_hit+1
                luc_row(luc_hit)   =  LUCITE_SANE_RAW_COUNTER_NUM2(i)
                ladc_pos(luc_hit)  =  LUCITE_SANE_RAW_ADC_POS(luc_row(luc_hit)) - luc_ped_mean_pos(luc_row(luc_hit))
                ladc_neg(luc_hit)  =  -100000
                call CORRECT_RAW_TIME_SANE(LUCITE_SANE_RAW_TDC_POS(i),ltdc_pos(luc_hit))
                ltdc_NEG(luc_hit)  =  -100000
                LUCITE_SANE_RAW_TDC_POS(i) = 0
c                call HFILL(10121, float(luc_row(luc_hit)), float(ltdc_pos(luc_hit)), 1.)
c                call HFILL(10125, float(luc_row(luc_hit)), float(ladc_pos(luc_hit)), 1.)
            
         endif
      enddo
      do i=1,LUCITE_SANE_RAW_TOT_HITS3
         if(LUCITE_SANE_RAW_TDC_NEG(i).gt.0)then
                luc_hit            =  luc_hit+1
                luc_row(luc_hit)   =  LUCITE_SANE_RAW_COUNTER_NUM3(i)
                ladc_neg(luc_hit)  =  LUCITE_SANE_RAW_ADC_NEG(luc_row(luc_hit)) - luc_ped_mean_pos(luc_row(luc_hit))
                ladc_pos(luc_hit)  =  -100000
                call CORRECT_RAW_TIME_SANE(LUCITE_SANE_RAW_TDC_NEG(i),ltdc_neg(luc_hit))
                ltdc_POS(luc_hit)  =  -100000
                LUCITE_SANE_RAW_TDC_NEG(i) = 0
c                call HFILL(10122, float(luc_row(luc_hit)), float(ltdc_neg(luc_hit)), 1.)
c                call HFILL(10126, float(luc_row(luc_hit)), float(ladc_neg(luc_hit)), 1.)
            
         endif
      enddo
cccccccccc End Lucite Hodoscope

cccccccccccccccccccccccccccccccccc
cc InSANE SCALERS cccccccccccccccc
cccccccccccccccccccccccccccccccccc
c     Cherenkov Scalers 6*12=72
c     Cherenkov Scalers start at 519
      do i=1,12
        cerscalernroll(i)=gscaler_nroll(518+i)
        cerscaler(i)=gscaler(518+i)
        cerscaler_change(i)=gscaler_change(518+i)
        cerscaler_old(i)=gscaler_old(518+i)
        cerscaler_skipped(i)=gscaler_skipped(518+i)
        cerscaler_saved(i)=gscaler_saved(518+i)

      enddo
c     Hodoscope Scalers 6*56*2 = 672 
C     Hodoscope Scalers start at??????
      do i=1,12
        lucscalernroll(i)=gscaler_nroll(518+i)
        lucscaler(i)=gscaler(518+i)
        lucscaler_change(i)=gscaler_change(518+i)
        lucscaler_old(i)=gscaler_old(518+i)
        lucscaler_skipped(i)=gscaler_skipped(518+i)
        lucscaler_saved(i)=gscaler_saved(518+i)
      enddo
c     Bigcal scalers 6*271=1626
c     Bigcal scalers start at index 271
      nbcscalers=272
      do i=1,272
        bcscalernroll(i)=gscaler_nroll(230+i)
        bcscaler(i)=gscaler(230+i)
        bcscaler_change(i)=gscaler_change(230+i)
        bcscaler_old(i)=gscaler_old(230+i)
        bcscaler_skipped(i)=gscaler_skipped(230+i)
        bcscaler_saved(i)=gscaler_saved(230+i)

      enddo
c     Forward Tracker scalers 32*6=192
c     Forward Tracker scalers start at index 550
      do i=1,32
        tkscalernroll(i)=gscaler_nroll(550+i)
        tkscaler(i)=gscaler(550+i)
        tkscaler_change(i)=gscaler_change(550+i)
        tkscaler_old(i)=gscaler_old(550+i)
        tkscaler_skipped(i)=gscaler_skipped(550+i)
        tkscaler_saved(i)=gscaler_saved(550+i)
      enddo
c
c    Total BETA Detector Scalers = 2562
c
ccccccccccccccccccccccccccccccccc
cc END InSANE SCALERS ccccccccccc
ccccccccccccccccccccccccccccccccc

ccccccc Cherenkov 
      cer_hit = 0
c      write(*,*)'c, ',CERENKOV_SANE_RAW_COUNTER_NUM
c      write(*,*)'a, ' ,CERENKOV_SANE_RAW_ADC
      do i=1,CERENKOV_SANE_RAW_TOT_HITS2
         if(CERENKOV_SANE_RAW_TDC(i).gt.0)then
            cer_hit         =  cer_hit+1
            cer_num(cer_hit)   =  CERENKOV_SANE_RAW_COUNTER_NUM2(i)
            call CORRECT_RAW_TIME_SANE(CERENKOV_SANE_RAW_TDC(i),cer_tdc(cer_hit))
            cer_adcc(cer_hit) = CERENKOV_SANE_RAW_ADC(cer_num(cer_hit))-cer_sane_ped_mean(cer_num(cer_hit))
            call HFILL(10111,float(cer_num(cer_hit)),float(cer_TDC(cer_hit)), 1.)

            call NANcheck(cer_hit,CERENKOV_SANE_ID)
            call NANcheck(cer_num(cer_hit),CERENKOV_SANE_ID)
            call NANcheck(cer_adcc(cer_hit),CERENKOV_SANE_ID2)
            call NANcheck(cer_tdc(cer_hit),CERENKOV_SANE_ID)
c            if ( T_trgBIG.ge.40) then
c               call HFILL(10500+cer_num(cer_hit),float(cer_adcc(cer_hit)),float(cer_tdc(cer_hit)),1.)
c            endif
         endif
      enddo

c         write(*,*)CERENKOV_SANE_RAW_TOT_HITS2,' ',
c     ^ CERENKOV_SANE_RAW_TOT_HITS

       ceradc_hit = 0
      do i=1,CERENKOV_SANE_RAW_TOT_HITS
         if (ceradc_hit .le. 15) then
            ceradc_hit = ceradc_hit + 1
            ceradc_num(ceradc_hit)   =  CERENKOV_SANE_RAW_COUNTER_NUM(i)
            cer_adc(ceradc_hit)   =  CERENKOV_SANE_RAW_ADC(ceradc_num(ceradc_hit))-cer_sane_ped_mean(ceradc_num(ceradc_hit))
            call NANcheck(ceradc_hit,CERENKOV_SANE_ID2)
            call NANcheck(ceradc_num(ceradc_hit),CERENKOV_SANE_ID2)
            call NANcheck(cer_adc(ceradc_hit),CERENKOV_SANE_ID2)
            call HFILL(10112,float(ceradc_num(ceradc_hit)),float(cer_adc(ceradc_hit)), 1.)
         endif
       enddo
c
       
c
c      write(*,*)'Cer sane done'

      x1t_hit         =  0
      if(x1t_hit.gt.300) go to 10
      do i=1,TRACKER_SANE_RAW_TOT_HITS_X
         if(TRACKER_SANE_RAW_TDC_X(i).gt.0)then
            x1t_hit         =  x1t_hit+1
            x1t_row(x1t_hit)   =  TRACKER_SANE_RAW_COUNTER_X(i)
            call CORRECT_RAW_TIME_SANE(TRACKER_SANE_RAW_TDC_X(i),x1t_tdc(x1t_hit))
            x1t_x(x1t_hit)     =  -12.32+0.37422*(x1t_row(x1t_hit)-1)

            call HFILL(10100,float(x1t_row(x1t_hit)),float(x1t_tdc(x1t_hit)),1.) 
            call NANcheck(x1t_hit,TRACKER_SANE_X_ID)
            call NANcheck(x1t_row(x1t_hit),TRACKER_SANE_X_ID)
            call NANcheck(x1t_tdc(x1t_hit),TRACKER_SANE_X_ID)
         endif
      enddo
      y1t_hit=0
      y2t_hit=0
c      write(*,*)gen_event_ID_number,TRACKER_SANE_RAW_TOT_HITS_Y
      
      do i=1,TRACKER_SANE_RAW_TOT_HITS_Y
c      write(*,*)'TDC, ', TRACKER_SANE_RAW_TDC_Y(i),TRACKER_SANE_RAW_COUNTER_Y(i)
         if(TRACKER_SANE_RAW_TDC_Y(i).lt.67000.and.
     ,        TRACKER_SANE_RAW_TDC_Y(i).gt.0)then
            if(TRACKER_SANE_RAW_COUNTER_Y(i).lt.129)then
               y1t_hit            =  y1t_hit + 1 
c               write(*,*)'Tracker TDC', y1t_hit,TRACKER_SANE_RAW_TDC_Y(i)
               if(y1t_hit.gt.300) go to 20
               y1t_row(y1t_hit)   =  TRACKER_SANE_RAW_COUNTER_Y(i)
               call CORRECT_RAW_TIME_SANE(TRACKER_SANE_RAW_TDC_Y(i),y1t_tdc(y1t_hit))
               y1t_y(y1t_hit)     =  -22.225+(y1t_row(y1t_hit)-1)*0.35
               call HFILL(10101,float(y1t_row(y1t_hit)),float(y1t_tdc(y1t_hit)),1.) 
               call NANcheck(y1t_hit,TRACKER_SANE_Y_ID)
               call NANcheck(y1t_row(y1t_hit),TRACKER_SANE_Y_ID)
               call NANcheck(y1t_tdc(y1t_hit),TRACKER_SANE_Y_ID)

             else if(TRACKER_SANE_RAW_COUNTER_Y(i).lt.257)then
               y2t_hit            =  y2t_hit + 1 
               if(y2t_hit.gt.300) go to 20
               y2t_row(y2t_hit)   =  TRACKER_SANE_RAW_COUNTER_Y(i)-128
               call CORRECT_RAW_TIME_SANE(TRACKER_SANE_RAW_TDC_Y(i),y2t_tdc(y2t_hit))
               y2t_y(y2t_hit)     =  -22.4+(y2t_row(y2t_hit)-1)*0.35
               call HFILL(10102,float(y2t_row(y2t_hit)),float(y2t_tdc(y2t_hit)),1.) 
               call NANcheck(y2t_hit,TRACKER_SANE_Y_ID)
               call NANcheck(y2t_row(y2t_hit),TRACKER_SANE_Y_ID)
               call NANcheck(y2t_tdc(y2t_hit),TRACKER_SANE_Y_ID)
            endif
         endif
 20      CONTINUE
      enddo
c      write(*,*)'TRACK sane done'
c          do inum=1,nclust
c         enddo
             hms_p = 0
      if(HSNUM_FPTRACK.gt.0)then
c         write(*,*)HSNUM_FPTRACK,hsp,hstheta
         hms_p        = hsp	
         call NANcheckF(hms_p,4)
         hms_e        = hsenergy
         call NANcheckF(hms_e,4)
         hms_theta    = hstheta
         call NANcheckF(hms_theta,4)
         hms_phi      = hsphi
         call NANcheckF(hms_phi,4)
         hsxfp_s      = hsx_fp
         call NANcheckF(hsxfp_s,4)
         hsyfp_s      = hsy_fp
         call NANcheckF(hsyfp_s,4)
         hsxpfp_s     = hsxp_fp
         call NANcheckF(hsxpfp_s,4)
         hsypfp_s     = hsyp_fp
         call NANcheckF(hsypfp_s,4)
         hms_xtar     = hsx_tar*100
         call NANcheckF(hms_xtar,4)
         hms_ytar     = hsy_tar*100
         call NANcheckF(hms_ytar,4)
c         write(*,*)hms_ytar,hsy_tar
         hms_yptar    = hsyp_tar
         call NANcheckF(hms_yptar,4)
         hms_xptar    = hsxp_tar
c         write(*,*)hms_yptar,hms_xptar
         call NANcheckF(hms_xptar,4)
         hms_delta    = hsdelta
         call NANcheckF(hms_delta,4)
         hms_start    = hstart_time
         call NANcheck(hms_start,4)
         hsshtrk_s    = HSTRACK_ET
         call NANcheckF(hsshtrk_s,4)
         hsshsum_s    = hsshsum
         call NANcheckF(hsshsum_s,4)
         hsbeta_s     = hsbeta 
         call NANcheckF(hsbeta_s,4)
         hms_cer_npe1 = hcer_npe(1)
         call NANcheckF(hms_cer_npe1,4)
         hms_cer_npe2 = hcer_npe(2)
         call NANcheckF(hms_cer_npe2,4)
         hms_cer_adc1 = hcer_adc(1) 
         call NANcheckF(hms_cer_adc1,4)
         hms_cer_adc2 = hcer_adc(2)
         call NANcheckF(hms_cer_adc2,4)
         call HFILL(10302,X_HMS,Y_HMS,1.)
c         if(nclust.eq.1)then
         do i=1,nclust
!             call HFILL(10300,X_HMS,xclust(i)+Bigcal_SHIFT(1),1.) 
!             call HFILL(10304,X_HMS-Xclust(i),Y_HMS-Yclust(i),1.)
!             call HFILL(10301,Y_HMS,Yclust(i)+Bigcal_SHIFT(2),1.) 
c            write(*,*)Bigcal_SHIFT(1),Bigcal_SHIFT(2)
               if(abs(X_HMS-xclust(i)-Bigcal_SHIFT(1)).lt.10.and.
     ,              abs(Y_HMS-Yclust(i)-Bigcal_SHIFT(2)).lt.10)then
c                  write(*,*)'Slow raster ',gsrx_calib,gsry_calib
c                  write(*,*)'HMS raster ',hms_xtar,hms_ytar
!                   call HFILL(10303,Xclust(i)+Bigcal_SHIFT(1),Yclust(i)+Bigcal_SHIFT(2),1.)
!                   call HFILL(10310,hms_delta,hms_yptar ,1.)
!                   call HFILL(10311,hms_delta,hms_xptar ,1.)
!                   call HFILL(10312,dpel_hms,hms_yptar ,1.)
!                   call HFILL(10313,dpel_hms,hms_xptar ,1.)
!                   call HFILL(10315,dpel_hms,hms_ytar ,1.)
!                   call HFILL(10314,dpel_hms,hms_xtar ,1.)
!                   call HF1(10321,0.006*hms_delta+0.01-hms_yptar,1.)
                  P_e = hms_p
                  P_el(1) = p_e*sin(hms_theta)*cos(HMS_phi)
                  P_el(2) = p_e*sin(hms_theta)*sin(HMS_phi)
                  P_el(3) = p_e*cos(hms_theta)
                  P_el(4) = hms_e
                  ww2 = (GEBEAM+Mp-P_el(4))**2-
     ,                 (P_el(1)**2+p_el(2)**2+(GEBEAM-p_el(3))**2)
c                  write(*,*)ww2
!                   call HF1(10322,ww2,1.)
!                   call HFILL(10323,ww2,hms_yptar,1.)
!                   call HFILL(10324,ww2,hms_xtar,1.)
                
               endif
         enddo
c         endif

      endif

      srast_x_adc = gsrx_raw_adc
      srast_y_adc = gsry_raw_adc
      frast_x_adc = gfrx_raw_adc
      frast_y_adc = gfry_raw_adc

      rast_x       = gfry_raw_adc
      call NANcheckF(rast_x,3)
      rast_y       = gfrx_raw_adc
      call NANcheckF(rast_y,3)
      i_helicity   = gbeam_helicity
      call NANcheck(i_helicity,3)
!       write(*,*)'i_helicity',i_helicity

c      if(sane_ntuple_type.eq.1)then
         slow_rast_x  = gsrx_calib
         call NANcheckF(gsrx_raw_adc,3)
         slow_rast_y  = gsry_calib
         call NANcheckF(gsry_raw_adc,3)
c      else 
c         slow_rast_x  = gsrx_raw_adc
c         call NANcheckF(gsrx_raw_adc,3)
c         slow_rast_y  = gsry_raw_adc
c         call NANcheckF(gsry_raw_adc,3)
            
c      endif
      call HFILL(10215,gsry_raw_adc,gsrx_raw_adc, 1.)

      call HFILL(10216,gsrx_calib,gsry_calib, 1.)

      if(HSNUM_FPTRACK.gt.0)then
            
                  call HFILL(10316,slow_rast_y,-hms_xtar ,1.)
                  call HFILL(10317,slow_rast_x,hms_ytar ,1.)
      endif
      call NANcheckF(gsry_raw_adc,3)
      sem_x        = -ntbpmx/10.
      call NANcheckF(sem_x,3)
      sem_y        = ntbpmy/10.
      call NANcheckF(sem_y,3)
      call HFILL(10214,sem_x,sem_y, 1.)
      
      n_clust = nclust
      do i =1,  n_clust

          call Bigcal_Betta(i)
          call icer(i)
c          call Bigcal_Betta(i)
          call tracker(i)
          call TrackerCoordnate(i)
          call GeometryMatch(i)
          call Lucite(i)
         do j=1, ncellclust(i)
            call HFILL(10200,float(ixcell(j,i)),float(iycell(j,i)), 1.)
         enddo
c         if(sane_ntuple_type.eq.1)then
c            n_clust = nclust
c            call Lucite(i)
c         endif
      enddo
c      write(*,*)'Sane is Done'
      abort=.not.HEXIST(sane_ntuple_ID)
      if(abort) then
         call G_build_note(':Ntuple ID#$ does not exist',
     $        '$',sane_ntuple_ID,' ',0.,' ',err)
         call G_add_path(here,err)
      else 
         icycle=999999
         call HFNT(sane_ntuple_ID)
         if(sane_ntuple_type.eq.9) then 
           call HFNT(sane_ntuple_ID+1)
c           call HFNT(sane_ntuple_ID+2)
c           call HFNT(sane_ntuple_ID+3)
c           call HFNT(sane_ntuple_ID+4)
c           call HFNT(sane_ntuple_ID+5)
         endif
      endif
 10   CONTINUE
  
      return 
  18   write(*,*)'HELP charge error',charge2s,gbcm1_charge
       return
 19    write(*,*)'HELP Polarization error'
       return
      end

      SUBROUTINE CORRECT_RAW_TIME_SANE(RAW_TDC,CORRECTED_TDC)
      IMPLICIT NONE
      include 'sane_data_structures.cmn'
      include 'f1trigger_data_structures.cmn'
c
c     Function arguments are RAW_TDC -raw TDC value
c     and CORRECTED_TDC -Corrected by Trigger time and rolover time 
c     MAKE SURE TO Include correct parameter files
c
c
      integer*4 RAW_TDC, CORRECTED_TDC, f1trigmax
      save

c find largest value of trigger time, to check rollover
      if(TRIGGER_F1_START_TDC_COUNTER(
     >        SANE_TRIGGER_COUNTER) .gt.f1trigmax) then
        write(6,'('' SANE trigger time max='',i8)')
     >  TRIGGER_F1_START_TDC_COUNTER(
     >        SANE_TRIGGER_COUNTER)
        f1trigmax = 
     >  TRIGGER_F1_START_TDC_COUNTER(
     >        SANE_TRIGGER_COUNTER)
      endif
      if(RAW_TDC.gt.0)then
         CORRECTED_TDC =  RAW_TDC - 
     ,        TRIGGER_F1_START_TDC_COUNTER(SANE_TRIGGER_COUNTER)
c
c     Taking care of ROLOVER For positive TDC
c     
         if(CORRECTED_TDC.lt.-30000)
     ,        CORRECTED_TDC = CORRECTED_TDC+TRIGGER_F1_ROLOVER(SANE_TRIGGER_COUNTER)
         if(CORRECTED_TDC.gt.30000)
     ,        CORRECTED_TDC = CORRECTED_TDC-TRIGGER_F1_ROLOVER(SANE_TRIGGER_COUNTER)
      else
         CORRECTED_TDC =0
      endif 

      end

      subroutine NANcheck(l,did)
      IMPLICIT NONE
      integer*4 l
      integer did
      if(l.ne.l)then
         l=0
c         write(*,*)did
      endif
      end
      subroutine NANcheckF(l,did)
      IMPLICIT NONE
      real*4 l
      integer did
      if(l.ne.l)then
         l=0
c         write(*,*)did
      endif
      end
