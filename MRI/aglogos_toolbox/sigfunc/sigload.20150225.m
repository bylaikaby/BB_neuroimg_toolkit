function varargout = sigload(Ses,GrpExp,varargin)
%SIGLOAD - Loads the signal for Ses, ExpNo/GrpName.
%   SIGLOAD(SESSION,EXPNO/GRPNAME) loads all variables in the
%   corresponding mat file into caller's workspace.
%
%   [SIG1,...] = SIGLOAD(SESSION,EXPNO,SIGNAME1,SIGNAME2,...)
%   returns signal of individual experiment (EXPNO) in the SESSION.
%
%   [SIG1,...] = SIGLOAD(SESSION,GRPNAME,SIGNAME1,SIGNAME2,...)
%   returns the signal of GRPNAME in the SESSION.
%
%  If no ouput argument, then SIGLOAD assigns and may overwrite
%  signals into caller's workspace.
%
%  Note on grouped 'tcImg' : When 2nd argument is a group name and
%  SIGNAME is 'tcImg', SIGLOAD reads and returns 'grp.name'
%  variable in 'tcimg.mat'.
%
%  EXAMPLE :
%    >> sigload('g03gp1','tcImg')
%    >> sigload('g03gp1','tcImg.bak')   % load tcImg from .bak file
%
%  VERSION :
%    0.90 21.04.04 YM  first release.
%    0.91 22.04.04 YM  accepts multipe signal names.
%    0.92 30.04.04 YM  sets tcImg.usr.pvpar.
%    0.93 01.06.04 YM  if cell array, then load as it is.
%    0.94 14.01.04 YM  avoid error for D98.at1/at2.
%    0.95 09.01.06 YM  not to update .stm/evt for sorted signals.
%    0.96 13.04.07 YM  supports to load from .bak file
%    0.97 01.10.11 YM  clean up
%    1.00 30.10.12 YM  now 1 var in 1 file, use sigfilename().
%    1.10 06.02.12 YM  adds 'glmcont' 'corana' if exists.
%    1.11 14.04.13 YM  updates SigName with signame().
%
% See also LOAD, SIGFILENAME, EXPGETPAR, ASSIGNIN, ANALOAD, SIGNAME, SIGSAVE

if nargin < 2,  help sigload;  return;  end  
%warning('sigload: new sigload loads contrast from Contrasts subdirectory');
Ses = goto(Ses);

if nargin < 3,
  % ----------------------------------------------------------------
  % if no signal names, then loads all variables.
  % 03.06.04 NKL: Added a few things to make sure it works, when the
  % group name implies reading tcImg.mat and getting the structure
  % with the defined group's name.
  % ----------------------------------------------------------------
  if ischar(GrpExp) || isstruct(GrpExp),
    % GrpExp as group's name or structure
    grp = getgrp(Ses,GrpExp);
    matfile = sprintf('%s.mat',grp.name);
  else
    matfile = catfilename(Ses,GrpExp,'mat');
  end
  SigName = who('-file',matfile);
else
  % get signal names
  SigName = {};
  if nargin >= 3,
    for N = 1:length(varargin),
      if iscell(varargin{N}),
        SigName(end+1:end+length(varargin{N})) = varargin{N}(:);
      else
        SigName{end+1} = varargin{N};
      end
    end
  end
end

if ischar(SigName),  SigName = { SigName };  end
for N = 1:length(SigName),
  [tmpsig tmpname] = sub_sigload(Ses,GrpExp,SigName{N});
  if nargout,
    varargout{N} = tmpsig;
  else
    assignin('caller', tmpname, tmpsig);
  end
end

return



% ----------------------------------------------------------------
% now loads specified sinal(s).
function [Sig SigName] = sub_sigload(Ses,GrpExp,SigName)
% ----------------------------------------------------------------


