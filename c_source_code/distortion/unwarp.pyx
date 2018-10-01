# distutils: language = c++
# distutils: sources = unwarp_functions.cpp timestamp.c
# distutils: define_macros='BITS32=1' 'SAVU=1'

#$Id: unwarp.pyx 451 2016-01-04 15:08:19Z kny48981 $

import numpy as np
import logging
cimport numpy as np
cimport cunwarp

cdef public void pydebug(char * message):
   logging.debug(message)
cdef public void pyinfo(char * message):
   logging.info(message)
cdef public void pyuser(char * message):
   logging.log("USER",message)



cdef cunwarp.Options ctrl
cdef unsigned int batchsize

def logprint (*messages):
   #print "unwarp.pyx (float): ", messages
   pass



def getversion():
   global ctrl
   ctrl.versionflag=1
   cunwarp.runUnwarp(&ctrl,0,NULL,NULL)

def setcoeff(a,b,c,d,e):
   global ctrl
   ctrl.acoeff=a
   ctrl.bcoeff=b
   ctrl.ccoeff=c
   ctrl.dcoeff=d
   ctrl.ecoeff=e
   logprint("coefficients",a,b,c,d,e)

def setctr(xc,yc):
   ctrl.xcentre=xc
   ctrl.ycentre=yc
   logprint("centre",xc,yc)

def setup(np.ndarray[np.float32_t,ndim=3,mode="c"] inarray,np.ndarray[np.float32_t,ndim=3,mode="c"] outarray,logfile="unwarp.log",versionflag=0): 
   global ctrl
   cunwarp.timestamp_open(logfile)
   cunwarp.timestamp_init()
   ctrl.versionflag=0
   ctrl.pixelflag=1
   ctrl.f_call_num=0
   logprint ( "coercing array")
   inbuf=<unsigned char *>np.PyArray_DATA(inarray)
   outbuf=<unsigned char *>np.PyArray_DATA(outarray)
   ctrl.wd=inarray.shape[2]
   ctrl.ht=inarray.shape[1]
   batchsize=inarray.shape[0]
   logprint( "calling c function --  setup" )
   logprint( "Input array batchsize %i height %i width %i "%(batchsize,ctrl.ht,ctrl.wd) )

   cunwarp.runUnwarp(&ctrl,batchsize, <unsigned char *>np.PyArray_DATA(inarray), <unsigned char *> np.PyArray_DATA(outarray))

def run(np.ndarray[np.float32_t,ndim=3,mode="c"] inarray,np.ndarray[np.float32_t,ndim=3,mode="c"] outarray): 
   global ctrl
   ctrl.versionflag=0
   ctrl.f_call_num=1
   batchsize=inarray.shape[0]
   logprint ( "coercing arrays ")
   inbuf=<unsigned char *>np.PyArray_DATA(inarray)
   outbuf=<unsigned char *>np.PyArray_DATA(outarray)
   logprint("inarray shape",inarray.shape[0],inarray.shape[1],inarray.shape[2])
   #testval=inarray[0,100,100]
   #logprint("testval",testval)
   cunwarp.runUnwarp(&ctrl,batchsize, <unsigned char *>np.PyArray_DATA(inarray), <unsigned char *> np.PyArray_DATA(outarray))

def cleanup():
   global ctrl
   cunwarp.timestamp("unwarp cleanup",0);
   ctrl.versionflag=0
   ctrl.f_call_num=2
   cunwarp.runUnwarp(&ctrl,1,NULL,NULL)
   cunwarp.timestamp_close()

