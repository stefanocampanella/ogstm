      SUBROUTINE diadump(datemean,datefrom,dateTo,FREQ_GROUP)
!     ******************
      USE calendar
      USE myalloc
      USE IO_mem
      USE FN_mem
      USE TIME_MANAGER
#ifdef key_mpp
      USE myalloc_mpp
#endif

      IMPLICIT NONE


      CHARACTER(LEN=17), INTENT(IN) :: datemean, dateFrom, dateTo
      INTEGER, INTENT(IN) :: FREQ_GROUP
      INTEGER jk,jj,ji, jn, jn_high
      INTEGER ind

      CHARACTER(LEN=42) forcing_file
      CHARACTER(LEN=60) bkpname
      CHARACTER(LEN=11) DIR
      logical IsBackup
      integer ave_counter


      CHARACTER(LEN=56) dia_file_nc
      CHARACTER(LEN=20)  var

      INTEGER idrank, ierr, istart, jstart, iPe, iPd, jPe, jPd, status(MPI_STATUS_SIZE)
      INTEGER irange, jrange
      INTEGER totistart, totiend, relistart, reliend
      INTEGER totjstart, totjend, reljstart, reljend


      call mppsync()
! ----------------------------------------
      IsBackup =  (datemean.eq.dateTo)
      if (lwp) write(*,*) 'diadump IsBackup = ',IsBackup, ' group ' ,FREQ_GROUP
! ----------------------------------------
      bkpname  = 'ave.20111231-15:30:00.N1p.nc.bkp'
      if (IsBackup) then
         forcing_file   = 'AVE_PHYS/ave.'//datemean//'.phys.nc.bkp'
      else
         forcing_file   = 'AVE_PHYS/ave.'//datemean//'.phys.nc'
      endif


      SELECT CASE (FREQ_GROUP)
        CASE (1) 
       ave_counter=ave_counter_1 
       DIR='AVE_FREQ_1/'
        CASE (2) 
       ave_counter=ave_counter_2 
       DIR='AVE_FREQ_2/'
      END SELECT


!      PHYSICS FIRST!!
      if ( freq_ave_phys.eq.FREQ_GROUP) then
      ! *************** START COLLECTING DATA *****************************
      if (rank == 0) then                    ! IF LABEL 1


! ******* rank 0 sets indexes of tot matrix where to place its own part

          iPd    = nldi
          iPe    = nlei
          jPd    = nldj
          jPe    = nlej
          istart = nimpp
          jstart = njmpp
          irange    = iPe - iPd + 1
          jrange    = jPe - jPd + 1
          totistart = istart + iPd - 1 
       totiend   = totistart + irange - 1
          totjstart = jstart + jPd - 1 
       totjend   = totjstart + jrange - 1
          relistart = 1 + iPd - 1      
       reliend   = relistart + irange - 1
          reljstart = 1 + jPd - 1      
       reljend   = reljstart + jrange - 1

          totsnIO  (totistart:totiend, totjstart:totjend,:) = snIO    (relistart:reliend, reljstart:reljend, :)
          tottnIO  (totistart:totiend, totjstart:totjend,:) = tnIO    (relistart:reliend, reljstart:reljend, :)
          totvatmIO(totistart:totiend, totjstart:totjend)   = vatmIO  (relistart:reliend, reljstart:reljend)
          totempIO (totistart:totiend, totjstart:totjend)   = empIO   (relistart:reliend, reljstart:reljend)
          totqsrIO (totistart:totiend, totjstart:totjend)   = qsrIO   (relistart:reliend, reljstart:reljend)
          totunIO  (totistart:totiend, totjstart:totjend,:) = unIO    (relistart:reliend, reljstart:reljend, :)
          totvnIO  (totistart:totiend, totjstart:totjend,:) = vnIO    (relistart:reliend, reljstart:reljend, :)
          totwnIO  (totistart:totiend, totjstart:totjend,:) = wnIO    (relistart:reliend, reljstart:reljend, :)
          totavtIO (totistart:totiend, totjstart:totjend,:) = avtIO   (relistart:reliend, reljstart:reljend, :)
          tote3tIO (totistart:totiend, totjstart:totjend,:) = e3tIO   (relistart:reliend, reljstart:reljend, :)

          do idrank = 1, mpi_size_comm-1
