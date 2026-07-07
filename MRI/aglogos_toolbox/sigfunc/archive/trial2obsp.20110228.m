function oSig = trial2obsp(Sig,StatName)
%TRIAL2OBSP - Convert trial-based time series into continuous obserpvation periods
% oSig = TRIAL2OBSP(Sig, StatName) is useful if we want to do observation-based analysis. It
% "undoes" the results of gettrial, but with one important difference: The trials are now
% sorted by stimulus or trial type, which means the time course of observation periods can be
% averaged. In a randomized stimulus presentation design this is obviously not possible without
% the double conversion (obsp-> sorted-trial -> obsp).
%
% If StatName is 'none', the multiple occurances of a trial are concatanated serially. (DEFAULT)
% If StatName is mean/median the multiple occurances are averaged; so the obsp is shorter
% than the original one; but with better SNR.
%
% TO DEBUG:
%   y04yz1/11       Multiple different trial in obsp
%   n03qv1/1        Mutliple same trials in obsp
%   n03qv1/81       Mutliple different trials in obsp
%   m02lx1/1        No trials
%  
% NOTE: TO SEE THE RESULTS OF THIS FUNCTION CALL IT WITHOUT ARGUMENTS
%
% See also GETTRIAL DSPSIG
%  
% NKL 08.01.06
% YM  22.05.07 supports also 'tcImg'.
% YM  28.02.11 use nanmean() instead of mean().

if nargin < 1,
  help trial2obsp;
  return;
end;

if nargin < 2,
  StatName = 'mean';
end;

if ~iscell(Sig),
  fprintf('trial2obsp: Expects a cell array as sigal-input\n');
  keyboard;
end;

if isstruct(Sig{1}),
  % blp or other neural signals.
  SigName = Sig{1}.dir.dname;
  oSig = subTrial2Obsp(Sig,SigName,StatName);
else
  % it is likely to be 'troiTs'.
  SigName = Sig{1}{1}.dir.dname;
  for RoiNo = 1:length(Sig),
    oSig{RoiNo} = subTrial2Obsp(Sig{RoiNo},SigName,StatName);
  end;
end;


% if no output, then plot Sig and oSig.
if nargout == 0,
  if strcmpi(SigName,'roiTs'),
    mfigure([10 100 900 800]);
    subplot(2,1,1);
    dsproits(Sig,'FigFlag',0);
    subplot(2,1,2);
    dsproits(oSig,'FigFlag',0);
  else
    mfigure([10 100 900 800]);
    subplot(2,1,1);
    dspsig(Sig);
    subplot(2,1,2);
    dspsig(oSig);
  end
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to convert Sig from 'tiral' to 'obsp'
function oSig = subTrial2Obsp(Sig,SigName,StatName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SesName = Sig{1}.session;
GrpName = Sig{1}.grpname;
ExpNo = Sig{1}.ExpNo(1);

Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);
anap = getanap(Ses,ExpNo);

oSig = Sig{1};
oSig.dat = [];
oSig.stm = {};
DIM = length(size(Sig{1}.dat));

if DIM == 2,  DIM = 3;  end  % only 1 repeats..


if ~any(strcmpi(SigName,{'tcImg','roiTs','troiTs','blp','model','ClnSpc','Spkt','Sdf'})),
  error('ERROR %s: ''%s'' is not supported yet.',mfilename,SigName);
end

% if grouped along EXPS, then average across EXPS.
switch lower(SigName),
 case {'blp'}
  if DIM == 5,
    % GROUPED BLP
    % .dat is Time X Chan X Band X TrialNo X ExpNo for BLP
    for T=1:length(Sig),
      Sig{T}.dat = nanmean(Sig{T}.dat,DIM);
    end;
    DIM = DIM-1;
  end
 case {'tcimg'}
  if DIM == 6,
    % GROUPED tcImg
    % .dat as (x,y,z,t,repeats,exps)
    for T = 1:length(Sig),
      Sig{T}.dat = nanmean(Sig{T}.dat,DIM);
    end
    DIM = DIM-1;
  end
 case {'clnspc'}
  if DIM == 5,
    % GROUPED ClnSpc
    % .dat as (t,f,chan,repeats,exps)
    for T = 1:length(Sig),
      Sig{T}.dat = nanmean(Sig{T}.dat,DIM);
    end
    DIM = DIM-1;
  end
 otherwise
  if DIM == 4,
    % GROUPED SIGNAL
    % .dat is Time X Voxel X TrialNo X ExpNo for (t)roiTs
    for T=1:length(Sig),
      Sig{T}.dat = nanmean(Sig{T}.dat,DIM);
    end;
    DIM = DIM-1;
  end
end


if strcmpi(SigName,'tcImg'),
  % convert (x,y,z,t,repeats) into (t,xyz,repeats)
  TCIMG_XYZ = [];
  for T = 1:length(Sig),
    tmpsz = size(Sig{T}.dat);
    TCIMG_XYZ = tmpsz(1:3); % will be used later to recover dimension
    Sig{T}.dat = reshape(Sig{T}.dat,[prod(tmpsz(1:3)), tmpsz(4), tmpsz(5)]);
    Sig{T}.dat = permute(Sig{T}.dat,[2 1 3]);
  end
  DIM = 3;
end