grp = getgrp(Ses,GrpExp);
if isempty(grp),
  fprintf('SIGLOAD: "getgrp(Ses, GrpExp) returns an empty group\n');
  fprintf('SIGLAOD: Check description file; perhaps GrpExp was excluded!!\n');
  keyboard;
end;


tmpsigname = SigName;
idx = strfind(lower(tmpsigname),'.bak');
if ~isempty(idx),
  USE_BAKFILE = 1;
  tmpsigname = tmpsigname(1:idx-1);
else
  USE_BAKFILE = 0;
end

if sesversion(Ses) >= 2,
  matfile = sigfilename(Ses,GrpExp,tmpsigname);
else
  switch lower(tmpsigname),
   case { 'cln','clnspc','clnfft','tcimg'}
    % those signals are saved in "SIGS" directory
    matfile = sigfilename_ver1(Ses,GrpExp, tmpsigname);
   case { 'spktblp' ,'spktcln','brsttblp','brsttcln',...
          'atspktblp' ,'atspktcln','atbrsttblp','atbrsttcln' }
    matfile = sigfilename_ver1(Ses,GrpExp, tmpsigname);
   case lower(Ses.ctg.GrpDEPSigs)
    matfile = sigfilename_ver1(Ses,GrpExp,'contrasts');
   otherwise
    matfile = sigfilename_ver1(Ses,GrpExp,'mat');
  end
end

if USE_BAKFILE && exist(sprintf('%s.bak',matfile),'file'),
  matfile = sprintf('%s.bak',matfile);
end

Sig = sub_load(matfile, tmpsigname, Ses, GrpExp);
SigName = tmpsigname;

if isstruct(Sig),
if ~isfield(Sig,'dir') | strcmpi(Sig.dir.dname,'mblp'), return; end;
end

if isempty(Sig), return;  end

% 30.06.04 NKL: This here serves the following purpose:
% Many signals (e.g. statistics) do not have any conventional
% fields, and they do not need the addition of grp/evt/stm
% either. To read them with this function, skip appending
% fields if a signal does not have the basic "dir" field.
if ~sub_have_dirstr(Sig),  return;  end


% make sure the corret signal's name
Sig = signame(Sig,SigName);


% add results of GLM/COR analysis
if sesversion(Ses) >= 2,
  glmcont = statload(Ses,GrpExp,SigName,'glmcont','verbose',0);
  corana  = statload(Ses,GrpExp,SigName,'corana','verbose',0);
  if ~isempty(glmcont),
    Sig = sub_add_stat(Sig,glmcont,{'glmcont'});
  end
  if ~isempty(corana),
    Sig = sub_add_stat(Sig,corana,{'r' 'p'});
  end
  clear glmcont corana;
end


% ES-averaged signals, no need update "stm" parameters.
if isstruct(Sig),
  if isfield(Sig.dir,'dname') && strcmp(Sig.dir.dname(1:2),'es'), return; end;
elseif isstruct(Sig{1}),
  if isfield(Sig{1}.dir,'dname') && strcmp(Sig{1}.dir.dname(1:2),'es'), return; end;
end


% use updated "stm" parameter.


% NKL 02.06.04
% ATTENTION: Yusuke, this here has the following purpose: To
% estimate precisely what our Type I error is for
% Hypothesis-Testing, it is better to extract it from the data,
% instead of making assumptions. For example, we can estimate
% the probability of obtaining different r-values by chance, by
% using experiments without stimulus (e.g. baseline, spont, etc.)
% and correlate the responses with a stimulus pattern, that we
% chose from another experiment having visual stimulation. Our
% description files have the field "epoch" which was taken into
% account for the dependence analysis. We can also use it here
% for "simulating" visual stimulation. If epoch==3, the third
% experiment's stm is used etc...
if iscell(Sig), DIR=Sig{1}.dir; else DIR = Sig.dir; end;
if ~strcmpi(DIR.dname,'mblp'),
  if isfield(grp,'epoch') && grp.epoch,
    fprintf(' sigload: stm/evt/grp are overwrited by "grp.epoch (exp=%d)".\n',grp.epoch);
    pars = expgetpar(Ses,grp.epoch);
  else
    if sub_is_trial(Sig) > 0,
      pars = [];
    else
      pars = expgetpar(Ses,GrpExp);
    end
  end;
