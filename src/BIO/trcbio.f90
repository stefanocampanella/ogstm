
      SUBROUTINE trcbio
!!!---------------------------------------------------------------------
!!!
!!!                       ROUTINE trcbio
!!!                     *******************
!!!
!!!  PURPOSE :
!!!  ---------
!!!     compute the now trend due to biogeochemical processes
!!!     and add it to the general trend of passive tracers equations.
!!!
!!!    Three options:
!!!
!!!   METHOD :
!!!   -------
!!!      each now biological flux is calculated  in FUNCTION of now
!!!      concentrations of tracers.
!!!      depending on the tracer, these fluxes are sources or sinks.
!!!      the total of the sources and sinks for each tracer
!!!      is added to the general trend.
!!!
!!!        tra = tra + zf...tra - zftra...
!!!                             |         |
!!!                             |         |
!!!                          source      sink
!!!
!!!
!!!      IF 'key_trc_diabio' key is activated, the biogeochemical
!!!    trends for passive tracers are saved for futher diagnostics.
!!!
!!!      multitasked on vertical slab (jj-loop)
!!!
!!!   MODIFICATIONS:
!!!   --------------

      USE myalloc
      ! epascolo USE myalloc_mpp
      USE BIO_mem
      USE BC_mem
      USE mpi
      
      IMPLICIT NONE


!!!----------------------------------------------------------------------
!!! local declarations
!!! ==================
      logical :: sur,bot
#ifdef BFMv2
      double precision,dimension(jptra) :: a,b
      double precision,dimension(4) :: c
      double precision,dimension(jptra_dia) :: d
      double precision,dimension(10) :: er
      double precision,dimension(jptra_dia_2d) :: d2
#else
      double precision,dimension(jptra,jpk) :: a,b
      double precision,dimension(4,jpk) :: c
      double precision,dimension(jptra_dia,jpk) :: d
      double precision,dimension(10,jpk) :: er
#endif


      integer :: jk,jj,ji,jb,jn
      integer :: jtr,jtrmax,tra_idx


!!!----------------------------------------------------------------------
!!! statement functions
!!! ===================


!   | --------------|
!   | BFM MODEL CALL|
!   | --------------|

        BIOparttime = MPI_WTIME()

          surf_mask(:) = 0.
          surf_mask(1) = 1.
! -------------------------------------------------

          tra_idx = tra_matrix_gib(1)
          jtrmax=jptra

! ---------------- Fuori dai punti BFM

      ogstm_sediPI=0.
      tra_DIA    = 0.
#ifdef BFMv2
      tra_DIA_2d = 0.



      MAIN_LOOP: DO  jb = 1, NBFMPOINTS


                 ji = BFMpoints(3, jb)
                 jj = BFMpoints(2, jb)
                 jk = BFMpoints(1, jb)


                          sur = (jk .eq. 1)
                          bot = .FALSE.
                          DO jtr=1, jtrmax
                             a(jtr) = trn(jk,jj,ji,jtr) ! current biogeochemical concentrations
                          END DO
