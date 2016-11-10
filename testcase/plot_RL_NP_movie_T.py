# plotting Tilman diagram

import os,sys, getopt
import glob
import datetime
import numpy  as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import scipy.io.netcdf as NC
from matplotlib.lines import Line2D
import matplotlib.animation as animation


def compute_R2(mydata,depth,i,mu,loss,bioC,bioN,sC,dC,alphaN,Q):
    if depth == 0:
    	aa     = (mydata[i,depth][loss] - mydata[i,depth+1][sC] - mydata[i,depth+1][dC]) /mydata[i,depth][bioC]
    	bb     = mydata[i,depth][bioN]/mydata[i,depth][bioC]
    else:
    	aa     = (mydata[i,depth][loss] + mydata[i,depth][sC] + mydata[i,depth][dC] - mydata[i,depth+1][sC] + mydata[i,depth+1][dC] ) /mydata[i,depth][bioC]
    	bb     = mydata[i,depth][bioN]/mydata[i,depth][bioC]
       
    return  (aa*bb)/alphaN

def plot_RL_NP_movie_T(test):
#   Domain paramters
    jpi=test['jpi'];
    jpj=test['jpj'];
    jpk=test['jpk'];
    time = 1
    maskfile=test['Dir'] + '/meshmask.nc'

    M=NC.netcdf_file(maskfile,"r")

    Lon     =  M.variables['glamt'].data[0,0,:,:].copy()
    Lat     =  M.variables['gphit'].data[0,0,:,:].copy()
    gdept   =  M.variables['gdept'].data[0,:,0,0].copy()
    gdepw   =  M.variables['gdepw'].data[0,:,0,0].copy()
    e1t     =  M.variables['e1t'].data[0,0,1,1].copy() 
    e2t     =  M.variables['e2t'].data[0,0,1,1].copy() 
    SURF    =  e1t * e2t

    M.close()

#define derived type to store informations
    mydtype = [('N1p','f4')    ,('N3n','f4')    ,('N4n','f4'),
               ('P1c','f4')    ,('P2c','f4')    ,('P3c','f4')    ,('P4c','f4'), ('B1c','f4'),
               ('P1p','f4')    ,('P2p','f4')    ,('P3p','f4')    ,('P4p','f4'), ('B1p','f4'),
               ('P1n','f4')    ,('P2n','f4')    ,('P3n','f4')    ,('P4n','f4'), ('B1n','f4'),
               ('ruPPY1c','f4'),('ruPPY2c','f4'),('ruPPY3c','f4'),('ruPPY4c','f4'), ('ruPBAc','f4'),
               ('loPPY1c','f4'),('loPPY2c','f4'),('loPPY3c','f4'),('loPPY4c','f4'), ('loBAc','f4'),          
               ('sP1c','f4'),('sP2c','f4'),('sP3c','f4'),('sP4c','f4'), ('sB1c','f4'), 
               ('dP1c','f4'),('dP2c','f4'),('dP3c','f4'),('dP4c','f4'), ('dB1c','f4')]          

    filename      = 'POSTPROC/' + test['Area'] + '.nc'
    filename_dia  = 'POSTPROC/' + test['Area'] + '_dia.nc'
    filename_flux = 'POSTPROC/' + test['Area'] + '_flux.nc'

    M       = NC.netcdf_file(filename,"r",mmap=False)
    aux     = (M.variables[mydtype[0][0]].data[:,:]).copy()

    ntime= aux.shape[0]
    jpk  = aux.shape[1] 

    M_dia   = NC.netcdf_file(filename_dia,"r",mmap=False)

    M_flux  = NC.netcdf_file(filename_flux,"r",mmap=False)

    mydata=np.zeros((ntime,jpk),dtype=mydtype)


    for var in mydata.dtype.names[0:18]:
       mydata[:,:][var]=M.variables[var].data[:,:].copy()
    for var in mydata.dtype.names[18:28]:
       mydata[:,:][var]=M_dia.variables[var].data[:,:].copy()
    for var in mydata.dtype.names[28:33]:
       mydata[:,:399][var]=M_flux.variables[var[1:]].data[:,:,3].copy()/SURF # sinking terms
    for var in mydata.dtype.names[33:]:
       mydata[:,:399][var]=M_flux.variables[var[1:]].data[:,:,6].copy()/SURF # diffusive terms

    alpha_p=[0.0025, 0.0025, 0.0025, 0.0025,0.0025];#m3/mgC/d
    alpha_n=[0.025, 0.025, 0.25, 0.025,0.0025];#m3/mgC/d

    Qpcmin =[1.80e-4,   1.80e-4,  1.80e-4, 4.29e-4, 0.00095];#mmolP/mgC 
    Qncmin =[4.193e-3, 4.193e-3, 4.193e-3, 0.00687, 0.0085];#mmolN/mgC 

