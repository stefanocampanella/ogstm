      SUBROUTINE trcdmp
!---------------------------------------------------------------------
!
!                       ROUTINE trcdmp
!                     ******************
!
!  Purpose :
!  --------
!    Compute (if asked) the passive tracer trend due to a newtonian
!    damping of the tracer field towards given data field and add it
!    to the general tracer trends.
!
!   Method :
!   --------
!    Default key          : empty routine, no damping trend
!    'key_trc_dmp' defined :
!       Newtonian damping towards tdta and sdta computed and add to
!       the general tracer trends:
!                     trc = ta + restotrc * (trcdta - trcb)
!       The trend is computed either throughout the water column
!       (nlmdmptrc=0) or in area of weak vertical mixing (nlmdmptrc=1) or
!       below the well mixed layer (nlmdmptrc=2)



       USE myalloc
       USE myalloc_mpp
       USE BC_mem
       IMPLICIT NONE

!----------------------------------------------------------------------
! local declarations
! ==================

      INTEGER jk,jj,ji, jn
      INTEGER tra_idx
      INTEGER(4) jv
      INTEGER shift
      REAL(8)  ztra
      INTEGER :: mytid, ntids
#ifdef __OPENMP1
      INTEGER ::  omp_get_thread_num, omp_get_num_threads, omp_get_max_threads
      EXTERNAL :: omp_get_thread_num, omp_get_num_threads, omp_get_max_threads
#endif

#ifdef __OPENMP1
      ntids = omp_get_max_threads() ! take the number of threads
      mytid = -1000000
#else
      ntids = 1
      mytid = 0
#endif


      trcdmpparttime = MPI_WTIME() ! cronometer-start


! Boundary conditions fo Gib area
       IF (Gsize .NE. 0) THEN
         DO jn=1, jn_gib, ntids
!!!$omp   parallel default(none) private(mytid,jk,jj,ji,ztra,jv,tra_idx)
!!!$omp&                         shared(jn,tra,trb,gib, Gsize, gib_ridxt,restotr,tra_matrix_gib,jn_gib)
#ifdef __OPENMP1
        mytid = omp_get_thread_num()  ! take the thread ID
#endif
      IF( mytid + jn <= jn_gib ) THEN

          tra_idx=tra_matrix_gib(jn+mytid)
          DO jv=1, Gsize
             ji = gib_ridxt(2,jv)
             jj = gib_ridxt(3,jv)
             jk = gib_ridxt(4,jv)

             ztra = restotr(jk,jj,ji,tra_idx) * ( gib(jv,jn+mytid)-trb(jk,jj,ji,tra_idx) )

             tra(jk,jj,ji,tra_idx) = tra(jk,jj,ji,tra_idx) + ztra
          ENDDO
      ENDIF
!!!$omp end parallel

         ENDDO

       ENDIF


! Boundary conditions for rivers
       IF (Rsize .NE. 0) THEN
         DO jn=1, jn_riv,ntids
!!!$omp   parallel default(none) private(mytid,jk,jj,ji,jv,tra_idx,shift)
!!!$omp&                         shared(jn,tra, riv,Rsize, riv_ridxt,tra_matrix_riv,jn_riv,tra_DIA)
#ifdef __OPENMP1
        mytid = omp_get_thread_num()  ! take the thread ID
#endif
        IF( mytid +jn <= jn_riv ) THEN
          tra_idx=tra_matrix_riv(jn+mytid)

          DO jv=1, Rsize

             ji = riv_ridxt(2,jv)
             jj = riv_ridxt(3,jv)
             jk = riv_ridxt(4,jv)
            tra(jk,jj,ji,tra_idx) = tra(jk,jj,ji,tra_idx) + riv(jv,jn+mytid)
          ENDDO


        ENDIF
!!!$omp end parallel


         ENDDO


       ENDIF


! Boundary conditions for Atmosphere
       IF (Asize .NE. 0) THEN
         DO jn=1, jn_atm, ntids
!!!$omp   parallel default(none) private(mytid,jk,jj,ji,jv,tra_idx,shift)
!!!$omp&                         shared(jn,tra,atm,Asize, atm_ridxt,tra_matrix_atm,jn_atm,tra_DIA)
#ifdef __OPENMP1
        mytid = omp_get_thread_num()  ! take the thread ID
#endif

      IF( mytid + jn <= jn_atm ) THEN
          tra_idx=tra_matrix_atm(jn+mytid)
        DO jj=1,jpj
          DO ji=1,jpi
          ! DO jv=1, Asize
          !
          !    ji = atm_ridxt(2,jv)
          !    jj = atm_ridxt(3,jv)
          !    jk = atm_ridxt(4,jv)
        tra(1,ji,jj,tra_idx) = tra(1,ji,jj,tra_idx) + atm(ji,jj,jn+mytid)
         ENDDO
         ENDDO

      ENDIF
!!!$omp end parallel


         ENDDO

       ENDIF




       trcdmpparttime = MPI_WTIME() - trcdmpparttime ! cronometer-stop
       trcdmptottime  = trcdmptottime + trcdmpparttime



      END SUBROUTINE trcdmp