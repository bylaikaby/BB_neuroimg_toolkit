function sesplotlfpmuacont(SESSION,EXPS,SIGNAME)
%SESPLOTLFPMUACOH
%
%  VERSION :
%    0.90 xx.03.05 YM  pre-release
%  See also SESLFPMUACONT

if nargin == 0,  help seslfpmuacont; return;   end
if nargin < 3,   SIGNAME = 'lfpmuacoh';  end

Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

% make sure signal name is valid
switch lower(SIGNAME),
 case {'coh'}
  SIGNAME = 'lfpmuacoh';
 case {'cor','corr'}
  SIGNAME = 'lfpmuacor_fft';
 case {'kc'}
  SIGNAME = 'lfpmuakc_fft';
 case {'mi'}
  SIGNAME = 'lfpmuami_fft';
end

fprintf(' %s : loading exps(N=%d) ',mfilename,length(EXPS));

MUALFPb = [];  LFPLFPb = [];  MUAMUAb = [];
MUALFPm = [];  LFPLFPm = [];  MUAMUAm = [];
for N = length(EXPS):-1:1,
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  fprintf('%d.',ExpNo);
  
  % load data
  [fp,fr,fe] = fileparts(catfilename(SESSION,ExpNo,'mat'));
  matfile = sprintf('%s_%s.mat',fr,SIGNAME);
  matfile = fullfile(fp,'Contrasts',matfile);
  
  SIG = load(matfile,SIGNAME);
  SIG = SIG.(SIGNAME);
  
  MUALFPb(:,:,:,N) = SIG.con.mualfp.blank;
  MUALFPm(:,:,:,N) = SIG.con.mualfp.movie;
  LFPLFPb(:,:,:,N) = SIG.con.lfplfp.blank;
  LFPLFPm(:,:,:,N) = SIG.con.lfplfp.movie;  
  MUAMUAb(:,:,:,N) = SIG.con.muamua.blank;
  MUAMUAm(:,:,:,N) = SIG.con.muamua.movie;

  MUALFPb2(:,:,:,N) = SIG.conraw.mualfp.blank;
  MUALFPm2(:,:,:,N) = SIG.conraw.mualfp.movie;
  LFPLFPb2(:,:,:,N) = SIG.conraw.lfplfp.blank;
  LFPLFPm2(:,:,:,N) = SIG.conraw.lfplfp.movie;  
  MUAMUAb2(:,:,:,N) = SIG.conraw.muamua.blank;
  MUAMUAm2(:,:,:,N) = SIG.conraw.muamua.movie;

end
fprintf(' done.\n');


SIG.ExpNo = EXPS;

if length(SIG.ExpNo) == 1,
  figroot = sprintf('%s_%s_%03d',SIG.session,SIG.dir.dname,SIG.ExpNo);
else
  figroot = sprintf('%s_%s_%s',SIG.session,SIG.dir.dname,SIG.grpname);
end

fprintf(' %s : plotting/saving fig data... ',mfilename);

h = subPlot(SIG,LFPLFPb,LFPLFPm,LFPLFPb2,LFPLFPm2,'LFP-LFP');
saveas(h,sprintf('%s_lfplfp.fig',figroot));
fprintf(' %s ',sprintf('%s_lfplfp.fig',figroot));

h = subPlot(SIG,MUAMUAb,MUAMUAm,MUAMUAb2,MUAMUAm2,'MUA-MUA');
saveas(h,sprintf('%s_muamua.fig',figroot));
fprintf(' %s ',sprintf('%s_muamua.fig',figroot));

h = subPlot(SIG,MUALFPb,MUALFPm,MUALFPb2,MUALFPm2,'MUA-LFP');
saveas(h,sprintf('%s_mualfp.fig',figroot));
fprintf(' %s ',sprintf('%s_mualfp.fig',figroot));


fprintf(' done.\n');


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hFig = subPlot(SIG,DATblank,DATmovie,DATblank2,DATmovie2,WHAT_DAT)

idxmovie = find(strcmpi(SIG.stm.stmtypes,'movie'));
if isempty(idxmovie),
  moviefile = 'none';
else
  moviefile = SIG.stm.stmpars.stmobj{idxmovie}.moviefile;
end