else
  return;
end;

if iscell(Sig),
  % if the signal is a cell array, do nothing except "roiTs"
  if isfield(Sig{1},'dir') && isfield(Sig{1}.dir,'dname'),
    if strcmpi(Sig{1}.dir.dname,'roiTs') && strcmpi(SigName,'roiTs'),
      for K = 1:length(Sig)
        Sig{K}.stm = pars.stm;
      end
    end
  end
else
  if strcmp(Sig.dir.dname,'rpblp'),
  else
    if isfield(pars,'stm') && ~isempty(pars.stm) && ~isfield(Sig,'sigsort') && ~isfield(Sig,'rp'),
      Sig.stm = pars.stm;
    end
    if isfield(Sig.dir,'dname') && strcmpi(Sig.dir.dname,'tcImg'),
      Sig.usr.pvpar = pars.pvpar;
    end
  end;
end;
return;


% ===================================================================
function Sig = sub_load(Filename,SigName, Ses, GrpExp)
% Sig = matsigload(Filename,SigName);
% this is 10% faster.
% YUSUKE: This is a DIRTY patch to avoid the problem of reading the group name from the
% Signal structure. By doing this we can have multiple group definitsion for the same raw
% data... You can change this the way you like if necessary
% Sunday 04.03.2007
% ===================================================================
try
  Sig = load(Filename,SigName,'-mat');
  Sig = Sig.(SigName);
catch
  fprintf(' sigload.sub_load: ''%s'' not found in %s.\n',SigName,Filename);
  Sig = {};
  return;
end

if nargin > 2,
  grp = getgrp(Ses,GrpExp);
  if iscell(Sig),
    if iscell(Sig{1}),
      for C=1:length(Sig),
        for N=1:length(Sig{C}),
          Sig{C}{N}.grpname = grp.name;
        end;
      end;
    else
      for N=1:length(Sig),
        Sig{N}.grpname = grp.name;
      end;
    end;
  else
    Sig.grpname = grp.name;
  end;
end;
return;



% ===================================================================
function IS_SIG = sub_have_dirstr(Sig)
% ===================================================================

IS_SIG = 0;

if isempty(Sig),  return;  end

if iscell(Sig)
  IS_SIG = sub_have_dirstr(Sig{1});
  return
end

if isfield(Sig,'dir'),  IS_SIG = 1;  end


% if isstruct(Sig),
%   if ~isfield(Sig,'dir'),  return;  end
% elseif iscell(Sig),
%   if iscell(Sig{1}),
%     if ~isfield(Sig{1}{1},'dir'),  return;  end
%   else
%     if ~isfield(Sig{1},'dir'),  return;  end
%   end
% end


return



% ===================================================================
function IS_TRIAL = sub_is_trial(Sig)
% ===================================================================
if iscell(Sig),
  IS_TRIAL = sub_is_trial(Sig{1});
  return;
end

if isfield(Sig,'sigsort'),
  IS_TRIAL = 1;
else
  IS_TRIAL = 0;
end

return




% ====================================================================
function Sig = sub_add_stat(Sig,Stat,Fields)
% ====================================================================
if numel(Sig) ~= numel(Stat),  return;  end
if ~isa(Sig,class(Stat)),      return;  end

if iscell(Sig),
  for N = 1:length(Sig),
    Sig{N} = sub_add_stat(Sig{N},Stat{N},Fields);
  end
  return;
end

if ischar(Fields),  Fields = { Fields };  end

for F = 1:length(Fields),
  if isfield(Stat,Fields{F}),
    Sig.(Fields{F}) = Stat.(Fields{F});
  end
end
return

  
  