function showsigcf(SesName,ExpNo,SigName,Contrast,bins)
%SHOWSIGCF - Display the signals resulting from depend-analysis
% SHOWSIGCF - Reads the signal SigName and displays it

if nargin < 5,
  bins = 10;
end;

if nargin < 4,
  Contrast = 'corr';
end;

if nargin < 3,
  SigName = 'crroiTs';
end;

if nargin < 2,
  help showsigcf;
  return;
end;

sig = sigload(SesName,ExpNo,SigName);

LEN = length(sig);
switch LEN,
 case 1,
  COL=1; ROW=1;
 case 2,
  COL=1; ROW=2;
 case {3 4},
  COL=2; ROW=2;
 case {5 6 7 8},
  COL=4; ROW=2;
 otherwise
  COL=2; ROW=ceil(LEN/COL);
end;

mfigure([10 50 800 800]);
for N=1:LEN,
  subplot(ROW,COL,N);
  dspsigcf(sig{N},Contrast,bins);
end;

  
  