! **************  rank 0 is receiving from the others their buffer  ****

              call MPI_RECV(jpi_rec    , 1,                 mpi_integer, idrank, 1,mpi_comm_world, status, ierr) !* first info to know where idrank is working
              call MPI_RECV(jpj_rec    , 1,                 mpi_integer, idrank, 2,mpi_comm_world, status, ierr)
              call MPI_RECV(istart     , 1,                 mpi_integer, idrank, 3,mpi_comm_world, status, ierr)
              call MPI_RECV(jstart     , 1,                 mpi_integer, idrank, 4,mpi_comm_world, status, ierr)
              call MPI_RECV(iPe        , 1,                 mpi_integer, idrank, 5,mpi_comm_world, status, ierr)
              call MPI_RECV(jPe        , 1,                 mpi_integer, idrank, 6,mpi_comm_world, status, ierr)
              call MPI_RECV(iPd        , 1,                 mpi_integer, idrank, 7,mpi_comm_world, status, ierr)
              call MPI_RECV(jPd        , 1                 ,mpi_integer, idrank, 8,mpi_comm_world, status, ierr)


      call MPI_RECV(buffsn  ,jpi_rec*jpj_rec*jpk          ,mpi_real8,idrank, 11,mpi_comm_world, status, ierr)
      call MPI_RECV(bufftn  ,jpi_rec*jpj_rec*jpk          ,mpi_real8,idrank, 12,mpi_comm_world, status, ierr)
      call MPI_RECV(buffvatm,jpi_rec*jpj_rec              ,mpi_real8,idrank, 13,mpi_comm_world, status, ierr)
      call MPI_RECV(buffemp ,jpi_rec*jpj_rec              ,mpi_real8,idrank, 14,mpi_comm_world, status, ierr)
      call MPI_RECV(buffqsr ,jpi_rec*jpj_rec              ,mpi_real8,idrank, 15,mpi_comm_world, status, ierr)
      call MPI_RECV(buffun  ,jpi_rec*jpj_rec*jpk          ,mpi_real8,idrank, 16,mpi_comm_world, status, ierr)
      call MPI_RECV(buffvn  ,jpi_rec*jpj_rec*jpk          ,mpi_real8,idrank, 17,mpi_comm_world, status, ierr)
      call MPI_RECV(buffwn  ,jpi_rec*jpj_rec*jpk          ,mpi_real8,idrank, 18,mpi_comm_world, status, ierr)
      call MPI_RECV(buffavt ,jpi_rec*jpj_rec*jpk          ,mpi_real8,idrank, 19,mpi_comm_world, status, ierr)
      call MPI_RECV(buffe3t ,jpi_rec*jpj_rec*jpk          ,mpi_real8,idrank, 19,mpi_comm_world, status, ierr)

