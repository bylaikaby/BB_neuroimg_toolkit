function FILENAME = evtsave(SesName,GrpExp,EvtVarName,EvtVar,varargin)
%EVTSAVE - Saves events with EvtVarName in mat file.
%  EVTSAVE (SesName,ExpNo,EvtVarName,EvtVar,...) 
%  FILENAME = EVTSAVE(SesName,ExpNo,EvtVarName,EvtVar,...) 
%  This function must be called with all arguments. No defaults exist.
%
%  Supported options are :
%    'verbose' : 0|1, prints info or not.
%    'file'    : filename to save. if not-any, uses evtfilename().
%    'backup'  : 0|1, makes .bak file or not.
%
%  VERSION :
%    1.00 25.01.16 YM  first-release.
%
%  See also evtfilename mmkdir save evtload getevent

if nargin < 4, eval(['help ' mfilename]); return;  end

VERBOSE    =  1;
FILENAME   = '';
DO_BACKUP  =  0;
SUBDIR     = -1;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'file' 'filename' 'fname'}
    FILENAME = varargin{N+1};
   case {'backup' 'bak'}
    DO_BACKUP = varargin{N+1};
   case {'subdir'}
    SUBDIR = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if ~ischar(EvtVarName) && ischar(EvtVar),
  % swap EvtVarName and EvtVar...
  tmpname = EvtVar;
  EvtVar = EvtVarName;
  EvtVarName = tmpname;
  clear tmpname;
end

if isempty(FILENAME),
  if numel(EvtVar) > 1,
    % support a structure array
    for N = 1:numel(EvtVar),
      FILENAME{N} = evtsave(SesName,GrpExp,EvtVarName,EvtVar(N),...
                            'backup',DO_BACKUP,'subdir',SUBDIR,'verbose',VERBOSE);
    end
    return
  end
  
  if isfield(EvtVar,'evtsite'),
    FILENAME = evtfilename(SesName,GrpExp,EvtVarName,'evtsite',EvtVar.evtsite,'subdir',SUBDIR);
  else
    FILENAME = evtfilename(SesName,GrpExp,EvtVarName,'evtsite','','subdir',SUBDIR);
  end
end

% update 'varname' if needed.
if isfield(EvtVar,'varname'),
  for N = 1:numel(EvtVar),
    EvtVar(N).varname = EvtVarName;
  end
end


if VERBOSE,  tStart = tic;  end

eval([ EvtVarName ' = EvtVar;' ]);
if exist(FILENAME,'file'),
  if any(DO_BACKUP),
    %[fp fr fe] = fileparts(FILENAME);
    %x = dir(FILENAME);
    %bakfile = sprintf('%s.%s%s',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'),fe);
    %bakfile = fullfile(fp,bakfile);
    bakfile = sprintf('%s.bak',FILENAME);
    copyfile(FILENAME,bakfile,'f');
  end
  
  if VERBOSE,
    fprintf('%s Saving ''%s'' to ''%s''...',datestr(now,'HH:MM:SS'),EvtVarName,FILENAME);
  end
  save(FILENAME,EvtVarName,'-v7.3');
else
  if VERBOSE,
    fprintf('%s Saving ''%s'' to ''%s''...',datestr(now,'HH:MM:SS'),EvtVarName,FILENAME);
  end
  mmkdir(fileparts(FILENAME));
  save(FILENAME,EvtVarName,'-v7.3');
end;

%! sync;
[status,cmdout] = system('sync');

if VERBOSE,
  fprintf('(%gs) done.\n',toc(tStart));
end


return
