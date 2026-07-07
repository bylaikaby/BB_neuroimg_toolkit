function varargout = sigload(Ses,ExpNo,varargin)
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
%
% See also LOAD, CATFILENAME, EXPGETPAR, ASSIGNIN, ANALOAD
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
  if ischar(ExpNo) || isstruct(ExpNo),
    % ExpNo as group's name or structure
    grp = getgrp(Ses,ExpNo);
    matfile = sprintf('%s.mat',grp.name);
  else
    matfile = catfilename(Ses,ExpNo,'mat');
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


% ----------------------------------------------------------------
% now loads specified sinal(s).
% ----------------------------------------------------------------
if ischar(ExpNo) || isstruct(ExpNo),
  % ExpNo as group's name or structure
  grp = getgrp(Ses,ExpNo);
  if isempty(grp),
    fprintf('SIGLOAD: "getgrp(Ses, ExpNo) returns an empty group\n');
    fprintf('SIGLAOD: Check description file; perhaps ExpNo was excluded!!\n');
    keyboard;
  end;
  ExpNo = grp.exps(1);
  for N = 1:length(SigName),
    % grouped tcImg is in "tcImg.mat" as group's name.
    if strcmpi(SigName{N},'tcImg'),
      Sig{N} = subsigload('tcImg.mat', grp.name);
	else
      Sig{N} = subsigload(sprintf('%s.mat',grp.name), SigName{N});
    end
  end
else
  % ExpNo as experiment's number.
  grp = getgrp(Ses,ExpNo);
  if isempty(grp),
    fprintf('SIGLOAD: "getgrp(Ses, ExpNo) returns an empty group\n');
    fprintf('SIGLAOD: Check description file; perhaps ExpNo was excluded!!\n');
    keyboard;
  end;
  for N = 1:length(SigName),
    tmpsigname = SigName{N};
    idx = strfind(lower(tmpsigname),'.bak');
    if ~isempty(idx),
      USE_BAKFILE = 1;
      tmpsigname = tmpsigname(1:idx-1);
    else
      USE_BAKFILE = 0;
    end
    
    switch lower(tmpsigname),
     case { 'cln','clnspc','clnfft','tcimg'}
      % those signals are saved in "SIGS" directory
      matfile = catfilename(Ses,ExpNo, tmpsigname);
     case { 'spktblp' ,'spktcln','brsttblp','brsttcln',...
            'atspktblp' ,'atspktcln','atbrsttblp','atbrsttcln' }
      matfile = catfilename(Ses,ExpNo, tmpsigname);
	 case lower(Ses.ctg.GrpDEPSigs)
      matfile = catfilename(Ses,ExpNo,'contrasts');
     otherwise
      matfile = catfilename(Ses,ExpNo,'mat');
    end
    
    if USE_BAKFILE,
      matfile = sprintf('%s.bak',matfile);
    end

    Sig{N} = subsigload(matfile, tmpsigname, Ses, ExpNo);
    SigName{N} = tmpsigname;
  end
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
if isfield(grp,'epoch') && grp.epoch,
  fprintf(' sigload: stm/evt/grp are overwrited by "grp.epoch (exp=%d)".\n',grp.epoch);
  pars = expgetpar(Ses,grp.epoch);
else
  pars = expgetpar(Ses,ExpNo);
end;
for N = 1:length(Sig),
  if isempty(Sig{N}), continue;  end

  if isstruct(Sig{N}),
    if isfield(Sig{N},'dir') && isfield(Sig{N}.dir,'dname') && strcmp(Sig{N}.dir.dname(1:2),'es'), continue; end;
  elseif isstruct(Sig{N}{1}),
    if isfield(Sig{N}{1},'dir') && isfield(Sig{N}{1}.dir,'dname') && strcmp(Sig{N}{1}.dir.dname(1:2),'es'), continue; end;
  end;
  
  % signal is not empty.
  if iscell(Sig{N}),
    % if the signal is a cell array, do nothing except "roiTs"
    if isfield(Sig{N}{1},'dir') && isfield(Sig{N}{1}.dir,'dname'),
      if strcmpi(Sig{N}{1}.dir.dname,'roiTs') && strcmpi(SigName{N},'roiTs'),
        for K = 1:length(Sig{N})
          Sig{N}{K}.grp = grp;
          Sig{N}{K}.evt = pars.evt;
          Sig{N}{K}.stm = pars.stm;
        end
      end
    end
  else
    % 30.06.04 NKL: This here serves the following purpose:
    % Many signals (e.g. statistics) do not have any conventional
    % fields, and they do not need the addition of grp/evt/stm
    % either. To read them with this function, skip appending
    % fields if a signal does not have the basic "dir" field.
    if ~isfield(Sig{N},'dir'),
      continue;
    end;
    Sig{N}.grp = grp;
    if isfield(pars,'evt') && ~isempty(pars.evt) && ~isfield(Sig{N},'sigsort'),
      Sig{N}.evt = pars.evt;
    end
    if isfield(pars,'stm') && ~isempty(pars.stm) && ~isfield(Sig{N},'sigsort') && ~isfield(Sig{N},'rp'),
      Sig{N}.stm = pars.stm;
    end
    if isfield(Sig{N}.dir,'dname') && strcmpi(Sig{N}.dir.dname,'tcImg'),
      Sig{N}.usr.pvpar = pars.pvpar;
    end
  end
end;

% assign signal(s) in caller's workspace.
if nargout == 0,
  for N = 1:length(SigName),
    assignin('caller', SigName{N}, Sig{N});
  end
else
  varargout = Sig;
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = subsigload(Filename,SigName, Ses, ExpNo)
% Sig = matsigload(Filename,SigName);
% this is 10% faster.
% YUSUKE: This is a DIRTY patch to avoid the problem of reading the group name from the
% Signal structure. By doing this we can have multiple group definitsion for the same raw
% data... You can change this the way you like if necessary
% Sunday 04.03.2007
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
  Sig = load(Filename,SigName,'-mat');
  eval(sprintf('Sig = Sig.%s;',SigName));
catch
  fprintf(' sigload.subsigload: ''%s'' not found in %s.\n',SigName,Filename);
  Sig = {};
  return;
end

if nargin > 2,
  grp = getgrp(Ses,ExpNo);
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
