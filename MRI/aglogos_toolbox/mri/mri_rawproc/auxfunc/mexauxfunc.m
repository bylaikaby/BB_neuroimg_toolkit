%
% mexauxfunc.m : batch file to make all mex DLLs.
%
%  VERSION :
%    1.00  26-Jan-2016  YM  first release

switch lower(mexext)
 case {'mexa64'}
   mex CFLAGS='-std=c99 -fPIC' -largeArrayDims  choose_metric5_psiC.c
   mex CFLAGS='-std=c99 -fPIC' -largeArrayDims  choose_metric5_dpsiC.c
 
 otherwise
  mex -largeArrayDims  choose_metric5_psiC.c
  mex -largeArrayDims  choose_metric5_dpsiC.c

end     
