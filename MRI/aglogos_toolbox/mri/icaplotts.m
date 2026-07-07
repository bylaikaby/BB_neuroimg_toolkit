function icaplotts(ICA, icomp, CompType, SINGLE_PLOT, NUM)
%ICAPLOTTS - Plot the time series of selected (icomp) ICs
%  
% ICA structure:
%         ana: [72x72x12 double]
%          ds: [0.7500 0.7500 2]
%      slices: [4 5 6 7 8 9]
%         map: [20x2575 double]
%      colors: {1x34 cell}
%     anapica: [1x1 struct]
%       mview: [1x1 struct]
%         raw: [1x1 struct]
%          ic: [1x1 struct]
% ICA.raw
%     session: 'h05tm1'
%     grpname: 'visesmix'
%       ExpNo: [1x40 double]
%      coords: [2575x3 double]
%       icomp: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
%         dat: [120x20 double]
%         err: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
% ICA.ic
%     session: 'h05tm1'
%     grpname: 'visesmix'
%       ExpNo: [1x40 double]
%         dat: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
%
% NKL 11.06.09
%
% See also GETICA ICALOAD ICAPLOTIC2D ICAPLOTCLUSTERS SHOWICA

if nargin < 5, NUM=0; end;
if nargin < 4, SINGLE_PLOT = 1; end;
if nargin < 3, CompType = 'ic'; end;

Sig = ICA.(CompType);
if nargin < 2 | isempty(icomp),
  icomp = [1:size(Sig.dat,2)];
end;

for N=1:length(icomp),
  MDLNAMES{N} = sprintf('%s%d', upper(CompType),icomp(N));
end;

BASELINE=0;

Sig.dat = Sig.dat(:,icomp);
if BASELINE,
  fSig = sigfilt(Sig,0.003,'low');
end;

t  = [0:size(Sig.dat,1)-1]*Sig.dx;
for C=1:length(icomp),
  hd(C)=plot(t,Sig.dat(:,C),'color',ICA.colors{icomp(C)},'linewidth',2);
  if BASELINE,
    hold on;
    plot(t,fSig.dat(:,C),'color',ICA.colors{icomp(C)},'linewidth',3);
  end;
  
  if isfield(Sig,'m'),
    txt{C} = sprintf('%s (r=%f)', MDLNAMES{C},Sig.anap.r(C));
  else
    txt{C} = sprintf('%s', MDLNAMES{C});
  end;
  if ~SINGLE_PLOT,
    set(gca,'ylim',[min(Sig.dat(:,C)) max(Sig.dat(:,C))]);
  end;
  hold on;
end;

icadrawstim(gca,Sig,1);

if SINGLE_PLOT,
  xlabel('Time in seconds');
  ylabel(sprintf('%s-Signal in SD Units',upper(CompType)));
else
  axis off;
  text(1,1,sprintf('%s%d', upper(CompType),NUM));
end
set(gca,'xlim',[t(1) t(end)]);
set(gca,'layer','top');
return

