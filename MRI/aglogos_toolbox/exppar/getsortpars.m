function varargout = getsortpars(Ses, ExpNo, ExcludeBlank,varargin)
%GETSORTPARS - Get parameters required to reshape/sort signals with the sigsort function
% USAGE   : sortp = getsortpars(Ses,ExpNo)
%
% NOTES   : if nargout == 0, then display information
%           if awake-exp, then 'trial' would start with the first stimulus in the trial.
%
%           if not compatible DAQ, then use GRP.xxx.trialid/trialtvol in the session file.
%
% ARGOUTS : sortp.xxx.name                 : sorting name
%                    .imgtr                : inter-volume time in sec
%                    .id[ncond]            : id list of conditions
%                    .nrep[ncond]          : # of repeats of conditions
%                    .obs{ncond}[nrep]     : observation
%                    .tonset{ncond}{nrep}  : time onset in sec
%                    .tlen{ncond}{nrep}    : duration in sec
%                    .types                : stimulus types
%                    .v{ncond}             : expected pattern
%                    .val{ncond}           : values for stimulus model
%                    .tvol{ncond}          : expected timings in volumes
%                    .dtvol{ncond}         : expected durations in volumes
%
% VERSION :
%   0.90 03.02.04 YM   first release
%   0.91 04.02.04 YM   adds .types,v,t,dt for plotting.
%   0.92 11.02.04 YM   supports old experiments.
%   0.93 13.04.04 YM   use expgetpar().
%   0.94 19.04.04 YM   supports 'ExpNo' as a group name.
%   0.95 04.01.05 YM   supports 'ExcludeBlank'.
%   0.96 09.01.06 YM   supports stm.val
%   0.97 14.01.06 YM   renamed .t/.dt as .tvol/.dtvol to avoied confusion.
%   0.98 17.01.06 YM   align timing by 1st stimulus for trial.
%   0.99 17.03.06 YM   aoivd error of negative stim IDs (old sessions like d01nm4)
%   1.00 13.03.07 YM   supports awake stuff.
%   1.01 10.06.10 YM   bug fix for SPIKE2 related information.
%   1.02 12.10.10 YM   adds .trialstim, which is aligned to the first stimulus in trials.
%
% See also SIGSORT, GETTRIAL, SESGETTRIAL, EXPGETPAR


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end
if ischar(Ses), Ses = goto(Ses);  end

  
grp = getgrp(Ses,ExpNo);
if ~isnumeric(ExpNo),  ExpNo = grp.exps(1);  end
ExpPar = expgetpar(Ses,ExpNo);

expevt = ExpPar.evt;
expevt.stm = ExpPar.stm;

if nargin < 3,  ExcludeBlank = 'ExcludeBlank';  end
if ischar(ExcludeBlank),
  if ~isempty(strfind(lower(ExcludeBlank),'exclude')),
    ExcludeBlank = 1;
  else
    ExcludeBlank = 0;
  end
end

evtinf.interVolumeTime = expevt.interVolumeTime;
evtinf.prmnames = expevt.prmnames;
for N = 1:length(expevt.validobsp),
  ObspNo = expevt.validobsp(N);
  evtinf.params{N} = expevt.obs{ObspNo}.params;
  if isfield(expevt.obs{ObspNo},'trialCorrect'),
    evtinf.trialCorrect{N} = expevt.obs{ObspNo}.trialCorrect;
  end;
  evtinf.times{N}  = expevt.obs{ObspNo}.times;
  evtinf.mri1E{N}  = expevt.obs{ObspNo}.mri1E;
  evtinf.mri{N}    = expevt.obs{ObspNo}.times.mri;
  evtinf.origtimes{N} = expevt.obs{ObspNo}.origtimes;
end

if ~isfield(grp,'daqver') || grp.daqver < 2,
  fprintf(' WARNING %s: old data(%s,%s), parameters may not be correct...',...
          mfilename,Ses.name,grp.name);
  %return;
end

evtinf.stm = ExpPar.stm;

