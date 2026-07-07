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
% VERSION : 0.90 21.04.04 YM  first release.
%           0.91 22.04.04 YM  accepts multipe signal names.
%           0.92 30.04.04 YM  sets tcImg.usr.pvpar.
%           0.93 01.06.04 YM  if cell array, then load as it is.
%
% See also LOAD, CATFILENAME, EXPGETPAR, ASSIGNIN, ANALOAD

if nargin < 2,  help sigload;  return;  end  

Ses = goto(Ses);

% ----------------------------------------------------------------
% if no signal names, then loads all variables.
% 03.06.04 NKL: Added a few things to make sure it works, when the
% group name implies reading tcImg.mat and getting the structure
% with the defined group's name.
% ----------------------------------------------------------------
if nargin < 3,
  if ischar(ExpNo),
    % ExpNo as group's name
    grp = getgrpbyname(Ses,ExpNo);
    ExpNo = grp.exps(1);
    try,
      Sig = load(sprintf('%s.mat',grp.name));
    catch,
      try,
        Sig = load('tcImg.mat',grp.name);
      catch,
        disp(lasterr);
        keyboard;
      end;
    end;
  else
    % ExpNo as experiment's number.
    grp = getgrp(Ses,ExpNo);
    Sig = load(catfilename(Ses,ExpNo,'mat'));
  end

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
  if isfield(grp,'epoch') & grp.epoch,
    fprintf(' sigload: stm/evt/grp are overwrited by "grp.epoch (exp=%d)".\n',grp.epoch);
    pars = expgetpar(Ses,grp.epoch);
  else
    pars = expgetpar(Ses,ExpNo);
  end;
  
  SigName = fieldnames(Sig);
  for N = 1:length(SigName),
    if eval(sprintf('iscell(Sig.%s)',SigName{N})),
      % if the signal is a cell array, do nothing except "roiTs".
      if strcmpi(SigName{N},'roiTs'),
        for K = 1:length(Sig.roiTs),
          Sig.roiTs{K}.grp = grp;
          Sig.roiTs{K}.evt = pars.evt;
          Sig.roiTs{K}.stm = pars.stm;
        end
      end
    else 
      % add grp,evt,stm fields
      % 30.06.04 NKL: This here serves the following purpose:
      % Many signals (e.g. statistics) do not have any conventional
      % fields, and they do not need the addition of grp/evt/stm
      % either. To read them with this function, skip appending
      % fields if a signal does not have the basic "dir" field.
      if ~eval(sprintf('isfield(Sig.%s,''dir'')',SigName{N})),
        continue;
      end;
      eval(sprintf('Sig.%s.grp = grp;',SigName{N}));
      eval(sprintf('Sig.%s.evt = pars.evt;',SigName{N}));
      eval(sprintf('Sig.%s.stm = pars.stm;',SigName{N}));
    end
    if strcmpi(SigName{N},'tcImg') | strcmpi(SigName{N},grp.name),
      eval(sprintf('Sig.%s.usr.pvpar = pars.pvpar;',SigName{N}));
    end
    if nargout,
      eval(sprintf('tmp = Sig.%s;',SigName{N}));
      varargout{N} = tmp;
    else
      cmdstr = sprintf('assignin(''caller'',SigName{N},Sig.%s);',SigName{N});
      eval(cmdstr);
    end;
  end
  return;
end

% ----------------------------------------------------------------
% now loads specified sinal(s).
% ----------------------------------------------------------------
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

if ischar(ExpNo),
  % ExpNo as group's name
  grp = getgrpbyname(Ses,ExpNo);
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
  for N = 1:length(SigName),
    switch lower(SigName{N}),
     case { 'cln','clnspc','tcimg' }
      % those signals are saved in "SIGS" directory
      Sig{N} = subsigload(catfilename(Ses,ExpNo,SigName{N}), SigName{N});
     otherwise
      Sig{N} = subsigload(catfilename(Ses,ExpNo,'mat'), SigName{N});
    end
  end
end


% use updated "stm" parameter.

if isfield(grp,'epoch') & grp.epoch,
  pars = expgetpar(Ses,grp.epoch);
else
  pars = expgetpar(Ses,ExpNo);
end;
for N = 1:length(Sig),
  if isempty(Sig{N}), continue;  end
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
    Sig{N}.evt = pars.evt;
    Sig{N}.stm = pars.stm;
    if isfield(Sig{N}.dir,'dname') & strcmpi(Sig{N}.dir.dname,'tcImg'),
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
function Sig = subsigload(Filename,SigName)
% Sig = matsigload(Filename,SigName);
% this is 10% faster.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
  Sig = load(Filename,SigName);
  eval(sprintf('Sig = Sig.%s;',SigName));
catch
  fprintf(' sigload.subsigload: ''%s'' not found in %s.\n',SigName,Filename);
  Sig = {};
  return;
end
return;
