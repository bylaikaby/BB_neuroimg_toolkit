function spc2model(SesName,GrpName,ChanNo,DOPLOT,LineColor)
%SPC2MODEL - Generates regressors from frequency ranges of SPC
% spc2model(SesName) - The purpose of this function is to generate frequency specific models
%     
% info.band{ 1}  = {[   0     4] 'ep'    'LFP',  0};    % Evoked potential
% info.band{ 2}  = {[   4    12] 'stmnm' 'LFP',  2};    % Stim-related & Neuromodulatory?
% info.band{ 3}  = {[  15    60] 'nm'    'LFP',  4};    % Stim-unrelated; Neuromodulatory
% info.band{ 4}  = {[  70   110] 'stm'   'LFP',  4};    % Stim-related; independent of MUA (50%)
% info.band{ 5}  = {[  10   110] 'lfp'   'LFP',  4};    % Traditional LFPs
% info.band{ 6}  = {[ 400  3000] 'mua'   'MUA', 45};    % Traditional Analog MUA
%
% NKL 11.02.07
% YM  27.09.07 upsample-convolve-downsample

if nargin < 1,
  help spc2model;
  return;
end;

if nargin < 5,  LineColor = 'k';    end;
if nargin < 4,  DOPLOT = 0;         end;
if nargin < 3,  ChanNo = [];        end;
if nargin < 2,  GrpName = {};       end

Ses = goto(SesName);

if nargin < 2,
  if isfield(Ses.anap,'RefGroup') & ~isempty(Ses.anap.RefGroup),
    GrpName = Ses.anap.RefGroup;
  end;
end;
  
if isempty(GrpName),
  GrpName = getgrpnames(Ses);
end
if ischar(GrpName),  GrpName = { GrpName };  end

for N=1:length(GrpName),
  fprintf('spc2model: Making model from data of %s\n', GrpName{N});
  sub_spc2model(Ses,GrpName{N},ChanNo,DOPLOT,LineColor);
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function sub_spc2model(SesName,GrpName,ChanNo,DOPLOT,LineColor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);
par = expgetpar(Ses,grp.exps(1));

if isfield(grp,'freqrange'),
  freqrange = grp.freqrange;
else
  freqrange = {[0 4], [4 12], [15 60], [70 110], [10 110], [400 3000]};
  freqrange = {[0 12], [70 120], [500 3000]};
  freqrange = {[20 2500]};                      % GET ALL BANDS FOR NOW!
end;
  
Spc = sigload(Ses,GrpName,'ClnSpc');

% FOR NOW WE ASSUME OBSERVATION W/OUT TRIALS (FIX LATER...)
if iscell(Spc),
  Spc = Spc{1};
end;

% validate signal by removing irregular point(s)
Spc = subRemoveIrregularPoints(Spc,5);
Spc = xform(Spc,'tosdu','blank');
Sig = spc2blp(Spc,freqrange);
if isstruct(Sig),
  Sig = {Sig};
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET STRUCTURE-DETAILS FROM THE FIRST RANGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model = Sig;
if iscell(model) & length(model)==1,
  model = model{1};
end;
model.range = freqrange;                    % Definitions regarding sorting by trial
model.tag = {};
model.dat = [];
for N=1:length(Sig),
  if isempty(ChanNo),
    tmp = squeeze(hnanmean(Sig{N}.dat,2));    % Average multiple channels
  else
    tmp = squeeze(Sig{N}.dat(:,ChanNo));
  end;
  model.dat = cat(2,model.dat,tmp);
  model.tag = cat(2,model.tag,Sig{N}.tag);
end;

model = sigconv(model,par.pvpar.imgtr);
if size(model.dat,1) > par.pvpar.nt,
  model.dat = model.dat(1:par.pvpar.nt,:);
elseif par.pvpar.nt > size(model.dat,1),
  dif = par.pvpar.nt - size(model.dat,1) - 1;
  tmp = model.dat(end-dif:end,:);
  model.dat = cat(1,model.dat,tmp);
end;

model.fname = strcat('SPC_',GrpName,'.mat');

if DOPLOT,
  t = [0:size(model.dat,1)-1] * model.dx;
  plot(t,model.dat,'color',LineColor);
  xlabel('Time in sec');
  ylabel('Arbitrary Units');
end;

save(model.fname,'model');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTOIN to resample data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = subRemoveIrregularPoints(Sig,THR_SD);
if iscell(Sig),
  for N = 1:length(Sig),
    Sig{N} = subRemoveIrregularPoints(Sig{N},THR_SD);
  end
  return;
end

idx_blank = getStimIndices(Sig,'blank',0,0);

szdat = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[szdat(1) prod(szdat(2:end))]);
tmpdat = Sig.dat(idx_blank,:);
tmpm   = hnanmean(tmpdat,1);
tmps   = hnanstd(tmpdat,1)*THR_SD;
for N=1:length(tmps),
  idx = find(abs(tmpdat(:,N)-tmpm(N)) > tmps(N));
  if isempty(idx),  continue;  end
  newdat = rand(length(idx),1)*tmps(N);
  tmpdat(idx,N) = newdat;
end
Sig.dat(idx_blank,:) = tmpdat;
Sig.dat = reshape(Sig.dat,szdat);
return


