function axel_plot(SESSION,ExpNo,ChanNo,DO_EXPLORE)
%AXEL_PLOT - plots CLN/EPI data for Axel's papar
%  AXEL_PLOT(SESSION,EXPNO,CHANNO) plot cleaning data for Axel's papar
%
%  GOOD EXAMPLE for CLN:
%    f01kj1 : ExpNo=11, ChanNo=1
%
%  GOOD EXAMPLE for EPI:
%    g02lv1 : ExpNo=1
%    d04wi1 : ExpNo=1
%    j00me1 : ExpNo=1
%
%  EXAMPLE :
%
%  VERSION :
%    0.90 08.12.06 YM  pre-release
%    0.92 13.12.06 YM  looked for more examples
%
%  See also CLNMAIN CLNADF

if nargin == 0,
  % plots good example
  %subPlotCLN('f01kj1',11,1)
  subPlotEPI('g02lv1', 1);
  subPlotEPI('d04wi1', 1);
  subPlotEPI('j00me1', 1);
  return;
end

  
if nargin < 3,  ChanNo = [];  end
if nargin < 4,  DO_EXPLORE = 1;  end
if isempty(ChanNo),  ChanNo = 1;  end



if DO_EXPLORE,
  %subExploreCLN(SESSION,ExpNo,ChanNo)
  subExploreEPI(SESSION,ExpNo);
else
  %subPlotCLN(SESSION,ExpNo,ChanNo)
  subPlotEPI(SESSION,ExpNo)
end


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotCLN(SESSION,ExpNo,ChanNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);

if ~isimaging(grp) | ~isrecording(grp),
  fprintf('%s: not imagnig+recording.\n',mfileanme);
  return;
end

ARGS.DEBUG = 1; ARGS.SAVEGRA = 1; ARGS.HIGHPASS = 1;
Cln = clnmain(Ses,ExpNo,ARGS);

tmpfile = sprintf('y:/DataMatlab/tmp/tmp_%s_%03d_ob%03d_ch%03d_pca_grad%d.mat',...
                  Ses.name,ExpNo,1,ChanNo,1);
load(tmpfile,'PCA');
tmpfile = sprintf('y:/DataMatlab/tmp/tmp_%s_%03d_ob%03d_ch%03d.mat',...
                  Ses.name,ExpNo,1,ChanNo);

load(tmpfile,'ADF');

% temporal limit
T_LIM = 10;  % in sec
if size(Cln.dat,1)*Cln.dx > T_LIM,
  npts = round(T_LIM/ADF.dx);
  ADF.dat = ADF.dat(1:npts);
  npts = round(T_LIM/Cln.dxorg);
  Cln.dat = Cln.dat(1:npts,:);
  Cln.gra = Cln.gra(1:npts);
end

figure('Name',sprintf('%s: %s ExpNo=%d ChanNo=%d',mfilename,Ses.name,ExpNo,ChanNo));
set(gcf,'DefaultAxesfontsize',	10);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf, 'DefaultAxesFontName', 'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

subplot(1,2,1);
t = [0:length(ADF.dat)-1]*ADF.dx;
plot(t,ADF.dat,'color',[0 0.8 0]);  hold on; grid on;
t = [0:length(Cln.gra)-1]*Cln.dxorg;
plot(t,Cln.gra,'color','r');
t = [0:size(Cln.dat,1)-1]*Cln.dxorg;
plot(t,Cln.dat(:,ChanNo),'color','b');
xlabel('Time in seconds');
ylabel('ADC Units');
title('Before/After Denoising');
legend('Recorded Signal','Interference Noise','Denoised Signal');
set(gca,'layer','top');


subplot(2,2,2);
t = [0:length(PCA.mNoise)-1]*PCA.dx*1000;
plot(t,PCA.mNoise,'color','r');  hold on; grid on;
title('mean noise');
set(gca,'xlim',[0 max(t)]);
xlabel('Time in msec');
ylabel('Normalized Unit');
title('Mean Noise');
set(gca,'layer','top');

subplot(2,2,4);
t = [0:size(PCA.pc,1)-1]*PCA.dx*1000;
plot(t,PCA.pc(:,PCA.pcidx));  hold on; grid on;
set(gca,'xlim',[0 max(t)]);
xlabel('Time in msec');
ylabel('Normalized Unit');
title('Noise-Correlated PCs');
set(gca,'layer','top');
tmplegend = {};
for N=1:length(PCA.pcidx),
  tmplegend{end+1} = sprintf('PC%d r=%.2f',PCA.pcidx(N),PCA.pcacoef(N));
end
legend(tmplegend);

return





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subExploreCLN(SESSION,ExpNo,ChanNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);

