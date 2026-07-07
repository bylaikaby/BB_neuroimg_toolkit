function Sig = signormalize(Sig,METHOD,varargin)
%SIGNORMALIZE - Normalize the signal with the given method.
%  SIG = SIGNORMALIZE(SIG,METHOD,...) normalize the signal with the given method.
%
%  Supported options are :
%    'epoch'     : 
%    'hemodelay' :
%    'hemotail'  :
%    'datname'   :
%
%  EXAMPLE :
%    Sig = signormalize(Sig,'sdu');
%    Sig = signormalize(Sig,'sdu','epoch','blank');
%
%  VERSION :
%    0.90 03.02.12 YM  pre-release
%    0.91 04.04.16 YM  bsxfun, the same result as xform/getStimIndices.
%
%  See also xform getStimIndices

if nargin < 2,  help signormalize; return;  end

if iscell(Sig),
  for N = 1:length(Sig),
    Sig{N} = signormalize(Sig{N},METHOD,varargin{:});
  end
  return
end

EPOCH      = '';
HEMO_DELAY = [];
HEMO_TAIL  = [];
FLAG       = 0;    % "flag" for std()/nanstd().
DAT        = 'dat';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case { 'epoch' 'period' }
    EPOCH = varargin{N+1};
   case { 'hemodelay' 'delay' }
    HEMO_DELAY = varargin{N+1};
   case { 'hemotail' 'tail' }
    HEMO_TAIL  = varargin{N+1};
   case { 'flag' }
    FLAG = varargin{N+1};
   case { 'datname' 'dat' }
    DAT = varargin{N+1};
  end
end

[tmpv infosig] = issig(Sig);


if isempty(EPOCH),  EPOCH = 'prestim';  end

if isempty(HEMO_DELAY),
  % set default HEMO_DELAY
  switch infosig.signame,
   case { 'tcImg','Pts','xcor','xcortc','roiTs','troiTs','froiTs','tfroiTs'}
    HEMO_DELAY = 2;
   otherwise
    HEMO_DELAY = 0;
  end
end
if isempty(HEMO_TAIL),
  % set default HEMO_TAIL
  switch infosig.signame,
   case { 'tcImg','Pts','xcor','xcortc','roiTs','troiTs' 'froiTs','tfroiTs' }
    HEMO_TAIL = 5;
   otherwise
    HEMO_TAIL = 0;
  end
end


V_PERMUTE = [];
if strcmpi(infosig.signame,'tcImg'),
  if ~strcmpi(DAT,'dat'),
    error('\n ERROR %s: supports .dat only for tcImg.\n',mfilename);
  end
  if ndims(Sig.dat) > 4,
    error('\n ERROR %s: tcImg.dat is not (x,y,z,t).\n',mfilename);
  end
  % (X,Y,Z,T)
  V_PERMUTE = [4 1 2 3];
  Sig.dat = permute(Sig.dat,V_PERMUTE);
end

V_RESHAPE = [];
if ndims(Sig.(DAT)) > 2,
  V_RESHAPE = size(Sig.(DAT));
  Sig.(DAT) = reshape(Sig.(DAT),[V_RESHAPE(1) prod(V_RESHAPE(2:end))]);
end

xi = sub_getperiods(Sig,DAT,EPOCH,HEMO_DELAY,HEMO_TAIL);


