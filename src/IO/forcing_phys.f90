      SUBROUTINE forcings_PHYS(datestring)
!---------------------------------------------------------------------
!
!                       ROUTINE DTADYN
!                     ******************
!
!  PURPOSE :
!  ---------
!     Prepares dynamics and physics fields
!     for an off-line simulation for passive tracer
!                          =======
!
!   METHOD :
!   -------
!      calculates the position of DATA to read
!      READ DATA WHEN needed (example month changement)
!      interpolates DATA IF needed
!
!----------------------------------------------------------------------
! parameters and commons
! ======================

       USE myalloc
       USE TIME_MANAGER
       use mpi
       IMPLICIT NONE

      character(LEN=17), INTENT(IN) ::  datestring

! local declarations
! ==================
      double precision :: sec,zweigh
      integer :: Before, After
      integer :: iswap



!     iswap  : indicator of swap of dynamic DATA array

       forcing_phys_partTime = MPI_WTIME()  ! cronometer-start

      sec=datestring2sec(DATEstring)
      call TimeInterpolation(sec,TC_FOR, BEFORE, AFTER, zweigh) ! 3.e-05 sec
 
      iswap  = 0

! ----------------------- INITIALISATION -------------
      IF (datestring.eq.DATESTART) then

          CALL LOAD_PHYS(TC_FOR%TimeStrings(TC_FOR%Before)) ! CALL dynrea(iperm1)


          iswap = 1
          call swap_PHYS


        CALL LOAD_PHYS(TC_FOR%TimeStrings(TC_FOR%After)) !CALL dynrea(iper)




      ENDIF





! --------------------------------------------------------
! and now what we have to DO at every time step
! --------------------------------------------------------

! check the validity of the period in memory

      if (BEFORE.ne.TC_FOR%Before) then
         TC_FOR%Before = BEFORE
         TC_FOR%After  = AFTER

         call swap_PHYS
         iswap = 1


          CALL LOAD_PHYS(TC_FOR%TimeStrings(TC_FOR%After))




          IF(lwp) WRITE (numout,*) ' dynamics DATA READ for Time = ', TC_FOR%TimeStrings(TC_FOR%After)

!      ******* LOADED NEW FRAME *************
      END IF


! compute the DATA at the given time step

      SELECT CASE (nsptint)
           CASE (0)  !  ------- no time interpolation
!      we have to initialize DATA IF we have changed the period
              IF (iswap.eq.1) THEN
                 zweigh = 1.0
                 call ACTUALIZE_PHYS(zweigh)! initialize now fields with the NEW DATA READ
              END IF

          CASE (1) ! ------------linear interpolation ---------------

             call ACTUALIZE_PHYS(zweigh)



      END SELECT


       forcing_phys_partTime = MPI_WTIME() - forcing_phys_partTime
       forcing_phys_TotTime  = forcing_phys_TotTime  + forcing_phys_partTime


      END SUBROUTINE forcings_PHYS

! ******************************************************
!     SUBROUTINE LOAD_PHYS(datestring)
!
!
! ******************************************************
       SUBROUTINE LOAD_PHYS(datestring)
! ======================
      USE calendar
      USE myalloc
      USE TIME_MANAGER

      IMPLICIT NONE

      character(LEN=17), INTENT(IN) :: datestring
      LOGICAL :: B, IS_INGV_E3T
      integer  :: jk,jj,ji
      ! LOCAL
      character(LEN=30) nomefile
      double precision ssh(jpj,jpi)
      double precision diff_e3t(jpk,jpj,jpi)
      double precision, dimension(jpj,jpi)   :: e1u_x_e2u, e1v_x_e2v, e1t_x_e2t
      double precision correction_e3t, s0,s1,s2

      nomefile='FORCINGS/U19951206-12:00:00.nc'

! Starting I/O
! U  *********************************************************
      nomefile = 'FORCINGS/U'//datestring//'.nc'
      if(lwp) write(*,'(A,I4,A,A)') "LOAD_PHYS --> I am ", myrank, " starting reading forcing fields from ", nomefile(1:30)
      call readnc_slice_float(nomefile,'vozocrtx',buf)
      udta(:,:,:,2) = buf * umask

      call EXISTVAR(nomefile,'e3u',IS_INGV_E3T)
      if (IS_INGV_E3T) then
          call readnc_slice_float(nomefile,'e3u',buf)
          e3udta(:,:,:,2) = buf*umask
      endif