switch SIG.con.method,
 case {'cor'}
  CONTNAME = 'Correlation';
  ZLIM = [0 1];
  CLIM = [0 0.7];
  CLIMdiff = [-0.2 0.2];
 case {'coh'}
  CONTNAME = 'Coherence';
  ZLIM = [0 1]
  CLIM = [0 0.7];
  CLIMdiff = [-0.2 0.2];
 case {'kc'}
  CONTNAME = 'KernelCov';
  ZLIM = [];
  CLIM = [];
  CLIMdiff = [];
 case {'mi'}
  CONTNAME = 'MutualInfo';
  ZLIM = [];
  CLIM = [];
  CLIMdiff = [];
 otherwise
end



if length(SIG.ExpNo) == 1,
  figtitle = sprintf('%s Exp=%d(%s) %s %s, movie=%s',...
                     SIG.session,SIG.ExpNo,SIG.grpname,WHAT_DAT,CONTNAME,moviefile);
else
  figtitle = sprintf('%s %s(N=%d) %s %s, movie=%s',...
                     SIG.session,SIG.grpname,length(SIG.ExpNo),WHAT_DAT,CONTNAME,moviefile);
end

if strcmpi(WHAT_DAT,'MUA-LFP'),
  IsSymmetric = 0;
else
  IsSymmetric = 1;
end

hFig = figure;
set(gcf,'Name',figtitle,'PaperType','A4',...
        'PaperOrientation','landscape',...
        'DefaultAxesFontName','Comic Sans MS',...
        'DefaultAxesFontSize',10,...
        'DefaultAxesFontWeight','bold');


[EleCoords,EleDist,EleList] = subGetEleCoords(SIG.session,SIG.ExpNo(1));
for iX = size(DATblank,2):-1:1,
  for iY = size(DATblank,3):-1:1,
    ELE_DIST(iX,iY) = subGetEleDistance(EleCoords,EleDist,EleList,SIG.chan(iX),SIG.chan(iY));
  end
end

for iExp = size(DATblank,4):-1:1,
  [MAPblank(:,:,iExp), Dist] = subGetMap(DATblank(:,:,:,iExp), ELE_DIST, IsSymmetric);
  [MAPmovie(:,:,iExp), Dist] = subGetMap(DATmovie(:,:,:,iExp), ELE_DIST, IsSymmetric);
  [MAPblank2(:,:,iExp), Dist] = subGetMap(DATblank2(:,:,:,iExp), ELE_DIST, IsSymmetric);
  [MAPmovie2(:,:,iExp), Dist] = subGetMap(DATmovie2(:,:,:,iExp), ELE_DIST, IsSymmetric);
end
F = SIG.con.f;
selF = find(F > 0 & F < 500);
F = F(selF);
MAPblank = MAPblank(selF,:,:);
MAPmovie = MAPmovie(selF,:,:);

axes;
text(0.5,1.02,strrep(figtitle,'_','\_'),'units','normalized',...
     'fontweight','bold','fontname','Comic Sans MS',...
     'VerticalAlignment','bottom','HorizontalAlignment','center');
set(gca,'visible','off');


%subplot(2,2,1);
axes('pos',[0.1300    0.5838    0.3347    0.3412]);
tmpdata = squeeze(mean(MAPmovie,3));
surf(Dist,F,tmpdata,'linestyle','none');
shading interp;
hold on;  grid on;
for iF = [1 2 5 10 20 50 100 200],
  [dummy,idx] = min(abs(F - iF));
  idx = idx(1);
  tmpf = ones(1,length(Dist))*F(idx);
  plot3(Dist,tmpf,tmpdata(idx,:)*1.01,'color','k');
end
if ~isempty(CLIM), set(gca,'clim',CLIM);  end
if ~isempty(ZLIM),  set(gca,'zlim',ZLIM);  end
set(gca,'ylim',[0.5 500],'xlim',[0 max(Dist)]);
set(gca,'yscale','log','xdir','reverse','ydir','reverse');
xlabel('Distance in mm');  ylabel('Frequency in Hz');
title(sprintf('%s during movie',CONTNAME));
text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(SIG.ExpNo),size(DATblank,2)),...
     'units','normalized','fontweight','bold');