''' 
def setup(np.ndarray[np.float32_t,ndim=3,mode="c"] inarray,np.ndarray[np.float32_t,ndim=3,mode="c"] outarray,outlier_mu,npad,logfile="dezing.log",versionflag=0): #,bytes summary):
   global ctrl
   global batchsize
   logprint ( "opening log file")
   cunwarp.timestamp_open(logfile)
   cunwarp.timestamp_init()
   logprint ( "coercing array")
   inbuf=<unsigned char *>np.PyArray_DATA(inarray)
   outbuf=<unsigned char *>np.PyArray_DATA(outarray)

   logprint ( "setting control flags")
   ctrl.versionflag=versionflag
   ctrl.outlier_mu=outlier_mu
   ctrl.cropwd=inarray.shape[2]
   ctrl.nlines=inarray.shape[1]
   ctrl.npad=npad
   batchsize=inarray.shape[0]

   ctrl.f_call_num=0

   cunwarp.timestamp( "calling c function setup" )
   #cunwarp.runUnwarp(&ctrl,batchsize,<unsigned char *> inarray.data,<unsigned char *> outarray.data)
   cunwarp.runUnwarp(&ctrl,batchsize, inbuf, outbuf)
   pass

def run(np.ndarray[np.float32_t,ndim=3,mode="c"] inarray,np.ndarray[np.float32_t,ndim=3,mode="c"] outarray): #,bytes summary):
   global ctrl
   global batchsize

   logprint ( "coercing arrays ")
   inbuf=<unsigned char *>np.PyArray_DATA(inarray)
   outbuf=<unsigned char *>np.PyArray_DATA(outarray)
   logprint (  "in unwarp.run: ctrl.cropwd is:" ,ctrl.cropwd, "batchsize is",batchsize)

   cunwarp.timestamp( "calling c function with run flag" )
   ctrl.f_call_num=1
   cunwarp.runUnwarp(&ctrl,batchsize, <unsigned char *>np.PyArray_DATA(inarray), <unsigned char *> np.PyArray_DATA(outarray))
   pass



def cleanup(np.ndarray[np.float32_t,ndim=3,mode="c"] inarray,np.ndarray[np.float32_t,ndim=3,mode="c"] outarray): #,bytes summary):
   global ctrl
   global batchsize
   logprint ( "coercing array")
   inbuf=<unsigned char *>np.PyArray_DATA(inarray)
   outbuf=<unsigned char *>np.PyArray_DATA(outarray)
   ctrl.f_call_num=2
   cunwarp.timestamp( "calling c function with cleanup flag" )
   cunwarp.runUnwarp(&ctrl,batchsize, <unsigned char *>np.PyArray_DATA(inarray), <unsigned char *> np.PyArray_DATA(outarray))
   cunwarp.timestamp_close()







def test_run(width=2550,length=2500,batchsize=100):
   #cdef np.ndarray[np.float32_t,ndim=3] inarray =np.ones((width,length,batchsize),dtype=np.float32_t)
   #cdef np.ndarray[np.float32_t,ndim=3] outarray =np.empty((width,length,batchsize),dtype=np.float32_t)
   inarray =np.ones((width,length,batchsize),dtype=np.float32_t)
   outarray =np.empty((width,length,batchsize),dtype=np.float32_t)
   print "setting control flags"
   ctrl.versionflag=0
   ctrl.outlier_mu=1.5
   ctrl.cropwd=width
   ctrl.nlines=length
   print "setting a test value at element 0"
   inarray[0,0,0]=143
   print "creating random zingers"
   xarray=np.random.random_integers(0,width-1,1000)
   yarray=np.random.random_integers(0,length-1,1000)
   print "applying random zingers"
   for i in range(0,batchsize):
      for d in range(0,len(xarray)):
         xidx=xarray[d]
         yidx=yarray[d]
         inarray[xidx,yidx,i]=100*np.random.rand()
   
   print "getting slice of input"
   in50=inarray[:,:,50]
   print "setting inarray element 0 to %i"%inarray[0,0,0]
   cunwarp.timestamp_open("test_run.log")


   inbuf=<unsigned char *>np.PyArray_DATA(inarray)
   outbuf=<unsigned char *>np.PyArray_DATA(outarray)

   ctrl.f_call_num=0
   print "calling c function setup"
   #cunwarp.runUnwarp(&ctrl,batchsize,<unsigned char *> inarray.data,<unsigned char *> outarray.data)
   cunwarp.runUnwarp(&ctrl,batchsize, inbuf, outbuf)

   ctrl.f_call_num=1
   print "calling c function"
   #cunwarp.runUnwarp(&ctrl,batchsize,<unsigned char *> inarray.data,<unsigned char *> outarray.data)
   cunwarp.runUnwarp(&ctrl,batchsize, <unsigned char *>np.PyArray_DATA(inarray), <unsigned char *> np.PyArray_DATA(outarray))

   ctrl.f_call_num=2
   print "calling c function cleanup"
   #cunwarp.runUnwarp(&ctrl,batchsize,<unsigned char *> inarray.data,<unsigned char *> outarray.data)
   cunwarp.runUnwarp(&ctrl,batchsize, <unsigned char *>np.PyArray_DATA(inarray), <unsigned char *> np.PyArray_DATA(outarray))


   cunwarp.timestamp_close()
   print "finished c function"
   print "outarray element 0 is %i"%outarray[0,0,0]
   out50=outarray[:,:,50]
   return(in50,out50)




def test_data():
   cdef np.ndarray[np.float32_t,ndim=3] inarray =np.ones((50,100,15),dtype=np.float32_t)
   cdef np.ndarray[np.float32_t,ndim=3] outarray =np.empty((50,100,15),dtype=np.float32_t)
   ctrl.versionflag=2
   ctrl.outlier_mu=0.7
   ctrl.cropwd=50
   ctrl.nlines=100
   inarray[0,0,0]=143
   print "setting inarray element 0 to %i"%inarray[0,0,0]
   print "calling c function"
   cunwarp.timestamp("calling c function")
   cunwarp.runUnwarp(&ctrl,15,<unsigned char *> inarray.data,<unsigned char *> outarray.data)
   print "finished c function"
   print "outarray element 0 is %i"%outarray[0,0,0]

'''
