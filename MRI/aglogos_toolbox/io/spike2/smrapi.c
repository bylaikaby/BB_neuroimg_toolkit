/*
 *  SMRAPI.C : APIs for SMR (CED's Spike2 format) interface
 *
 *  NOTE :
 *    Following data type are substituted for OS compatibility.
 *      BOOLEAN : uint8_t
 *      WORD    : uint16_t
 *      long    : int32_t
 *      TDOF    : int32_t
 *      TSTime  : int32_t
 *      TSONCreator : as char[8]
 *
 *  VERSION :
 *    0.90 12.Nov.2015 YM@MPI  pre-release
 *
 *  See also smrapi.h son.h sonintl.h machine.h
 */


#ifdef _WIN32
//#elif defiend (__OSX__)
#elif defined __OSX__
#define off64_t   off_t
#define fopen64   fopen
#define fseeko64  fseek
#else
#define _LARGEFILE_SOURCE
#define _FILE_OFFSET_BITS  64
#endif

#include <stdlib.h>
#include <stdio.h>
#include <memory.h> 
#include "smrapi.h"


/////////////////////////////////////////////////////////////////////////
// local functions
#ifdef _WIN32
FILE *smr_fopen(const char *fname, const char *mode)
{
    FILE *fp;
    if (fopen_s(&fp, fname, mode) != 0)  fp = NULL;
    return fp;
}

int smr_fseek(FILE *fp, int64_t offset, int origin)
{
    return _fseeki64(fp, offset, origin);
}

int smr_fclose(FILE *fp)
{
    return fclose(fp);
}
#else
FILE *smr_fopen(const char *fname, const char *mode)
{
    return fopen64(fname,mode);
}

int smr_fseek(FILE *fp, int64_t offset, int origin)
{
    //return fseek(fp, offset, origin);
    return fseeko64(fp, (off64_t)offset, origin);
}

int smr_fclose(FILE *fp)
{
    return fclose(fp);
}
#endif


/////////////////////////////////////////////////////////////////////////
// SMR APIs
void smr_freeHeader(SMR_TFileHead *h)
{
    if (h == NULL)  return;
    free(h);  h = NULL;
}

void smr_initHeader(SMR_TFileHead *h)
{
    return;
}


void smr_freeChanInfo(SMR_TChannel *chinfo)
{
    if (chinfo == NULL)  return;
    free(chinfo);  chinfo = NULL;
    return;
}

void smr_freeChanBlocks(SMR_CHANBLOCKS *chblocks)
{
    if (chblocks == NULL)  return;

    if (chblocks->blhead  != NULL) {
        free(chblocks->blhead);
        chblocks->blhead = NULL;
    }
    
    free(chblocks);  chblocks = NULL;
    return;
}



int  smr_findchan(FILE *fp, SMR_TFileHead *header, char *chanstr)
{
    SMR_TChannel chinfo;    
    size_t status;
    int chan, i;
    char *pstr;

    if (header == NULL)  return -1;
    if (chanstr == NULL)  return -1;

    pstr = &(chinfo.title.string[1]);
    chan = -1;
    for (i = 0; i < header->channels; i++) {
        smr_fseek(fp, (int64_t)(512+140*i), SEEK_SET);
        //status = fread(chinfo,  sizeof(SMR_TFileHead), 1, fp);
        status = fread(&chinfo,  140, 1, fp);  // sizeof)(SMR_TChannel) must be 140.
        if (!status)  return -1;
        pstr[chinfo.title.len] = '\0';
        if (strcmp(chanstr,pstr) == 0) {
            chan = i;  break;
        }
    }
    return chan;
}

double smr_getSampleInterval(FILE *fp, SMR_TFileHead *header, SMR_TChannel *chinfo)
{
    double sampt;

    if (header == NULL || chinfo == NULL)  return 0;

    // header
    /* uint16_t usPerTime;               /\* microsecs per time unit *\/ */
    /* uint16_t timePerADC;              /\* time units per ADC interrupt *\/ */
    /* double   dTimeBase;               /\* time scale factor, normally 1.0e-6 *\/ */

    // chinfo
    /* int32_t   lChanDvd;        /\* Was 0, V6: waveform divide from usPerTime, else 0 *\/ */
    /* union                      /\* Section which changes with the data *\/ */
    /* { */
    /*     struct */
    /*     {                      /\* Data for ADC and ADCMark channels *\/ */
    /*         float scale; */
    /*         float offset;      /\* to convert to units *\/ */
    /*         TUnits units;      /\* channel units *\/ */
    /*         uint16_t divide;   /\* was ADC divide, now AdcMark interleave *\/ */
    /*     } adc; */
    /*     ...    */
    /* } v; */

        
    if (header->systemID < 6) {
        sampt = (double)chinfo->v.adc.divide * (double)header->usPerTime * (double)header->timePerADC;
    } else {
        sampt = (double)chinfo->lChanDvd * (double)header->usPerTime * (1.0e+6*header->dTimeBase);
    }
    
    return sampt;
}


//////////////////////////////////////////////////////////////////

