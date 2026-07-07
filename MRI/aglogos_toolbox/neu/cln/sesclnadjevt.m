function sesclnadjevt(SESSION,EXPS,varargin)
%SESCLNADJEVT -  Detect/Adjust timings of MRI events for cleaning interference noises.
%  SESCLNADJEVT(Ses,...)
%  SESCLNADJEVT(Ses,EXPS/GrpName,...) detects/adjusts timings of MRI events for cleaning
%  interference noises.
%
%  Supported options are :
%    'interactive' : 0|1, run in the interactive mode
%    'debug'       : 0|1, debug mode
%    'log'         : 0|1, make a logfile or not
%
%  NOTE :
%    For old data with multiple obsp:
%      if "grp.pvpar" is 1 in the session file, then CLNMAIN_PVAVR will be called.
%
%  VERSION :
%    1.00 NKL 10.10.02  firtst version
%    1.10 YM  26.06.14  clean-up, uses "varargin".
%
%  See also clnadjevt clnmain clnadf

if nargin < 1,  help sesclnadjevt; return;  end

if nargin < 2,  EXPS = [];  end


% control settings
LOG         = 0;
INTERACTIVE = 0;
DEBUG       = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'log'}
    LOG = any(varargin{N+1});
   case {'interactive'}
    INTERACTIVE = any(varargin{N+1});
   case {'debug'}
    DEBUG = any(varargin{N+1});
  end
end

Ses = goto(SESSION);

if isempty(EXPS),
  EXPS = validexps(Ses);
elseif ~isnumeric(EXPS),
  % EXPS as a group name or a cell array of group names.
  EXPS = getexps(Ses,EXPS);
end


if LOG,
  LogFile=strcat('SESCLNADJEVT_',Ses.name,'.log');	% Start log file
  diary off;										% Close previous ones...
  hbackup(LogFile);									% Make a backup for history
  diary(LogFile);									% Start the new one
end;

fprintf('%s: ',mfilename);
fprintf('**** CLNADJEVT -- Detecting/Adjusting MRI events...\n');
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp   = getgrp(Ses,ExpNo);
  fprintf(' %s: %3d/%d[Exp%3d]',datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
  if isrecording(grp) && isimaging(grp),
    if isfield(grp,'pvavr') && grp.pvavr > 0,
      fprintf(' %s...',expfilename(Ses,ExpNo,'phys'));
      % this is for old data acquisition like a003x1.
      clnadjevt_pvavr(Ses,ExpNo,INTERACTIVE,DEBUG);
      fprintf(' done.\n');
    else
      clnadjevt(Ses,ExpNo,'interactive',INTERACTIVE,'debug',DEBUG);
    end
  else
    fprintf(' not Phys+MRI, ...skipped\n');
  end
end;

if LOG,
  diary off;										% Close log file
end;

