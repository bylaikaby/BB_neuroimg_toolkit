function varargout = dspspktrigavr(SIG)
%DSPSPKTRIGAVR - displays 'spkBlp' signal.
%
%
%  NOTE:
% spkBlp = ----------AS OF 03.01.04---------
%     session: 's02nm1'
%     grpname: 'movie1'
%       ExpNo: 1
%         dir: [1x1 struct]
%         dsp: [1x1 struct]
%         usr: [1x1 struct]
%        chan: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]
%          dx: 0.0040
%       movie: [1x1 struct]
%       dxorg: 1.4400e-004
%         grp: [1x1 struct]
%         evt: [1x1 struct]
%         stm: [1x1 struct]
%        info: [1x1 struct]
%         dat: [4001x10x16x16 double]
%        lags: [1x4001 double]
%        nspk: [4314 1243 921 1976 2095 1862 2605 2980 5810 2650 2723 1393 2677 2732 2126 1707]
%       spkHz: [1x16 double]
%        dist: [16x16 double]
%    shuffled: [1x1 struct]
%
%  VERSION : 0.90 03.01.04 YM  pre-release
%
%  See also SESSPKTRIGAVR, SIGSPKTRIGAVR

if nargin == 0,  help dspspktrigavr; return;   end


if isfield(SIG,'shuffled') & ~isempty(SIG.shuffled.dat)
  DAT = SIG.dat - SIG.shuffled.dat;
  %DAT = SIG.dat;
  %DAT = SIG.shuffled.dat;
  SPC = SIG.spc - SIG.shuffled.spc;
  %SPC = SIG.spc;
else
  fprintf(' %s: no way for shuffle correction.\n',mfilename);
  DAT = SIG.dat;
  SPC = SIG.spc;
end

if length(SIG.ExpNo) > 1,
  txt_title = sprintf('%s(%s): %s GRP=%s',...
                      mfilename,SIG.dir.dname,SIG.session,SIG.grpname);
else
  txt_title = sprintf('%s(%s): %s EXP=%d (%s)',...
                      mfilename,SIG.dir.dname,SIG.session,SIG.ExpNo,SIG.grpname);
end


% makes spkCln compatible with SpktBlp
if any(strcmpi(SIG.dir.dname,{'SpktCln','BrsttCln','SpktGamma','BrsttGamma','SpktLfp','BrsttLfp'})),
  DAT = reshape(DAT,[size(DAT,1),1,size(DAT,2),size(DAT,3)]);
  SPC = reshape(SPC,[size(SPC,1),1,size(SPC,2),size(SPC,3)]);
  BANDS = { {[],'Cln','ALL'} };
else
  BANDS = SIG.info.band;
end

% selection of channels
if any(strcmpi(SIG.dir.dname,{'BrsttCln','Brsttblp'})),
  selchan = find(SIG.spkHz >= 0.1);
  %selchan = [1 4 5 7 9 10 14];
  %selchan = [2 6 11 13 15];
  %selchan = [6 11 15];
  DAT = DAT(:,:,selchan,:);
  DAT = DAT(:,:,:,selchan);
  SPC = SPC(:,:,selchan,:);
  SPC = SPC(:,:,:,selchan);
  SIG.spkchan = SIG.spkchan(selchan);
  SIG.nspk = SIG.nspk(selchan);
  SIG.spkHz = SIG.spkHz(selchan);
  SIG.dist = SIG.dist(selchan,:);
  SIG.dist = SIG.dist(:,selchan);
end

% selects interesting bands only
if strcmpi(SIG.dir.dname,'SpktBlp'),
  selBand = [];
  if 0,
    showBands = {'Delta';'Theta';'Alpha';'Beta';'GammaH';'MUA'};
  end;
  
  for iBand = 1:length(BANDS),
    if strcmpi(BANDS{iBand}{2},'LFP'),
      showBands = {'GammaM','LFP','MUA'};
      break;
    end
  end
  showBands = {'gamma'};
  for iBand = 1:length(BANDS),
    if any(strcmpi(BANDS{iBand}{2},showBands)),
      selBand(end+1) = iBand;
    end
  end
  BANDS = BANDS(selBand);
  DAT = DAT(:,selBand,:,:);
  SPC = SPC(:,selBand,:,:);