! V *********************************************************
      nomefile = 'FORCINGS/V'//datestring//'.nc'
      call readnc_slice_float(nomefile,'vomecrty',buf)
      vdta(:,:,:,2) = buf*vmask
      

      if (IS_INGV_E3T) then
          call readnc_slice_float(nomefile,'e3v',buf)
          e3vdta(:,:,:,2) = buf*vmask
      endif



! W *********************************************************


      nomefile = 'FORCINGS/W'//datestring//'.nc'

      call readnc_slice_float(nomefile,'vovecrtz',buf)
      wdta(:,:,:,2) = buf * tmask

      call readnc_slice_float(nomefile,'votkeavt',buf)
      avtdta(:,:,:,2) = buf*tmask

      if (IS_INGV_E3T) then
          call readnc_slice_float(nomefile,'e3w',buf)
          e3wdta(:,:,:,2) = buf*tmask
      endif


! T *********************************************************
      nomefile = 'FORCINGS/T'//datestring//'.nc'
      call readnc_slice_float(nomefile,'votemper',buf)
      tdta(:,:,:,2) = buf*tmask

      call readnc_slice_float(nomefile,'vosaline',buf)
      sdta(:,:,:,2) = buf*tmask


      if (IS_INGV_E3T) then
          call readnc_slice_float(nomefile,'e3t',buf)
          e3tdta(:,:,:,2) = buf*tmask
      endif

    if (.not.IS_INGV_E3T) then
         call readnc_slice_float_2d(nomefile,'sossheig',buf2)
         ssh = buf2*tmask(1,:,:)

          e3t = e3t_0
          DO ji= 1,jpi
          DO jj= 1,jpj
          if (tmask(1,jj,ji).eq.1) then  ! to do the division
              correction_e3t=( 1.0 + ssh(jj,ji)/h_column(jj,ji))
              DO jk=1,mbathy(jj,ji)
                   e3t(jk,jj,ji)  = e3t_0(jk,jj,ji) * correction_e3t
              ENDDO
          endif
          ENDDO
          ENDDO

         e1u_x_e2u = e1u*e2u
         e1v_x_e2v = e1v*e2v
         e1t_x_e2t = e1t*e2t

         diff_e3t = e3t - e3t_0
         e3u = 0.0
         e3v = 0.0

         DO ji = 1,jpim1
         DO jj = 1,jpjm1
         DO jk = 1,jpk
             s0= e1t_x_e2t(jj,ji ) * diff_e3t(jk,jj,ji)
             s1= e1t_x_e2t(jj,ji+1) * diff_e3t(jk,jj,ji+1)
             s2= e1t_x_e2t(jj+1,ji) * diff_e3t(jk,jj+1,ji)
             e3u(jk,jj,ji) = 0.5*(umask(jk,jj,ji)/(e1u_x_e2u(jj,ji)) * (s0 + s1))
             e3v(jk,jj,ji) = 0.5*(vmask(jk,jj,ji)/(e1v_x_e2v(jj,ji)) * (s0 + s2))
         ENDDO
         ENDDO
         ENDDO

         DO ji = 1,jpi
         DO jj = 1,jpj
         DO jk = 1,jpk
             e3u(jk,jj,ji) = e3u_0(jk,jj,ji) + e3u(jk,jj,ji)
             e3v(jk,jj,ji) = e3v_0(jk,jj,ji) + e3v(jk,jj,ji)
         ENDDO
         ENDDO
         ENDDO



         DO ji = 1,jpi
         DO jj = 1,jpj
             e3w(1,jj,ji) = e3w_0(1,jj,ji) + diff_e3t(1,jj,ji)
         ENDDO
         ENDDO

         DO ji = 1,jpi
         DO jj = 1,jpj
         DO jk = 2,mbathy(jj,ji)
              e3w(jk,jj,ji) = e3w_0(jk,jj,ji) + 0.5*( diff_e3t(jk-1,jj,ji) + diff_e3t(jk,jj,ji))
         ENDDO
         DO jk =  mbathy(jj,ji)+1, jpk
             e3w(jk,jj,ji) = e3w_0(jk,jj,ji) + diff_e3t(jk-1,jj,ji)
         ENDDO

         ENDDO
         ENDDO

     endif ! IS_INGV_E3T





      call readnc_slice_float_2d(nomefile,'sowindsp',buf2)
      flxdta(:,:,jpwind,2) = buf2*tmask(1,:,:)
      call readnc_slice_float_2d(nomefile,'soshfldo',buf2)
      flxdta(:,:,jpqsr ,2) = buf2*tmask(1,:,:)
      flxdta(:,:,jpice ,2) = 0.
      flxdta(:,:,jpemp ,2) = 0.