if ~isimaging(grp) | ~isrecording(grp),
  fprintf('%s: not imagnig+recording.\n',mfileanme);
  return;
end



MriEvtName = sprintf('exp%03d',ExpNo);
MriEvt = load('ClnAdjEvt.mat', MriEvtName);
MriEvt = MriEvt.(MriEvtName);
if ~isfield(MriEvt,'SS_OFFS'),
  fprintf('old format....');
  MriEvt.SS_OFFS = round(MriEvt.mri1orig{1}(1)/MriEvt.dx) - 20;
end
ADFOFFS = MriEvt.SS_OFFS;


adffile = catfilename(Ses,ExpNo,'adfw');


[nchan nobs sampt obslens] = adf_info(adffile);
wv = adf_read(adffile,0,ChanNo-1);
noise = adf_read(adffile,0,length(grp.hardch));
Cln = sigload(Ses,ExpNo,'Cln');


wv = wv(ADFOFFS:end);
noise = noise(ADFOFFS:end);


% temporal limit
T_LIM = 10;  % in sec
if length(wv)*sampt/1000 > T_LIM,
  npts = round(T_LIM/sampt*1000);
  wv = wv(1:npts);
  noise = noise(1:npts);
  npts = round(T_LIM/Cln.dxorg);
  Cln.dat = Cln.dat(1:npts,:);
end

if ~isfield(anap,'clnpar') | ~isfield(anap.clnpar,'DECFRAC'),
  anap.clnpar.DECFRAC = 3;
end
if anap.clnpar.DECFRAC > 1,
  fprintf('decimate(%d)...',anap.clnpar.DECFRAC);
  wv = decimate(wv,anap.clnpar.DECFRAC);
  noise = decimate(noise,anap.clnpar.DECFRAC);
  sampt = sampt * anap.clnpar.DECFRAC;
end


figure('pos',[0 0 580 420],'Name',sprintf('%s ExpNo=%d Chan=%d',Ses.name,ExpNo,ChanNo));
t = [0:length(noise)-1]*sampt/1000;
plot(t,wv,'color',[0 0.8 0]);
hold on; grid on;
plot(t,noise,'r');
t = [0:size(Cln.dat,1)-1]*Cln.dxorg;
plot(t,Cln.dat(:,ChanNo));
%drawstmlines(Cln);
set(gca,'xlim',[0 T_LIM]);


fprintf('done.\n');


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotEPI(SESSION,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);

if ~isimaging(grp) | (~isrecording(grp) & ~ismicrostimulation(grp))
  fprintf('%s: not imagnig+recording.\n',mfileanme);
  return;
end

ROI = load('Roi.mat',grp.grproi);
ROI = ROI.(grp.grproi);

GAMMA = 1.0;
cmap = gray(256).^(1/GAMMA);

anaImg = anaload(Ses,ExpNo);
tcImg = sigload(Ses,ExpNo,'tcImg');
imgdat = squeeze(mean(tcImg.dat,4));
dxy    = tcImg.ds;


figure('Name',sprintf('%s: %s ExpNo=%d',mfilename,Ses.name,ExpNo));
set(gcf,'DefaultAxesfontsize',	10);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf, 'DefaultAxesFontName', 'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');

maxv = max(imgdat(:))*0.9;
minv = min(imgdat(:));
tmpdat = imgdat;
tmpdat = (imgdat - minv) / (maxv - minv);
tmpdat = round(tmpdat * 256);
tmpdat(find(tmpdat(:) > 256)) = 256;
tmpdat(find(tmpdat(:) < 1))   = 1;

