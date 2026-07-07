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
  
if nargin < 1,
  help trial2obsp;
  return;
end;

if nargin < 2,
  StatName = 'mean';
end;

if isstruct(Sig),
  fprintf('trial2obsp: Expects a cell array as sigal-input\n');
  keyboard;
end;

if isstruct(Sig{1}),
  SigName = Sig{1}.dir.dname;
else
  SigName = Sig{1}{1}.dir.dname;
end;

if strcmpi(SigName,'blp') | strcmpi(SigName,'tblp'),
  oSig = subTrial2Obsp(Sig,SigName,StatName);
  if ~nargout,
    mfigure([10 100 900 800]);
    subplot(2,1,1);
    dspsig(Sig);
    subplot(2,1,2);
    dspsig(oSig);
  end;
elseif strcmpi(SigName,'roiTs') | strcmpi(SigName,'troiTs'),
  for RoiNo = 1:length(Sig),
    oSig{RoiNo} = subTrial2Obsp(Sig{RoiNo},SigName,StatName);
  end;
  if ~nargout,
    mfigure([10 100 900 800]);
    subplot(2,1,1);
    dsproits(Sig,'FigFlag',0);
    subplot(2,1,2);
    dsproits(oSig,'FigFlag',0);
  end;
else
  fprintf('trial2obsp: UNKNOWN signal name\n');
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subTrial2Obsp(Sig,SigName,StatName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SesName = Sig{1}.session;
GrpName = Sig{1}.grpname;
ExpNo = Sig{1}.ExpNo(1);

Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);
anap = getanap(Ses,ExpNo);

oSig = Sig{1};
oSig.dat = [];
DIM = length(size(Sig{1}.dat));

% .dat is Time X Chan X Band X TrialNo X ExpNo for BLP
% or .dat is Time X Voxel X TrialNo X ExpNo for roiTs
if strcmpi(SigName,'roiTs') & DIM==4,       % GROUP FILE
  for T=1:length(Sig),
    Sig{T}.dat = mean(Sig{T}.dat,DIM);
  end;
  DIM = DIM-1;
elseif strcmpi(SigName,'blp') & DIM==5,     % GROUP FILE
  for T=1:length(Sig),
    Sig{T}.dat = mean(Sig{T}.dat,DIM);
  end;
  DIM = DIM-1;
end;

switch StatName,
 case {'none'},
  for T=1:length(Sig),
    for N=1:DIM,
      if DIM == 3,        % roiTs or other one-band signals
        oSig.dat = cat(1,oSig.dat,Sig{T}.dat(:,:,DIM));
      elseif DIM==4,    % blp like signals
        oSig.dat = cat(1,oSig.dat,Sig{T}.dat(:,:,:,DIM));
      else
        fprintf('trial2obsp: Unexpected dat field dimensions (DIM=%d)\n', DIM);
      end;
    end;
    
    if T>1,
      oSig.stm.labels = cat(2,oSig.stm.labels,Sig{T}.stm.labels);
      for K=1:length(oSig.stm.v),
        oSig.stm.v{K} = cat(2,oSig.stm.v{K},Sig{T}.stm.v{K});
        oSig.stm.dt{K} = cat(2,oSig.stm.dt{K},Sig{T}.stm.dt{K});
        if isfield(oSig.stm,'val'),
          oSig.stm.val{K} = cat(2,oSig.stm.val{K},Sig{T}.stm.val{K});
        end;
      end;
    end;
    
  end;
    
 case {'mean'},
  for T=1:length(Sig),
    oSig.dat = cat(1,oSig.dat,mean(Sig{T}.dat,DIM));
    if T>1,
      oSig.stm.labels = cat(2,oSig.stm.labels,Sig{T}.stm.labels);
      for K=1:length(oSig.stm.v),
        oSig.stm.v{K} = cat(2,oSig.stm.v{K},Sig{T}.stm.v{K});
        oSig.stm.dt{K} = cat(2,oSig.stm.dt{K},Sig{T}.stm.dt{K});
        if isfield(oSig.stm,'val'),
          oSig.stm.val{K} = cat(2,oSig.stm.val{K},Sig{T}.stm.val{K});
        end;
      end;
    end;
  end;
    
 case {'median'},
  for T=1:length(Sig),
    oSig.dat = cat(1,oSig.dat,median(Sig{T}.dat,DIM));
    if T>1,
      oSig.stm.labels = cat(2,oSig.stm.labels,Sig{T}.stm.labels);
      for K=1:length(oSig.stm.v),
        oSig.stm.v{K} = cat(2,oSig.stm.v{K},Sig{T}.stm.v{K});
        oSig.stm.dt{K} = cat(2,oSig.stm.dt{K},Sig{T}.stm.dt{K});
        if isfield(oSig.stm,'val'),
          oSig.stm.val{K} = cat(2,oSig.stm.val{K},Sig{T}.stm.val{K});
        end
      end;
    end;
  end;
  
 otherwise,
  fprintf('trial2obsp: Possible arguments: none, mean, median\n');
  keyboard;
end;

for K=1:length(oSig.stm.v),
  oSig.stm.t{K} = cumsum(oSig.stm.dt{K});
  oSig.stm.time{K} = cumsum(oSig.stm.dt{K});
end;

  