! ******* rank 0 sets indexes of tot matrix where to place buffers of idrank
              irange    = iPe - iPd + 1
              jrange    = jPe - jPd + 1
              totistart = istart + iPd - 1 
       totiend   = totistart + irange - 1
              totjstart = jstart + jPd - 1 
       totjend   = totjstart + jrange - 1
              relistart = 1 + iPd - 1      
       reliend   = relistart + irange - 1
              reljstart = 1 + jPd - 1      
       reljend   = reljstart + jrange - 1

              do jk =1 , jpk ! 3d vars
               do jj =totjstart,totjend
                 do ji =totistart,totiend
                     ind = (ji-totistart+ relistart )+ (jj-totjstart+ reljstart-1)*jpi_rec+(jk-1)*jpj_rec*jpi_rec
                     totsnIO (jk,jj,ji)= buffsn (ind)
                     tottnIO (jk,jj,ji)= bufftn (ind)
                     totunIO (jk,jj,ji)= buffun (ind)
                     totvnIO (jk,jj,ji)= buffvn (ind)
                     totwnIO (jk,jj,ji)= buffwn (ind)
                     totavtIO(jk,jj,ji)= buffavt(ind)
                     tote3tIO(jk,jj,ji)= buffe3t(ind)
                 enddo
                enddo
               enddo


               do jj =totjstart,totjend ! and 2d vars
                 do ji =totistart,totiend
                  ind = (ji-totistart+ relistart )+ (jj-totjstart+ reljstart -1)*jpi_rec
                  totvatmIO (ji,jj)= buffvatm(ind)
                  totempIO  (ji,jj)= buffemp (ind)
                  totqsrIO  (ji,jj)= buffqsr (ind)
             enddo
            enddo

          enddo !idrank = 1, size-1


      else  ! IF LABEL 1,  if(rank == 0)


           do jk =1 , jpk
            do jj =1 , jpj
             do ji =1 , jpi
                   ind         =  ji + jpi * (jj-1) + jpi * jpj *(jk-1)
                   buffsn (ind)= snIO (jk,jj,ji)
                   bufftn (ind)= tnIO (jk,jj,ji)
                   buffun (ind)= unIO (jk,jj,ji)
                   buffvn (ind)= vnIO (jk,jj,ji)
                   buffwn (ind)= wnIO (jk,jj,ji)
                   buffavt(ind)= avtIO(jk,jj,ji)
                   buffe3t(ind)= e3tIO(jk,jj,ji)
              enddo
             enddo
            enddo

            do jj =1 , jpj
             do ji =1 , jpi
               ind           = ji + jpi * (jj-1)
               buffvatm (ind)= vatmIO(ji,jj)
               buffemp  (ind)= empIO (ji,jj)
               buffqsr  (ind)= qsrIO (ji,jj)
              enddo
             enddo


              call MPI_SEND(jpi  , 1,mpi_integer, 0, 1, mpi_comm_world,ierr)
              call MPI_SEND(jpj  , 1,mpi_integer, 0, 2, mpi_comm_world,ierr)
              call MPI_SEND(nimpp, 1,mpi_integer, 0, 3, mpi_comm_world,ierr)
              call MPI_SEND(njmpp, 1,mpi_integer, 0, 4, mpi_comm_world,ierr)
              call MPI_SEND(nlei , 1,mpi_integer, 0, 5, mpi_comm_world,ierr)
              call MPI_SEND(nlej , 1,mpi_integer, 0, 6, mpi_comm_world,ierr)
              call MPI_SEND(nldi , 1,mpi_integer, 0, 7, mpi_comm_world,ierr)
              call MPI_SEND(nldj , 1,mpi_integer, 0, 8, mpi_comm_world,ierr)

           call MPI_SEND(buffsn  , jpk*jpj*jpi  ,mpi_real8, 0, 11, mpi_comm_world,ierr)
           call MPI_SEND(bufftn  , jpk*jpj*jpi  ,mpi_real8, 0, 12, mpi_comm_world,ierr)
           call MPI_SEND(buffvatm, jpi*jpj      ,mpi_real8, 0, 13, mpi_comm_world,ierr)
           call MPI_SEND(buffemp , jpi*jpj      ,mpi_real8, 0, 14, mpi_comm_world,ierr)
           call MPI_SEND(buffqsr , jpi*jpj      ,mpi_real8, 0, 15, mpi_comm_world,ierr)
           call MPI_SEND(buffun  , jpk*jpj*jpi  ,mpi_real8, 0, 16, mpi_comm_world,ierr)
           call MPI_SEND(buffvn  , jpk*jpj*jpi  ,mpi_real8, 0, 17, mpi_comm_world,ierr)
           call MPI_SEND(buffwn  , jpk*jpj*jpi  ,mpi_real8, 0, 18, mpi_comm_world,ierr)
           call MPI_SEND(buffavt , jpk*jpj*jpi  ,mpi_real8, 0, 19, mpi_comm_world,ierr)
           call MPI_SEND(buffe3t , jpk*jpj*jpi  ,mpi_real8, 0, 19, mpi_comm_world,ierr)




      endif ! IF LABEL 1, if(rank == 0)
!************* END COLLECTING DATA  *****************

! *********** START WRITING **************************

      if(rank == 0) then ! IF LABEL 4,
         if (IsBackup) then

            call PhysDump_bkp(forcing_file, datefrom, dateTo,ave_counter)
          else
            call PhysDump(forcing_file, datefrom, dateTo)
         endif
      endif

      endif !if ( freq_ave_phys.eq.FREQ_GROUP)



      jn_high = 0

