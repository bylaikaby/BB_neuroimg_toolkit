function RESP = mvoxresponse(ROITS,varargin)
% MVOXRESPONSE - computes responses of roiTs/troiTs returned by mvoxselect.m
%
%  EXAMPLE :
%    >> sig1 = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> sig1.resp = mvoxresponse(sig1);
%
%  VERSION :
%    0.90 14.11.07 YM  pre-release
%    0.91 06.06.08 YM  bug fix on no-stimulus case.
%    0.92 12.10.10 YM  if no period for BaseType, try other possibility.
%
%  See also mvoxselect getStimIndices

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end


if iscell(ROITS),
  for N = 1:length(ROITS),
    RESP{N} = mvoxresponse(ROITS{N},varargin{:});
  end
  return
end


if strncmp(ROITS.grpname,'spont',5) || strncmp(ROITS.grpname,'base',4),
  RESP = {};
  return;
end;

% default values
anap = getanap(ROITS.session,ROITS.grpname);
HemoDelay = anap.HemoDelay;
HemoTail  = anap.HemoTail;
StimType  = 'anystim';
BaseType  = 'prestim';

% process optional arguments
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'hemodelay'}
    HemoDelay = varargin{N+1};
   case {'hemotail'}
    HemoTail = varargin{N+1};
   case {'stim','stimtype'}
    StimType = varargin{N+1};
   case {'base','basetype','baseline'}
    BaseType = varargin{N+1};
  end
end


if length(ROITS.stm.stmtypes)==1 && strcmpi(ROITS.stm.stmtypes{1},'blank');
  fprintf('MVOXRESPONSE: Spontaneous activity file! RESP = [];\n');
  RESP = [];
else
  % THIS IS THE BIGGEST BS EVER.... but I need to move on...
  % I hope we shall never have this randomization mistake again
  % 25 Sep 2010 NKL (just before leaving for Cyprus!)
  if strcmp(ROITS.session,'i07431'),
    ROITS.stm.v = {[0 1 0 0 1 0 0 1 0 0 1 0 0 1 0]};
    ROITS.stm.val = {[0 1 0 0 1 0 0 1 0 0 1 0 0 1 0]};
  end;    
    
  iresp = getStimIndices(ROITS,StimType,HemoDelay,HemoTail);
  ibase = getStimIndices(ROITS,BaseType,0,0);
  if isempty(ibase),
    if strcmpi(BaseType,'blank'),
      ibase = getStimIndices(ROITS,'prestim',0,0);
    elseif strcmpi(BaseType,'prestim'),
      ibase = getStimIndices(ROITS,'blank',0,0);
    end
  end
  if isempty(iresp),
    fprintf(' WARNING %s: no stimulus found, getting resp during blank...\n',mfilename);
    iresp = ibase;
  end
  RESP.stimtype = StimType;
  RESP.basetype = BaseType;
  RESP.iresp  = [iresp(1) iresp(end)];
  RESP.ibase  = [ibase(1) ibase(end)];
  RESP.base   = nanmean(ROITS.dat(ibase,:),1);
  RESP.mean   = nanmean(ROITS.dat(iresp,:),1);
  RESP.max    = max(ROITS.dat(iresp,:),[],1);
  RESP.min    = min(ROITS.dat(iresp,:),[],1);
end;


return;
  