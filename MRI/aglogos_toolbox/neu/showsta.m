function varargout = showsta(SesName, FileID)
%SHOWSTA - displays 'spkBlp' signal.
%
%  VERSION : 0.90 03.01.04 YM  pre-release
%
%  See also SESSPKTRIGAVR, SIGSPKTRIGAVR

if nargin < 2,  help showsta; return;   end


% LOAD DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
sigload(Ses, FileID, 'Spktblp');
if iscell(Spktblp),
  Spktblp = Spktblp{1};
end;

sub_dspspktrigavr(Spktblp);
return;


function varargout = sub_dspspktrigavr(SIG)
if nargin == 0,  help dspspktrigavr; return;   end


if isfield(SIG,'shuffled') & ~isempty(SIG.shuffled.dat)
  DAT = SIG.dat - SIG.shuffled.dat;
  SPC = SIG.spc - SIG.shuffled.spc;
else
  fpritnf(' %s: no way for shuffle correction.\n',mfilename);
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


% plot average of spk-triggered average of each electrode
for iBand = 1:size(DAT,2),
  h = mfigure([150 150 930 700]);
  subPlotAverageSTA(squeeze(DAT(:,iBand,:,:)),SIG,BANDS{iBand});
  set(gcf,'Name',sprintf('%s,  AVR-WAV: DIST=0 of spk-%s',txt_title,BANDS{iBand}{2}));
  figtitle(sprintf('%s,  AVR-WAV: DIST=0 of spk-%s',txt_title,BANDS{iBand}{2}));
end  


if 0,
% plot spk-triggered averages of each electrode
for iBand = 1:size(DAT,2),
  h = mfigure([150 150 930 700]);;
  plotsta(squeeze(DAT(:,iBand,:,:)),SIG,BANDS{iBand});
  set(gcf,'Name',sprintf('%s,  WAV: DIST=0 of spk-%s',txt_title,BANDS{iBand}{2}));
  suptitle(sprintf('%s,  WAV: DIST=0 of spk-%s',txt_title,BANDS{iBand}{2}));
end
end;
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% PLOT AVERAGE OF STA
function h = subPlotAverageSTA(DAT,SIG,BAND)

% average all STA of the same electorde combination.
Nchan  = size(DAT,2);
Nscale = SIG.nspk / sum(SIG.nspk);
SIG.nspk  = sum(SIG.nspk);
SIG.spkHz = mean(SIG.spkHz);
tmpDAT = zeros(size(DAT,1),1);
%tmpSPC = zeros(size(SPC,1),1);
tmpdist = 0; 
for iCh = 1:Nchan,
  tmpDAT = tmpDAT + DAT(:,iCh,iCh) * Nscale(iCh);
  %tmpSPC = tmpDAT + SPC(:,iCh,iCh) * Nscale(iCh);
  tmpdist = tmpdist + SIG.dist(iCh,iCh)/Nchan;
end
DAT = tmpDAT;
%SPC = tmpSPC;
SIG.dist  = tmpdist; % must be 0...


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


LAGS = SIG.lags;
h = gca;  cla;
plot(LAGS,DAT(:));
grid on;
set(gca,'xlim',LAG_LMT);
title(sprintf('ele-all chn-alld'));
tmptxt = sprintf('N=%d (%.2fHz)',round(SIG.nspk),SIG.spkHz);
text(0.01,0.95,tmptxt,'units','normalized');
ylabel('Amplitude in SDU');
xlabel('Lags in seconds');
title('Weighted AVERAGE of STA (all electrodes)');


  

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = plotsta(DAT,SIG,BAND)
% DAT = [t,chan1,chan2]

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
  subplot(2,2,iEle);
  cla;
  plot(LAGS,DAT(:,iChan,iChan));
  grid on;
  set(gca,'xlim',LAG_LMT);
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