#   depth=getDepthIndex(nav_lev, 0.)
# R --> PO4 
    rp  = np.zeros((5,20),dtype='float32')
    rn  = np.zeros((5,20),dtype='float32')
    Qpc = np.zeros((4),dtype='float32')
    Qnc = np.zeros((4),dtype='float32')
    
#   fileout="POSTPROC/MOVIE/TIL" + test['Area'] + ".log"
#   f = open(fileout, 'wb')

#   for d,depth in enumerate(np.arange(0,100,5)):

#      rp[0,d] =  max(0.,compute_R2(mydata,depth,'ruPPY1c','loPPY1c','P1c','P1p','sP1c','dP1c',alpha_p[0],Qpcmin[0]))
#      rp[1,d] =  max(0.,compute_R2(mydata,depth,'ruPPY2c','loPPY2c','P2c','P2p','sP2c','dP2c',alpha_p[1],Qpcmin[1]))
#      rp[2,d] =  max(0.,compute_R2(mydata,depth,'ruPPY3c','loPPY3c','P3c','P3p','sP3c','dP3c',alpha_p[2],Qpcmin[2]))
#      rp[3,d] =  max(0.,compute_R2(mydata,depth,'ruPPY4c','loPPY4c','P4c','P4p','sP4c','dP4c',alpha_p[3],Qpcmin[3]))
#      rp[4,d] =  max(0.,compute_R2(mydata,depth,'ruPBAc',  'loBAc','B1c','B1p' ,'sB1c','dB1c',alpha_p[4],Qpcmin[4]))

#      rn[0,d] =  max(0.,compute_R2(mydata,depth,'ruPPY1c','loPPY1c','P1c','P1n','sP1c','dP1c',alpha_n[0],Qncmin[0]))
#      rn[1,d] =  max(0.,compute_R2(mydata,depth,'ruPPY2c','loPPY2c','P2c','P2n','sP2c','dP2c',alpha_n[1],Qncmin[1]))
#      rn[2,d] =  max(0.,compute_R2(mydata,depth,'ruPPY3c','loPPY3c','P3c','P3n','sP3c','dP3c',alpha_n[2],Qncmin[2]))
#      rn[3,d] =  max(0.,compute_R2(mydata,depth,'ruPPY4c','loPPY4c','P4c','P4n','sP4c','dP4c',alpha_n[3],Qncmin[3]))
#      rn[4,d] =  max(0.,compute_R2(mydata,depth,'ruPBAc' ,'loBAc'  ,'B1c','B1n','sB1c','dB1c',alpha_n[4],Qncmin[4]))

#      Qpc[0] = mydata['P1p']/mydata['P1c']; Qpc[1] = mydata['P2p']/mydata['P2c']; Qpc[2] = mydata['P3p']/mydata['P3c']; Qpc[3] = mydata['P4p']/mydata['P4c']
#      Qnc[0] = mydata['P1n']/mydata['P1c']; Qnc[1] = mydata['P2n']/mydata['P2c']; Qnc[2] = mydata['P3n']/mydata['P3c']; Qnc[3] = mydata['P4n']/mydata['P4c']
       
#      f.write( str(depth)   + ' ')
#      f.write( str(rp[0,d]) + ' ' + str(rp[1,d]) + ' ' + str(rp[2,d]) + ' ' + str(rp[3,d]) + ' ' + str(rp[4,d]) + ' ' ) 
#      f.write( str(rn[0,d]) + ' ' + str(rn[1,d]) + ' ' + str(rn[2,d]) + ' ' + str(rn[3,d]) + ' ' + str(rn[4,d]) + ' ' ) 
#      f.write( str(Qpc[0,d]) + ' ' + str(Qpc[1,d]) + ' ' + str(Qpc[2,d]) + ' ' + str(Qpc[3,d]) + ' ' + str(Qpc[4,d]) + ' ' ) 
#      f.write( str(Qnc[0,d]) + ' ' + str(Qnc[1,d]) + ' ' + str(Qnc[2,d]) + ' ' + str(Qnc[3,d]) + ' ' + str(Qnc[4,d]) + ' ' ) 