%subplot(2,2,2);
axes('pos',[0.5703    0.5838    0.3347    0.3412]);
tmpdata = squeeze(mean(MAPblank,3));
surf(Dist,F,tmpdata,'linestyle','none');
shading interp;
hold on;  grid on;
for iF = [1 2 5 10 20 50 100 200],
  [dummy,idx] = min(abs(F - iF));
  tmpf = ones(1,length(Dist))*F(idx);
  plot3(Dist,tmpf,tmpdata(idx,:)*1.01,'color','k');
end
if ~isempty(CLIM),  set(gca,'clim',CLIM);  end
if ~isempty(ZLIM),  set(gca,'zlim',ZLIM);  end
set(gca,'ylim',[0.5 500],'xlim',[0 max(Dist)]);
set(gca,'yscale','log','xdir','reverse','ydir','reverse');
xlabel('Distance in mm');  ylabel('Frequency in Hz');
title(sprintf('%s during blank',CONTNAME));
text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(SIG.ExpNo),size(DATblank,2)),...
     'units','normalized','fontweight','bold');



%subplot(1,2,2);
%axes('pos',[0.5703    0.1100    0.3347    0.8150]);
%subplot(2,2,3);
axes('pos',[0.1300    0.1100    0.3347    0.3412]);
tmpdata = squeeze(mean(MAPmovie-MAPblank,3));
surf(Dist,F,tmpdata,'linestyle','none');
shading interp;
hold on;  grid on;
for iF = [1 2 5 10 20 50 100 200],
  [dummy,idx] = min(abs(F - iF));
  tmpf = ones(1,length(Dist))*F(idx);
  plot3(Dist,tmpf,tmpdata(idx,:)*1.01,'color','k');
end
if ~isempty(CLIMdiff),  set(gca,'clim',CLIMdiff);  end
set(gca,'ylim',[0.5 500],'xlim',[0 max(Dist)]);
set(gca,'yscale','log','xdir','reverse','ydir','reverse');
xlabel('Distance in mm');  ylabel('Frequency in Hz');
title(sprintf('Diff of %s during movie/blank',CONTNAME));
text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(SIG.ExpNo),size(DATblank,2)),...
     'units','normalized','fontweight','bold');


%subplot(2,2,4);
axes('pos',[0.5703    0.1100    0.3347    0.3412]);
for iExp = 1:size(MAPblank2,3),
  plot(Dist,squeeze(MAPblank2(1,:,iExp)),'color','b','linestyle','none','marker','.');
  hold on; grid on;  
  plot(Dist,squeeze(MAPmovie2(1,:,iExp)),'color','r','linestyle','none','marker','.');
end
plot(Dist,mean(MAPblank2,3),'color','b','linewidth',2);  hold on; grid on;
plot(Dist,mean(MAPmovie2,3),'color','r','linewidth',2);
legend('blank','movie');
set(gca,'xlim',[0 max(Dist)]);
xlabel('Distance in mm'); ylabel(CONTNAME);
text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(SIG.ExpNo),size(DATblank,2)),...
     'units','normalized','fontweight','bold');
title(sprintf('%s by Raw signals',CONTNAME));


switch SIG.con.method,
 case {'cor','coh'}
  if length(strfind(lower(WHAT_DAT),'lfp')) == 2 || length(strfind(lower(WHAT_DAT),'mua')) == 2,
    % force to intercept (0,1)
    fh1 = @(x,xdata)exp(-xdata/x(1));
    X0 = [1.0 1.0];
  else
  fh1 = @(x,xdata)x(2)*exp(-xdata/x(1));
  X0 = [1.0 1.0];
  end
 otherwise
  fh1 = @(x,xdata)x(2)*exp(-xdata/x(1));
  X0 = [1.0 1.0];
end
%fh1 = @(x,xdata)(xdata/x(1)+1).^-1;  % so far the best
%fh1 = @(x,xdata)(xdata/x(1)+1).^x(2);
%X0  = [1.0 0.0];

tmpsel = [1:length(Dist)];
%Dist(1) = 0.01;