! ******************  DIAGNOSTIC OUTPUT   2D *******************
      DO jn = 1, JPTRA_DIA_2D

          if (.not.is_time_to_save(jn,FREQ_GROUP,2)) CYCLE
          if (FREQ_GROUP.eq.1) jn_high = jn_high+1
      if (rank == 0) then
  ! ******* rank 0 sets indexes of tot matrix where to place its own part

             iPd    = nldi
             iPe    = nlei
             jPd    = nldj
             jPe    = nlej
             istart = nimpp
             jstart = njmpp
             irange    = iPe - iPd + 1
             jrange    = jPe - jPd + 1
             totistart = istart + iPd - 1 
       totiend   = totistart + irange - 1
             totjstart = jstart + jPd - 1 
       totjend   = totjstart + jrange - 1
             relistart = 1 + iPd - 1      
       reliend   = relistart + irange - 1
             reljstart = 1 + jPd - 1      
       reljend   = reljstart + jrange - 1

              if (FREQ_GROUP.eq.1) then
              tottrnIO2d (totistart:totiend, totjstart:totjend) = tra_DIA_2d_IO_HIGH(relistart:reliend,reljstart:reljend,jn_high)
              else
              tottrnIO2d (totistart:totiend, totjstart:totjend) = tra_DIA_2d_IO(     relistart:reliend,reljstart:reljend,jn)
              endif

             do idrank = 1, mpi_size_comm-1
! **************  rank 0 is receiving from the others their buffer  ****

                call MPI_RECV(jpi_rec    , 1,                 mpi_integer, idrank, 32,mpi_comm_world, status, ierr) !* first info to know where idrank is working
                call MPI_RECV(jpj_rec    , 1,                 mpi_integer, idrank, 33,mpi_comm_world, status, ierr)
                call MPI_RECV(istart     , 1,                 mpi_integer, idrank, 34,mpi_comm_world, status, ierr)
                call MPI_RECV(jstart     , 1,                 mpi_integer, idrank, 35,mpi_comm_world, status, ierr)
                call MPI_RECV(iPe        , 1,                 mpi_integer, idrank, 36,mpi_comm_world, status, ierr)
                call MPI_RECV(jPe        , 1,                 mpi_integer, idrank, 37,mpi_comm_world, status, ierr)
                call MPI_RECV(iPd        , 1,                 mpi_integer, idrank, 38,mpi_comm_world, status, ierr)
                call MPI_RECV(jPd        , 1                 ,mpi_integer, idrank, 39,mpi_comm_world, status, ierr)

                call MPI_RECV(buffDIA2d,jpi_rec*jpj_rec      ,mpi_real8,idrank, 40,mpi_comm_world, status, ierr)

! ******* rank 0 sets indexes of tot matrix where to place buffers of idrank
                irange    = iPe - iPd + 1
                jrange    = jPe - jPd + 1
                totistart = istart + iPd - 1 
       totiend   = totistart + irange - 1
                totjstart = jstart + jPd - 1 
       totjend   = totjstart + jrange - 1
                relistart = 1 + iPd - 1      
       reliend   = relistart + irange - 1
                reljstart = 1 + jPd - 1      
       reljend   = reljstart + jrange - 1

                do jj =totjstart,totjend ! only 2d vars
                 do ji =totistart,totiend
                  ind = (ji-totistart+ relistart )+ (jj-totjstart+ reljstart -1)*jpi_rec
                  tottrnIO2d (ji,jj)= buffDIA2d(ind)
                 enddo
                enddo

             enddo !idrank = 1, size-1

      ELSE ! ranks 1 --> size-1


      if (FREQ_GROUP.eq.2) then
            do jj =1 , jpj
             do ji =1 , jpi
               ind           = ji + jpi * (jj-1)
               buffDIA2d (ind)= tra_DIA_2d_IO(ji,jj,jn)
              enddo
             enddo
      else
            do jj =1 , jpj
             do ji =1 , jpi
               ind           = ji + jpi * (jj-1)
               buffDIA2d (ind)= tra_DIA_2d_IO_high(ji,jj,jn_high)
              enddo
             enddo
      endif

              call MPI_SEND(jpi  , 1,mpi_integer, 0, 32, mpi_comm_world,ierr)
              call MPI_SEND(jpj  , 1,mpi_integer, 0, 33, mpi_comm_world,ierr)
              call MPI_SEND(nimpp, 1,mpi_integer, 0, 34, mpi_comm_world,ierr)
              call MPI_SEND(njmpp, 1,mpi_integer, 0, 35, mpi_comm_world,ierr)
              call MPI_SEND(nlei , 1,mpi_integer, 0, 36, mpi_comm_world,ierr)
              call MPI_SEND(nlej , 1,mpi_integer, 0, 37, mpi_comm_world,ierr)
              call MPI_SEND(nldi , 1,mpi_integer, 0, 38, mpi_comm_world,ierr)
              call MPI_SEND(nldj , 1,mpi_integer, 0, 39, mpi_comm_world,ierr)

             call MPI_SEND(buffDIA2d, jpi*jpj   ,mpi_real8, 0, 40, mpi_comm_world,ierr)

      ENDIF

      if (rank == 0) then
              var        =  dianm_2d(jn)
              bkpname     = DIR//'ave.'//datemean//'.'//trim(var)//'.nc.bkp'
              dia_file_nc = DIR//'ave.'//datemean//'.'//trim(var)//'.nc'

              if (IsBackup) then
                 !write(*,*) "trcdia ave_counter --> ", bkpname, ave_counter
                 CALL WRITE_AVE_2d_BKP(bkpname,var,datefrom, dateTo,tottrnIO2d, ave_counter)
      
              else
                 d2f2d = REAL(tottrnIO2d(:,:),4)
                 CALL WRITE_AVE_2d(dia_file_nc,var,datefrom,dateTo, d2f2d)
      

              endif
      end if ! if(rank == 0)

         if (.not.IsBackup) then
             if (FREQ_GROUP.eq.2) then
                tra_DIA_2d_IO(:,:,jn) = 0.
              else
                tra_DIA_2d_IO_HIGH(:,:,jn_high) = 0.
              endif
          endif

      ENDDO ! on jn


      jn_high = 0