switch lower(METHOD),
 case { 'sdu' 'tosdu' }
  if isa(Sig.dat,'single'),
    % nanmean() returns wrong values when 'single'...
    tmpm = single(nanmean(double(Sig.dat(xi,:)),1));
    tmps = single(nanstd(double(Sig.dat(xi,:)),FLAG,1));
  else
    tmpm = nanmean(Sig.dat(xi,:),1);
    tmps = nanstd(Sig.dat(xi,:),FLAG,1);
  end
  tmpidx = (tmps <= eps);
  tmps(tmpidx) = 1;  % avoid zero div.
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = (Sig.dat(:,N) - tmpm(N)) / tmps(N);
  % end
  Sig.dat = bsxfun(@minus,   Sig.dat, tmpm);
  Sig.dat = bsxfun(@rdivide, Sig.dat, tmps);
  Sig.dat(:,tmpidx) = 0;
  tmps(tmpidx) = 0;

  stat.method = 'sdu';
  stat.epoch  = EPOCH;
  stat.m      = single(tmpm);
  stat.s      = single(tmps);
  
 case { 'percent' 'percentage' }
  if isa(Sig.dat,'single'),
    % nanmean() returns wrong values when 'single'...
    tmpm = single(nanmean(double(Sig.dat(xi,:)),1));
  else
    tmpm = nanmean(Sig.dat(xi,:),1);
  end
  tmpidx = (abs(tmpm) <= eps);
  tmpm(tmpidx) = 1;  % avoid zero div.
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = Sig.dat(:,N) / tmpm(N);
  % end
  Sig.dat = bsxfun(@rdivide, Sig.dat, tmpm);
  Sig.dat = Sig.dat * 100 - 100;
  Sig.dat(:,tmpidx) = 0;
  tmpm(tmpidx) = 0;
  
  stat.method = 'percent';
  stat.epoch  = EPOCH;
  stat.m      = single(tmpm);
  
 case { 'frac' 'fraction' }
  if isa(Sig.dat,'single'),
    % nanmean() returns wrong values when 'single'...
    tmpm = single(nanmean(double(Sig.dat(xi,:)),1));
  else
    tmpm = nanmean(Sig.dat(xi,:),1);
  end
  tmpidx = (abs(tmpm) <= eps);
  tmpm(tmpidx) = 1;  % avoid zero div.
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = Sig.dat(:,N) / tmpm(N);
  % end
  Sig.dat = bsxfun(@rdivide, Sig.dat, tmpm);
  Sig.dat(:,tmpidx) = 0;
  tmpm(tmpidx) = 0;
  
  stat.method = 'fraction';
  stat.epoch  = EPOCH;
  stat.m      = single(tmpm);
 
 case { 'zerobase' }
  if isa(Sig.dat,'single'),
    % nanmean() returns wrong values when 'single'...
    tmpm = single(nanmean(double(Sig.dat(xi,:)),1));
  else
    tmpm = nanmean(Sig.dat(xi,:),1);
  end
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = Sig.dat(:,N) - tmpm(N);
  % end
  Sig.dat = bsxfun(@minus, Sig.dat, tmpm);

  stat.method = 'zerobase';
  stat.epoch  = EPOCH;
  stat.m      = single(tmpm);
  
 otherwise
  error('\n ERROR %s: METHOD(%s) not supported yet.\n',mfilename,METHOD);
  
end

if any(V_RESHAPE),
  Sig.(DAT) = reshape(Sig.(DAT),V_RESHAPE);
  if isfield(stat,'m'),
    stat.m = reshape(stat.m, V_RESHAPE(2:end));
  end
  if isfield(stat,'s'),
    stat.s = reshape(stat.s, V_RESHAPE(2:end));
  end
end
if any(V_PERMUTE),
  Sig.(DAT) = ipermute(Sig.(DAT),V_PERMUTE);
end


if ~isfield(Sig,mfilename),
  Sig.(mfilename) = { stat };
else
  Sig.(mfilename){end+1} = stat;
end

return




% ========================================================================
function StimIndices = sub_getperiods(Sig,DAT,ObjType,HemoDelay,HemoTail)
% ========================================================================

grp = getgrp(Sig.session,Sig.ExpNo(1));

StimV       = Sig.stm.v{1};
StimT       = Sig.stm.time{1};
StimDT      = Sig.stm.dt{1};
StimIndices = [];  StimTypes = {};

% make sure to add end time for the last stimulus.
if length(StimV) == length(StimT),
  %StimT(end+1) = size(Sig.(DAT),1)*Sig.dx(1);
  StimT(end+1) = StimT(end) + StimDT(length(StimV));  % the same as getStimIndices().
end

% reconstruct all stimobjs in the session.
for N = 1:length(StimT)-1,
  % supports negative IDs of old session like d01nm4.
  StimTypes{N} = Sig.stm.stmpars.StimTypes{abs(StimV(N))+1};
end


if ~isempty(strfind(ObjType,'stim[')) && ~isempty(strfind(ObjType,']')),
  SELSTIM = str2num(ObjType(strfind(ObjType,'['):end));
  ObjType = 'stimseq';
end

if isawake(grp) && isfield(grp,'daqver') && grp.daqver >= 2,
  if any(strcmpi(ObjType,{'prestim','prestm'})),
    ObjType = 'awakeprestim';
  end
  if any(strcmpi(ObjType,{'poststim','poststm'})),
    ObjType = 'awakepoststim';
  end
end