x = [0:size(imgdat,1)-1]*dxy(1) + dxy(1)/2;
y = [0:size(imgdat,2)-1]*dxy(2) + dxy(2)/2;
subplot(1,2,1);
for N = 1:size(imgdat,3),
  yoffs = (N-1)*size(imgdat,2)*dxy(2);
  tmpx = x;
  tmpy = y + yoffs;
  tmprgb = ind2rgb(tmpdat(:,:,N)',cmap);
  image(tmpx,tmpy,tmprgb);  hold on;
  text(0.5,1+yoffs,sprintf('slice%d',N),'color','y','fontsize',12);
  % plot electrode positons
  switch lower(Ses.name),
   case {'g02lv1'}
    if N == 1,
      plot(11.5,20.5,'o','markersize',8,'color','y','linewidth',2)
      text(11.5-1,20.5+1.5,'ele-1','color','r','fontsize',8);
      plot(14,20.3,'o','markersize',8,'color','y','linewidth',2)
      text(14-1,20.3+1.5,'ele-2','color','r','fontsize',8);
    end
   case {'d04wi1'}
    if N == 2,
      plot(12.3,24.3,'o','markersize',8,'color','y','linewidth',2)
      text(12.3-1,24.3+1.5,'ele-1','color','r','fontsize',8);
    end
   case {'j00me1'}
    if N == 1,
      plot(16.4,15.4,'o','markersize',8,'color','y','linewidth',2)
      text(16.4-1,15.4+1.5,'ele-1','color','r','fontsize',8);
    elseif N == 2,
      plot(17,39.5,'o','markersize',8,'color','y','linewidth',2)
      text(17-1,39.5+1.5,'ele-2','color','r','fontsize',8);
    end
   otherwise
    if isfield(ROI,'ele'),
      for K = 1:length(ROI.ele),
        tmpele = ROI.ele{K};
        if tmpele.slice ~= N,  continue;  end
        tmpx = tmpele.x*dxy(1) - dxy(1)/2;
        tmpy = tmpele.y*dxy(2) - dxy(2)/2 + yoffs;
        plot(tmpx,tmpy,'o','markersize',8,'color','y');
        text(tmpx-1,tmpy+1.5,sprintf('ele%d',K),'color','r','fontsize',8);
      end
    end
  end
  
end
daspect(gca,[1 1 1]);
set(gca,'ydir','reverse','xlim',[0 max(x)],'ylim',[0 max(y)*size(imgdat,3)]);
set(gca,'YTickLabel',[]);
title('EPI Image');
xlabel('X (mm)');  ylabel('Y (mm)');



% PLOT ANATOMY
imgdat = anaImg.dat;
h = fspecial('gaussian',3,0.5);
for N=1:size(imgdat,3),
  imgdat(:,:,N) = filter2(h,imgdat(:,:,N));
end

dxy    = anaImg.ds;
if strcmpi(Ses.name,'d04wi1'),
  maxv = max(imgdat(:))*0.35;
else
  maxv = max(imgdat(:))*0.8;
end
minv = min(imgdat(:));
tmpdat = imgdat;
tmpdat = (imgdat - minv) / (maxv - minv);
tmpdat = round(tmpdat * 256);
tmpdat(find(tmpdat(:) > 256)) = 256;
tmpdat(find(tmpdat(:) < 1))   = 1;

x = [0:size(imgdat,1)-1]*dxy(1) + dxy(1)/2;
y = [0:size(imgdat,2)-1]*dxy(2) + dxy(2)/2;
subplot(1,2,2);
for N = 1:size(imgdat,3),
  yoffs = (N-1)*size(imgdat,2)*dxy(2);
  tmpx = x;
  tmpy = y + yoffs;
  tmprgb = ind2rgb(tmpdat(:,:,N)',cmap);
  image(tmpx,tmpy,tmprgb);  hold on;
  text(0.5,1+yoffs,sprintf('slice%d',N),'color','y','fontsize',12);
  if isfield(ROI,'ele'),
    for K = 1:length(ROI.ele),
      tmpele = ROI.ele{K};
      if tmpele.slice ~= N,  continue;  end
      tmpx = tmpele.x*dxy(1) - dxy(1)/2;
      tmpy = tmpele.y*dxy(2) - dxy(2)/2 + yoffs;
      %plot(tmpx,tmpy,'y+','markersize',12,'color','r');
      %text(tmpx-3,tmpy-3,sprintf('ele%d',K),'color','r','fontsize',8);
    end
  end
end
daspect(gca,[1 1 1]);
set(gca,'ydir','reverse','xlim',[0 max(x)],'ylim',[0 max(y)*size(imgdat,3)]);
set(gca,'YTickLabel',[]);
title(sprintf('%s Image',upper(grp.ana{1})));
xlabel('X (mm)');  ylabel('Y (mm)');




return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subExploreEPI(SESSION,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);

if ~isimaging(grp) | (~isrecording(grp) & ~ismicrostimulation(grp))
  fprintf('%s: not imagnig+recording.\n',mfileanme);
  return;
end


tcImg = sigload(Ses,ExpNo,'tcImg');
anaImg = anaload(Ses,ExpNo,0);
imgdat = squeeze(mean(tcImg.dat,4));
imgdat = permute(imgdat,[2 1 3]);

figure('pos',[0 0 580 420],'Name',sprintf('%s ExpNo=%d',Ses.name,ExpNo));
subplot(1,2,1);
tmpimg = mgetcollage(imgdat);
imagesc(tmpimg);
subplot(1,2,2);
tmpimg = mgetcollage(permute(anaImg.dat,[2 1 3]));
imagesc(tmpimg);

colormap(gray(256).^(1/1.8));

fprintf(' done.\n');
return