!     CALL div()               ! Horizontal divergence
!     CALL wzv()               ! vertical velocity

!        could be written for OpenMP
              DO ji=1,jpi
            DO jj=1,jpj
          DO jk=1,jpk
                tn(jk,jj,ji)=tdta(jk,jj,ji,2)
                sn(jk,jj,ji)=sdta(jk,jj,ji,2)
              END DO
            END DO
          END DO


      END SUBROUTINE LOAD_PHYS

! ******************************************************
!     SUBROUTINE ACTUALIZE_PHYS(zweigh)
!     performs time interpolation
!     x(1)*(1-zweigh) + x(2)*zweigh
! ******************************************************
      SUBROUTINE ACTUALIZE_PHYS(zweigh)
         USE myalloc
         USE OPT_mem
         IMPLICIT NONE
         double precision zweigh, Umzweigh

         INTEGER jk,jj,ji,jf
         INTEGER uk, uj      ! aux variables for OpenMP

   
      Umzweigh  = 1.0 - zweigh

!!!$omp parallel default(none) private(mytid,jj,ji,uk)
!!!$omp&                       shared(jpk,jpj,jpi,jk,ub,un,udta, vb,vn,vdta,wn,wdta,avt,avtdta,tn,tdta,sn,sdta,
!!!$omp&                       zweigh,Umzweigh,tmask,umask,vmask,e3u,e3udta,e3v,e3vdta,e3t,e3tdta,e3w,e3wdta,e3t_back)
          DO ji=1,jpi
          DO jj=1,jpj
          DO uk=1,jpk
                if (umask(uk,jj,ji) .eq. 1) then
                un(uk,jj,ji)  = (Umzweigh*  udta(uk,jj,ji,1) + zweigh*  udta(uk,jj,ji,2))
                e3u(uk,jj,ji) = (Umzweigh*  e3udta(uk,jj,ji,1) + zweigh*  e3udta(uk,jj,ji,2))
                endif
          ENDDO
          ENDDO
          ENDDO

          DO ji=1,jpi
          DO jj=1,jpj
          DO uk=1,jpk
                if (vmask(uk,jj,ji) .eq. 1) then
                vn(uk,jj,ji)  = (Umzweigh*  vdta(uk,jj,ji,1) + zweigh*  vdta(uk,jj,ji,2))
                e3v(uk,jj,ji) = (Umzweigh*  e3vdta(uk,jj,ji,1) + zweigh*  e3vdta(uk,jj,ji,2))
                endif
          ENDDO
          ENDDO
          ENDDO

          DO ji=1,jpi
          DO jj=1,jpj
          DO uk=1,jpk
                if (tmask(uk,jj,ji) .eq.1) then
                 wn(uk,jj,ji) = (Umzweigh*  wdta(uk,jj,ji,1) + zweigh*  wdta(uk,jj,ji,2))
                avt(uk,jj,ji) = (Umzweigh*avtdta(uk,jj,ji,1) + zweigh*avtdta(uk,jj,ji,2))
                e3w(uk,jj,ji) = (Umzweigh*  e3wdta(uk,jj,ji,1) + zweigh*  e3wdta(uk,jj,ji,2))
                endif
          ENDDO
          ENDDO
          ENDDO
          DO ji=1,jpi
          DO jj=1,jpj
          DO uk=1,jpk
                if (tmask(uk,jj,ji) .eq.1) then
                 tn(uk,jj,ji) = (Umzweigh*  tdta(uk,jj,ji,1) + zweigh*  tdta(uk,jj,ji,2))
                 sn(uk,jj,ji) = (Umzweigh*  sdta(uk,jj,ji,1) + zweigh*  sdta(uk,jj,ji,2))
                endif
          ENDDO
          ENDDO
          ENDDO


       if (forcing_phys_initialized) then
          DO ji=1,jpi
          DO jj=1,jpj
          DO uk=1,jpk
                if (tmask(uk,jj,ji) .eq.1) then          
                e3t_back(uk,jj,ji) = e3t(uk,jj,ji)
                e3t(uk,jj,ji) = (Umzweigh*  e3tdta(uk,jj,ji,1) + zweigh*  e3tdta(uk,jj,ji,2))
                endif ! tmask
          END DO
          END DO
          END DO
       else
          DO ji=1,jpi
          DO jj=1,jpj
          DO uk=1,jpk
                if (tmask(uk,jj,ji) .eq.1) then
                e3t(uk,jj,ji) = (Umzweigh*  e3tdta(uk,jj,ji,1) + zweigh*e3tdta(uk,jj,ji,2))
                e3t_back(uk,jj,ji) = e3t(uk,jj,ji)
                endif ! tmask
          END DO
          END DO
          END DO
        forcing_phys_initialized = .TRUE.
        endif


