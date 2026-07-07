function FILENAME = statfilename(Ses,GrpExp,SigName,StatName,varargin)
%STATFILENAME - Return the filename for statistical result.
%  FILENAME = STATFILENAME(SESSION,GROUP,SIGNAME,StatName)
%  FILENAME = STATFILENAME(SESSION,EXPNO,SIGNAME,StatName) returns the filename for statistical result.
%
%  NOTE :
%    "SigName" is the signal name from which "Statistics" was computed.
%
%  EXAMPLE :
%    fname = statfilename('m02lx1',10,'roiTs','glmcont')
%    fname = statfilename('m02lx1',10,'roiTs','glmregr')
%
%  VERSION :
%    0.90 01.02.12 YM  pre-release
%
%  See also statsave statload sigfilename expfilename

if nargin < 1, eval(['help ' mfilename]); return;  end

Ses = getses(Ses);


VERSION = sesversion(Ses);
SUBDIR  = -1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case { 'ver' 'version' }
    VERSION = varargin{N+1};
   case { 'subdir' }
    SUBDIR = varargin{N+1};
  end
end

if VERSION < 2,
  FILENAME = sigfilename_ver1(Ses,GrpExp,'mat');
  return
end


% check .bak or not
idx = strfind(lower(SigName),'.bak');
if ~isempty(idx),
  USE_BAKFILE = 1;
  SigName = SigName(1:idx-1);
else
  USE_BAKFILE = 0;
end



if isa(Ses,'csession'),
  fpath = fullfile(Ses.dir('DataMatlab'),Ses.dir('dirname'));
else
  if isfield(Ses.sysp,'DataMatlab'),
    fpath = fullfile(Ses.sysp.DataMatlab,Ses.sysp.dirname);
  else
      fpath = fullfile(Ses.sysp.matdir,Ses.sysp.dirname);
  end
end

if isnumeric(GrpExp),
  tmpstr = num2str(GrpExp,'%04d');
  if isequal(SUBDIR,-1) || ~ischar(SUBDIR)
    subdir = sprintf('%s.glm',lower(SigName));
  else
    subdir = SUBDIR;
  end
  % STYLE: %SIG%.glm/SESSION_%EXP%_%SIG%_%GLM%.mat
  fname = sprintf('%s/%s_%s_%s.%s.mat',subdir,Ses.name,tmpstr,lower(SigName),lower(StatName));
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
  % STYLE: %GRP%\SESSION_%GRP%_%SIG%.%GLM%.mat
  fname = sprintf('%s/%s_%s_%s.%s.mat',subdir,Ses.name,tmpstr,lower(SigName),lower(StatName));
end


FILENAME = fullfile(fpath,fname);
if any(USE_BAKFILE),
  FILENAME = sprintf('%s.bak',FILENAME);
end

return
