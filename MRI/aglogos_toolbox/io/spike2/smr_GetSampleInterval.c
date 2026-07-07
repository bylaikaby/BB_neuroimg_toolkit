/*=================================================================
 *
 * SMR_GETSAMPLEINTERVAL.C	.MEX file to get the sample interval (usec) of the channel.
 *
 * The calling syntax is:
 *
 *		chan = smr_GetSampleInterval(filename,chanstr/chan)
 *
 * To compile in Matlab:
 *  Make sure you have run "mex -setup"
 *  Then at the command prompt:
 *    >> mex smr_GetSampleInterval.c   smrapi.c
 *  For Linux, use CFLAGS
 *    >> mex CFLAGS='-std=c99 -fPIC' smr_GetSampleInterval.c   smrapi.c
 *
 *=================================================================*/
/* $Revision: 1.00 $ 13-Nov-2015 YM/MPI : pre-release              */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include "matrix.h"
#include "mex.h"
#include "smrapi.h"

/* Input Arguments */
#define	FILE_IN	       prhs[0]
#define CHAN_IN        prhs[1]


/* Output Arguments */
#define	SAMP_OUT       plhs[0]


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    FILE *fp = NULL;
    char *filename;
    char *chanstr;
    int chanmat;  // matlab style indexing, starts from 1 (one), not 0(zero)
    SMR_TFileHead  *header = NULL;
    SMR_TChannel   *chinfo = NULL;
    double sampinterval;

    /* Check for proper number of arguments */
    if (nrhs == 0) {
        mexPrintf("samp_interval_usec = smr_GetSampleInterval(smrfile,chan)\n");
        mexPrintf("   chan:1~MaxCh or a string of channel name/title\n");
        mexPrintf("                 ver.0.90 Nov-2015 (c) 2015 YM@MPI Tuebingen\n");
        return;
    }

    if (nrhs < 2) { 
        mexErrMsgTxt("smr_GetSampleInterval: missing \"channel index/name\"."); 
    }


    /* Get the filename */
    if (mxIsChar(FILE_IN) != 1 || mxGetM(FILE_IN) != 1) {
        mexErrMsgTxt("smr_GetSampleInterval: first arg must be a string (filename)."); 
    }
    filename = mxArrayToString(FILE_IN);
    if (filename == NULL)
        mexErrMsgTxt("smr_GetSampleInterval: not enough memory for the filename.");

    /* open the file */
    fp = smr_fopen(filename, "rb");
    if (!fp) {
        mexPrintf("smr_GetSampleInterval: smrfile='%s'\n",filename);
        if (filename != NULL)  { mxFree(filename);  filename = NULL; }
        mexErrMsgTxt("smr_GetSampleInterval: file not found.");
        return;
    }

    header = smr_readHeader(fp);
    if (header == NULL) {
        smr_fclose(fp);
        mexErrMsgTxt("smr_GetSampleInterval: failed to read file header."); 
        return;
    }

    // get channel index
    if (mxIsChar(CHAN_IN) == 1) {
        chanstr = mxArrayToString(CHAN_IN);
        chanmat = smr_findchan(fp,header,chanstr) + 1;  // +1 for matlab-style indexing
        if (chanmat <= 0) {
            smr_fclose(fp);
            free(header);
            mexPrintf("smr_GetSampleInterval: chanstr='%s'\n",chanstr);
            mexErrMsgTxt("smr_GetSampleInterval: failed to find the given channel.");
            return;
        }
    } else {
        chanmat = (int) mxGetScalar(CHAN_IN);
    }

    if (chanmat <= 0 || chanmat > header->channels) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
        }
        mexErrMsgTxt("smr_GetSampleInterval: \"chan\" is out of range.");
        return;
    }

    
    chinfo = smr_readChanInfo(fp,header,chanmat-1);
    if (chinfo == NULL) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
        }
        mexErrMsgTxt("smr_GetSampleInterval: failed to read channel info.");
        return;
    }

    sampinterval = smr_getSampleInterval(fp,header,chinfo);
    
    smr_fclose(fp);  fp = NULL;


    // make the output
    SAMP_OUT = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(SAMP_OUT) = sampinterval;
    
    if (header != NULL) {
        free(header);  header = NULL;
    }
    if (chinfo != NULL) {
        free(chinfo);  chinfo = NULL;
    }

    return;
}
