function FILENAME = sigsave(SesName,GrpExp,SigName,Sig,varargin)
%SIGSAVE - Saves signal Sig with name SigName in mat file SesName/ExpNo
%  SIGSAVE (SesName,ExpNo,SigName,Sig,...) 
%  FILENAME = SIGSAVE(SesName,ExpNo,SigName,Sig,...) 
%  This function must be called with all arguments. No defaults exist.
%
%  Supported options are :
%    'verbose' : 0|1, prints info or not.
%    'file'    : filename to save. if not-any, uses sigfilename().
%    'backup'  : 0|1, makes .bak file or not.
%
%  VERSION :
%    1.00 26.07.04 NKL
%    2.00 30.01.12 YM  use sigfilename(), now 1 var in 1 file.
%    2.01 31.01.12 YM  supports 'backup'.
%    2.02 01.01.12 YM  supports 'subdir'.
%    2.10 05.06.13 YM  save with '-v7.3' for partial reading.
%    2.11 12.06.13 YM  no '-append' when sesversion()>=2
%
%  See also sigfilename mmkdir save sigload

if nargin < 4,  help sigsave; return;  end;

VERBOSE    =  1;
FILENAME   = '';
DO_BACKUP  =  0;
SUBDIR     = -1;
TRY_APPEND =  1;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'file' 'filename' 'fname'}
    FILENAME = varargin{N+1};
   case {'backup' 'bak'}
    DO_BACKUP = varargin{N+1};
   case {'subdir'}
    SUBDIR = varargin{N+1};
   case {'append'}
    TRY_APPEND = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if ~ischar(SigName) && ischar(Sig),
  % swap SigName and Sig...
  tmpname = Sig;
  Sig = SigName;
  SigName = tmpname;
  clear tmpname;
end

if isempty(FILENAME),
  if sesversion(SesName) >= 2,
    FILENAME = sigfilename(SesName,GrpExp,SigName,'subdir',SUBDIR);
    TRY_APPEND = 0;  % no '-append' when sesversion()>=2.
  else
    if ischar(GrpExp),
      % GrpExp as a group name
      FILENAME = sprintf('%s.mat',GrpExp);
    else
      if any(strcmpi(SigName,{'Cln','tcImg','ClnSpc'})),
        FILENAME = sigfilename_ver1(SesName,GrpExp,SigName);
      else
        FILENAME = sigfilename_ver1(SesName,GrpExp,'mat');
      end
    end
  end
end

if VERBOSE,  tStart = tic;  end

eval([ SigName ' = Sig;' ]);
if exist(FILENAME,'file'),
  if any(DO_BACKUP),
    %[fp fr fe] = fileparts(FILENAME);
    %x = dir(FILENAME);
    %bakfile = sprintf('%s.%s%s',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'),fe);
    %bakfile = fullfile(fp,bakfile);
    bakfile = sprintf('%s.bak',FILENAME);
    copyfile(FILENAME,bakfile,'f');
  end
  
  if any(TRY_APPEND)
    if VERBOSE,
      fprintf('%s Adding ''%s'' to ''%s''...',datestr(now,'HH:MM:SS'),SigName,FILENAME);
    end
    save(FILENAME,SigName,'-append','-v7.3');
  else
    if VERBOSE,
      fprintf('%s Saving ''%s'' to ''%s''...',datestr(now,'HH:MM:SS'),SigName,FILENAME);
    end
    save(FILENAME,SigName,'-v7.3');
  end
else
  if VERBOSE,
    fprintf('%s Saving ''%s'' to ''%s''...',datestr(now,'HH:MM:SS'),SigName,FILENAME);
  end
  mmkdir(fileparts(FILENAME));
  save(FILENAME,SigName,'-v7.3');
end;

%! sync;
[status,cmdout] = system('sync');

if VERBOSE,
  fprintf('(%gs) done.\n',toc(tStart));
end


return
