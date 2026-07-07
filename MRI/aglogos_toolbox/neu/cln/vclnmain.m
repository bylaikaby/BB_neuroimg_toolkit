function Cln = vclnmain(SESSION,ExpNo,ARGS)
%VCLNMAIN - Remove electromagnetic interference patterns from physiology signal.
%
% VERSION :
%    0.90 ??.??.?? YM  pre-release
%    0.91 26.10.07 YM  bug fix for anap.mri/anap.SS_OFFS.
%    0.92 25.07.12 YM  use expfilename() and sigsave().
%
% See also CLNADJEVT, CLNADF, CLNMAIN, VDECMAIN, VGETFRAMEDATA, EXPFILENAME

SAVE	    = 1;			% Create/Append MAT file
SAVEAS_ADX  = 0;			% Save decimated data into a separate data.

if exist('ARGS','var'),
  Cln = clnmain(SESSION,ExpNo,ARGS);
else
  Cln = clnmain(SESSION,ExpNo);
end

Ses	= goto(SESSION);
par = expgetpar(Ses,ExpNo);

SESDIR = pwd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if sesversion(Ses) >= 2,
  MriEvtName = 'clnpar';
  anap = sigload(Ses,ExpNo,'clnadj');
else
  MriEvtName = sprintf('exp%03d',ExpNo);
  load('ClnAdjEvt.mat',MriEvtName);
  eval(sprintf('anap = %s;',MriEvtName));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get frame indices of movie;
% NOTE: 29.09.03 YM
% adf-offset should be precise for movie analysis.
% 'clnadf.m' uses ANAP.mri to read ADF.  ANAP.mri{1}(1) may differ
% from the time of first MRI event in the event file. 
Cln.dir.videofile = expfilename(Ses,ExpNo,'video');
if ~isempty(Cln.dir.videofile),
  if isfield(anap,'mri'),
    % OLD FORMAT
    adfofsSec = anap.mri{1}(1) + Cln.usr.adfoffset;
  else
    % NEW FORMAT
    adfofsSec = anap.SS_OFFS(1)*anap.dx;
  end
  adflenSec = size(Cln.dat,1)*Cln.dx;
  Cln.movie = vgetframedata(Ses,ExpNo,par.evt.validobsp,adfofsSec,adflenSec);
else
  Cln.movie = {};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ===========================================================================
% SAVE in MAT file if regular process..
% ===========================================================================
if ~nargout & SAVE,
  sigsave(Ses,ExpNo,'Cln',Cln);
  % no need to hold data
  clear Cln;
end;
cd(SESDIR);

return;
