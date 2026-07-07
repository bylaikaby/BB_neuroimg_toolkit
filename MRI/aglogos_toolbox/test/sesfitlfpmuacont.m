function sesfitfpmuacont(SESSION,EXPS,SIGNAME)
%SESFITLFPMUACONT
%
%  VERSION :
%    0.90 xx.03.05 YM  pre-release
%  See also

if nargin == 0,  help seslfpmuacont; return;   end
if nargin < 3,   SIGNAME = 'lfpmuacor_fft';  end

% make sure correct signal name
switch SIGNAME,
 case {'coh'}
  METHOD  = 'Coherence';
  SIGNAME = 'lfpmuacoh';
 case {'cor','corr'}
  METHOD  = 'Correlation';
  SIGNAME = 'lfpmuacor_fft';
 case {'kc'}
  METHOD  = 'KernelCov.';
  SIGNAME = 'lfpmuakc_fft';
 case {'mi'}
  METHOD  = 'MutualInfo.';
  SIGNAME = 'lfpmuami_fft';
end


Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end


fprintf('%s %s : loading exps(N=%d) ',gettimestring,mfilename,length(EXPS));

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

end
fprintf(' done.\n');


SIG.ExpNo = EXPS;

if length(SIG.ExpNo) == 1,
  figroot = sprintf('%s_%s_%03d',SIG.session,SIGNAME,SIG.ExpNo);
else
  figroot = sprintf('%s_%s_%s',SIG.session,SIGNAME,SIG.grpname);
end

fprintf('%s %s : processing data[lfplfp]... ',gettimestring,mfilename);
[h,Sig] = subPlot(SIG,LFPLFPb,LFPLFPm,'LFP-LFP',METHOD);
saveas(h,sprintf('%s_lfplfp_fit.fig',figroot));
fprintf(' %s ',sprintf('%s_lfplfp_fit.fig',figroot));
SIG.map.f       = Sig.f;
SIG.map.d       = Sig.d;
SIG.map.lfplfp  = Sig.map;
SIG.fit.f       = Sig.f;
SIG.fit.d       = Sig.d;
SIG.fit.func    = Sig.fitfunc;
SIG.fit.lfplfp  = Sig.fit;
SIG.fit2.f      = Sig.f;
SIG.fit2.d      = Sig.d;
SIG.fit2.func   = Sig.fitfunc2;
SIG.fit2.lfplfp = Sig.fit2;
fprintf(' done.\n');


fprintf('%s %s : processing data[muamua]... ',gettimestring,mfilename);
[h,Sig] = subPlot(SIG,MUAMUAb,MUAMUAm,'MUA-MUA',METHOD);
saveas(h,sprintf('%s_muamua_fit.fig',figroot));
fprintf(' %s ',sprintf('%s_muamua_fit.fig',figroot));
SIG.map.muamua  = Sig.map;
SIG.fit.muamua  = Sig.fit;
SIG.fit2.muamua = Sig.fit2;
fprintf(' done.\n');


fprintf('%s %s : processing data[mualfp]... ',gettimestring,mfilename);
[h,Sig] = subPlot(SIG,MUALFPb,MUALFPm,'MUA-LFP',METHOD);
saveas(h,sprintf('%s_mualfp_fit.fig',figroot));
fprintf(' %s ',sprintf('%s_mualfp_fit.fig',figroot));
SIG.map.mualfp  = Sig.map;
SIG.fit.mualfp  = Sig.fit;
SIG.fit2.mualfp = Sig.fit2;
fprintf(' done.\n');


SIG = rmfield(SIG,{'dx','dat','con'});

matfile = sprintf('%s.mat',figroot);
fprintf('%s %s : saving ''%s'' to ''%s''...',gettimestring,mfilename,SIG.dir.dname,matfile);
eval(sprintf('%s = SIG;',SIG.dir.dname));
save(matfile,SIG.dir.dname);
fprintf(' done.\n');



return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [hFig,oSig] = subPlot(SIG,DATblank,DATmovie,WHAT_DAT,METHOD)

idxmovie = find(strcmpi(SIG.stm.stmtypes,'movie'));
if isempty(idxmovie),
  moviefile = 'none';
else
  moviefile = SIG.stm.stmpars.stmobj{idxmovie}.moviefile;
end


if length(SIG.ExpNo) == 1,
  figtitle = sprintf('%s Exp=%d(%s) %s %s/Fitting, movie=%s',...
                     SIG.session,SIG.ExpNo,SIG.grpname,WHAT_DAT,METHOD,moviefile);
else
  figtitle = sprintf('%s %s(N=%d) %s %s/Fitting, movie=%s',...
                     SIG.session,SIG.grpname,length(SIG.ExpNo),WHAT_DAT,METHOD,moviefile);
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
end


