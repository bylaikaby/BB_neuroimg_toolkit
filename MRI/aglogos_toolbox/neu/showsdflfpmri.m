function showsdflfpmri(SesName, FILESPEC, Chan)
%SHOWSDFLFPMRI - Show the Sdf, LFP and BOLD Responses
%
%   info.band{ 1}  = {[   0     4] 'ep'    'LFP',  0};    % Evoked potential
%   info.band{ 2}  = {[   4    12] 'stmnm' 'LFP',  2};    % Stim-related & Neuromodulatory?
%   info.band{ 3}  = {[  15    60] 'nm'    'LFP',  4};    % Stim-unrelated; Neuromodulatory
%   info.band{ 4}  = {[  70   110] 'stm'   'LFP',  4};    % Stim-related; independent of MUA (50%)
%   info.band{ 5}  = {[  10   110] 'lfp'   'LFP',  4};    % Traditional LFPs
%   info.band{ 6}  = {[ 500  3000] 'mua'   'MUA', 45};    % Traditional Analog MUA
%
% NKL 21.10.2007
  
if nargin < 1,
  SesName = 'g02mn1';
  FILESPEC = 33;
  Chan = 1;
end;

MUAIDX = 6;
LFPIDX = [2:5];
LFPNAMES = {'LFP[4-12Hz] (STM-NM)','LFP[15-60Hz] (NM)','LFP[70-110Hz] (STM)','SDF'};

HRFLAGS = 20;
% HRFBANDS = [1 2 3 4 6];
HRFALLMONKEYS = 'Y:\DataMatlab\workspace\impresp.mat';

if nargin & nargin < 3,
  Chan = 1;
end;

if nargin & nargin < 2,
  help showsdflfpmri;
  return;
end;

Ses = goto(SesName);

myroi = 'ele';
if strcmp(myroi,'ele'),
  if ~any(strcmp(Ses.roi.names,'ele')),
    myroi = sprintf('ele%d',Chan);
  end;
end;

if ischar(FILESPEC),
  grp = getgrpbyname(Ses,FILESPEC);
  GrpName = FILESPEC;
  ExpNo = grp.exps(1);
else
  grp = getgrp(Ses,FILESPEC);
  GrpName = grp.name;
end;

[Sdf, blp] = sigload(Ses,FILESPEC,'Sdf','blp');
if iscell(Sdf),  Sdf = Sdf{1}; end;
if iscell(blp),  blp = blp{1}; end;
blp.dat = squeeze(blp.dat(:,Chan,LFPIDX));
blpt = [0:size(blp.dat,1)-1]*blp.dx;

% Sdf.dat [time, chan]
if size(Sdf.dat,3) > 1,  Sdf.dat = hnanmean(Sdf.dat,3); end;
% blp.dat [time, chan, band]
if size(blp.dat,4) > 1,  blp.dat = hnanmean(blp.dat,4); end;
% roiTs.dat [time, chan, band]
if size(blp.dat,4) > 1,  blp.dat = hnanmean(blp.dat,4); end;
sdfy = Sdf.dat(:,Chan);
sdft = [0:size(Sdf.dat,1)-1] * Sdf.dx;
blp.dat(:,length(LFPNAMES)) = sdfy;        % Replace MUA w/ SDF


Mask = glmname2idx(Ses,GrpName,'pbr');
if isempty(Mask), return; end;
mdl = sprintf('glm[%d]',Mask);
roiTs = mvoxselect(Ses,FILESPEC,myroi,mdl,[],0.05);
roiTs.dat = hnanmean(roiTs.dat,2);
roit = [0:size(roiTs.dat,1)-1]*roiTs.dx;