end


% remove center-peak
iCenter = find(abs(SIG.lags) <= 0.002);
iPeri = find(abs(SIG.lags) <= 0.003 & abs(SIG.lags) > 0.002);
if length(iCenter) > 1 & length(iPeri) > 1,
  tmpv = mean(DAT(iPeri,:,:,:),1);
  DAT(iCenter,:,:,:) = repmat(tmpv,[length(iCenter),1,1,1]);
end



% WAVEFORM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot spk-triggered averages of each electrode
for iBand = 1:size(DAT,2),
  h = mfigure([150 150 930 700]);;
  subShowEachSelf(squeeze(DAT(:,iBand,:,:)),SIG,BANDS{iBand});
  set(gcf,'Name',sprintf('%s,  WAV: DIST=0 of spk-%s',txt_title,BANDS{iBand}{2}));
  suptitle(sprintf('%s,  WAV: DIST=0 of spk-%s',txt_title,BANDS{iBand}{2}));
  %keyboard
end

% plot average of all distance
%for iBand = 1:size(DAT,2),
%  h = figure;
%  subShowAverage(squeeze(DAT(:,iBand,:,:)),SIG,BANDS{iBand});
%  set(gcf,'Name',sprintf('%s,  WAV: DIST-AVERAGE of spk-%s',txt_title,BANDS{iBand}{2}));
%end


% SPECTRUM %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot spectrum of spk-triggered average of each electrode
%for iBand = 1:size(SPC,2),
%  h = figure;
%  subShowSpcEachSelf(squeeze(SPC(:,iBand,:,:)),SIG,BANDS{iBand});
%  set(gcf,'Name',sprintf('%s,  SPC: DIST=0 of spk-%s',txt_title,BANDS{iBand}{2}));
%end

% plot average-spectrum of all distance
%for iBand = 1:size(SPC,2),
%  h = figure;
%  subShowSpcAverage(squeeze(SPC(:,iBand,:,:)),SIG,BANDS{iBand});
%  set(gcf,'Name',sprintf('%s,  SPC: DIST-AVERAGE of spk-%s',txt_title,BANDS{iBand}{2}));
%end




return;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = subShowEachSelf(DAT,SIG,BAND)
% DAT = [t,chan1,chan2]

% set N.A. for all
for iChan = 1:16,
  subplot(4,4,iChan);
  set(gca,'color','black','xticklabel',{},'yticklabel',{})
  text(0.4,0.5,'N.A.','color','red');
end

LAG_LMT = [-1.5, 1.5];
switch lower(BAND{2}),
 case {'cln'}
  %AMP_LMT = [-0.08 0.08];
  if SIG.info.band{1}{1}(1) == 0,
    AMP_LMT = [-0.4 0.4];
    AMP_LMT = [-0.8 0.8];
  else
    AMP_LMT = [-0.1 0.1];
    LAG_LMT = [-0.2 0.2];
  end
 case {'mua'}
  AMP_LMT = [-0.5 3.5];
 case {'gammam'}
  AMP_LMT = [-0.4 0.4];
 case {'lfp','delta'}
  AMP_LMT = [-0.4 0.4];
 otherwise
  AMP_LMT = [-0.2 0.2];
end

% plot data while clearing 'N.A.'.
ELE = SIG.spkchan;
LAGS = SIG.lags;
for iChan = 1:size(DAT,2),
  iEle = ELE(iChan);
  subplot(4,4,iEle);
  cla;
  plot(LAGS,DAT(:,iChan,iChan));
  grid on;
  set(gca,'xlim',LAG_LMT);