OFFS_STM_TIME = 0;
switch StatName,
 case {'none'},
  for T=1:length(Sig),
    % update .dat
    for N=1:size(Sig{T}.dat,DIM),
      if DIM == 3,        % roiTs or other one-band signals
        oSig.dat = cat(1,oSig.dat,Sig{T}.dat(:,:,N));
      elseif DIM==4,    % blp like signals
        oSig.dat = cat(1,oSig.dat,Sig{T}.dat(:,:,:,N));
      else
        fprintf('trial2obsp: Unexpected dat field dimensions (DIM=%d,N=%d)\n', DIM,N);
      end;
      if isfield(Sig{T},'sigsort') && isfield(Sig{T}.sigsort,'nrepeats'),
        oSig.sigsort.nrepeats(T) = Sig{T}.sigsort.nrepeats(1);
      end
    end;
    % update .stm
    DatLen = size(Sig{T}.dat,1)*Sig{T}.dx(1);
    Nrep   = size(Sig{T}.dat,DIM);
    oSig.stm = subUpdateSTM(oSig.stm, Sig{T}, Nrep, DatLen, OFFS_STM_TIME);
    OFFS_STM_TIME = size(oSig.dat, 1) * oSig.dx(1);
  end;
    
 case {'mean'},
  for T=1:length(Sig),
    % update .dat
    oSig.dat = cat(1,oSig.dat,nanmean(Sig{T}.dat,DIM));
    % update .stm
    DatLen = size(Sig{T}.dat,1)*Sig{T}.dx(1);
    Nrep   = 1;    % should be 1 since it is averaged.
    oSig.stm = subUpdateSTM(oSig.stm, Sig{T}, Nrep, DatLen, OFFS_STM_TIME);
    OFFS_STM_TIME = size(oSig.dat, 1) * oSig.dx(1);
    if isfield(Sig{T},'sigsort') && isfield(Sig{T}.sigsort,'nrepeats'),
      oSig.sigsort.nrepeats(T) = Sig{T}.sigsort.nrepeats(1);
    end
  end;
    
 case {'median'},
  for T=1:length(Sig),
    % update .dat
    oSig.dat = cat(1,oSig.dat,median(Sig{T}.dat,DIM));
    % update .stm
    DatLen = size(Sig{T}.dat,1)*Sig{T}.dx(1);
    Nrep   = 1;    % should be 1 since it is medianed.
    oSig.stm = subUpdateSTM(oSig.stm, Sig{T}, Nrep, DatLen, OFFS_STM_TIME);
    OFFS_STM_TIME = size(oSig.dat, 1) * oSig.dx(1);
    if isfield(Sig{T},'sigsort') && isfield(Sig{T}.sigsort,'nrepeats'),
      oSig.sigsort.nrepeats(T) = Sig{T}.sigsort.nrepeats(1);
    end
  end;
  
 otherwise,
  fprintf('trial2obsp: Possible arguments: none, mean, median\n');
  keyboard;
end;

% just to avoid error in display functions
DatLen = size(oSig.dat,1)*oSig.dx(1);
for K = 1:length(oSig.stm.v),
  if isfield(oSig.stm,'tvol'),
    oSig.stm.tvol{K}(end+1) = DatLen / oSig.stm.voldt;
  else
    oSig.stm.tvol{K} = cumsum([0 oSig.stm.dt{K}]) / oSig.stm.voldt;
  end
  oSig.stm.t{K}(end+1)    = DatLen;
end


% if oSig has .r/.p/.mdl, make it non-sense.
if isfield(oSig,'r'),
  oSig.r = oSig.r(1);  oSig.r{1}(:) = 0;
  oSig.p = oSig.p(1);  oSig.p{1}(:) = 1;
  if isfield(oSig,'mdl'),
    %oSig = rmfield(oSig,'mdl');
    oSig.mdl = oSig.mdl(1);  oSig.mdl{1}(:) = 0;
  end
end



% recover dimension
if strcmpi(SigName,'tcImg'),
  % convert (t,xyz,...) --> (x,y,z,t,...)
  tmpsz = size(oSig.dat);
  tmppermute = 1:length(tmpsz);
  tmppermute(1:2) = [2 1];
  oSig.dat = permute(oSig.dat,tmppermute);
  tmpsz([1 2]) = tmpsz([2 1]);
  oSig.dat = reshape(oSig.dat,[TCIMG_XYZ,tmpsz(2:end)]);
end



return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCITON to update .stm field
function stm = subUpdateSTM(stm, Sig, Nrep, DatLen, OffsT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
if isempty(stm),
  stm = Sig.stm;
  stm.labels = {};
  stm.ntrials = 0;
  for K = 1:length(Sig.stm.v),
    stm.v{K}    = [];
    stm.val{K}  = [];
    stm.t{K}    = [];
    stm.dt{K}   = [];
    stm.time{K} = [];
    if isfield(stm,'tvol'),
      stm.tvol{K} = [];
    end
  end
  if isfield(stm,'prmvals'),
    stm = rmfield(stm,'prmvals');
  end
end

for K = 1:length(Sig.stm.v),
  sel = 1:length(Sig.stm.v{K});
  stm.v{K}   = cat(2, stm.v{K},   repmat(Sig.stm.v{K},        [1 Nrep]));
  stm.val{K} = cat(2, stm.val{K}, repmat(Sig.stm.val{K}(sel), [1 Nrep]));
  stm.dt{K}  = cat(2, stm.dt{K},  repmat(Sig.stm.dt{K}(sel),  [1 Nrep]));
  for N = 1:Nrep,
    tmpoffs = DatLen*(N-1) + OffsT;
    stm.t{K}    = cat(2, stm.t{K},    Sig.stm.t{K}(sel)+tmpoffs);
    stm.time{K} = cat(2, stm.time{K}, Sig.stm.time{K}(sel)+tmpoffs);
  end
  if isfield(stm,'tvol'),
    stm.tvol{K} = stm.t{K} / stm.voldt;
  end
end

stm.labels = cat(2, stm.labels, Sig.stm.labels);
stm.ntrials = stm.ntrials + Nrep;

return;