! Environmental regulating factors (er)

                          er(1)  = tn (jk,jj,ji)        ! Temperature (Celsius)
                          er(2)  = sn (jk,jj,ji)        ! Salinity PSU
                          er(3)  = rho(jk,jj,ji)        ! Density Kg/m3
                          er(4)  = ice                  ! from 0 to 1 adimensional
                          er(5)  = ogstm_co2(jj,ji)           ! CO2 Mixing Ratios (ppm)  390
                          er(6)  = xpar(jk,jj,ji)       ! PAR umoles/m2/s | Watt to umoles photons W2E=1./0.217
                          er(7)  = DAY_LENGTH(jj,ji)    ! fotoperiod expressed in hours
                          er(8)  = e3t(jk,jj,ji)        ! depth in meters of the given cell
                          er(9)  = vatm(jj,ji) * surf_mask(jk) ! wind speed (m/s)
                          er(10) = ogstm_PH(jk,jj,ji)         ! PH

                          call BFM0D_Input_EcologyDynamics(sur,bot,a,jtrmax,er)

                         call BFM0D_reset()

                         call EcologyDynamics()
                          if (sur) then
                             call BFM0D_Output_EcologyDynamics_surf(b, c, d ,d2)
                           else
                              call BFM0D_Output_EcologyDynamics(b, c, d)
                           endif

                          DO jtr=1, jtrmax
                             tra(jk,jj,ji,jtr) =tra(jk,jj,ji,jtr) +b(jtr) ! trend
                          END DO

                          DO jtr=1,4
                             ogstm_sediPI(jk,jj,ji,jtr) = c(jtr) ! BFM output of sedimentation speed (m/d)
                          END DO

                          DO jtr=1,jptra_dia -2 ! We skip the last two ppHT1 and ppHT2
                             tra_DIA(jtr,jk,jj,ji) = d(jtr) ! diagnostic
                          END DO

                          if (sur) tra_DIA_2d(:,jj,ji) = d2(:) ! diagnostic

                          ogstm_PH(jk,jj,ji)=d(pppH) ! Follows solver guess, put 8.0 if pppH is not defined

                          NPPF2(jk,jj,ji)=d(ppF04) ! Flagellate production

                END DO MAIN_LOOP
#else


      DO ji=1,jpi
      DO jj=1,jpj
      if (tmask(1,jj,ii).lt.1.0) CYCLE

      sur=.True.
                          DO jtr=1, jtrmax
                          DO jk=1,jpk
                             a(jtr,jk) = trn(jk,jj,ji,jtr) ! current biogeochemical concentrations
                          END DO
                          END DO

! Environmental regulating factors (er,:)
                          DO jk=1,jpk
                          er(1,jk)  = tn (jk,jj,ji)        ! Temperature (Celsius)
                          er(2,jk)  = sn (jk,jj,ji)        ! Salinity PSU
                          er(3,jk)  = rho(jk,jj,ji)        ! Density Kg/m3
                          er(4,jk)  = ice                  ! from 0 to 1 adimensional
                          er(5,jk)  = co2(jj,ji)           ! CO2 Mixing Ratios (ppm)  390
                          er(6,jk)  = xpar(jk,jj,ji)       ! PAR umoles/m2/s | Watt to umoles photons W2E=1./0.217
                          er(7,jk)  = DAY_LENGTH(jj,ji)    ! fotoperiod expressed in hours
                          er(8,jk)  = e3t(jk,jj,ji)        ! depth in meters of the given cell
                          er(9,jk)  = vatm(jj,ji) * surf_mask(jk) ! wind speed (m/s)
                          er(10,jk) = PH(jk,jj,ji) ! 8.1
                          ENDDO
                          call BFM1D_Input_EcologyDynamics(sur,mbathy(jj,ji),a,jtrmax,er)

                         call BFM1D_reset()

                         call EcologyDynamics()

                          call BFM1D_Output_EcologyDynamics(b, c, d)

                          DO jtr=1, jtrmax
                             tra(:,jj,ji,jtr) =tra(:,jj,ji,jtr) +b(jtr,:) ! trend
                          END DO
                          DO jtr=1,4
                             sediPI(:,jj,ji,jtr) = c(jtr,:)      ! BFM output of sedimentation speed (m/d)
                          END DO

                          DO jtr=1,jptra_dia
                             tra_DIA(:,jj,ji,jtr) = d(jtr,:) ! diagnostic
                          END DO
                          PH(:,jj,ji)=d(pppH,:) ! Follows solver guess, put 8.0 if pppH is not defined

      END DO
      END DO
#endif

                BIOparttime =  MPI_WTIME() -BIOparttime
                BIOtottime  = BIOtottime  + BIOparttime
               
      END SUBROUTINE trcbio