%  set(gca,'ylim',AMP_LMT);
  title(sprintf('ele%02d chn:%02d',iEle,iChan));
  tmptxt = sprintf('N=%d (%.2fHz)',round(SIG.nspk(iChan)),SIG.spkHz(iChan));
  text(0.01,0.95,tmptxt,'units','normalized');
  if mod(iEle,4) == 1,
    ylabel('Amplitude in SDU');
  end
  if iEle/4 > 3,
    xlabel('Lags in seconds');
  end
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = subShowAverage(DAT,SIG,BAND)
% DAT = [t,chan1,chan2]
DAT  = reshape(DAT,[size(DAT,1),size(DAT,2)*size(DAT,3)]);
DIST = SIG.dist(:);
udist = sort(unique(DIST));
LAGS = SIG.lags;
mDAT = NaN(length(LAGS),length(udist));
sDAT = NaN(length(LAGS),length(udist));
for iDist = 1:length(udist),
  idx = find(DIST == udist(iDist));
  mDAT(:,iDist) = mean(DAT(:,idx),2);
  sDAT(:,iDist) = std(DAT(:,idx),[],2);
end

% plot as waveform
% subplot(2,1,1);
% cla;
% X = ones(length(LAGS),1);
% for iDist = 1:length(udist),
%   plot3(X*udist(iDist),LAGS,mDAT(:,iDist));
%   hold on;
% end
% grid on;
% set(gca,'ylim',[-0.2,0.2]);
% set(gca,'zlim',[-300 300]);

%LAG_LMT = [-0.2 0.2];
LAG_LMT = [-1.5 1.5];
DST_LMT = [0 5.7];
switch lower(BAND{2}),
 case {'cln'}
  %AMP_LMT = [-0.08 0.08];
  if SIG.info.band{1}{1}(1) == 0,
    AMP_LMT = [-0.4 0.4];
    AMP_LMT = [-0.8 0.8];
  else
    AMP_LMT = [-0.05 0.05];
    LAG_LMT = [-0.2 0.2];
  end
 case {'mua'}
  AMP_LMT = [-0.5 3.5];
 case {'gammam'}
  AMP_LMT = [-0.4 0.4];
 case {'lfp','delta'}
  AMP_LMT = [-0.4 0.4];
 otherwise
  AMP_LMT = [-0.2 0.2];
end


mDAT(find(mDAT(:) < AMP_LMT(1)*1.2)) = AMP_LMT(1)*1.2;
mDAT(find(mDAT(:) > AMP_LMT(2)*1.2)) = AMP_LMT(2)*1.2;

% plot as surface
selL = find(LAGS >= LAG_LMT(1) & LAGS <= LAG_LMT(2));
selD = find(udist >= DST_LMT(1) & udist <= DST_LMT(2));


%subplot(2,1,2);
surf(udist(selD),LAGS(selL),mDAT(selL,selD),'linestyle','none');
shading interp;
%imagesc(udist,LAGS,mDAT);
set(gca,'xlim',DST_LMT);
set(gca,'ylim',LAG_LMT);
set(gca,'zlim',AMP_LMT);
set(gca,'clim',AMP_LMT);
xlabel('Distance in mm');
ylabel('Lags in seconds');
zlabel('Amplitude in SDU');

% plot waveform
X = ones(length(selL),1)*max(get(gca,'xlim'));
hold on;
plot3(X,LAGS(selL),mean(mDAT(selL,selD),2),'linewidth',2,'color','black');
% near
selNear = find(udist >= DST_LMT(1) & udist < 2);
plot3(X,LAGS(selL),mean(mDAT(selL,selNear),2),'color','red');
% far
selFar  = find(udist >= 2 & udist <= DST_LMT(2));
plot3(X,LAGS(selL),mean(mDAT(selL,selFar),2),'color','green');



Y = ones(length(selD),1)*max(get(gca,'ylim'));
plot3(udist(selD),Y,mean(mDAT(selL,selD),1),'linewidth',2,'color','black');

set(gca,'ydir','reverse');  % this causes troubles of 3D plotting

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = subShowSpcEachSelf(DAT,SIG,BAND)
% DAT = [t,chan1,chan2]

