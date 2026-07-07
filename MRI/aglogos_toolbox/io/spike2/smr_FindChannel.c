/*=================================================================
 *
 * SMR_FINDCHANNEL.C	.MEX file to find smr channel by name/title.
 *
 * The calling syntax is:
 *
 *		chan = smr_FindChannel(filename,chanstr)
 *
 * To compile in Matlab:
 *  Make sure you have run "mex -setup"
 *  Then at the command prompt:
 *    >> mex smr_FindChannel.c   smrapi.c
 *  For Linux, use CFLAGS
 *    >> mex CFLAGS='-std=c99 -fPIC' smr_FindChannel.c   smrapi.c
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
#define	CHINDX_OUT     plhs[0]


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    FILE *fp = NULL;
    char *filename;
    char *chanstr;
    int chanmat;  // matlab style indexing, starts from 1 (one), not 0(zero)
    SMR_TFileHead  *header = NULL;

    /* Check for proper number of arguments */
    if (nrhs == 0) {
        mexPrintf("chindex = smr_FindChannel(smrfile,chan_name)\n");
        mexPrintf("   chan_name:a string of channel name/title\n");
        mexPrintf("                 ver.0.90 Nov-2015 (c) 2015 YM@MPI Tuebingen\n");
        return;
    }

    if (nrhs < 2) { 
        mexErrMsgTxt("smr_FindChannel: missing \"channel_name\"."); 
    }


    /* Get the filename */
    if (mxIsChar(FILE_IN) != 1 || mxGetM(FILE_IN) != 1) {
        mexErrMsgTxt("smr_FindChannel: first arg must be a string (filename)."); 
    }
    filename = mxArrayToString(FILE_IN);
    if (filename == NULL)
        mexErrMsgTxt("smr_FindChannel: not enough memory for the filename.");

    if (mxIsChar(CHAN_IN) != 1 || mxGetM(CHAN_IN) != 1) {
        mexErrMsgTxt("smr_FindChannel: second arg must be a string (channel name)."); 
    }
    chanstr = mxArrayToString(CHAN_IN);

    /* open the file */
    fp = smr_fopen(filename, "rb");
    if (!fp) {
        mexPrintf("smr_FindChannel: smrfile='%s'\n",filename);
        if (filename != NULL)  { mxFree(filename);  filename = NULL; }
        mexErrMsgTxt("smr_FindChannel: file not found.");
        return;
    }

    header = smr_readHeader(fp);
    if (header == NULL) {
        smr_fclose(fp);
        mexErrMsgTxt("smr_FindChannel: failed to read file header."); 
        return;
    }

    // get channel index
    chanmat = smr_findchan(fp,header,chanstr) + 1;  // +1 for matlab-style indexing
    if (chanmat <= 0) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
        }
        mexPrintf("smr_FindChannel: chanstr='%s'\n",chanstr);
        mexErrMsgTxt("smr_FindChannel: failed to find the given channel.");
        return;
    }

    smr_fclose(fp);  fp = NULL;


    // make the output
    CHINDX_OUT = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(CHINDX_OUT) = (double)chanmat;
    
    if (header != NULL) {
        free(header);  header = NULL;
    }

    return;
}