% LEAVE THIS HEAR FOR FUTURE REFERENCE
if exist('HRFBANDS','var'),
  fprintf('SHOWSDFLFPMRI: Computing HRF from Spont Data\n');
  Mask = glmname2idx(Ses,GrpName,'fVal');
  mdl = sprintf('glm[%d]',Mask);

  HRFFILE = 'spont1';
  hgrp = getgrp(Ses,HRFFILE);
  EXPS = hgrp.exps;
  for N=1:length(EXPS),
    nSig = sigload(Ses,EXPS(N),'blp');
    if iscell(nSig), nSig = nSig{1}; end;
    nChan = 2;
    nSig.dat = squeeze(nSig.dat(:,nChan,HRFBANDS));
    nSig.dat = hnanmean(nSig.dat,2);
    hSig = mvoxselect(Ses,EXPS(N),myroi,mdl,[],0.05);
    hSig.dat = hnanmean(hSig.dat,2);
    if N==1,
      hrf = sighrf(nSig,hSig,HRFLAGS);
    else
      tmphrf = sighrf(nSig,hSig,HRFLAGS);
      hrf.dat = cat(2,hrf.dat,tmphrf.dat);
    end;
  end;
  hrf.dat = hnanmean(hrf.dat,2);
  hrf.xdata = [0:size(hrf.dat,1)-1] * hrf.dx;
else
  % Theoretical HRF
  %   IRTLEN = round(HRFLAGS/blp.dx);     % 25 sec duration
  %   IRT = [0:IRTLEN-1] * blp.dx;	% see impresp.mat/supir.t
  %   Lamda = 10;
  %   Theta = 0.4;
  %   Kernel.dat = gampdf(IRT,Lamda,Theta);
  %   Kernel.dat = Kernel.dat(:);
  %   Kernel.dat = Kernel.dat/sum(Kernel.dat);
  %   Kernel.dx  = blp.dx;
  %   Kernel.xdata = [0:length(Kernel.dat)-1]*Kernel.dx;
  s = load(HRFALLMONKEYS);
  hrf.dat = s.ir.fdat;
  hrf.dx = mean(diff(s.ir.t));
  clear s;
  NewFs = 1/blp.dx;
  NewLen = round(size(hrf.dat,1) * NewFs/(1/hrf.dx));
  hrf = sigresample(hrf, NewFs, 'len',NewLen);
  hrf.dat = mean(hrf.dat,2);
  hrf.dat = hrf.dat/sum(hrf.dat);
end;
cblp = sigconv(blp,hrf);

ts = sigresample(roiTs, 1/blp.dx, 'len',size(cblp.dat,1));
for N=1:size(cblp.dat,2),
  rstat(N) = mcor(cblp.dat(:,N),ts.dat);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT NOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%
mfigure([50 120 1400 1000]);
suptitle(sprintf('Session: %s, GrpName: %s, ExpNo: %d, Chan: %d',SesName,GrpName,ExpNo,Chan));

for N=1:length(LFPNAMES),
  subplot(length(LFPNAMES),1,N);
  area(roit,roiTs.dat,'facecolor',[.8 .7 .7]);
  hold on;
  h(N) = plot(blpt, cblp.dat(:,N),'color','r');
  subDrawStm(blp);
  title(sprintf('%s, r = %3.2f', LFPNAMES{N},rstat(N)),'fontweight','bold');
  ylabel('SD Units');
end;
xlabel('Time in sec');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDrawStm(sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DefArgs = {'facecolor',[.85 .85 .85],'linestyle','none','Tag','ScaleBar'};

stm = sig.stm.time{1};
if isfield(sig.stm,'stmtypes'),
  stimuli = sig.stm.stmtypes(sig.stm.v{1}+1);
  if any(strcmpi(stimuli,'blank')),
    idxon = find(~strcmpi(stimuli,'blank'));
    idxoff = idxon + 1;
    stm(end+1) = max([stm(end) sum(sig.stm.dt{1})]);
    stm = unique(stm([idxon(:)' idxoff(:)']));
  else
    stm = zeros(1,2*length(sig.stm.time{1}));
    stm(1:2:end) = sig.stm.time{1};
    stm(2:2:end) = sig.stm.time{1} + sig.stm.dt{1};
  end
end
tmp = get(gca,'ylim'); tmpy = tmp(1);
tmph = tmp(2)-tmp(1);
hd = [];

for N=1:2:length(stm),
  tmpx = stm(N);
  tmpw = stm(N+1)-stm(N);
  hd(end+1) = rectangle('Position',[tmpx tmpy tmpw tmph],DefArgs{:});
end
setback(hd);
set(gca,'layer','top');
return;