% set N.A. for all
for iChan = 1:16,
  subplot(4,4,iChan);
  set(gca,'color','black','xticklabel',{},'yticklabel',{})
  text(0.4,0.5,'N.A.','color','red');
  if mod(iChan,4) == 1,
    ylabel('Amplitude in SDU');
  end
  if iChan/4 > 3,
    xlabel('Lags in seconds');
  end
end



% plot data while clearing 'N.A.'.
ELE = SIG.spkchan;
FRQ = SIG.f;
for iChan = 1:size(DAT,2),
  iEle = ELE(iChan);
  subplot(4,4,iEle);
  cla;
  plot(FRQ,DAT(:,iChan,iChan));
  grid on;
  set(gca,'xlim',[0 max(FRQ)]);
  set(gca,'ylim',[0 30]);
  title(sprintf('ele%02d chn:%02d',iEle,iChan));
  tmptxt = sprintf('N=%d (%.2fHz)',round(SIG.nspk(iChan)),SIG.spkHz(iChan));
  text(0.01,0.95,tmptxt,'units','normalized');
  if mod(iEle,4) == 1,
    ylabel('Amplitude');
  end
  if iEle/4 > 3,
    xlabel('Frequency in Hz');
  end
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = subShowSpcAverage(DAT,SIG,BAND)
% DAT = [f,chan1,chan2]
DAT  = reshape(DAT,[size(DAT,1),size(DAT,2)*size(DAT,3)]);
DIST = SIG.dist(:);
udist = sort(unique(DIST));
FRQ = SIG.f;
mDAT = NaN(length(FRQ),length(udist));
sDAT = NaN(length(FRQ),length(udist));
for iDist = 1:length(udist),
  idx = find(DIST == udist(iDist));
  mDAT(:,iDist) = mean(DAT(:,idx),2);
  sDAT(:,iDist) = std(DAT(:,idx),[],2);
end

% due to Maltab's bug of 3D plotting and 'Ydir'-reverse,
% flip freq axis
%FRQ = flipud(FRQ(:));
%mDAT = flipdim(mDAT,1);
%sDAT = flipdim(sDAT,1);


%AMP_LMT = [-0.5 20];
AMP_LMT = [-0.5 200];
FRQ_LMT = [0 50];
DST_LMT = [0 5.7];

mDAT(find(mDAT(:) < AMP_LMT(1)*1.2)) = AMP_LMT(1)*1.2;
mDAT(find(mDAT(:) > AMP_LMT(2)*1.2)) = AMP_LMT(2)*1.2;

% plot as surface
selF = find(FRQ >= FRQ_LMT(1) & FRQ <= FRQ_LMT(2));
selD = find(udist >= DST_LMT(1) & udist <= DST_LMT(2));


%subplot(2,1,2);
surf(udist(selD),FRQ(selF),mDAT(selF,selD),'linestyle','none');
shading interp;
%imagesc(udist,FRQ,mDAT);
set(gca,'xlim',DST_LMT);
set(gca,'ylim',FRQ_LMT);
set(gca,'zlim',[0 max(AMP_LMT(:))]);
set(gca,'clim',AMP_LMT);
xlabel('Distance in mm');
ylabel('Frequency in Hz ');
zlabel('Amplitude');


% plot waveform
X = ones(length(selF),1)*max(get(gca,'xlim'));
hold on;
plot3(X,FRQ(selF),mean(mDAT(selF,selD),2),'linewidth',2,'color','black');
% near
selNear = find(udist >= DST_LMT(1) & udist < 2);
plot3(X,FRQ(selF),mean(mDAT(selF,selNear),2),'color','red');
% far
selFar  = find(udist >= 2 & udist <= DST_LMT(2));
plot3(X,FRQ(selF),mean(mDAT(selF,selFar),2),'color','green');


Y = ones(length(selD),1)*max(get(gca,'ylim'));
plot3(udist(selD),Y,mean(mDAT(selF,selD),1),'linewidth',2,'color','black');


set(gca,'ydir','reverse');  % this causes troubles of 3D plotting


return;
