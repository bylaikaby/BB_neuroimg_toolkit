/*=================================================================
 *
 * SMR_READHEADER.C	.MEX file to read smr header
 *
 * The calling syntax is:
 *
 *		[header] = smr_ReadHeader(filename)
 *
 * To compile in Matlab:
 *  Make sure you have run "mex -setup"
 *  Then at the command prompt:
 *    >> mex smr_ReadHeader.c   smrapi.c
 *  For Linux, use CFLAGS
 *    >> mex CFLAGS='-std=c99 -fPIC' smr_ReadHeader.c   smrapi.c
 *
 * As of 12-Nov-2015, some values are exported as "double" instead of 
 * int32/int16 for ease in MATLAB.
 *
 *=================================================================*/
/* $Revision: 1.00 $ 12-Nov-2015 YM/MPI : pre-release              */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include "matrix.h"
#include "mex.h"
#include "smrapi.h"

/* Input Arguments */
#define	FILE_IN	       prhs[0]


/* Output Arguments */
#define	HDR_OUT	       plhs[0]


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    FILE *fp = NULL;
    char *filename;
    SMR_TFileHead *header = NULL;
    int i, n;
    // output structure
    const char *field_names[] = {
        "systemID", "copyright", "creator", "usPerTime", "timePerADC",
        "fileState", "firstData", "channels", "chanSize", "extraData",
        "bufferSz", "osFormat", "maxFTime", "dTimeBase", "timeDate",
        "cAlignFlag", "LUTable", "fileComment" };
    const char *f_timeDate[] = {
        "ucHun", "ucSec", "ucHour", "ucDay", "ucMon", "wYear" };

    mwSize dims[2];
    mxArray *field_val, *sub_fval;
    int field_idx, sub_fidx;
    char tmpbuf[128], *pstr;
   

    /* Check for proper number of arguments */
    if (nrhs == 0) {
        mexPrintf("header = smr_ReadHeader(smrfile)\n");
        mexPrintf("                 ver.0.90 Nov-2015 (c) 2015 YM@MPI Tuebingen\n");
        return;
    }

    /* Get the filename */
    if (mxIsChar(FILE_IN) != 1 || mxGetM(FILE_IN) != 1) {
        mexErrMsgTxt("smr_ReadHeader: first arg must be a string (filename)."); 
    }
    filename = mxArrayToString(FILE_IN);
    if (filename == NULL)
        mexErrMsgTxt("smr_ReadHeader: not enough memory for the filename string.");

    /* open the file */
    fp = smr_fopen(filename, "rb");
    if (!fp) {
        mexPrintf("smr_ReadHeader: smrfile='%s'\n",filename);
        if (filename != NULL)  { mxFree(filename);  filename = NULL; }
        mexErrMsgTxt("smr_ReadHeader: file not found.");
    }

    header = smr_readHeader(fp);
    smr_fclose(fp);  fp = NULL;

    if (header == NULL) {
        mexErrMsgTxt("smr_ReadHeader: failed to read file header."); 
        return;
    }

    // make the output structure
    HDR_OUT = mxCreateStructMatrix(1, 1, 18, field_names);

    /* short    systemID;                /\* filing system revision level *\/ */
    dims[0] = 1; dims[1] = 1;
    field_idx = mxGetFieldNumber(HDR_OUT,"systemID");
    field_val = mxCreateNumericArray(2,dims,mxINT16_CLASS, mxREAL);
    *((short *)mxGetData(field_val)) = (short)header->systemID;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* char     copyright[LENCOPYRIGHT]; /\* space for "(C) CED 87" *\/ */
    dims[0] = 1; dims[1] = LENCOPYRIGHT;
    memcpy(tmpbuf,header->copyright,LENCOPYRIGHT);  tmpbuf[LENCOPYRIGHT] = '\0';
    field_idx = mxGetFieldNumber(HDR_OUT,"copyright");
    field_val = mxCreateString(tmpbuf);
    //field_val = mxCreateCharArray(2,dims);
    //memcpy(mxGetData(field_val),header->copyright,LENCOPYRIGHT);
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);
    
    /* char     creator[8]; */
    //dims[0] = 1; dims[1] = 8;
    memcpy(tmpbuf,header->creator,8);  tmpbuf[8] = '\0';
    field_idx = mxGetFieldNumber(HDR_OUT,"creator");
    field_val = mxCreateString(tmpbuf);
    //field_val = mxCreateCharArray(2,dims);
    //memcpy(mxGetData(field_val),header->creator,8);
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    dims[0] = 1; dims[1] = 1;
    /* uint16_t usPerTime;               /\* microsecs per time unit *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"usPerTime");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = header->usPerTime;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->usPerTime;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* uint16_t timePerADC;              /\* time units per ADC interrupt *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"timePerADC");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = header->timePerADC;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->timePerADC;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* short    fileState;               /\* condition of the file *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"fileState");
    //field_val = mxCreateNumericArray(2,dims,mxINT16_CLASS, mxREAL);
    //*((int16_t *)mxGetData(field_val)) = header->fileState;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->fileState;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* int32_t  firstData;               /\* offset to first data block *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"firstData");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = header->firstData;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->firstData;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* short    channels;                /\* maximum number of channels *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"channels");
    //field_val = mxCreateNumericArray(2,dims,mxINT16_CLASS, mxREAL);
    //*((int16_t *)mxGetData(field_val)) = header->channels;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->channels;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);
    
    /* uint16_t chanSize;                /\* memory size to hold chans *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"chanSize");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = header->chanSize;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->chanSize;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* uint16_t extraData;               /\* No of bytes of extra data in file *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"extraData");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = header->extraData;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->extraData;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* uint16_t bufferSz;                /\* Not used on disk; bufferP in bytes *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"bufferSz");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = header->bufferSz;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->bufferSz;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* uint16_t osFormat;                /\* either 0x0101 for Mac, or 0x00 for PC *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"osFormat");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = header->osFormat;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->osFormat;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* int32_t  maxFTime;                /\* max time in the data file *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"maxFTime");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = header->maxFTime;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->maxFTime;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* double   dTimeBase;               /\* time scale factor, normally 1.0e-6 *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"dTimeBase");
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->dTimeBase;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* TSONTimeDate timeDate;            /\* time that corresponds to tick 0 *\/  */
    field_idx = mxGetFieldNumber(HDR_OUT,"timeDate");
    field_val = mxCreateStructMatrix(1, 1, 6, f_timeDate);
    {
        sub_fidx  = mxGetFieldNumber(field_val,"ucHun");
        sub_fval  = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
        *((uint8_t *)mxGetData(sub_fval)) = header->timeDate.ucHun;
        mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);

        sub_fidx  = mxGetFieldNumber(field_val,"ucSec");
        sub_fval  = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
        *((uint8_t *)mxGetData(sub_fval)) = header->timeDate.ucSec;
        mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);

        sub_fidx  = mxGetFieldNumber(field_val,"ucHour");
        sub_fval  = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
        *((uint8_t *)mxGetData(sub_fval)) = header->timeDate.ucHour;
        mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);

        sub_fidx  = mxGetFieldNumber(field_val,"ucDay");
        sub_fval  = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
        *((uint8_t *)mxGetData(sub_fval)) = header->timeDate.ucDay;
        mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);

        sub_fidx  = mxGetFieldNumber(field_val,"ucMon");
        sub_fval  = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
        *((uint8_t *)mxGetData(sub_fval)) = header->timeDate.ucMon;
        mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);

        sub_fidx  = mxGetFieldNumber(field_val,"wYear");
        sub_fval  = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
        *((uint16_t *)mxGetData(sub_fval)) = header->timeDate.wYear;
        mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
    }
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);    
    
    /* char     cAlignFlag;              /\* 0 if not aligned to 4, set bit 1 if aligned *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"cAlignFlag");
    field_val = mxCreateNumericArray(2,dims,mxINT8_CLASS, mxREAL);
    *((int8_t *)mxGetData(field_val)) = (int8_t)header->cAlignFlag;
    //field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    //*mxGetPr(field_val) = (double)header->cAlignFlag;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* int32_t  LUTable;                 /\* 0, or the TDOF to a saved look up table on disk *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"LUTable");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = header->LUTable;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)header->LUTable;
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    /* TFileComment fileComment;         /\* what user thinks of it so far *\/ */
    field_idx = mxGetFieldNumber(HDR_OUT,"fileComment");
    field_val = mxCreateCellMatrix(1,SON_NUMFILECOMMENTS);
    for (i = 0; i < SON_NUMFILECOMMENTS; i++) {
        n = (int)header->fileComment[i].len;
        pstr = &(header->fileComment[i].string[1]);
        if (n > 0 && n <= SON_COMMENTSZ) {
            memcpy(tmpbuf,pstr,n);  tmpbuf[n] = '\0';
        } else {
            tmpbuf[0] = '\0';
        }
        mxSetCell(field_val, i, mxCreateString(tmpbuf));
    }
    mxSetFieldByNumber(HDR_OUT, 0, field_idx, field_val);

    
    if (header != NULL) {
        free(header);  header = NULL;
    }

    return;
}
