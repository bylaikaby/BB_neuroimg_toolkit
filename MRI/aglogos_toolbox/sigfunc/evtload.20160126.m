function varargout = evtload(SesName,GrpExp,EvtVarName,EvtSites,varargin)
%EVTLOAD - Load event data of EvtVarName in mat file.
%  EVTLOAD (SesName,ExpNo,EvtVarName,EvtSites,...) 
%  EVT = EVTLOAD (SesName,ExpNo,EvtVarName,EvtSites,...) loads event data.
%  This function must be called with all arguments. No defaults exist.
%
%  Supported options are :
%    'verbose' : 0|1, prints info or not.
%    'file'    : filename to save. if not-any, uses evtfilename().
%
%  VERSION :
%    1.00 25.01.16 YM  first-release.
%
%  See also evtfilename load evtsave getevent

if nargin < 3, eval(['help ' mfilename]); return;  end
if nargin < 4, EvtSites = {};  end

VERBOSE    =  1;
FILENAME   = '';
SUBDIR     = -1;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'file' 'filename' 'fname'}
    FILENAME = varargin{N+1};
   case {'subdir'}
    SUBDIR = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if isempty(FILENAME),
  EVT = [];
  if isempty(EvtSites),
    tmpfile = evtfilename(SesName,GrpExp,EvtVarName,'evtsite','','subdir',SUBDIR);
    [tmpp,tmpf,tmpe] = fileparts(tmpfile);
    fpatt = [tmpf,'_*.mat'];
    tmpdirs = dir(fullfile(tmpp,fpatt));
    if isempty(tmpdirs),
      error(' ERROR %s: no file found, %s\n',mfilename,fullfile(tmpp,fpatt));
    end
    EvtSites = cell(1,length(tmpdirs));
    for N = 1:length(tmpdirs),
      EvtSites{N} = tmpdirs(N).name(length(tmpf)+2:end-4);
    end
  end
  if ischar(EvtSites),  EvtSites = {EvtSites};  end
  for N = 1:length(EvtSites),
    tmpfile = evtfilename(SesName,GrpExp,EvtVarName,'evtsite',EvtSites{N},'subdir',SUBDIR);
    try,
      tmpevt = load(tmpfile, EvtVarName);
      tmpevt = tmpevt.(EvtVarName);
    catch
      error(' ERROR %s: ''%s'' not found in %s.\n',mfilename,EvtVarName,FILENAME);
    end
    EVT = [EVT tmpevt];
  end
else
  try,
    EVT = load(FILENAME,EvtVarName);
    EVT = EVT.(EvtVarName);
  catch
    error(' ERROR %s: ''%s'' not found in %s.\n',mfilename,EvtVarName,FILENAME);
  end
end


if any(nargout),
  varargout{1} = EVT;
else
  assignin('caller', EvtVarName, EVT);
end


return
