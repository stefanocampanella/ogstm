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


def plot_BIOc_movie(test):
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

    M.close()

#define derived type to store informations
    mydtype = [('P1c','f4')    ,('P2c','f4')    ,('P3c','f4')    ,('P4c','f4')]

    filename     = 'POSTPROC/' + test['Area'] + '.nc'
    filename_dia = 'POSTPROC/' + test['Area'] + '_dia.nc'

    M       = NC.netcdf_file(filename,"r",mmap=False)
    aux     = (M.variables[mydtype[0][0]].data[:,:]).copy()

    ntime= aux.shape[0]
    jpk  = aux.shape[1] 

    M_dia   = NC.netcdf_file(filename_dia,"r",mmap=False)

    mydata=np.zeros((ntime,jpk),dtype=mydtype)


    for var in mydata.dtype.names[0:3]:
       mydata[:,:][var]=M.variables[var].data[:,:].copy()

    line_cs=['r','g','c','b'];

    class SubplotAnimation(animation.TimedAnimation):
        def __init__(self):
            fig = plt.figure(figsize=(10, 10))
            ax=[] 
            BIO0_lines=[]
            BIO1_lines=[]
            BIO2_lines=[]
            BIO3_lines=[]

            self.data=mydata

            for d,depth in enumerate(np.arange(0,100,5)):
                ax.append(fig.add_subplot(4, 5, d+1))

                BIO0_lines.append(Line2D([], [], color=line_cs[0]))
                BIO1_lines.append(Line2D([], [], color=line_cs[1]))
                BIO2_lines.append(Line2D([], [], color=line_cs[2]))
                BIO3_lines.append(Line2D([], [], color=line_cs[3]))

                ax[d].add_line(BIO0_lines[d])
                ax[d].add_line(BIO1_lines[d])
                ax[d].add_line(BIO2_lines[d])
                ax[d].add_line(BIO3_lines[d])

                ax[d].set_xlim([0,365])
                ax[d].set_ylim([0,30])

                for label in (ax[d].get_xticklabels() + ax[d].get_yticklabels()):
                     label.set_fontsize(7) 


                if depth <= 70:
                   ax[d].set_xticklabels([])  
                else:
                   for label in (ax[d].get_xticklabels()):
                       label.set_fontsize(10) 
                       label.set_rotation('vertical') 
                   ax[d].set_xlabel('time - days')

                my_title = str(depth) + ' m'

                if d%5 == 0:
                   for label in (ax[d].get_yticklabels()):
                       label.set_fontsize(10)
                   ax[d].set_ylabel('mg C/m3')
                else:
                   ax[d].set_yticklabels([])


                ax[d].set_title(my_title,fontsize=10)


            self.BIO0_lines = BIO0_lines
            self.BIO1_lines = BIO1_lines
            self.BIO2_lines = BIO2_lines
            self.BIO3_lines = BIO3_lines

#           annotation = ax[0].annotate(JD,xy=(0.5,0.5))
#           annotation.set_animated(True)
            date = datetime.datetime(2003, 1, 1) + datetime.timedelta(0)  
            mm   = date.strftime('%m')
            dd   = date.strftime('%d')
            
            main_title = test['Area'] + ' Red--> Dia, Green-->Fla, cia -->Cia, Blue-->Dino date: ' + 'm: ' + mm + ' - d: ' + dd

            self.big_title=plt.suptitle(main_title)

            self.ax=ax

            animation.TimedAnimation.__init__(self, fig, interval=50, blit=True,repeat=False)       

        def _draw_frame(self, framedata):

            i = framedata

            for d,depth in enumerate(np.arange(0,100,5)):

                 x =np.arange(i)

                 y0=self.data[0:i,depth]['P1c']
                 y1=self.data[0:i,depth]['P2c']
                 y2=self.data[0:i,depth]['P3c']
                 y3=self.data[0:i,depth]['P4c']

                 self.BIO0_lines[d].set_data(x, y0)
                 self.BIO0_lines[d].set_label(str(i))
                 self.BIO1_lines[d].set_data(x, y1)
                 self.BIO2_lines[d].set_data(x, y2)
                 self.BIO3_lines[d].set_data(x, y3)

            line_list =[]

            for d,depth in enumerate(np.arange(0,100,5)):
                line_list.append(self.BIO0_lines[d])
                line_list.append(self.BIO1_lines[d])
                line_list.append(self.BIO2_lines[d])
                line_list.append(self.BIO3_lines[d])
              

#           self._drawn_artists =line_list

#           self.old_an.remove()
#           self.old_an=self.ax[0].text(0.1,1.1,str(i),fontdict=None)
#           self.old_an=self.ax[0].text(str(i),xy=(10,25))
#           self.ax[0].set_title(str(i),fontsize=7)
            date = datetime.datetime(2003, 1, 1) + datetime.timedelta(i)
            mm   = date.strftime('%m')
            dd   = date.strftime('%d')

            main_title = test['Area'] + ' Red--> Dia, Green-->Fla, cia -->Cia, Blue-->Dino date: ' + 'm: ' + mm + ' - d: ' + dd

            self.big_title=plt.suptitle(main_title)

        def new_frame_seq(self):
            return iter(range(0,365))

        def _init_draw(self):
            lines= [self.BIO0_lines, self.BIO1_lines, self.BIO2_lines, self.BIO3_lines]
            for l in lines:
                for ld in l: 
                    ld.set_data([], [])
    ani = SubplotAnimation()
    fileout="POSTPROC/MOVIE/BIOc" + test['Area'] + ".mp4"
    ani.save(fileout)
#   plt.show()