SMR_TFileHead *smr_readHeader(FILE *fp)
{
    SMR_TFileHead *header;
    size_t status;
    
    header = (SMR_TFileHead *) calloc(1, sizeof(SMR_TFileHead));
    if (header == NULL)  return NULL;

    //mexPrintf("sizeof(SMR_TFileHead)=%d\n",sizeof(SMR_TFileHead));

    smr_fseek(fp, 0LL, SEEK_SET);
    //status = fread(header,  sizeof(SMR_TFileHead), 1, fp);
    status = fread(header,  512, 1, fp);  // sizeof(SMR_TFileHead) must be 512.
    if (!status)  goto error;

    if (header->systemID < 6) {
        header->dTimeBase       = 1.0e-6;
        header->timeDate.ucHun  = 0;
        header->timeDate.ucSec  = 0;
        header->timeDate.ucHour = 0;
        header->timeDate.ucDay  = 0;
        header->timeDate.ucMon  = 0;
        header->timeDate.wYear  = 0;
    }
    
    return header;

error:
    free(header);  header = NULL;
    return NULL;
}


SMR_TChannel *smr_readChanInfo(FILE *fp, SMR_TFileHead *header, int chan)
{
    SMR_TChannel *chinfo;
    size_t status;

    if (header == NULL)  return NULL;
    if (chan < 0 || chan >= header->channels)  return NULL;
    
    chinfo = (SMR_TChannel *) calloc(1, sizeof(SMR_TChannel));
    if (chinfo == NULL)  return NULL;

    // mexPrintf("sizeof(SMR_TChannel)=%d\n",sizeof(SMR_TChannel));  // must be 140

    smr_fseek(fp, (int64_t)(512+140*chan), SEEK_SET);
    //status = fread(chinfo,  sizeof(SMR_TFileHead), 1, fp);
    status = fread(chinfo,  140, 1, fp);  // sizeof)(SMR_TChannel) must be 140.
    if (!status)  goto error;
    
    return chinfo;

error:
    free(chinfo);  chinfo = NULL;
    return NULL;
}

SMR_CHANBLOCKS *smr_readChanBlocks(FILE *fp, SMR_TFileHead *header, SMR_TChannel *chinfo) {

    SMR_CHANBLOCKS *chblocks;
    SMR_TDataBlockHead *pblock;
    size_t status;
    int i, n;

    if (header == NULL || chinfo == NULL)  return NULL;

    n = (int)chinfo->blocks;
    
    chblocks = (SMR_CHANBLOCKS *) calloc(1, sizeof(SMR_CHANBLOCKS));
    if (chblocks == NULL)  return NULL;

    chblocks->nblocks   = 0;
    chblocks->blhead    = NULL;
    if (n <= 0)  return chblocks;
    
    chblocks->blhead    = (SMR_TDataBlockHead *)malloc(n*sizeof(SMR_TDataBlockHead));
    if (chblocks->blhead == NULL) goto error;

    pblock = chblocks->blhead;

    // read the 1st block
    smr_fseek(fp, (int64_t)chinfo->firstBlock, SEEK_SET);
    status = fread(&pblock[0], sizeof(SMR_TDataBlockHead), 1, fp);
    if (!status)  goto error;
    
    if (pblock[0].succBlock == -1) {
        chblocks->nblocks = 1;
    } else {
        for (i = 1; i < n; i++) {
            smr_fseek(fp, (int64_t)pblock[i-1].succBlock, SEEK_SET);            
            status = fread(&pblock[i], sizeof(SMR_TDataBlockHead), 1, fp);
        }
        chblocks->nblocks = n;
    }

    return chblocks;
      
error:
    smr_freeChanBlocks(chblocks);  chblocks = NULL;
    return;
}



int smr_ReadWaveS(FILE *fp, SMR_TFileHead *header, SMR_TChannel *chinfo, SMR_CHANBLOCKS *chblck, int bfrom, int bto, short **vals, int *istart)
{
    int i;
    int nitems, nread;
    short *data = NULL;
    size_t status;
    int64_t nseek;
    
    if (header == NULL || chinfo == NULL || chblck == NULL)  return 0;

    *istart = -1;
    if (bfrom < 0 || bfrom >= (int)chinfo->blocks)  return 0;
    if (bto   < 0 || bto   >= (int)chinfo->blocks)  return 0;
    if (bfrom > bto)  return 0;

    nitems = 0;
    for (i = bfrom; i <= bto; i++) {
        nitems = nitems + (int64_t)chblck->blhead[i].items;
    }

    //data = (short *)malloc(nitems*sizeof(short));
    data = (short *)calloc(nitems,sizeof(short));
    if (data == NULL)  return 0;

    nread = 0;
    for (i = bfrom; i <= bto; i++) {
        if (i == 0) {
            nseek = (int64_t)chinfo->firstBlock + sizeof(SMR_TDataBlockHead);
        } else {
            nseek = (int64_t)chblck->blhead[i-1].succBlock + sizeof(SMR_TDataBlockHead);
        }
        smr_fseek(fp, nseek, SEEK_SET);
        status = fread(&data[nread], sizeof(short), chblck->blhead[i].items, fp);
        nread = nread + (int)status;
        if (status != (size_t)chblck->blhead[i].items) {
            break;
        }
    }

    *vals = data;
    *istart = (int)chblck->blhead[bfrom].startTime;
    return nread;
}




#ifdef MATLAB_MEX_FILE /* Is this file being compiled as a MEX-file? */

#endif
