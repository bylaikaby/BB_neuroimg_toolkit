/*=================================================================
 *
 * SMR_READCHANINFO.C	.MEX file to read smr channel info
 *
 * The calling syntax is:
 *
 *		[chinfo, chblck] = smr_ReadChanInfo(filename,chan)
 *
 * To compile in Matlab:
 *  Make sure you have run "mex -setup"
 *  Then at the command prompt:
 *    >> mex smr_ReadChanInfo.c   smrapi.c
 *  For Linux, use CFLAGS
 *    >> mex CFLAGS='-std=c99 -fPIC' smr_ReadChanInfo.c   smrapi.c
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
#define	CHINFO_OUT     plhs[0]
#define	CHBLCK_OUT     plhs[1]


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
{
    FILE *fp = NULL;
    char *filename;
    char *chanstr;
    int chanmat;  // matlab style indexing, starts from 1 (one), not 0(zero)
    SMR_TFileHead  *header = NULL;
    SMR_TChannel   *chinfo = NULL;
    SMR_CHANBLOCKS *chblck = NULL;
    SMR_TDataBlockHead *pblock;
    int i, j, n;
    // output structure
    const char *field_names[] = {
        "channel",
        "delSize", "nextDelBlock", "firstBlock", "lastBlock", "blocks",
        "nExtra",  "preTrig", "blocksMSW", "phySz", "maxData",
        "comment", "maxChanTime", "lChanDvd", "phyChan", "title",
        "idealRate", "kind", "delSizeMSB",
        "adc", "event", "real" };
    const char *field_adc[]   = { "scale", "offset", "units", "divide", "interleave" };
    const char *field_event[] = { "initLow", "nextLow" };
    const char *field_real[]  = { "min", "max", "units" };
    //const char *field_block[] = { "nblocks", "seek", "startTime", "endTime", "items" };
    const char *field_block[] = { "nblocks", "bheader", "varinfo"};
    mwSize dims[2];
    mxArray *field_val, *sub_fval;
    int field_idx, sub_fidx;
    char tmpbuf[128], *pstr;
    double *pdata;
   

    /* Check for proper number of arguments */
    if (nrhs == 0) {
        mexPrintf("[chinfo, chblocks] = smr_ReadChanInfo(smrfile,chan)\n");
        mexPrintf("   chan:1~MaxChan or a string of channel name/title\n");
        mexPrintf("                 ver.0.90 Nov-2015 (c) 2015 YM@MPI Tuebingen\n");
        return;
    }

    if (nrhs < 2) { 
        mexErrMsgTxt("smr_ReadChanInfo: missing \"channel\"."); 
    }


    /* Get the filename */
    if (mxIsChar(FILE_IN) != 1 || mxGetM(FILE_IN) != 1) {
        mexErrMsgTxt("smr_ReadChanInfo: first arg must be a string (filename)."); 
    }
    filename = mxArrayToString(FILE_IN);
    if (filename == NULL)
        mexErrMsgTxt("smr_ReadChanInfo: not enough memory for the filename string.");

    /* open the file */
    fp = smr_fopen(filename, "rb");
    if (!fp) {
        mexPrintf("smr_ReadChanInfo: smrfile='%s'\n",filename);
        if (filename != NULL)  { mxFree(filename);  filename = NULL; }
        mexErrMsgTxt("smr_ReadChanInfo: file not found.");
        return;
    }

    header = smr_readHeader(fp);
    if (header == NULL) {
        smr_fclose(fp);
        mexErrMsgTxt("smr_ReadChanInfo: failed to read file header."); 
        return;
    }

    // get channel index
    if (mxIsChar(CHAN_IN) == 1) {
        chanstr = mxArrayToString(CHAN_IN);
        chanmat = smr_findchan(fp,header,chanstr) + 1;  // +1 for matlab-style indexing
        if (chanmat <= 0) {
            smr_fclose(fp);
            free(header);
            mexPrintf("smr_ReadChanInfo: chanstr='%s'\n",chanstr);
            mexErrMsgTxt("smr_ReadChanInfo: failed to find the given channel.");
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
        mexErrMsgTxt("smr_ReadChanInfo: \"chan\" is out of range.");
        return;
    }
    chinfo = smr_readChanInfo(fp,header,chanmat-1);
    if (chinfo == NULL) {
        smr_fclose(fp);
        if (header != NULL) {
            free(header);  header = NULL;
        }
        mexErrMsgTxt("smr_ReadChanInfo: failed to read channel info.");
        return;
    }
    if (nlhs > 1) {
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
            mexErrMsgTxt("smr_ReadChanInfo: failed to read channel block-headers.");
            return;
        }
    }
    smr_fclose(fp);  fp = NULL;


    // make the output structure
    CHINFO_OUT = mxCreateStructMatrix(1, 1, 22, field_names);

    // channel (given input)
    field_idx = mxGetFieldNumber(CHINFO_OUT,"channel");
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chanmat;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    dims[0] = 1;  dims[1] = 1;

    /* uint16_t  delSize;         /\* number of blocks in deleted chain, 0=none *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"delSize");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = chinfo->delSize;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->delSize;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* int32_t   nextDelBlock;    /\* if deleted, first block in chain pointer *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"nextDelBlock");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = chinfo->nextDelBlock;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->nextDelBlock;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* int32_t   firstBlock;      /\* points at first block in file *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"firstBlock");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = chinfo->firstBlock;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->firstBlock;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* int32_t   lastBlock;       /\* points at last block in file *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"lastBlock");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = chinfo->lastBlock;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->lastBlock;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* uint16_t  blocks;          /\* number of blocks in file holding data *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"blocks");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = chinfo->blocks;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->blocks;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* uint16_t  nExtra;          /\* Number of extra bytes attached to marker *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"nExtra");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = chinfo->nExtra;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->nExtra;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* short     preTrig;         /\* Pre-trig points for ADC Marker data *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"preTrig");
    //field_val = mxCreateNumericArray(2,dims,mxINT16_CLASS, mxREAL);
    //*((int16_t *)mxGetData(field_val)) = chinfo->preTrig;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->preTrig;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* short     blocksMSW;       /\* hi word of block count in version 9 *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"blocksMSW");
    //field_val = mxCreateNumericArray(2,dims,mxINT16_CLASS, mxREAL);
    //*((int16_t *)mxGetData(field_val)) = chinfo->blocksMSW;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->blocksMSW;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* uint16_t  phySz;           /\* physical size of block written =n*512 *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"phySz");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = chinfo->phySz;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->phySz;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* uint16_t  maxData;         /\* maximum number of data items in block *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"maxData");
    //field_val = mxCreateNumericArray(2,dims,mxUINT16_CLASS, mxREAL);
    //*((uint16_t *)mxGetData(field_val)) = chinfo->maxData;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->maxData;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);
    
    /* TChanComm comment;         /\* string commenting on this data *\/ */
    n = (int)chinfo->comment.len;
    pstr = &(chinfo->comment.string[1]);
    memcpy(tmpbuf,pstr,n);  tmpbuf[n] = '\0';
    field_idx = mxGetFieldNumber(CHINFO_OUT,"comment");
    field_val = mxCreateString(tmpbuf);
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);
    
    /* int32_t   maxChanTime;     /\* last time on this channel *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"maxChanTime");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = chinfo->maxChanTime;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->maxChanTime;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* int32_t   lChanDvd;        /\* Was 0, V6: waveform divide from usPerTime, else 0 *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"lChanDvd");
    //field_val = mxCreateNumericArray(2,dims,mxINT32_CLASS, mxREAL);
    //*((int32_t *)mxGetData(field_val)) = chinfo->lChanDvd;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->lChanDvd;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* short     phyChan;         /\* physical channel used *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"phyChan");
    //field_val = mxCreateNumericArray(2,dims,mxINT16_CLASS, mxREAL);
    //*((int16_t *)mxGetData(field_val)) = chinfo->phyChan;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->phyChan;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* TTitle    title;           /\* user name for channel *\/ */
    n = (int)chinfo->title.len;
    pstr = &(chinfo->title.string[1]);
    memcpy(tmpbuf,pstr,n);  tmpbuf[n] = '\0';
    field_idx = mxGetFieldNumber(CHINFO_OUT,"title");
    field_val = mxCreateString(tmpbuf);
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);
    
    /* float     idealRate;       /\* ideal rate:ADC, estimate:event *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"idealRate");
    //field_val = mxCreateNumericArray(2,dims,mxSINGLE_CLASS, mxREAL);
    //*((float *)mxGetData(field_val)) = chinfo->idealRate;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->idealRate;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* unsigned char kind;        /\* data type in the channel - really is TDataKind*\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"kind");
    //field_val = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
    //*((uint8_t *)mxGetData(field_val)) = chinfo->kind;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->kind;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    /* unsigned char delSizeMSB;  /\* extension for deleted chain if version 9 *\/ */
    field_idx = mxGetFieldNumber(CHINFO_OUT,"delSizeMSB");
    //field_val = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
    //*((uint8_t *)mxGetData(field_val)) = chinfo->delSizeMSB;
    field_val = mxCreateDoubleMatrix(1,1,mxREAL);
    *mxGetPr(field_val) = (double)chinfo->delSizeMSB;
    mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);

    switch (chinfo->kind) {
    case 1:
    case 6:
        // adc : Data for ADC and ADCMark channels
        field_idx = mxGetFieldNumber(CHINFO_OUT,"adc");
        field_val = mxCreateStructMatrix(1, 1, 5, field_adc);
        {
            /*         float scale; */
            sub_fidx = mxGetFieldNumber(field_val,"scale");
            sub_fval = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(sub_fval) = (double)chinfo->v.adc.scale;
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            /*         float offset;      /\* to convert to units *\/ */
            sub_fidx = mxGetFieldNumber(field_val,"offset");
            sub_fval = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(sub_fval) = (double)chinfo->v.adc.offset;
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            /*         TUnits units;      /\* channel units *\/ */
            n = (int)chinfo->v.adc.units.len;
            pstr = &(chinfo->v.adc.units.string[1]);
            memcpy(tmpbuf,pstr,n);  tmpbuf[n] = '\0';
            sub_fidx = mxGetFieldNumber(field_val,"units");
            sub_fval = mxCreateString(tmpbuf);
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            /*         uint16_t divide;   /\* was ADC divide, now AdcMark interleave *\/ */
            if (header->systemID < 6) {
                sub_fidx = mxGetFieldNumber(field_val,"divide");
                sub_fval = mxCreateDoubleMatrix(1,1,mxREAL);
                *mxGetPr(sub_fval) = (double)chinfo->v.adc.divide;
                mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
                sub_fidx = mxGetFieldNumber(field_val,"interleave");
                sub_fval = mxCreateDoubleMatrix(1,1,mxREAL);
                *mxGetPr(sub_fval) = 1.0;
                mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            } else {
                sub_fidx = mxGetFieldNumber(field_val,"interleave");
                sub_fval = mxCreateDoubleMatrix(1,1,mxREAL);
                *mxGetPr(sub_fval) = (double)chinfo->v.adc.divide;
                mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            }
        }
        mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);
        break;
    case 4:
        // event : only used by EventBoth channels
        field_idx = mxGetFieldNumber(CHINFO_OUT,"event");
        field_val = mxCreateStructMatrix(1, 1, 2, field_event);
        {
            /*         uint8_t initLow;   /\* initial event state *\/ */
            sub_fidx = mxGetFieldNumber(field_val,"initLow");
            sub_fval = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
            *((uint8_t *)mxGetData(sub_fval)) = chinfo->v.event.initLow;
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            /*         uint8_t nextLow;   /\* expected state of next write *\/ */
            sub_fidx = mxGetFieldNumber(field_val,"nextLow");
            sub_fval = mxCreateNumericArray(2,dims,mxUINT8_CLASS, mxREAL);
            *((uint8_t *)mxGetData(sub_fval)) = chinfo->v.event.nextLow;
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
        }
        mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);
        break;
    case 7:
        // real : NB this is laid out as for adc data
        field_idx = mxGetFieldNumber(CHINFO_OUT,"real");
        field_val = mxCreateStructMatrix(1, 1, 3, field_real);
        {
            /*         float min;         /\* expected minimum value *\/ */
            sub_fidx = mxGetFieldNumber(field_val,"min");
            sub_fval = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(sub_fval) = (double)chinfo->v.real.min;
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            /*         float max;         /\* expected maximum value *\/ */
            sub_fidx = mxGetFieldNumber(field_val,"max");
            sub_fval = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(sub_fval) = (double)chinfo->v.real.max;
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
            /*         TUnits units;      /\* channel units *\/ */
            n = (int)chinfo->v.real.units.len;
            pstr = &(chinfo->v.real.units.string[1]);
            memcpy(tmpbuf,pstr,n);  tmpbuf[n] = '\0';
            sub_fidx = mxGetFieldNumber(field_val,"units");
            sub_fval = mxCreateString(tmpbuf);
            mxSetFieldByNumber(field_val, 0, sub_fidx, sub_fval);
        }
        mxSetFieldByNumber(CHINFO_OUT, 0, field_idx, field_val);
        break;
    }


    if (nlhs > 1) {
        // set block information
        CHBLCK_OUT = mxCreateStructMatrix(1, 1, 3, field_block);

        // nblocks
        field_idx = mxGetFieldNumber(CHBLCK_OUT,"nblocks");
        field_val = mxCreateDoubleMatrix(1,1,mxREAL);
        *mxGetPr(field_val) = (double)chblck->nblocks;
        mxSetFieldByNumber(CHBLCK_OUT, 0, field_idx, field_val);

        // bhead
        field_idx = mxGetFieldNumber(CHBLCK_OUT,"bheader");
        field_val = mxCreateDoubleMatrix(4,chblck->nblocks,mxREAL);
        pdata = mxGetPr(field_val);
        pblock = chblck->blhead;
        pdata[0] = (double)chinfo->firstBlock;
        pdata[1] = (double)pblock[0].startTime;
        pdata[2] = (double)pblock[0].endTime;
        pdata[3] = (double)pblock[0].items;
        for (i = 1, n = 4; i < chblck->nblocks; i++, n+=4) {
            pdata[n]   = (double)pblock[i-1].succBlock;
            pdata[n+1] = (double)pblock[i].startTime;
            pdata[n+2] = (double)pblock[i].endTime;
            pdata[n+3] = (double)pblock[i].items;
        }
        mxSetFieldByNumber(CHBLCK_OUT, 0, field_idx, field_val);

        // varinfo
        field_idx = mxGetFieldNumber(CHBLCK_OUT,"varinfo");
        field_val = mxCreateString("1:seek, 2:startTime, 3:endTime, 4:items");
        mxSetFieldByNumber(CHBLCK_OUT, 0, field_idx, field_val);
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

    return;
}