switch lower(ObjType),
 case { 'all' }
  StimIndices = 1:round(StimT(end)/Sig.dx(1));
 case { 'nonblank','notblank','anystim','stim','noblank'}
  % should take a period from T(N)+HemoDelay to T(N+1)+HemoTail
  for N=1:length(StimTypes),
    if ~strcmpi(StimTypes{N},'blank'),
      % StimT(N),StimT(N+1)
      ts = round((StimT(N)   + HemoDelay)/Sig.dx(1)) + 1;  % +1 for matlab indexing
      te = round((StimT(N+1) + HemoTail )/Sig.dx(1));
      if ts > te,
        fprintf(' ERROR %s: the period is shorter than HemoTail-HemoDelay.\n',mfilename);
        %keyboard
        continue;
      end
      tmpdur = ts:te;
      StimIndices = [StimIndices, tmpdur];
    end
  end
 case { 'prestim','prestm' }
  % should take a period from 0 to T(1)+HemoDelay
  if isfield(grp,'prestim') && ~isempty(grp.prestim),
    for N=1:length(grp.prestim),
      for K=1:length(StimV),
        if StimV(K) ~= grp.prestim(N), continue;  end
        ts = round((StimT(K)   + 0        )/Sig.dx(1)) + 1;  % +1 for matlab indexing
        te = round((StimT(K+1) + HemoDelay)/Sig.dx(1));
        tmpdur = ts:te;
        StimIndices = [StimIndices, tmpdur];
        break;
      end
    end
  else
    idx = find(~strcmpi(StimTypes,'blank') & ~strcmpi(StimTypes,'none') & ~strcmpi(StimTypes,'nostim'));
    if isempty(idx),
      % sesms to be always blank.
      %fprintf(' WARNING %s: no ''prestim'' period, returnig ''blank'' instead.\n',mfilename);
      StimIndices = 1:size(Sig.(DAT),1);
      % assumes blank - stimulus ....
      %ts = round((StimT(1)   + 0        )/Sig.dx(1)) + 1;  % +1 for matlab indexing
      %te = round((StimT(1+1) + HemoDelay)/Sig.dx(1));
      return
    else
      % mixture of blank and stimulus
      idx = idx(1);
      if idx == 1,
        if StimT(idx) > Sig.dx(1),
          ts = 1;
          te = round((StimT(idx)   + HemoDelay)/Sig.dx(1));
          StimIndices = ts:te;
        else
          fprintf(' WARNING %s: no ''prestim'' period, returnig ''blank'' instead.\n',mfilename);
          StimIndices = getStimIndices(Sig,'blank',HemoDelay,HemoTail);
        end
      else
        ts = round((StimT(idx-1) + 0        )/Sig.dx(1)) + 1;  % +1 for matlab indexing
        te = round((StimT(idx)   + HemoDelay)/Sig.dx(1));
        StimIndices = ts:te;
      end
    end
  end

 case { 'poststim','poststm' }
  N = 2;
  while N <= length(StimTypes),
    % if N ~= blank, then skip
    if ~any(strcmpi(StimTypes{N},{'blank','none','nostim'})),
      N = N + 1;
      continue;
    end
    % if N-1 ~= blank, then process
    if ~any(strcmpi(StimTypes{N-1},{'blank','none','nostim'})),
      ts = round((StimT(N)   + HemoTail )/Sig.dx(1)) + 1;  % +1 for matlab indexing
      te = round((StimT(N+1) + HemoDelay)/Sig.dx(1));
      % if N+1 == blank, then include
      if N+1 <= length(StimTypes),
        while any(strcmpi(StimTypes{N+1},{'blank','none','nostim'})),
          te = round((StimT(N+1+1) + HemoDelay)/Sig.dx(1));
          N = N + 1;
        end
      end
      tmpdur = ts:te;
      StimIndices = [StimIndices, tmpdur];
      N = N + 1;
    end
  end

  
 case { 'blank','nostim'}
  for N=1:length(StimTypes),
    % should take a period from T(N)+HemoTail to T(N+1)+HemoDelay
    if strcmpi(StimTypes{N},'blank'),
      if N == 1 || strcmpi(StimTypes{N-1},'blank'),
        ts = round((StimT(N)   + 0       )/Sig.dx(1)) + 1;  % +1 for matlab indexing
      else
        ts = round((StimT(N)   + HemoTail)/Sig.dx(1)) + 1;  % +1 for matlab indexing
      end
      te = round((StimT(N+1) + HemoDelay)/Sig.dx(1));
      if ts > te,
        fprintf(' ERROR %s: the period is shorter than HemoTail-HemoDelay.\n',mfilename);
        keyboard
      end
      tmpdur = ts:te;
      StimIndices = [StimIndices, tmpdur];
    end
  end

 case {'stimseq'}
  SEQ_COUNT = 0;
  % should take a period from T(N)+HemoDelay to T(N+1)+HemoTail
  for N=1:length(StimTypes),
    if ~strcmpi(StimTypes{N},'blank'),
      SEQ_COUNT = SEQ_COUNT + 1;
      if ~any(SELSTIM == SEQ_COUNT),  continue;  end
      % StimT(N),StimT(N+1)
      ts = round((StimT(N)   + HemoDelay)/Sig.dx(1)) + 1;  % +1 for matlab indexing
      te = round((StimT(N+1) + HemoTail )/Sig.dx(1));
      if ts > te,
        fprintf(' ERROR %s: the period is shorter than HemoTail-HemoDelay.\n',mfilename);
        %keyboard
        continue;
      end
      tmpdur = ts:te;
      StimIndices = [StimIndices, tmpdur];
    end
  end
  
 case {'awakeprestim','prestimawake'}
  if ~exist('ExpPar','var') || isempty(ExpPar) || ~isfield(ExpPar,'evt'),
    ExpPar = expgetpar(Sig.session,Sig.ExpNo(1));
  end
  if isfield(ExpPar.evt,'systempar') && isfield(ExpPar.evt.systempar,'preStimTime'),
    PRE_T = ExpPar.evt.systempar.preStimTime / 1000 + 2;
  else
    PRE_T = 4;
  end
  if isfield(Sig,'sigsort'),
    for N = 1:length(StimV),
      ts = round((StimT(N) - PRE_T)/Sig.dx(1)) + 1;  % +1 for matlab indexing
      te = round((StimT(N) + HemoDelay)/Sig.dx(1));
      tmpdur = ts:te;
      StimIndices = [StimIndices, tmpdur];
    end
  else
    evtobs = ExpPar.evt.obs{1};
    evtobs.times.ttype(end+1) = evtobs.endE;
    for N = 1:length(evtobs.trialCorrect),
      if evtobs.trialCorrect(N) == 0,  continue;  end
      ts = evtobs.times.ttype(N) / 1000;
      te = evtobs.times.ttype(N+1) / 1000;
      tmpidx = find(StimT > ts & StimT < te);
      if isempty(tmpidx),  continue;  end
      ts = round((StimT(tmpidx(1)) - PRE_T)/Sig.dx(1)) + 1;  % +1 for matlab indexing
      te = round((StimT(tmpidx(1)))/Sig.dx(1));
      tmpdur = ts:te;
      StimIndices = [StimIndices, tmpdur];
    end
  end
  
 case { -1,'-1' }
  % take a period before the 1st stimulus.
  % should take a period from 0 to T(1)+HemoDelay
  ts = 0;
  te = round((StimT(1) + HemoDelay)/Sig.dx(1));
  StimIndices = ts:te;
  
 otherwise
  % should take a period from T(N)+HemoTail to T(N+1)+HemoDelay
  %%%%%%%%%%% ????? FIX THIS
  %fprintf('%s: Unknown epoch %s\n', mfilename,ObjType);
  %keyboard
  if isnumeric(ObjType),
    % ObjType is given by stimulus ID, not by name.
    ObjType = StimTypes{ObjType+1};
  end
  for N=1:length(StimTypes),
    if strcmpi(StimTypes{N},ObjType),
      % StimT(N),StimT(N+1);
      if N == 1 || strcmpi(StimTypes{N-1},'blank'),
        ts = round((StimT(N)   + HemoDelay)/Sig.dx(1)) + 1;  % +1 for matlab indexing
      else
        ts = round((StimT(N)   + HemoTail )/Sig.dx(1)) + 1;  % +1 for matlab indexing
      end
      if N < length(StimTypes) && strcmpi(StimTypes{N+1},'blank'),
        te = round((StimT(N+1) + HemoTail )/Sig.dx(1));
      else
        te = round((StimT(N+1) + HemoDelay)/Sig.dx(1));
      end
      if ts > te,
        fprintf(' ERROR %s: the period is shorter than HemoTail-HemoDelay.\n',mfilename);
        keyboard
      end
      tmpdur = ts:te;
      StimIndices = [StimIndices, tmpdur];
    end
  end
end

if isempty(StimIndices),
  fprintf('\n ERROR %s: ''%s'' not found.',mfilename,ObjType);
  StimIndices = [];
  return;
end

StimIndices = StimIndices(StimIndices > 0 & StimIndices <= size(Sig.(DAT),1));

% make sure no overlapped regions
StimIndices = unique(StimIndices);


return