! ******************  3D DIAGNOSTIC OUTPUT   *******************
      DO jn =1 , jptra_dia

          if (.not.is_time_to_save(jn,FREQ_GROUP,3)) CYCLE
          if (FREQ_GROUP.eq.1) jn_high = jn_high+1

          if (rank == 0) then                    ! IF LABEL 1


! ******* rank 0 sets indexes of tot matrix where to place its own part

             iPd    = nldi
             iPe    = nlei
             jPd    = nldj
             jPe    = nlej
             istart = nimpp
             jstart = njmpp
             irange    = iPe - iPd + 1
             jrange    = jPe - jPd + 1
             totistart = istart + iPd - 1 
      totiend   = totistart + irange - 1
             totjstart = jstart + jPd - 1 
       totjend   = totjstart + jrange - 1
             relistart = 1 + iPd - 1      
       reliend   = relistart + irange - 1
             reljstart = 1 + jPd - 1      
       reljend   = reljstart + jrange - 1

      if (FREQ_GROUP.eq.1) then
      tottrnIO (totistart:totiend, totjstart:totjend,:) = tra_DIA_IO_HIGH(relistart:reliend,reljstart:reljend, :,jn_high)
      else
      tottrnIO (totistart:totiend, totjstart:totjend,:) = tra_DIA_IO(relistart:reliend, reljstart:reljend, :,jn) ! diagnostic from reaction model
      endif
             do idrank = 1, mpi_size_comm-1
! **************  rank 0 is receiving from the others their buffer  ****

                call MPI_RECV(jpi_rec    , 1,                 mpi_integer, idrank, 22,mpi_comm_world, status, ierr) !* first info to know where idrank is working
                call MPI_RECV(jpj_rec    , 1,                 mpi_integer, idrank, 23,mpi_comm_world, status, ierr)
                call MPI_RECV(istart     , 1,                 mpi_integer, idrank, 24,mpi_comm_world, status, ierr)
                call MPI_RECV(jstart     , 1,                 mpi_integer, idrank, 25,mpi_comm_world, status, ierr)
                call MPI_RECV(iPe        , 1,                 mpi_integer, idrank, 26,mpi_comm_world, status, ierr)
                call MPI_RECV(jPe        , 1,                 mpi_integer, idrank, 27,mpi_comm_world, status, ierr)
                call MPI_RECV(iPd        , 1,                 mpi_integer, idrank, 28,mpi_comm_world, status, ierr)
                call MPI_RECV(jPd        , 1                 ,mpi_integer, idrank, 29,mpi_comm_world, status, ierr)

                call MPI_RECV(buffDIA  ,jpi_rec*jpj_rec*jpk*jptra_dia,mpi_real8,idrank, 30,mpi_comm_world, status, ierr)