#   f.close()

    line_cs=['r--','g--','c--','b--','k--'];
    line_cs=['r','g','c','b','k'];

    class SubplotAnimation(animation.TimedAnimation):
        def __init__(self):
            fig = plt.figure(figsize=(10, 10))
            ax=[] 
            N_P_lines=[]
            ZNGI_lines=[]

            self.data=mydata
            self.data=mydata

            for d,depth in enumerate(np.arange(0,100,5)):
                ax.append(fig.add_subplot(4, 5, d+1))
                N_P_lines.append(Line2D([], [], color='black'))
                ax[d].add_line(N_P_lines[d])
                ax[d].set_xscale('log')
                ax[d].set_yscale('log')
                ax[d].set_xlim([0.005,0.30])
                ax[d].set_ylim([0.005,5.])

                for label in (ax[d].get_xticklabels() + ax[d].get_yticklabels()):
                     label.set_fontsize(7) 

                ZNGI_comp=[]

                for i in range(10):
                    ZNGI_comp.append(Line2D([],[], line_cs[i/2], lw=2)); 
                    ax[d].add_line(ZNGI_comp[i])

                ZNGI_lines.append(ZNGI_comp)

                if depth <= 70:
                   ax[d].set_xticklabels([])  
                else:
                   for label in (ax[d].get_xticklabels()):
                       label.set_fontsize(10) 
                       label.set_rotation('vertical') 
                   ax[d].set_xlabel('mmol P/m3')  

                if d%5 == 0:
                   for label in (ax[d].get_yticklabels()):
                       label.set_fontsize(10) 
#                      label.set_rotation('vertical') 
                   ax[d].set_ylabel('mmol N/m3')  
                else:
                   ax[d].set_yticklabels([])  

                my_title = str(depth) + ' m'

                ax[d].set_title(my_title,fontsize=10)


            self.lines = N_P_lines
            self.ZNGI  = ZNGI_lines

            date = datetime.datetime(2003, 1, 1) + datetime.timedelta(0)  
            mm   = date.strftime('%m')
            dd   = date.strftime('%d')
            
            main_title = test['Area'] + ' Red--> Dia, Green-->Fla, cia -->Cia, Blue-->Dino date: ' + 'm: ' + mm + ' - d: ' + dd
            self.main_title=plt.suptitle(main_title)

            self.ax=ax

            animation.TimedAnimation.__init__(self, fig, interval=50, blit=True,repeat=False)       

        def _draw_frame(self, framedata):
            i = framedata

            for d,depth in enumerate(np.arange(0,100,5)):
                 x=self.data[0:i,depth]['N1p']
                 y=self.data[0:i,depth]['N3n']+self.data[0:i,depth]['N4n']
                 self.lines[d].set_data(x, y)
                 self.lines[d].set_label(str(i))

                 rp[0,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY1c','loPPY1c','P1c','P1p','sP1c','dP1c',alpha_p[0],Qpcmin[0]))
                 rp[1,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY2c','loPPY2c','P2c','P2p','sP2c','dP2c',alpha_p[1],Qpcmin[1]))
                 rp[2,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY3c','loPPY3c','P3c','P3p','sP3c','dP3c',alpha_p[2],Qpcmin[2]))
                 rp[3,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY4c','loPPY4c','P4c','P4p','sP4c','dP4c',alpha_p[3],Qpcmin[3]))
                 rp[4,d] =  max(0.,compute_R2(mydata,depth,i,'ruPBAc',  'loBAc','B1c','B1p' ,'sB1c','dB1c',alpha_p[4],Qpcmin[4]))

                 rn[0,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY1c','loPPY1c','P1c','P1n','sP1c','dP1c',alpha_n[0],Qncmin[0]))
                 rn[1,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY2c','loPPY2c','P2c','P2n','sP2c','dP2c',alpha_n[1],Qncmin[1]))
                 rn[2,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY3c','loPPY3c','P3c','P3n','sP3c','dP3c',alpha_n[2],Qncmin[2]))
                 rn[3,d] =  max(0.,compute_R2(mydata,depth,i,'ruPPY4c','loPPY4c','P4c','P4n','sP4c','dP4c',alpha_n[3],Qncmin[3]))
                 rn[4,d] =  max(0.,compute_R2(mydata,depth,i,'ruPBAc' ,'loBAc'  ,'B1c','B1n','sB1c','dB1c',alpha_n[4],Qncmin[4]))
                 count =0
                 for c in range(5):
                    self.ZNGI[d][count].set_data([rp[c,d],rp[c,d]], [rn[c,d],    5]); self.ZNGI[d][count].set_c(line_cs[c]); count =count +1
                    self.ZNGI[d][count].set_data([rp[c,d],0.30   ],[rn[c,d],rn[c,d]]);self.ZNGI[d][count].set_c(line_cs[c]); count =count +1

            date = datetime.datetime(2003, 1, 1) + datetime.timedelta(i)  
            mm   = date.strftime('%m')
            dd   = date.strftime('%d')
            
            main_title = test['Area'] + ' Red--> Dia, Green-->Fla, cia -->Cia, Blue-->Dino date: ' + 'm: ' + mm + ' - d: ' + dd

            self.main_title = plt.suptitle(main_title)

        def new_frame_seq(self):
            return iter(range(0,365))

        def _init_draw(self):
            for l in self.lines:
                l.set_data([], [])

    ani = SubplotAnimation()
    fileout="POSTPROC/MOVIE/TIL" + test['Area'] + "T.mp4"
    ani.save(fileout)
#   plt.show()




