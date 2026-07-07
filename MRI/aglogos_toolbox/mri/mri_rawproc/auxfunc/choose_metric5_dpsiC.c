/*=================================================================
 *
 * choose_metric5_dpsiC.C	.MEX version of choose_metric5_dpsi.m
 *
 * The calling syntax is:
 *
 *  dpsi = choose_metric5_dpsiC(u)
 *
 * To compile in Matlab:
 *  Make sure you have run "mex -setup"
 *  Then at the command prompt:
 *     >> mex -largeArrayDims choose_metric5_dpsiC.c
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
// sqrtuu = sqrt(u'*u);
// cu     = conj(u);
// vu     = sqrt(u.*cu)/sqrtuu;
// logvu1 = 1+log(vu);
// dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * (vu'*(logvu1)) / sqrtuu);

#define IN_DATA   prhs[0]  // input vector
#define OUT_DATA  plhs[0]  // output vector

#pragma pack(1)
typedef struct { double re, im; } d_complex;
#pragma pack()


d_complex c_conv(double x, double y)
{
    d_complex z;
    z.re = x;  z.im = y;
    return z;
}

d_complex c_conj(d_complex z)
{
    z.im = -z.im;
    return z;
}

double c_abs(d_complex z)
{
    double t;
    if (z.re == 0)  return fabs(z.im);
    if (z.im == 0)  return fabs(z.re);
    if (fabs(z.im) > fabs(z.re)) {
        t = z.re / z.im;
        return fabs(z.im) * sqrt(1 + t*t);
    } else {
        t = z.im / z.re;
        return fabs(z.re) * sqrt(1 + t*t);
    }
}

d_complex c_sign(d_complex z)
{
    double r = c_abs(z);
    if (r == 0) {
        z.re = 0;
        z.im = 0;
    } else {
        z.re = z.re / r;
        z.im = z.im / r;
    }
    return z;
}

double c_arg(d_complex z)
{
    return atan2(z.im, z.re);
}

d_complex c_add(d_complex x, d_complex y)
{
    x.re = x.re + y.re;
    x.im = x.im + y.im;
    return x;
}

d_complex c_sub(d_complex x, d_complex y)
{
    x.re = x.re - y.re;
    x.im = x.im - y.im;
    return x;
}

d_complex c_mul(d_complex x, d_complex y)
{
    d_complex z;
    z.re = x.re*y.re - x.im*y.im;
    z.im = x.re*y.im + x.im*y.re;
    return z;
}

d_complex c_div(d_complex x, d_complex y)
{
    double w, d;
    d_complex z;

    if (fabs(y.re) >= fabs(y.im)) {
        w = y.im / y.re;  d = y.re + y.im * w;
        z.re = (x.re + x.im * w) / d;
        z.im = (x.im - x.re * w) / d;
    } else {
        w = y.re / y.im;  d = y.re * w + y.im;
        z.re = (x.re * w + x.im) / d;
        z.im = (x.im * w - x.re) / d;
    }
    return z;
}

d_complex c_exp(d_complex x)
{
    double a;
    a = exp(x.re);
    x.re = a * cos(x.im);
    x.im = a * sin(x.im);
    return x;
}

d_complex c_log(d_complex x)
{
    d_complex z;
    z.re = 0.5 * log(x.re*x.re + x.im*x.im);
    z.im = atan2(x.im, x.re);
    return z;
}

d_complex c_pow(d_complex x, d_complex y)
{
    return c_exp(c_mul(y, c_log(x)));
}

d_complex c_sin(d_complex x)
{
    double e, f;
    e = exp(x.im);  f = 1 / e;
    x.im = 0.5 * cos(x.re) * (e - f);
    x.re = 0.5 * sin(x.re) * (e + f);
    return x;
}

d_complex c_cos(d_complex x)
{
    double e, f;
    e = exp(x.im);  f = 1 / e;
    x.im = 0.5 * sin(x.re) * (f - e);
    x.re = 0.5 * cos(x.re) * (f + e);
    return x;
}

d_complex c_tan(d_complex x)
{
    double e, f, d;
    e = exp(2 * x.im);  f = 1 / e;
    d = cos(2 * x.re) + 0.5 * (e + f);
    x.re = sin(2 * x.re) / d;
    x.im = 0.5 * (e - f) / d;
    return x;
}

d_complex c_sinh(d_complex x)
{
    double e, f;
    e = exp(x.re);  f = 1 / e;
    x.re = 0.5 * (e - f) * cos(x.im);
    x.im = 0.5 * (e + f) * sin(x.im);
    return x;
}

d_complex c_cosh(d_complex x)
{
    double e, f;
    e = exp(x.re);  f = 1 / e;
    x.re = 0.5 * (e + f) * cos(x.im);
    x.im = 0.5 * (e - f) * sin(x.im);
    return x;
}

d_complex c_tanh(d_complex x)
{
    double e, f, d;
    e = exp(2 * x.re);  f = 1 / e;
    d = 0.5 * (e + f) + cos(2 * x.im);
    x.re = 0.5 * (e - f) / d;
    x.im = sin(2 * x.im) / d;
    return x;
}

# define SQRT05 (0.707106781186547524)  // sqrt(0.5)
d_complex c_sqrt(d_complex x)
{
    double r, w;
    r = c_abs(x);
    w = sqrt(r + fabs(x.re));
    if (x.re >= 0) {
        x.re = SQRT05 * w;
        x.im = SQRT05 * x.im / w;
    } else {
        x.re = SQRT05 * fabs(x.im) / w;
        x.im = (x.im >= 0) ? SQRT05 * w : -SQRT05 * w;
    }
    
    return x;
}


// sqrt(u'*u)
double calc_sqrt_uu(mxArray *iu, mwSize n)
{
    mwSize i;
    double *a, *b;
    d_complex z;
    
    a = (double *)mxGetData(iu);
    b = (double *)mxGetImagData(iu);
    z.re = 0;  z.im = 0;
    if (mxIsComplex(iu)) {
        // in MATLAB, u' (u-dash) is transposed conj.
        for (i = 0; i < n; i++) {
            z.re = z.re + a[i]*a[i] + b[i]*b[i];
        }
        //mexPrintf("u'*u = %g + %gi\n",z.re,z.im);
        //z = c_sqrt(z);
        z.re = sqrt(z.re);
    } else {
        for (i = 0; i < n; i++) {
            z.re = z.re + a[i]*a[i];
        }
        z.re = sqrt(z.re);
        z.im = 0;
    }
    return z.re;
}

// cu     = conj(u);
void calc_cu(mxArray *iu, mwSize n, d_complex *cu)
{
    double *a, *b;
    mwSize i;

    a = (double *)mxGetData(iu);
    b = (double *)mxGetImagData(iu);
    if (mxIsComplex(iu)) {
        for (i = 0; i < n; i++) {
            cu[i].re = a[i];
            cu[i].im = -b[i];
        }
    } else {
        for (i = 0; i < n; i++) {
            cu[i].re = a[i];
            cu[i].im = 0;
        }
    }
    return;
}

//vu     = sqrt(u.*cu)/sqrtuu;
void calc_vu(mxArray *iu, mwSize n, double sqrtuu, double *vu)
{
    double *a, *b;
    mwSize i;

    a = (double *)mxGetData(iu);
    b = (double *)mxGetImagData(iu);
    if (mxIsComplex(iu)) {
        for (i = 0; i < n; i++) {
            vu[i] = sqrt(a[i]*a[i] + b[i]*b[i]) / sqrtuu;
        }
    } else {
        for (i = 0; i < n; i++) {
            vu[i] = sqrt(a[i]*a[i]) / sqrtuu;
        }
    }
    return;
}


//logvu1 = 1+log(vu);
void calc_1_log_vu(mxArray *iu, mwSize n, double *vu, double *logvu1)
{
    mwSize i;

    // note that "vc_vu" is not complex
    for (i = 0; i < n; i++)  logvu1[i] = 1 + log(vu[i]);
    return;
}

// dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * (vu'*(logvu1)) / sqrtuu);
// note "vu" and "logvu1" are not complex.
void calc_dpsi(mxArray *iu, mwSize n, double sqrtuu, double *v_vu, double *v_logvu1, double w, double *dpsi_re, double *dpsi_im)
{
    double *a, *b;
    mwSize i;
    d_complex z1, z2;

    if (w == 0) {
        for (i = 0; i < n; i++) {
            // note that "vu" and "logvu1" are not complex
            w = w + v_vu[i] * v_logvu1[i];
        }
        // note that "vu", "logvu1" and "sqrtuu" are not complex
        w = w / sqrtuu;
    }

    a = (double *)mxGetData(iu);
    b = (double *)mxGetImagData(iu);
    if (mxIsComplex(iu)) {
        for (i = 0; i < n; i++) {
            z1.re = v_vu[i] * v_logvu1[i];
            z1.im = 0;
            z1 = c_div(z1,c_conv(a[i],-b[i]));
            //if (i == 0)  mexPrintf("z1[%d] = %g %+gi\n",i+1,z1.re,z1.im);
            // note that "vu", "logvu1" and "sqrtuu" are not complex
            z2 = c_sign(c_conv(a[i],b[i]));
            //if (i == 0)  mexPrintf("sign(u[%d]) = %g %+gi\n",i+1,z2.re,z2.im);
            z2.re = z2.re * v_vu[i] * w;
            z2.im = z2.im * v_vu[i] * w;
            //if (i == 0)  mexPrintf("z2[%d] = %g %+gi\n",i+1,z2.re,z2.im);
            dpsi_re[i] = - (z1.re - z2.re);
            dpsi_im[i] = - (z1.im - z2.im);
            //if (i == 0)  mexPrintf("dpsi[%d] = %g %+gi\n",i+1,dpsi_re[i],dpsi_im[i]);
        }
    } else {
        for (i = 0; i < n; i++) {
            //z1.re = v_vu[i].re * v_logvu1[i].re / v_cu[i].re;
            z1.re = v_vu[i] * v_logvu1[i] / a[i];
            z2.re = v_vu[i] * w;
            dpsi_re[i] = (a[i] > 0)?  -(z1.re - z2.re) : -(z1.re + z2.re);
        }
    }
    return;
}


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[] )
{
    // vars
    mwSize N, dims[2];
    double *u_re, *u_im, *dpsi_re, *dpsi_im;
    double tmpv, w, sqrtuu, *v_vu, *v_logvu1;
    int i;

    v_vu = NULL;  v_logvu1 = NULL;
    
    // Check for proper number of arguments
    if (nrhs != 1) {
        mexPrintf("Usage: dpsi = choose_metric5_dpsiC(u)\n");
        mexPrintf("Note: INPUT \"u\" MUST BE A COLUMN VECTOR (double).     ver.1.00 Jan-2017\n");
        return;
    }

    // accept only double precision
    if (mxIsDouble(IN_DATA) == 0) {
        mexErrMsgTxt(" choose_metric5_dpsiC: The input must be DOUBLE-precision"); 
    }
    // accept only a vector
    if (mxGetNumberOfDimensions(IN_DATA) > 2) {
        mexErrMsgTxt(" choose_metric5_dpsiC: The input must be a column vector.");
    }
    dims[0] = mxGetM(IN_DATA);  // # of rows in array
    dims[1] = mxGetN(IN_DATA);  // # of columns in array
    if (dims[1] != 1) {
        mexErrMsgTxt(" choose_metric5_dpsiC: The input must be a column vector.");
    }
    N = dims[0] * dims[1];

    // sqrtuu = sqrt(u'*u);             % value
    // cu     = conj(u);                % array
    // vu     = sqrt(u.*cu)/sqrtuu;     % array
    // logvu1 = 1+log(vu);              % array
    // dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * (vu'*(logvu1)) / sqrtuu);
    if (mxIsComplex(IN_DATA)) {
        OUT_DATA = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS,  mxCOMPLEX);
        if (OUT_DATA == NULL) {
            mexErrMsgTxt(" choose_metric5_dpsiC: not enough memory for the output.");
            return;
        }
        
        u_re = (double *)mxGetData(IN_DATA);
        u_im = (double *)mxGetImagData(IN_DATA);
        dpsi_re = (double *)mxGetData(OUT_DATA);
        dpsi_im = (double *)mxGetImagData(OUT_DATA);

    } else {
        OUT_DATA = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS,  mxREAL);
        if (OUT_DATA == NULL) {
            mexErrMsgTxt(" choose_metric5_dpsiC: not enough memory for the output.");
            return;
        }
        u_re = (double *)mxGetData(IN_DATA);
        u_im = NULL;
        dpsi_re = (double *)mxGetData(OUT_DATA);
        dpsi_im = NULL;
    }

    v_vu = (double *)mxMalloc(N*sizeof(double));
    v_logvu1 = (double *)mxMalloc(N*sizeof(double));
    if (v_vu == NULL || v_logvu1 == NULL) {
        if (v_vu != NULL)  { mxFree(v_vu);  v_vu = NULL; }
        if (v_logvu1 != NULL)  { mxFree(v_logvu1);  v_logvu1 = NULL; }
        mexErrMsgTxt(" choose_metric5_dpsiC: not enough memory for processing.");
        return;
    }

    // note that "sqrtuu", "vu", "logvu1" and are not complex.
    // sqrtuu = sqrt(u'*u);
    // cu     = conj(u);
    // vu     = sqrt(u.*cu)/sqrtuu;
    // logvu1 = 1+log(vu);
    // dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * (vu'*(logvu1)) / sqrtuu);


    sqrtuu = 0;  w = 0;
    // first, calculate sqrtuu, vu, 1+logvu and a scalar value (w).
    if (mxIsComplex(IN_DATA)) {
        for (i = 0; i < N; i++) {
            tmpv = u_re[i]*u_re[i] + u_im[i]*u_im[i];
            sqrtuu = sqrtuu + tmpv;
            v_vu[i] = sqrt(tmpv);
        }
        sqrtuu = sqrt(sqrtuu);
        for (i = 0; i < N; i++) {
            v_vu[i] = v_vu[i] / sqrtuu;
            v_logvu1[i] = 1 + log(v_vu[i]);
            w = w + v_vu[i] * v_logvu1[i];
        }
        w = w / sqrtuu;
    } else {
        for (i = 0; i < N; i++) {
            tmpv = u_re[i]*u_re[i];
            sqrtuu = sqrtuu + tmpv;
            v_vu[i] = sqrt(tmpv);
        }
        sqrtuu = sqrt(sqrtuu);
        for (i = 0; i < N; i++) {
            v_vu[i] = v_vu[i] / sqrtuu;
            v_logvu1[i] = 1 + log(v_vu[i]);
            w = w + v_vu[i] * v_logvu1[i];
        }
        w = w / sqrtuu;
    }

    // sqrtuu = sqrt(u'*u);
    //sqrtuu = calc_sqrt_uu(IN_DATA,N);
    // vu     = sqrt(u.*cu)/sqrtuu;
    //calc_vu(IN_DATA,N, sqrtuu, v_vu);
    // logvu1 = 1+log(vu);
    //calc_1_log_vu(IN_DATA,N, v_vu,v_logvu1);
    // dpsi = -(vu.*(logvu1)./cu - sign(u).*vu * (vu'*(logvu1)) / sqrtuu);
    calc_dpsi(IN_DATA,N, sqrtuu, v_vu, v_logvu1, w, dpsi_re, dpsi_im);

#if 0
    mexPrintf("sqrtuu = %g\n",sqrtuu.re);
    for (i = 0; i < 5; i++)  mexPrintf("vu[%2d]     = %g\n",i+1,v_vu[i]);
    for (i = 0; i < 5; i++)  mexPrintf("logvu1[%2d] = %g\n",i+1,v_logvu1[i]);
    if (dpsi_im != NULL) {
        for (i = 0; i < 5; i++)  mexPrintf("dpsi[%2d]   = % g % +gi\n",i+1,dpsi_re[i],dpsi_im[i]);
    } else {
        for (i = 0; i < 5; i++)  mexPrintf("dpsi[%2d]   = % g\n",i+1,dpsi_re[i]);
    }
#endif

    if (v_vu != NULL)  { mxFree(v_vu);  v_vu = NULL; }
    if (v_logvu1 != NULL)  { mxFree(v_logvu1);  v_logvu1 = NULL; }


    return;
}
