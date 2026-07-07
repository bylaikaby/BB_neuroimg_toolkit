function FILENAME = sigfilename(Ses,GrpExp,SigName,varargin)
%SIGFILENAME - Return the filename of the given SigName.
%  FILENAME = SIGFILENAME(SESSION,GROUP,SIGNAME)
%  FILENAME = SIGFILENAME(SESSION,EXPNO,SIGNAME) returns the filename of
%  the given SIGNAME.
%
%  EXAMPLE :
%    fname = sigfilename('m02lx1',10,'blp')
%
%  VERSION :
%    0.90 29.01.12 YM  pre-release
%    0.91 01.02.12 YM  supports 'subdir' as option.
%    0.92 12.02.12 YM  supports 'fullpath' as option.
%    0.93 13.05.13 YM  now 'eeg','evt' can be as 'signal'.
%
%  See also sigload sigsave expfilename mcsession/exprawfile statfilename

if nargin < 1, eval(['help ' mfilename]); return;  end

Ses = getses(Ses);

VERSION  = sesversion(Ses);
SUBDIR   = -1;
FULLPATH = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case { 'ver' 'version' }
    VERSION = varargin{N+1};
   case { 'subdir' }
    SUBDIR = varargin{N+1};
   case { 'fullpath' }
    FULLPATH = varargin{N+1};
  end
end

if VERSION < 2,
  if nargin < 3,  SigName = '';  end
  if isempty(SigName),  SigName = 'mat';  end
  FILENAME = sigfilename_ver1(Ses,GrpExp,SigName);
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

switch lower(SigName),
 case { 'phys' 'adf' 'adfw' 'phys2' 'adf2' 'adfw2' 'adfx' 'adfx2'  ...
        'vsig', 'video' ...
        'dgz' 'stm', 'pdm', 'hst' 'rfp' ...
        'pvdir' '2dseq' 'fid' 'acqp' 'imnd' 'method' 'reco' 'visu_pars' ...
        'smr','spike2' ...
        'opt' 'optmat' ...
        'cogentlog' 'cogent' 'dicom' 'nifti' 'nii' }
  fpath = '';
  fname = expfilename(Ses,GrpExp,SigName);
  
 otherwise
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
      subdir = lower(SigName);
    else
      subdir = SUBDIR;
    end
    % STYLE: %SIG%/SESSION_%EXP%_%SIG%.mat
    fname = sprintf('%s/%s_%s_%s.mat',subdir,Ses.name,tmpstr,lower(SigName));
    % STYLE: %EXP%/SESSION_%SIG%.mat
    %fname = sprintf('%s/%s_%s.mat',subdir,Ses.name,SigName);
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
    % STYLE: %GRP%\SESSION_%GRP%_%SIG%.mat
    fname = sprintf('%s/%s_%s_%s.mat',subdir,Ses.name,tmpstr,lower(SigName));
  end
end


FILENAME = fullfile(fpath,fname);
if any(USE_BAKFILE),
  FILENAME = sprintf('%s.bak',FILENAME);
end

return

