/*=================================================================
 *
 * choose_metric5_psiC.C	.MEX version of choose_metric5_psi.m
 *
 * The calling syntax is:
 *
 *  psi = choose_metric5_psiC(u)
 *
 * To compile in Matlab:
 *  Make sure you have run "mex -setup"
 *  Then at the command prompt:
 *     >> mex -largeArrayDims choose_metric5_psiC.c
 *
 *
 *=================================================================*/
/* $Revision: 1.00 $ 25-Jan-2017 YM/MPI :                              */


#include <math.h>
#include <stdio.h>
#include "matrix.h"
#include "mex.h"

// %v = @(u) sqrt(u.*conj(u))/sqrt(u'*u);
// %psi = @(u) -v(u)'*log(v(u));
// %dpsi = @(u) -(v(u).*(1+log(v(u)))./conj(u) - sign(u).*v(u) * (v(u)'*(1 + log(v(u)))) / sqrt(u'*u));
// vu  = sqrt(u.*conj(u))/sqrt(u'*u);
// psi = -vu'*log(vu);


#define IN_DATA   prhs[0]  // input vector
#define OUT_DATA  plhs[0]  // output vector



void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[] )
{
    // vars
    mwSize N, dims[2];
    double *u_re, *u_im;
    double sqrtuu, *v_vu, tmpv, psi;
    int i;

    v_vu = NULL;
    // Check for proper number of arguments
    if (nrhs != 1) {
        mexPrintf("Usage: psi = choose_metric5_psiC(u)\n");
        mexPrintf("Note: INPUT \"u\" MUST BE A COLUMN VECTOR (double).     ver.1.00 Jan-2017\n");
        return;
    }

    // accept only double precision
    if (mxIsDouble(IN_DATA) == 0) {
        mexErrMsgTxt(" choose_metric5_psiC: The input must be DOUBLE-precision"); 
    }
    // accept only a vector
    if (mxGetNumberOfDimensions(IN_DATA) > 2) {
        mexErrMsgTxt(" choose_metric5_psiC: The input must be a column vector.");
    }
    dims[0] = mxGetM(IN_DATA);  // # of rows in array
    dims[1] = mxGetN(IN_DATA);  // # of columns in array
    if (dims[1] != 1) {
        mexErrMsgTxt(" choose_metric5_psiC: The input must be a column vector.");
    }
    N = dims[0] * dims[1];

    if (mxIsComplex(IN_DATA)) {
        u_re = (double *)mxGetData(IN_DATA);
        u_im = (double *)mxGetImagData(IN_DATA);
    } else {
        u_re = (double *)mxGetData(IN_DATA);
        u_im = NULL;
    }
    OUT_DATA = mxCreateDoubleMatrix(1, 1, mxREAL);
    if (OUT_DATA == NULL) {
        mexErrMsgTxt(" choose_metric5_psiC: not enough memory for the output.");
        return;
    }

    v_vu = (double *)mxMalloc(N*sizeof(double));
    if (v_vu == NULL) {
        if (v_vu != NULL)  { mxFree(v_vu);  v_vu = NULL; }
        mexErrMsgTxt(" choose_metric5_psiC: not enough memory for processing.");
        return;
    }

    // note that "sqrtuu" and "vu" are not complex.
    // vu  = sqrt(u.*conj(u))/sqrt(u'*u);
    // psi = -vu'*log(vu);

    sqrtuu = 0;;
    // first, calculate sqrtuu.
    if (mxIsComplex(IN_DATA)) {
        for (i = 0; i < N; i++) {
            tmpv = u_re[i]*u_re[i] + u_im[i]*u_im[i];
            sqrtuu = sqrtuu + tmpv;
            v_vu[i] = sqrt(tmpv);
        }
        sqrtuu = sqrt(sqrtuu);
    } else {
        for (i = 0; i < N; i++) {
            tmpv = u_re[i]*u_re[i];
            sqrtuu = sqrtuu + tmpv;
            v_vu[i] = sqrt(tmpv);
        }
        sqrtuu = sqrt(sqrtuu);
    }

    psi = 0;
    for (i = 0; i < N; i++) {
        tmpv = v_vu[i] / sqrtuu;
        tmpv = -tmpv*log(tmpv);
        psi = psi + tmpv;
    }
    *(double *)mxGetData(OUT_DATA) = psi;
    

#if 0
    mexPrintf("sqrtuu = %g\n",sqrtuu.re);
    for (i = 0; i < 5; i++)  mexPrintf("vu[%2d]     = %g\n",i+1,v_vu[i]);
#endif

    if (v_vu != NULL)  { mxFree(v_vu);  v_vu = NULL; }


    return;
}