% sortPar.stimulus : sorting by stimulus
pars = subSortParStimulus(Ses,grp,evtinf,ExcludeBlank);
if ~isempty(pars),
  pars.tfactor = expgettfactor(ExpPar);
  sortPar.stim = pars;
end

% sortPar.trial : sorting by trial
pars = subSortParTrial(Ses,grp,evtinf);
if ~isempty(pars),
  pars = subAlignByStim(pars,ExpPar.stm,grp);
  pars.tfactor = expgettfactor(ExpPar);
  sortPar.trial = pars;
  % sortPar.trialstim : sorting by trilal but 1st stimulus in the trial
  sortPar.trialstim = subSelectFirstStim(pars,ExpPar.stm,grp);
end




if nargout,
  varargout{1} = sortPar;
else
  fprintf('Trial-Related Parameters\n');
  rmfield(sortPar.trial,{'name','obs'})
  fprintf('\nStimulus-Related Parameters\n');
  rmfield(sortPar.stim,{'name','obs','prmnames','prmvals'})
end
return;

  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pars = subSortParStimulus(Ses,grp,evt,ExcludeBlank)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if grp.daqver < 2,
%  pars = subSortParStimulusOLD(Ses,grp,evt);
%  return;
%end

% preparation : get stimulus onsets.
imgtr = evt.interVolumeTime/1000.;

stmtypes = evt.stm.stmpars.StimTypes;

