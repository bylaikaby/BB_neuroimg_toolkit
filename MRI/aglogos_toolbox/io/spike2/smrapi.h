/*
 *  SMRAPI.H : header file for SMR (CED's Spike2 format) interface
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
 *  See also smrapi.c son.h sonintl.h machine.h
 */



#ifndef _SMR_API_H_INCLUDED
#define _SMR_API_H_INCLUDED

#if defined(_MSC_VER)
# if (_MSC_VER <= 1500)
typedef __int8   int8_t;
typedef __int16  int16_t;
typedef __int32  int32_t;
typedef __int64  int64_t;
typedef unsigned __int8   uint8_t;
typedef unsigned __int16  uint16_t;
typedef unsigned __int32  uint32_t;
typedef unsigned __int64  uint64_t;
# elif (_MSC_VER == 1600) && defined(_INTSAFE_H_INCLUDED_)
#   pragma warning (push)
#   pragma warning (disable : 4005)
#   include <stdint.h>
#   pragma warning (pop)
# else
#   include <stdint.h>
# endif
#else
#  include <stdint.h>
#endif


#ifdef _WIN32
#  define STRICMP   _stricmp
#  define STRNICMP  _strnicmp
#else
#  define STRICMP   strcasecmp
#  define STRNICMP  strncasecmp
#endif


/*
** These constants define the number and length of various strings
*/
#define SON_NUMFILECOMMENTS 5
#define SON_COMMENTSZ 79
#define SON_CHANCOMSZ 71
#define SON_UNITSZ 5
#define SON_TITLESZ 9

#define LENCOPYRIGHT  10                    /* Length of copyright and serial strings */

typedef short TAdc;
typedef char TMarkBytes[4];


#define SMR_LSTRING(size) union{unsigned char len;char string[size+1];}


