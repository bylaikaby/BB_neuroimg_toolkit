function showmoviettest(SESSION,arg2)
%SHOWMOVIETTEST - show sesroi results (ROIs xcor data etc.) for group
% SHOWMOVIETTEST(SESSION,GrpName) - shows correlation maps superimposed on
% anatomical scans, and if exists also the activated voxels in different
% regions of interest, such as different visual areas etc.
%
% NKL, 25.10.02

global DispPars DISPMODE PPTSTATE
DISPMODE = getdispmode;
if isempty(DISPMODE),
  DISPMODE=1;				% DEFAULT SHOW AVERAGE OBSP/CHAN
end;

PPTSTATE = getpptstate;
if isempty(PPTSTATE),
  PPTSTATE = 1;				% DEFAULT NO PPT OUTPUT
  setpptstate(PPTSTATE);
end;
initDispPars(DISPMODE,PPTSTATE);

if nargin < 4,
  pptstate = 0;
end;

if nargin < 2,
	error('usage: showmoviettest(SESSION,GrpName);');
end;

Ses = goto(SESSION);

if isa(arg2,'char'),
  GrpName = arg2;
  FileName = strcat(GrpName,'.mat');
else
  ExpNo = arg2;
  FileName = catfilename(Ses,ExpNo,'mat');
end;
load(FileName,'zsts');

mfigure([50 150 700 700]);
dspmoviettest(zsts);