nobs = length(evt.times);
stimonT = {};
stimuid = [];
for K = 1:nobs,
  stimonT{K} = evt.times{K}.stm(:)';
  stimonT{K}(end+1) = evt.times{K}.end;
  stimonT{K} = stimonT{K} / 1000.;  % convert to sec
  stimInCorrectTrial{K} = ones(size(evt.params{K}.stmid));

  stimuid = cat(2,stimuid,evt.params{K}.stmid(:)');

  if isawake(grp),
    trialT{K} = evt.times{K}.ttype(:)';
    trialT{K}(end+1) = evt.times{K}.end;
    trialT{K} = trialT{K} / 1000.; % convert to sec
    for T = 1:length(trialT{K})-1,
      tmpsel = find(stimonT{K} > trialT{K}(T) & stimonT{K} < trialT{K}(T+1));
      stimInCorrectTrial{K}(tmpsel) = evt.trialCorrect{K}(T);
    end
  end
end

stimuid = sort(unique(abs(stimuid)));


% get sorting parameters
pars.name = 'stimulus';
pars.imgtr = imgtr;  % inter-volume time in sec
pars.id = [];
X = 1;
%for N = 1:length(stmtypes),
%  stmid = N - 1;
for N = 1:length(stimuid),
   stmid = stimuid(N);
   if ~isempty(ExcludeBlank) && ExcludeBlank == 1,
    % exclude 'blank' period
    if strcmpi(stmtypes{stmid+1},'blank'),
      continue;
    end
  end
  onset = {}; obs = [];  tlen = [];
  stmv = [];  stmt = {};  stmdt = {};  stmval = {};
  for K = 1:nobs,
    stimsel = find(abs(evt.params{K}.stmid) == stmid & stimInCorrectTrial{K} > 0);
    if isempty(stimsel), continue;  end
    if isawake(grp),
      stimlen = evt.params{K}.stmdur(stimsel)*imgtr;
    else
      stimlen = stimonT{K}(stimsel+1) - stimonT{K}(stimsel);
    end
    stimdur = evt.params{K}.stmdur(stimsel); % in volumes
    for S = 1:length(stimsel),
      onset{end+1} = stimonT{K}(stimsel(S));
      %stmt{end+1}  = 0;
      %stmdt{end+1} = evt.params{K}.stmdur(stimsel(S));
    end
    tlen  = [tlen, stimlen(:)'];
    obs   = [obs, ones(1,length(stimsel))*K];
    if isempty(stmv),
      stmv  = stmid;
      stmt  = 0;
      stmdt = evt.params{K}.stmdur(stimsel(1));
      %stmval = evt.stm.val{1}(stmv+1);  % +1 for matlab indexing
      stmval = evt.stm.val{1}(stimsel(1));
    end
  end
  if isfield(grp,'labels') && length(grp.labels) == length(stimuid),
    pars.label{X} = grp.labels{X};
  elseif isfield(grp,'label') && length(grp.label) == length(stimuid),
    pars.label{X} = grp.label{X};
  else
    pars.label{X} = stmtypes{N};
  end
  pars.id(X)    = stmid;
  pars.nrep(X)      = length(obs);
  pars.obs{X}       = obs;         % observation
  pars.tonset{X}    = onset;       % onset of stimuli in the pattern in sec
  pars.tlen{X}      = tlen;        % pattern duration in sec
  pars.types{X}     = {stmtypes{stmid+1}}; % stimulus types in the pattern
  pars.v{X}         = stmv;        % pattern
  pars.val{X}       = stmval;      % value for stimulus model
  pars.tvol{X}      = stmt;        % timings in volumes
  pars.dtvol{X}     = stmdt;       % durations in volumes
  % additional parameters
  pars.prmnames{X}  = {};          % parameter names
  pars.prmvals{X}   = [];          % parameter values
  X = X + 1;
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pars = subSortParTrial(Ses,grp,evt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if grp.daqver < 2,  pars = {};  return;  end
if ~isfield(evt.times{1},'ttype') || isempty(evt.times{1}.ttype),  pars = {};  return;  end

% preparation :  get all possible trial ids, stimulus onsets, trial onsets.
imgtr = evt.interVolumeTime/1000.;
nobs = length(evt.times);
stimonT = {};  trids = [];  trialT = {};
for K = 1:nobs,
  stimonT{K} = evt.times{K}.stm(:)';
  stimonT{K}(end+1) = evt.times{K}.end;
  stimonT{K} = stimonT{K} / 1000.;   % convert to sec
  trialT{K} = evt.times{K}.ttype(:)';
  trialT{K}(end+1) = evt.times{K}.end;
  trialT{K} = trialT{K} / 1000.; % convert to sec
  trids = [trids, evt.params{K}.trialid(:)'];
end
trids = sort(unique(trids));
% likely trial id is not saved in DGZ, but in HST.
if trids < 0,
  fprintf('\nWARNING %s: trial IDs are not saved in DGZ.\n',mfilename);
  if isfield(evt.stm,'hstpars') && ~isempty(evt.stm.hstpars),
    trids = sort(unique(evt.stm.hstpars.paramIndices));
  else
    trids = 1;
  end
end

% get sorting parameters
pars.name = 'trial';
pars.imgtr = imgtr;  % inter-volume time in sec
pars.id = trids;
for N = 1:length(trids),
  if isfield(grp,'labels') && ~isempty(grp.labels),
    pars.label{N} = grp.labels{N};
  elseif isfield(grp,'label') && ~isempty(grp.label),
    pars.label{N} = grp.label{N};
  else
    pars.label{N} = sprintf('trial%d',trids(N));
  end
  onset = []; obs = [];   tlen = [];
  stmv = [];  stmt = {};  stmdt = {};  stmval = {};  prmvals = [];
  for K = 1:nobs,
    if isawake(grp),
      trisel = find(evt.params{K}.trialid == trids(N) & evt.trialCorrect{K} > 0);
    else
      trisel = find(evt.params{K}.trialid == trids(N));
    end
    if isempty(trisel),  continue;  end
try
    for X = 1:length(trisel),
      stimsel = find(stimonT{K} >= trialT{K}(trisel(X)) & ...
                     stimonT{K} < trialT{K}(trisel(X)+1));
      onset{end+1} = stimonT{K}(stimsel);
      
      if isawake(grp),
        stimlen = evt.params{K}.stmdur(stimsel)*imgtr;
      else
        stimlen = stimonT{K}(stimsel+1) - stimonT{K}(stimsel);
      end
      tlen = [tlen, sum(stimlen)];
      %stmv{end+1}  = evt.params{K}.stmid(stimsel);
      %stmdt{end+1} = evt.params{K}.stmdur(stimsel);
      %tmpt = cumsum(stmdt{end}(1:end-1));
      %stmt{end+1} = [0, tmp(:)'];
    end
catch
  keyboard
end
    if isempty(stmv),
      tmp = evt.params{K}.stmid(stimsel);    stmv  = abs(tmp(:)');
      tmp = evt.stm.val{1}(stimsel);         stmval = tmp(:)';
      tmp = evt.params{K}.stmdur(stimsel);   stmdt = tmp(:)';
      tmp = cumsum(stmdt(1:end-1));          stmt  = [0, tmp(:)'];
      if isfield(evt.params{K},'prm') && ~isempty(evt.params{K}.prm) && isfield(evt,'prmnames'),
        prmvals = evt.params{K}.prm{trisel(end)}(1:length(evt.prmnames));
      end
    end
    obs = [obs, ones(1,length(trisel))*K];
  end
  pars.nrep(N)      = length(obs);
  pars.obs{N}       = obs;            % observation
  pars.tonset{N}    = onset;          % onset of 1st stimulus in the trial
  pars.tlen{N}      = tlen;           % trial duration in sec
  pars.types{N} = evt.stm.stmpars.StimTypes(stmv+1);  % stimulus types
  pars.v{N}         = stmv;           % pattern
  pars.val{N}       = stmval;         % value for stimulus model
  pars.tvol{N}      = stmt;           % timings in volumes
  pars.dtvol{N}     = stmdt;          % duration in volumes
  % additional parameters
  if ~isfield(evt,'prmnames'),
    evt.prmnames = {};
  end
  pars.prmnames{N}  = evt.prmnames;   % parameter names
  pars.prmvals{N}   = prmvals(:)';    % parameter values
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sortPar = subAlignByStim(sortPar,stm,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

stmtypes = stm.stmtypes;

if isawake(grp),

else
  for N = 1:length(sortPar.label),
    STMV   = abs(sortPar.v{N});
    if length(STMV) == 1, continue;  end
    if strcmpi(stmtypes{STMV(1)+1},'blank'),
      % if blank-stim-..., then aligned to the 1st stimulus.
      STMDT  = sortPar.dtvol{N} * sortPar.imgtr;  % in sec
      for K = 1:length(sortPar.tonset{N}),
        %fprintf('%2d-%2d:',N,K);
        %fprintf('%10.3f ',sortPar.tonset{N}{K});
        t1old = sortPar.tonset{N}{K}(1);
        t1new = sortPar.tonset{N}{K}(2) - STMDT(1);
        sortPar.tonset{N}{K}(1) = t1new;
        sortPar.tlen{N}(K) = sortPar.tlen{N}(K) - (t1new - t1old);
        %fprintf(' ==> ');
        %fprintf('%10.3f ',sortPar.tonset{N}{K});
        %fprintf('\n');
      end
    end
  end
end

  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sortPar = subSelectFirstStim(sortPar,stm,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stmtypes = stm.stmtypes;

for N = 1:length(sortPar.label),
  STMV   = abs(sortPar.v{N});
  if length(STMV) == 1, continue;  end
  S0 = -1;
  for S = 1:length(STMV),
    if ~strcmpi(stmtypes{STMV(S)+1},'blank'),
      S0 = S;
      break;
    end
  end
  if S0 < 0,  continue;  end
  
  % now select the 1st stimulus
  for K = 1:length(sortPar.tonset{N}),
    t1old = sortPar.tonset{N}{K}(1);
    t1new = sortPar.tonset{N}{K}(S0);
    
    sortPar.tonset{N}{K} = sortPar.tonset{N}{K}(S0:end);
    sortPar.tlen{N}(K)   = sortPar.tlen{N}(K) - (t1new - t1old);
  end
  
  sortPar.types{N} = sortPar.types{N}(S0:end);
  sortPar.v{N}     = sortPar.v{N}(S0:end);
  sortPar.val{N}   = sortPar.val{N}(S0:end);
  sortPar.dtvol{N} = sortPar.dtvol{N}(S0:end);
  sortPar.tvol{N}  = sortPar.tvol{N}(S0:end) - sortPar.tvol{N}(S0);
end


return