! ******* rank 0 sets indexes of tot matrix where to place buffers of idrank
                irange    = iPe - iPd + 1
                jrange    = jPe - jPd + 1
                totistart = istart + iPd - 1 
       totiend   = totistart + irange - 1
                totjstart = jstart + jPd - 1 
       totjend   = totjstart + jrange - 1
                relistart = 1 + iPd - 1      
       reliend   = relistart + irange - 1
                reljstart = 1 + jPd - 1      
       reljend   = reljstart + jrange - 1


                do jk =1 , jpk ! 3d vars
                     do jj =totjstart,totjend
                        do ji =totistart,totiend
                           ind = (ji-totistart+ relistart )+ (jj-totjstart+ reljstart-1)*jpi_rec+(jk-1)*jpj_rec*jpi_rec
                           tottrnIO(jk,jj,ji)= buffDIA (ind)
                        enddo
                     enddo
                  enddo


             enddo !idrank = 1, size-1


          else  ! IF LABEL 1,  if(rank == 0)

      if (FREQ_GROUP.eq.2) then
            do jk =1, jpk
             do jj =1 , jpj
              do ji =1 , jpi
                  ind         =  ji + jpi * (jj-1) + jpi * jpj *(jk-1)
                  buffDIA(ind) = tra_DIA_IO(jk,jj,ji,jn)
              enddo
             enddo
            enddo
      else
            do jk =1, jpk
             do jj =1 , jpj
              do ji =1 , jpi
                  ind         =  ji + jpi * (jj-1) + jpi * jpj *(jk-1)
                  buffDIA(ind) = tra_DIA_IO_HIGH(jk,jj,ji,jn_high)
              enddo
             enddo
            enddo
      endif



              call MPI_SEND(jpi  , 1,mpi_integer, 0, 22, mpi_comm_world,ierr)
              call MPI_SEND(jpj  , 1,mpi_integer, 0, 23, mpi_comm_world,ierr)
              call MPI_SEND(nimpp, 1,mpi_integer, 0, 24, mpi_comm_world,ierr)
              call MPI_SEND(njmpp, 1,mpi_integer, 0, 25, mpi_comm_world,ierr)
              call MPI_SEND(nlei , 1,mpi_integer, 0, 26, mpi_comm_world,ierr)
              call MPI_SEND(nlej , 1,mpi_integer, 0, 27, mpi_comm_world,ierr)
              call MPI_SEND(nldi , 1,mpi_integer, 0, 28, mpi_comm_world,ierr)
              call MPI_SEND(nldj , 1,mpi_integer, 0, 29, mpi_comm_world,ierr)

              call MPI_SEND(buffDIA  , jpk*jpj*jpi,mpi_real8, 0, 30, mpi_comm_world,ierr)



      endif ! IF LABEL 1, if(rank == 0)
!************* END COLLECTING DATA  *****************

! *********** START WRITING **************************

      if (rank == 0) then
              var        =  dianm(jn)
              bkpname     = DIR//'ave.'//datemean//'.'//trim(var)//'.nc.bkp'
              dia_file_nc = DIR//'ave.'//datemean//'.'//trim(var)//'.nc'

              if (IsBackup) then
                 !write(*,*) "trcdia ave_counter --> ", bkpname, ave_counter
                 CALL WRITE_AVE_BKP(bkpname,var,datefrom, dateTo,tottrnIO(:,:,:),ave_counter)
      
              else
                 d2f3d = REAL(tottrnIO(:,:,:),4)
                 CALL WRITE_AVE(dia_file_nc,var,datefrom,dateTo, d2f3d)
      

              endif


      end if ! IF LABEL 4  if(rank == 0)
         if (.not.IsBackup) then
             if (FREQ_GROUP.eq.2) then
                tra_DIA_IO(:,:,:,jn) = 0.
              else
                tra_DIA_IO_HIGH(:,:,:,jn_high) = 0.
              endif
          endif
      enddo  ! loop in jn

      if ((.not.IsBackup).and.( freq_ave_phys.eq.FREQ_GROUP) ) then

          snIO     = 0.
          tnIO     = 0.
          vatmIO   = 0.
          empIO    = 0.
          qsrIO    = 0.
          unIO     = 0.
          vnIO     = 0.
          wnIO     = 0.
          avtIO    = 0.
      endif


      CONTAINS

      LOGICAL FUNCTION IS_TIME_TO_SAVE(jn,FREQ_GROUP,ndims)
      IMPLICIT NONE

      integer jn, FREQ_GROUP,ndims

      IF (FREQ_GROUP.eq.2) then
         IS_TIME_TO_SAVE = .true.
      ELSE
        IS_TIME_TO_SAVE = .false.
        IF (ndims==3) then
            IF (diahf(jn).eq.1)   IS_TIME_TO_SAVE = .true.
        ELSE
           IF (diahf_2d(jn).eq.1) IS_TIME_TO_SAVE = .true.
        ENDIF
      ENDIF
      END FUNCTION IS_TIME_TO_SAVE

      end SUBROUTINE diadump