F = SIG.con.f;
selF = find(F > 0 & F < 500);
F = F(selF);
MAPblank = MAPblank(selF,:,:);
MAPmovie = MAPmovie(selF,:,:);


% now average MAP(f,:,:), where f > 100,
forig = F;
[MAPblank, F] = subAverageMAP(forig,MAPblank);
[MAPmovie, F] = subAverageMAP(forig,MAPmovie);





% y = (1-B)exp(-x/A) + B
fh1 = @(x,xdata)(1-x(2))*exp(-xdata/x(1)) + x(2);
% y = exp(-x/A) + B
fh2 = @(x,xdata)exp(-xdata/x(1));


% fitting
FITblank1 = [];  FITmovie1 = [];  ERRblank1 = [];  ERRmovie1 = [];
FITblank2 = [];  FITmovie2 = [];  ERRblank2 = [];  ERRmovie2 = [];
for iExp = size(DATblank,4):-1:1,
  [FITblank1(:,:,iExp),ERRblank1(:,iExp)] = subFitMap(MAPblank(:,:,iExp),Dist,fh1);
  [FITmovie1(:,:,iExp),ERRmovie1(:,iExp)] = subFitMap(MAPmovie(:,:,iExp),Dist,fh1);
  [FITblank2(:,:,iExp),ERRblank2(:,iExp)] = subFitMap(MAPblank(:,:,iExp),Dist,fh2);
  [FITmovie2(:,:,iExp),ERRmovie2(:,iExp)] = subFitMap(MAPmovie(:,:,iExp),Dist,fh2);
end
%FITblank1 = FITblank1(selF,:,:);
%FITmovie1 = FITmovie1(selF,:,:);
%FITblank2 = FITblank2(selF,:,:);
%FITmovie2 = FITmovie2(selF,:,:);


oSig.f     = F;
oSig.d     = Dist;
oSig.map.blank = MAPblank;
oSig.map.movie = MAPmovie;

oSig.fitfunc  = fh1;
oSig.fit.blank = FITblank1;
oSig.fit.movie = FITmovie1;
oSig.fit.err_blank   = ERRblank1;
oSig.fit.err_movie   = ERRmovie1;

oSig.fitfunc2  = fh2;
oSig.fit2.blank = FITblank1;
oSig.fit2.movie = FITmovie2;
oSig.fit2.err_blank   = ERRblank2;
oSig.fit2.err_movie   = ERRmovie2;



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
set(gca,'clim',[0 0.7]);
set(gca,'ylim',[0.5 500],'xlim',[0 max(Dist)],'zlim',[0 1]);
set(gca,'yscale','log','xdir','reverse','ydir','reverse');
xlabel('Distance in mm');  ylabel('Frequency in Hz');
title(sprintf('%s during movie',METHOD));
text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(SIG.ExpNo),size(DATblank,2)),...
     'units','normalized','fontweight','bold');

%subplot(2,2,3);
axes('pos',[0.1300    0.1100    0.3347    0.3412]);
tmpdata = squeeze(mean(MAPblank,3));
surf(Dist,F,tmpdata,'linestyle','none');
shading interp;
hold on;  grid on;
for iF = [1 2 5 10 20 50 100 200],
  [dummy,idx] = min(abs(F - iF));
  tmpf = ones(1,length(Dist))*F(idx);
  plot3(Dist,tmpf,tmpdata(idx,:)*1.01,'color','k');
end
set(gca,'clim',[0 0.7]);
set(gca,'ylim',[0.5 500],'xlim',[0 max(Dist)],'zlim',[0 1]);
set(gca,'yscale','log','xdir','reverse','ydir','reverse');
xlabel('Distance in mm');  ylabel('Frequency in Hz');
title(sprintf('%s during blank',METHOD));
text(0.02,0.02,sprintf('nexps=%d nchans=%d',length(SIG.ExpNo),size(DATblank,2)),...
     'units','normalized','fontweight','bold');


%subplot(2,2,2);
axes('pos',[0.5703    0.5838    0.3347    0.3412]);
tmpdata = squeeze(mean(FITblank1,3));
plot(F,tmpdata(:,1),'b','linewidth',2);
hold on;  grid on;
tmpdata = squeeze(mean(FITmovie1,3));
plot(F,tmpdata(:,1),'r','linewidth',2);
tmpdata = squeeze(mean(FITblank2,3));
plot(F,tmpdata(:,1),'b','linestyle','--','linewidth',2);
tmpdata = squeeze(mean(FITmovie2,3));
plot(F,tmpdata(:,1),'r','linestyle','--','linewidth',2);

set(gca,'xlim',[0.5 500],'xscale','log','ylim',[0 5]);
xlabel('Frequency in Hz');  ylabel('Space Constant in mm');
title('Curve fitting, Space constant A');
text(0.02,0.02,sprintf('nexps=%d',length(SIG.ExpNo)),...
     'units','normalized','fontweight','bold');