!!!$omp parallel default(none) private(mytid,jk,uj,ji)
!!!$omp&                       shared(jpk,jpj,jpi,jj,flx,flxdta,
!!!$omp&                              vatm,freeze,emp,qsr,jpwind,jpice,jpemp,jpqsr,zweigh, Umzweigh,jpflx)

                              DO jf=1,jpflx
                        DO ji=1,jpi
                  DO uj=1,jpj

                flx(uj,ji,jf) = ( Umzweigh * flxdta(uj,ji,jf,1)+ zweigh * flxdta(uj,ji,jf,2) )
                !if(jf==3) write(*,200),ji,uj,flx(uj,ji,jf)
                        END DO
                  END DO
            END DO
!            STOP
!            200 FORMAT(' ',I4,I4,D30.23)

                  DO ji=1,jpi
            DO uj=1,jpj
                  vatm(uj,ji)   = flx(uj,ji,jpwind)
                  freeze(uj,ji) = flx(uj,ji,jpice)
                  emp(uj,ji)    = flx(uj,ji,jpemp)
                  qsr(uj,ji)    = flx(uj,ji,jpqsr)
!                 e3u(uj,ji,1)  = flx(uj,ji,8)
!                 e3v(uj,ji,1)  = flx(uj,ji,9)
!                 e3t(uj,ji,1)  = flx(uj,ji,10)
            END DO
       END DO


      END SUBROUTINE ACTUALIZE_PHYS



! *************************************************************
!     SUBROUTINE SWAP
!     copies index 2 in index 1
! **************************************************************

      SUBROUTINE swap_PHYS
         USE myalloc
         IMPLICIT NONE

                    udta(:,:,:,1) =    udta(:,:,:,2)
                  e3udta(:,:,:,1) =  e3udta(:,:,:,2)
                    vdta(:,:,:,1) =    vdta(:,:,:,2)
                  e3vdta(:,:,:,1) =  e3vdta(:,:,:,2)
                    wdta(:,:,:,1) =    wdta(:,:,:,2)
                  e3wdta(:,:,:,1) =  e3wdta(:,:,:,2)
                  avtdta(:,:,:,1) =  avtdta(:,:,:,2)
                    tdta(:,:,:,1) =    tdta(:,:,:,2)
                    sdta(:,:,:,1) =    sdta(:,:,:,2)
                  e3tdta(:,:,:,1) =  e3tdta(:,:,:,2)
                  flxdta(:,:,:,1) =  flxdta(:,:,:,2)


      END SUBROUTINE swap_PHYS
