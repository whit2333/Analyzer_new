/*-----------------------------------------------------------------------------
 * Copyright (c) 1994 Southeastern Universities Research Association,
 *                    Continuous Electron Beam Accelerator Facility
 *
 * This software was developed under a United States Government license
 * described in the NOTICE file included as part of this distribution.
 *
 * Stephen A. Wood, 12000 Jefferson Ave., Newport News, VA 23606
 * Email: saw@cebaf.gov  Tel: (804) 249-7367  Fax: (804) 249-5800
 *-----------------------------------------------------------------------------
 * 
 * Description:
 *  This file also contains some routines to help set up servers.
 *
 * Author:  Stephen Wood, CEBAF Hall C
 *
 * Revision History:
 *  $Log: daVarServ.c,v $
 *  Revision 1.3  2003/02/21 20:55:24  saw
 *  Clean up some types and casts to reduce compiler warnings.
 *
 *  Revision 1.2  1999/11/04 20:34:05  saw
 *  Alpha compatibility.
 *  New RPC call needed for root event display.
 *  Start of code to write ROOT trees (ntuples) from new "tree" block
 *
 *  Revision 1.2  1995/01/09 16:03:50  saw
 *  include errno.h
 *
 * Revision 1.1  1994/11/07  14:19:57  saw
 * Initial revision
 *
 */

#include <stdio.h>
#include <rpc/rpc.h>		/* always need this here */
#include "daVarRpc.h"		/* need this too: generated by rpcgen */
#include <errno.h>
#if 0
#include <stdlib.h> 
#include <rpc/pmap_clnt.h>
#include <memory.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <time.h>
#endif

#include "cfortran.h"

void davarsvr_1(struct svc_req *rqstp, register SVCXPRT *transp);

int daVarServSet(int prog, int version);
int daVarServUnSet(int prog, int version);
int daVarServOnce(int wait);
FCALLSCFUN2(INT,daVarServSet,THSERVSET,thservset,INT,INT);
FCALLSCFUN2(INT,daVarServUnSet,THSERVUNSET,thservunset,INT,INT);
FCALLSCFUN1(INT,daVarServOnce,THSERVONE,thservone,INT);

int last_program,last_version;	/* Save these for daVarServUnSet */
SVCXPRT *udp_transp,*tcp_transp; /* Descriptors that go with above */

int daVarGetProgVers(int *prog, int *version)
{
  *prog = last_program;
  *version = last_version;
}
int daVarServSet(int prog, int version)
{
   
  if(prog==0) prog = DAVARSVR;
  if(version==0) version = DAVARVERS;
  (void) pmap_unset(prog,version);
  last_program = prog;
  last_version = version;
  
  udp_transp = (SVCXPRT *) svcudp_create(RPC_ANYSOCK);
  if (udp_transp == NULL) {
    fprintf(stderr, "cannot create udp service.");
    exit(1);
  }
  if (!svc_register(udp_transp, prog, version, davarsvr_1, IPPROTO_UDP)) {
    fprintf(stderr, "unable to register (%d, %d), udp).\n",prog,version);
    exit(1);
  }
  
  tcp_transp = (SVCXPRT *) svctcp_create(RPC_ANYSOCK, 0, 0);
  if (tcp_transp == NULL) {
    fprintf(stderr, "cannot create tcp service.\n");
    exit(1);
  }
  if (!svc_register(tcp_transp, prog, version, davarsvr_1, IPPROTO_TCP)) {
    fprintf(stderr, "unable to register (%d, %d), tcp).\n",prog,version);
    exit(1);
  }
  
}
  
int daVarServUnSet(int prog, int version)
{
  register SVCXPRT *transp;
  
  if(prog==0) prog = last_program;
  if(version==0) version = last_version;
  (void) pmap_unset(prog,version);
  if(prog==last_program && version == last_version){
    if(udp_transp) svc_destroy(udp_transp);
    if(tcp_transp) svc_destroy(tcp_transp);
  }
  return(0);
}
  
int daVarServOnce(int wait)
{
  fd_set readfdset;
  extern int errno;
  int status;
  struct timeval timeout;
  struct timeval *timeoutp;
  static int tsize=0;
 
  if(wait>=0) {
    timeout.tv_sec = wait;
    timeout.tv_usec = 1;
    timeoutp = &timeout;
  } else {
    timeoutp = 0;
  }

#ifdef hpux
  if(!tsize) tsize = NFDBITS;
#else
  if(!tsize) tsize = getdtablesize(); /* how many descriptors can we have */
#endif

  readfdset = svc_fdset;
  switch((status=select(tsize, &readfdset, (fd_set *) NULL, (fd_set *) NULL,
		timeoutp))) {
  case -1:
    if (errno == EBADF) break;
    perror("select failed");
    break;
  case 0:
    /* perform other functions here if select() timed-out */
    break;
  default:
    svc_getreqset(&readfdset);
    status = 1;
  }
  return(status);
}
  