legend('blank: (1-B)*exp(-x/A)+B',...
       'movie: (1-B)*exp(-x/A)+B',...
       'blank: exp(-x/A)',...
       'movie: exp(-x/A)');


%subplot(4,2,6);
axes('pos',[0.5703    0.3301    0.3347    0.1567]);
tmpdata = squeeze(mean(FITblank1,3));
plot(F,tmpdata(:,2),'b','linewidth',2);
hold on;  grid on;
tmpdata = squeeze(mean(FITmovie1,3));
plot(F,tmpdata(:,2),'r','linewidth',2);
tmpdata = squeeze(mean(FITblank2,3));
plot(F,tmpdata(:,2),'b','linestyle','--','linewidth',2);
tmpdata = squeeze(mean(FITmovie2,3));
plot(F,tmpdata(:,2),'r','linestyle','--','linewidth',2);

set(gca,'xlim',[0.5 500],'xscale','log','ylim',[0 0.5]);
xlabel('Frequency in Hz');  ylabel('Constant Value');
title('Curve fitting, Constant value');
text(0.02,0.02,sprintf('nexps=%d',length(SIG.ExpNo)),...
     'units','normalized','fontweight','bold');
legend('blank: (1-B)*exp(-x/A)+B',...
       'movie: (1-B)*exp(-x/A)+B',...
       'blank: exp(-x/A)',...
       'movie: exp(-x/A)');


%subplot(4,2,8);
axes('pos',[0.5703    0.1110    0.3347    0.1567]);
tmpdata = squeeze(mean(ERRblank1,2));
plot(F,tmpdata(:,1),'b','linewidth',2);
hold on;  grid on;
tmpdata = squeeze(mean(ERRmovie1,2));
plot(F,tmpdata(:,1),'r','linewidth',2);
tmpdata = squeeze(mean(ERRblank2,2));
plot(F,tmpdata(:,1),'b','linestyle','--','linewidth',2);
tmpdata = squeeze(mean(ERRmovie2,2));
plot(F,tmpdata(:,1),'r','linestyle','--','linewidth',2);

set(gca,'xlim',[0.5 500],'xscale','log','ylim',[0 0.1]);
xlabel('Frequency in Hz');  ylabel('Fitting Error, sum((y''-y)^2)/sum(y^2)');
title('Curve fitting Error');
text(0.02,0.02,sprintf('nexps=%d',length(SIG.ExpNo)),...
     'units','normalized','fontweight','bold');
legend('blank: (1-B)*exp(-x/A)+B',...
       'movie: (1-B)*exp(-x/A)+B',...
       'blank: exp(-x/A)',...
       'movie: exp(-x/A)');



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
  %MAP(:,iDist) = mean(DAT(:,idx),2);
  %MAP(:,iDist) = max(DAT(:,idx),[],2);
  MAP(:,iDist) = median(DAT(:,idx),2);
end


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X Err] = subFitMap(MAP,Dist,fh)

TOLFUN		= 1.0000e-006;
options = optimset('TolFun',TOLFUN,'Display','off');

for iF = size(MAP,1):-1:1,
  [x,resnorm,residual] = lsqcurvefit(fh,[1.0 0],Dist,MAP(iF,:)',[],[],options);
  X(iF,:) = x(:)';
  Err(iF) = resnorm / sum(MAP(iF,:).*MAP(iF,:));
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [MAPnew,Fnew] = subAverageMAP(F,MAP)
% MAP as (f,dist,exp)
% average MAP where f0+i*Fres <= f < f0 + (i+1)*Fres

Fnew = F;
MAPnew = MAP;


Fres = [ 1   5];
fs   = [10 100];

n = max(find(F < fs(1)));

% for fs(1), Fres(1),  above 10Hz, average as 1Hz resolution
tmpf = fs(1);
while tmpf < fs(2),
  idx = find(F >= tmpf & F < tmpf + Fres(1));
  tmpf = tmpf + Fres(1);
  if isempty(idx), continue;  end
  n = n + 1;
  Fnew(n) = mean(F(idx));
  MAPnew(n,:,:) = mean(MAP(idx,:,:),1);
end

% for fs(2), Fres(2), above 100Hz, average as 5Hz resolution
tmpf = fs(2);
while tmpf < max(F),
  idx = find(F >= tmpf & F < tmpf + Fres(2));
  tmpf = tmpf + Fres(2);
  if isempty(idx), continue;  end
  n = n + 1;
  Fnew(n) = mean(F(idx));
  MAPnew(n,:,:) = mean(MAP(idx,:,:),1);
end

% discard unused part
Fnew = Fnew(1:n);
MAPnew = MAPnew(1:n,:,:);
  
  
  
return;
