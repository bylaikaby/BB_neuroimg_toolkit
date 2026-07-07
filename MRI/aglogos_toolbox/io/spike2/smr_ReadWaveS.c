/*=================================================================
 *
 * SMR_READWAVES.C	.MEX file to read a ADC Channel of the smrfile .
 *
 * The calling syntax is:
 *
 *		[Vals iTickStart] = smr_ReadWaveS(filename,chan,[iBlockFrom=1],[iBlockTo=-1],[bScale=1])
 *
 * To compile in Matlab:
 *  Make sure you have run "mex -setup"
 *  Then at the command prompt:
 *    >> mex smr_ReadWaveS.c   smrapi.c
 *  For Linux, use CFLAGS
 *    >> mex CFLAGS='-std=c99 -fPIC' smr_ReadWaveS.c   smrapi.c
 *
 *=================================================================*/
/* $Revision: 1.00 $ 13-Nov-2015 YM/MPI : pre-release              */
/* $Revision: 1.01 $ 18-Nov-2015 YM/MPI : supports 'scale'         */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include "matrix.h"
#include "mex.h"
#include "smrapi.h"

/* Input Arguments */
#define	FILE_IN	       prhs[0]
#define CHAN_IN        prhs[1]
#define BLK_FROM_IN    prhs[2]
#define BLK_TO_IN      prhs[3]
#define SCALE_IN       prhs[4]


/* Output Arguments */
#define	VALUES_OUT     plhs[0]
#define	TICK_START_OUT plhs[1]


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    FILE *fp = NULL;
    char *filename;
    char *chanstr;
    int chanmat;  // matlab style indexing, starts from 1 (one), not 0(zero)
    int bfrommat, btomat; // matlab style indexing, starts from 1 (one), not 0(zero)
    int bScale;
    SMR_TFileHead  *header = NULL;
    SMR_TChannel   *chinfo = NULL;
    SMR_CHANBLOCKS *chblck = NULL;
    short *vals;
    int i, nread;
    double *p, scale, offset;
    int istart;
    mwSize dims[2];

    /* Check for proper number of arguments */
    if (nrhs == 0) {
        mexPrintf("[Vals iTickStart] = smr_ReadWaveS(smrfile,chan,blockFrom=1,blockTo=-1,Scale=1)\n");
        mexPrintf("   chan:1~MaxCh or a string, block:1~nblocks, scale:0/1\n");
        mexPrintf("   if blockTo<0, then reads until the block-end.\n");
        mexPrintf("   if scale=1, \"vals\" as double, otherwise as int16.\n");
        mexPrintf("                 ver.0.90 Nov-2015 (c) 2015 YM@MPI Tuebingen\n");
        return;
    }

    if (nrhs < 2) { 
        mexErrMsgTxt("smr_ReadWaveS: missing \"channel\"."); 
    }


    /* Get the filename */
    if (mxIsChar(FILE_IN) != 1 || mxGetM(FILE_IN) != 1) {
        mexErrMsgTxt("smr_ReadWaveS: first arg must be a string (filename)."); 
    }
    filename = mxArrayToString(FILE_IN);
    if (filename == NULL)
        mexErrMsgTxt("smr_ReadWaveS: not enough memory for the filename string.");


    bScale = 1;
    if (nrhs > 3) {
        bScale = (mxGetScalar(SCALE_IN) > 0)? 1:0;
    }
    

    /* open the file */
    fp = smr_fopen(filename, "rb");
    if (!fp) {
        mexPrintf("smr_ReadWaveS: smrfile='%s'\n",filename);
        if (filename != NULL)  { mxFree(filename);  filename = NULL; }
        mexErrMsgTxt("smr_ReadWaveS: file not found.");
        return;
    }

    header = smr_readHeader(fp);
    if (header == NULL) {
        smr_fclose(fp);
        mexErrMsgTxt("smr_ReadWaveS: failed to read file header."); 
        return;
    }

    // get channel index
    if (mxIsChar(CHAN_IN) == 1) {
        chanstr = mxArrayToString(CHAN_IN);
        chanmat = smr_findchan(fp,header,chanstr) + 1;  // +1 for matlab-style indexing
        if (chanmat <= 0) {
            smr_fclose(fp);
            free(header);
            mexPrintf("smr_ReadWaveS: chanstr='%s'\n",chanstr);
            mexErrMsgTxt("smr_ReadWaveS: failed to find the given channel.");
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
        mexErrMsgTxt("smr_ReadWaveS: \"chan\" is out of range.");
        return;
    }
    chinfo = smr_readChanInfo(fp,header,chanmat-1);
    if (chinfo == NULL) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
        }
        mexErrMsgTxt("smr_ReadWaveS: failed to read channel info.");
        return;
    }

    // get blocks to read
    bfrommat = 1;  btomat = (int)chinfo->blocks;
    if (nrhs > 2) {
        bfrommat = (int) mxGetScalar(BLK_FROM_IN);
        if (nrhs > 3) {
            btomat = (int) mxGetScalar(BLK_TO_IN);
            if (btomat < 0)  btomat = (int)chinfo->blocks;
        }
    }
    if (bfrommat < 1 || bfrommat > (int)chinfo->blocks) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
            }
        if (chinfo != NULL) {
            free(chinfo);  chinfo = NULL;
        }
        mexErrMsgTxt("smr_ReadWaveS: block-start is out of range (1 to nblocks).");
        return;
    }
    if (btomat < 1 || btomat > (int)chinfo->blocks) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
            }
        if (chinfo != NULL) {
            free(chinfo);  chinfo = NULL;
        }
        mexErrMsgTxt("smr_ReadWaveS: block-end is out of range (1 to nblocks).");
        return;
    }

    // read block information
    chblck = smr_readChanBlocks(fp,header,chinfo);
    if (chblck == NULL) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
            }
        if (chinfo != NULL) {
            free(chinfo);  chinfo = NULL;
        }
        mexErrMsgTxt("smr_ReadWaveS: failed to read channel block-headers.");
        return;
    }

    // read waveform
    vals = NULL;  istart = -1;
    nread = smr_ReadWaveS(fp,header,chinfo,chblck,bfrommat-1,btomat-1,&vals,&istart);  // -1 for C-style indexing
    smr_fclose(fp);  fp = NULL;

    if (nread < 0)  nread = 0;
    
    if (bScale > 0) {
        VALUES_OUT = mxCreateDoubleMatrix(nread,1,mxREAL);
        p = (double *)mxGetData(VALUES_OUT);
        scale = (double)chinfo->v.adc.scale;
        offset = (double)chinfo->v.adc.offset;
        for (i = 0; i < nread; i++) {
            p[i] = ((double)vals[i]) * scale / 6553.6 + offset;
        }
    } else {
        dims[0] = nread;  dims[1] = 1;
        VALUES_OUT = mxCreateNumericArray(2, dims, mxINT16_CLASS, mxREAL);
        memcpy(mxGetData(VALUES_OUT), vals, nread*sizeof(short));
    }
    
    if (nlhs > 1) {
        TICK_START_OUT = mxCreateDoubleMatrix(1,1,mxREAL);
        *mxGetPr(TICK_START_OUT) = (double)istart;
    }

    if (header != NULL) {
        free(header);  header = NULL;
    }
    if (chinfo != NULL) {
        free(chinfo);  chinfo = NULL;
    }
    if (chblck != NULL) {
        free(chblck);  chblck = NULL;
    }
    if (vals != NULL) {
        free(vals);    vals = NULL;
    }
    

    return;
}
