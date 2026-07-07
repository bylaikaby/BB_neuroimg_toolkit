function FILENAME = evtfilename(Ses,GrpExp,EvtVarName,varargin)
%EVTFILENAME - Return the filename of the given EvtVarName.
%  FILENAME = EVTFILENAME(SESSION,GROUP,EvtVarName)
%  FILENAME = EVTFILENAME(SESSION,EXPNO,EvtVarName) returns the filename of
%  the given SIGNAME.
%
%  EXAMPLE :
%    fname = evtfilename('rathm1',4,'nevt')
%
%  VERSION :
%    0.90 25.01.16 YM  pre-release
%
%  See also evtload evtsave getevent

if nargin < 1, eval(['help ' mfilename]); return;  end

Ses = getses(Ses);


SUBDIR   = -1;
FULLPATH =  1;
EVT_SITE = '';
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case { 'subdir' }
    SUBDIR = varargin{N+1};
   case { 'fullpath' }
    FULLPATH = varargin{N+1};
   case { 'evtsite' 'elesite' 'site' }
    EVT_SITE = varargin{N+1};
  end
end


% check .bak or not
idx = strfind(lower(EvtVarName),'.bak');
if ~isempty(idx),
  USE_BAKFILE = 1;
  EvtVarName = EvtVarName(1:idx-1);
else
  USE_BAKFILE = 0;
end


if any(FULLPATH),
  if isa(Ses,'mcsession'),
    fpath = fullfile(Ses.dir('DataMatlab'),Ses.dir('dirname'));
  else
    if isfield(Ses.sysp,'DataMatlab'),
      fpath = fullfile(Ses.sysp.DataMatlab,Ses.sysp.dirname);
    else
      fpath = fullfile(Ses.sysp.matdir,Ses.sysp.dirname);
    end
  end
else
  fpath = '';
end
  
if isnumeric(GrpExp),
  tmpstr = num2str(GrpExp,'%04d');
  if isequal(SUBDIR,-1) || ~ischar(SUBDIR)
    subdir = lower(EvtVarName);
  else
    subdir = SUBDIR;
  end
  % STYLE: %SIG%/SESSION_%EXP%_%EVT%
  fname = sprintf('%s/%s_%s_%s',subdir,Ses.name,tmpstr,lower(EvtVarName));
else
  if ischar(GrpExp),
    tmpstr = GrpExp;
  else
    % as grp structure
    tmpstr = GrpExp.name;
  end
  if isequal(SUBDIR,-1) || ~ischar(SUBDIR)
    subdir = tmpstr;
  else
    subdir = SUBDIR;
  end
  % STYLE: %GRP%/SESSION_%GRP%_%EVT%
  fname = sprintf('%s/%s_%s_%s',subdir,Ses.name,tmpstr,lower(EvtVarName));
end

if isempty(EVT_SITE),
  % STYLE: %SIG%/SESSION_%EXP%_%EVT%.mat
  % STYLE: %GRP%/SESSION_%GRP%_%EVT%.mat
  fname = [fname '.mat'];
else
  % STYLE: %SIG%/SESSION_%EXP%_%EVT%_%SITE%.mat
  % STYLE: %GRP%/SESSION_%GRP%_%EVT%_%SITE%.mat
  fname = [fname '_' lower(EVT_SITE) '.mat'];
end

FILENAME = fullfile(fpath,fname);
if any(USE_BAKFILE),
  FILENAME = sprintf('%s.bak',FILENAME);
end

return