% fitting
FITblank1 = [];  FITmovie1 = [];  ERRblank1 = [];  ERRmovie1 = [];
FITblank2 = [];  FITmovie2 = [];  ERRblank2 = [];  ERRmovie2 = [];
for iExp = size(DATblank2,4):-1:1,
  [FITblank1(:,:,iExp),ERRblank1(:,iExp)] = subFitMap(MAPblank2(:,tmpsel,iExp),Dist(tmpsel),fh1,X0);
  [FITmovie1(:,:,iExp),ERRmovie1(:,iExp)] = subFitMap(MAPmovie2(:,tmpsel,iExp),Dist(tmpsel),fh1,X0);
end
mb = squeeze(mean(FITblank1(:,:,:),3));
sb = squeeze(std(FITblank1(:,:,:),1,3));
mm = squeeze(mean(FITmovie1(:,:,:),3));
sm = squeeze(std(FITmovie1(:,:,:),1,3));
text(0.95,0.85,sprintf('blank:%.2f+-%.2f  movie:%.2f+-%.2f',mb(1),sb(1),mm(1),sm(1)),...
     'units','normalized','horizontalalignment','right','fontweight','bold');
switch SIG.con.method,
 case {'cor','coh'}
  text(0.95,0.80,sprintf('blank:%.2f+-%.2f  movie:%.2f+-%.2f',mb(2),sb(2),mm(2),sm(2)),...
       'units','normalized','horizontalalignment','right','fontweight','bold');
 otherwise
  text(0.95,0.80,sprintf('blank:%.2e+-%.2e  movie:%.2e+-%.2e',mb(2),sb(2),mm(2),sm(2)),...
       'units','normalized','horizontalalignment','right','fontweight','bold');
end

plot(Dist,fh1(mb,Dist),'linestyle','--','color','b');
plot(Dist,fh1(mm,Dist),'linestyle','--','color','r');




return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get electrode coordinates
function [coords eledist elelist] = subGetEleCoords(Session,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = getses(Session);
grp = getgrp(Ses,ExpNo);
coords = [];
if isfield(grp,'confunc'),
  eleconfig = grp.confunc.eleconfig;
  eledist   = grp.confunc.eledist;
else
  eleconfig = Ses.anap.confunc.eleconfig;
  eledist   = Ses.anap.confunc.eledist;
end
uele = sort(unique(eleconfig));

for N = length(uele):-1:1,
  [y, x] = find(eleconfig == uele(N));
  coords(N,:) = [x y 1];
  elelist(N) = uele(N);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to get electrode distance
function Dist = subGetEleDistance(coords,eledist,elelist,xChan,yChan)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xChan = find(elelist == xChan);
yChan = find(elelist == yChan);
Dist = (coords(xChan,:) - coords(yChan,:)) * eledist;
Dist = sqrt(sum(Dist.*Dist));

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [MAP,uniqDist] = subGetMap(DAT,ELE_DIST,IsSymmetric)

if IsSymmetric,
  for iX = 1:size(DAT,2),
    for iY = iX+1:size(DAT,3),
      ELE_DIST(iX,iY) = NaN;
    end
  end
end
  
uniqDist = sort(unique(ELE_DIST(:)));
uniqDist = uniqDist(find(~isnan(uniqDist)));

MAP = zeros(size(DAT,1),length(uniqDist));

DAT = reshape(DAT,[size(DAT,1), size(DAT,2)*size(DAT,3)]);
ELE_DIST = reshape(ELE_DIST, [1 size(ELE_DIST,1)*size(ELE_DIST,2)]);

for iDist = 1:length(uniqDist),
  idx = find(ELE_DIST == uniqDist(iDist));
  if isempty(idx), continue;  end
  MAP(:,iDist) = mean(DAT(:,idx),2);
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X Err] = subFitMap(MAP,Dist,fh,X0)

if nargin < 4,  X0 = [];  end
if isempty(X0), X0 = [1.0 0];  end

TOLFUN		= 1.0000e-006;
options = optimset('TolFun',TOLFUN,'Display','off');

for iF = size(MAP,1):-1:1,
  [x,resnorm,residual] = lsqcurvefit(fh,X0,Dist,MAP(iF,:)',[],[],options);
  X(iF,:) = x(:)';
  Err(iF) = resnorm / sum(MAP(iF,:).*MAP(iF,:));
end

return;
