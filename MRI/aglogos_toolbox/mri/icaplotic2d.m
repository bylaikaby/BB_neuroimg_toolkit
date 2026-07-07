function icaplotic2d(ICA, icomp, CompType)
%ICAPLOTIC2D - Plot "icomp" IC/RAW components in 2D surface format
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

if nargin < 3,
  CompType = 'ic';
end;

if ~isfield(ICA,CompType),
  Sig = ICA;
else
  Sig = ICA.(CompType);
end;

Sig = sigresample(Sig,Sig.dx/100);
t  = [0:size(Sig.dat,1)-1]*Sig.dx;
s = size(Sig.dat);

if nargin < 2 | isempty(icomp),
  icomp = [1:size(Sig.dat,2)];
end;

Sig.dat = Sig.dat(:,icomp);
% for N=1:size(Sig.dat,2),
%   Sig.dat(:,N) = Sig.dat(:,N)./max(abs(Sig.dat(:,N)));
% end;

R = 20;
Sig.dat = reshape(repmat(Sig.dat,R,1),s(1),R*s(2));


imagesc(Sig.dat');
colormap(jet);

for N=1:length(icomp),
  MDLNAMES{N} = sprintf('IC%d', icomp(N));
end;

if isfield(ICA,'colors'),
  set(gca,'ytick',[],'xtick',[]);
  for C=1:length(icomp)
    text(0,(R/2)+(C-1)*R,MDLNAMES{C},'horizontalalignment','right',...
         'fontweight','bold','color',ICA.colors{icomp(C)});
  end;

  newax = axes('position',get(gca,'position'));
  set(newax,'color','none','xgrid','off','ygrid','off','box','off','yticklabel',[]);
  set(newax,'Xlim',[t(1) t(end)]);
  title(sprintf('%s%s - %s', 'Signal: ', CompType, ICA.stminfo),'fontweight','normal','fontsize',10);
  icadrawstim(gca,Sig,0);
end;
