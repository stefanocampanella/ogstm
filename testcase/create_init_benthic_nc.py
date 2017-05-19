import os,sys

import numpy as np

from mydtype import *

import scipy.io.netcdf as NC

import pickle



def create_init_benthic_nc(test):
    CODEPATH = test['Code'] + "/ogstm/"
    CODEPATH = CODEPATH.replace("~",os.getenv("HOME"))
    filename = CODEPATH +  "ready_for_model_namelists/namelist.ben"
    NAMELIST =file2stringlist(filename)
    initVARS=[]
    for line in NAMELIST:
        if line.find("cbennm") != -1:
            quote_1=line.find("\"")
            quote_2=line.find("\"",quote_1+1)
            varname=line[quote_1+1:quote_2]
            initVARS.append(varname)
    
    jpi=test['jpi'];
    jpj=test['jpj'];
    time = 1
    x_a=1
    y_a=1
    z_a=3

    maskfile=test['Dir'] + '/meshmask.nc'

    M=NC.netcdf_file(maskfile,"r")

    Lon     =  M.variables['glamt'  ].data[0,0,:,:].copy()
    Lat     =  M.variables['gphit'  ].data[0,0,:,:].copy()
    Lev_ben =  M.variables['nav_lev_ben'].data.copy()
    M.close()


    rst=np.zeros((1,jpk_ben,jpj,jpi),np.double)

    os.system("mkdir -p " + test['Dir'])
    os.system("mkdir -p " + test['Dir'] + "/RESTARTS/")
    os.system("mkdir -p " + test['Dir'] + "/AVE_FREQ_1/")
    os.system("mkdir -p " + test['Dir'] + "/AVE_FREQ_2/")    
    os.system("mkdir -p " + test['Dir'] + "/AVE_PHYS/")    
    
    for var in initVARS:
        filename = "KB/INIT_BENTHIC/init." + var
        datain = np.loadtxt(filename,ndmin=1)     
        for jk in range(jpk_ben):
            rst[0,jk,:,:] = datain[jk]
            for jj in range(jpj/2):
                rst[0,jk,jj,:] = datain[jk]
#       WRITE NetCDF restart file
        outfile = test['Dir'] + '/RESTARTS/RST.' + test['Start'] + '.' + var + '.nc'
        ncOUT   = NC.netcdf_file(outfile,"w");
        
        ncOUT.createDimension('x',jpi);
        ncOUT.createDimension('y',jpj);
        ncOUT.createDimension('z_ben',jpk_ben);
        ncOUT.createDimension('time',time)
    
        ncOUT.createDimension('x_a',x_a);
        ncOUT.createDimension('y_a',y_a);
        ncOUT.createDimension('z_a',z_a);     

        TRB   = 'TRB' + var;
        TRN   = 'TRN' + var;
        ncvar = ncOUT.createVariable('nav_lon' ,'d',('y','x')           ); ncvar[:] = Lon;
        ncvar = ncOUT.createVariable('nav_lat' ,'d',('y','x')           ); ncvar[:] = Lat;
        ncvar = ncOUT.createVariable('nav_lev_ben' ,'d',('z_ben',)      ); ncvar[:] = Lev_ben;
        ncvar = ncOUT.createVariable('time'    ,'d',('time',)           ); ncvar    = 1.;
        ncvar = ncOUT.createVariable(TRB       ,'d',('time','z_ben','y','x')); ncvar[:] = rst;   
        ncvar = ncOUT.createVariable(TRN       ,'d',('time','z_ben','y','x')); ncvar[:] = rst; 

        setattr(ncOUT.variables[TRB]   ,'missing_value',1e+20                              );     
        setattr(ncOUT.variables[TRN]   ,'missing_value',1e+20                              );
        setattr(ncOUT.variables['time'],'Units'        ,'seconds since 1582-10-15 00:00:00');
        setattr(ncOUT                  ,'TimeString'   ,'20010101-00:00:00');
        ncOUT.close()