#ifdef __cplusplus
extern "C" {
#endif

//typedef struct {char acID[8];} TSONCreator;    /* application identifier */

typedef SMR_LSTRING(SON_CHANCOMSZ) TChanComm;
typedef SMR_LSTRING(SON_COMMENTSZ) TComment;
typedef SMR_LSTRING(SON_TITLESZ)   TTitle;
typedef SMR_LSTRING(SON_UNITSZ)    TUnits;           /* units string for adc channels */
typedef TComment TFileComment[SON_NUMFILECOMMENTS];  /* file comment for header */

typedef struct
{
    unsigned char ucHun;    /* hundreths of a second, 0-99 */
    unsigned char ucSec;    /* seconds, 0-59 */
    unsigned char ucMin;    /* minutes, 0-59 */
    unsigned char ucHour;   /* hour - 24 hour clock, 0-23 */
    unsigned char ucDay;    /* day of month, 1-31 */
    unsigned char ucMon;    /* month of year, 1-12 */
    uint16_t      wYear;    /* year 1980-65535! */
} TSONTimeDate;


#pragma pack(1)
typedef struct _smr_tfilehead {
    short    systemID;                /* filing system revision level */
    char     copyright[LENCOPYRIGHT]; /* space for "(C) CED 87" */
    //TSONCreator creator;            /* optional application identifier */
    char     creator[8];
    uint16_t usPerTime;               /* microsecs per time unit */
    uint16_t timePerADC;              /* time units per ADC interrupt */
    short    fileState;               /* condition of the file */
    int32_t  firstData;               /* offset to first data block */
    short    channels;                /* maximum number of channels */
    uint16_t chanSize;                /* memory size to hold chans */
    uint16_t extraData;               /* No of bytes of extra data in file */
    uint16_t bufferSz;                /* Not used on disk; bufferP in bytes */
    uint16_t osFormat;                /* either 0x0101 for Mac, or 0x00 for PC */
    int32_t  maxFTime;                /* max time in the data file */
    double   dTimeBase;               /* time scale factor, normally 1.0e-6 */
    TSONTimeDate timeDate;            /* time that corresponds to tick 0 */ 
    char     cAlignFlag;              /* 0 if not aligned to 4, set bit 1 if aligned */
    char     pad0[3];                 /* align the next item to a 4 byte boundary */
    int32_t  LUTable;                 /* 0, or the TDOF to a saved look up table on disk */
    char     pad[44];                 /* padding for the future */
    TFileComment fileComment;         /* what user thinks of it so far */
} SMR_TFileHead;

typedef struct _smr_tchannel {
    uint16_t  delSize;         /* number of blocks in deleted chain, 0=none */
    int32_t   nextDelBlock;    /* if deleted, first block in chain pointer */
    int32_t   firstBlock;      /* points at first block in file */
    int32_t   lastBlock;       /* points at last block in file */
    uint16_t  blocks;          /* number of blocks in file holding data */
    uint16_t  nExtra;          /* Number of extra bytes attached to marker */
    short     preTrig;         /* Pre-trig points for ADC Marker data */
    short     blocksMSW;       /* hi word of block count in version 9 */
    uint16_t  phySz;           /* physical size of block written =n*512 */
    uint16_t  maxData;         /* maximum number of data items in block */
    TChanComm comment;         /* string commenting on this data */
    int32_t   maxChanTime;     /* last time on this channel */
    int32_t   lChanDvd;        /* Was 0, V6: waveform divide from usPerTime, else 0 */
    short     phyChan;         /* physical channel used */
    TTitle    title;           /* user name for channel */
    float     idealRate;       /* ideal rate:ADC, estimate:event */
    unsigned char kind;        /* data type in the channel - really is TDataKind*/
    unsigned char delSizeMSB;  /* extension for deleted chain if version 9 */
    union                      /* Section which changes with the data */
    {
        struct
        {                      /* Data for ADC and ADCMark channels */
            float scale;
            float offset;      /* to convert to units */
            TUnits units;      /* channel units */
            uint16_t divide;   /* was ADC divide, now AdcMark interleave */
        } adc;
        struct
        {                      /* only used by EventBoth channels */
            uint8_t initLow;   /* initial event state */
            uint8_t nextLow;   /* expected state of next write */
        } event;
        struct
        {                      /* This one for real marker data */
            float min;         /* expected minimum value */
            float max;         /* expected maximum value */
            TUnits units;      /* channel units */
        } real;                /* NB this is laid out as for adc data */
    } v;
} SMR_TChannel;


/*
** The data is stored in blocks (again multiples of 512 bytes long)
** on disk.  All the blocks have an identical header, but the rest
** depends on what the data is.
*/
typedef struct
{
    int32_t    mark;            /* Marker time as for events */
    TMarkBytes mvals;           /* the marker values */
} TMarker;

#define SON_MAXADCMARK 1024     /* maximum points in AdcMark data (arbitrary) */
#define SON_MAXAMTRACE 4        /* maximum interleaved traces in AdcMark data */
typedef struct
{
    TMarker m;                  /* the marker structure */
    TAdc a[SON_MAXADCMARK*SON_MAXAMTRACE];     /* the attached ADC data */
} TAdcMark;

#define ADCdataBlkSize  32000
#define timeDataBlkSize 16000
#define markDataBlkSize 8000
#define realDataBlkSize 8000

typedef struct _smr_tdatablock {
    int32_t  predBlock;     /* Predecessor block in the file */
    int32_t  succBlock;     /* Following block in the file */
    int32_t  startTime;     /* First time in the block */
    int32_t  endTime;       /* Last time in the block */
    uint16_t chanNumber;    /* Channel number+1 for the block */
    uint16_t items;         /* Actual number of data items found */
    union
    {
        TAdc      int2Data [ADCdataBlkSize];    /* ADC data */
        int32_t   int4Data [timeDataBlkSize];   /* time data */
        TMarker   markData [markDataBlkSize];   /* marker data */
        TAdcMark  adcMarkData;                  /* ADC marker data */
        float     realData [realDataBlkSize];   /* RealWave data */
    } data ;
} SMR_TDataBlock;

typedef struct _smr_tdatablockhead {
    int32_t  predBlock;     /* Predecessor block in the file */
    int32_t  succBlock;     /* Following block in the file */
    int32_t  startTime;     /* First time in the block */
    int32_t  endTime;       /* Last time in the block */
    uint16_t chanNumber;    /* Channel number+1 for the block */
    uint16_t items;         /* Actual number of data items found */
} SMR_TDataBlockHead;


typedef struct _smr_chanblocks {
    int32_t  nblocks;
    SMR_TDataBlockHead *blhead;
} SMR_CHANBLOCKS;
    
#pragma pack()
 
/*************************************************/
/* prototypes */

FILE *smr_fopen(const char *fname, const char *mode);
int smr_fseek(FILE *fp, int64_t offset, int origin);
int smr_fclose(FILE *fp);

void smr_freeHeader(SMR_TFileHead *h);
void smr_initHeader(SMR_TFileHead *h);
void smr_freeChanInfo(SMR_TChannel *chinfo);
void smr_freeChanBlocks(SMR_CHANBLOCKS *chblocks);

int    smr_findchan(FILE *fp, SMR_TFileHead *header, char *chanstr);
double smr_getSampleInterval(FILE *fp, SMR_TFileHead *header, SMR_TChannel *chinfo);
    
SMR_TFileHead  *smr_readHeader(FILE *fp);
SMR_TChannel   *smr_readChanInfo(FILE *fp, SMR_TFileHead *header, int chan);
SMR_CHANBLOCKS *smr_readChanBlocks(FILE *fp, SMR_TFileHead *header, SMR_TChannel *chinfo);
int smr_ReadWaveS(FILE *fp, SMR_TFileHead *header, SMR_TChannel *chinfo, SMR_CHANBLOCKS *chblck, int bfrom, int bto, short **vals, int *istart);


#ifdef MATLAB_MEX_FILE /* Is this file being compiled as a MEX-file? */

#endif


#ifdef __cplusplus
}
#endif

#endif	/* end of _SMR_API_H_INCLUDED	*/
    
