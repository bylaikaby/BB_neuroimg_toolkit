function showmodel(SESSION,GrpName,SUBPLOT)
%SHOWMODEL - Display all models defined by ESMODEL, for GrpName and SESSION 
% SHOWMODEL(SESSION, GrpName) displays the models produced by EXPMKMODEL
%
% NKL, 29.09.06a

COL= 'rgbckwmyrgbckwmyrgbckwmyrgbckwmyrgbckwmy';
  
if nargin < 2,
  help showmodel;
  return;
end;

Ses = goto(SESSION);
grp = getgrpbyname(Ses,GrpName);

if nargin < 3,
  SUBPLOT = 0;
end;

if nargin > 2 & SUBPLOT,
  subPlotAllModelsInOnePlot(Ses,GrpName,grp.glmana);
  return;
end;

mfigure([20 100 1200 900]);
suptitle(sprintf('Session: %s, Group: %s', Ses.name, GrpName));

% GLMANA contains only the names of the models!!
% E.G.: GRP.esadapt.glmana{1}.mdlsct = {'MDL_esadapt_ic2mdl.mat[1]',...
subPlotModel(Ses,GrpName,grp.glmana);
return;
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotModel(Ses,GrpName,model)
% EXAMPLE MODELS
% GRPP.corana{1}.mdlsct         = 'hemo';    Model for correlation analysis
% GRPP.glmana{1}.mdlsct         = {'hemo'};  Model for GLM analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(model),
  if ~iscell(model{N}.mdlsct),
    model{N}.mdlsct = {model{N}.mdlsct};
  end;
end;
NP=length(model)*length(model{1}.mdlsct);

P=1;
for M=1:length(model),
  for N=1:length(model{M}.mdlsct),
    mdl = expmkmodel(Ses,GrpName,model{M}.mdlsct{N});
    
    if iscell(mdl),
      % It means we have multiple trials!!!!
      if length(mdl) > 1,
        for J=1:length(mdl),
          if J==1,
            tmp=mdl{1};
          else
            tmp.dat = cat(2,tmp.dat,mdl{J}.dat);
          end;

          if J==length(mdl),
            mdl = tmp;
          end;
        end;
        
      else
        mdl = mdl{1};
      end;
    end;
    
    if P==1,
      tmpmdl = mdl;
    else
      tmpmdl.dat = cat(2,tmpmdl.dat,mdl.dat);
    end;

    specmdl{P} = subSpec(mdl);
    mdl.ModelStr = model{M}.mdlsct{N};
    subplot(NP,2,2*(P-1)+1);
    P=P+1;
    DOPLOT(Ses,GrpName,mdl);
  end;
end;

% SHOW THE DEGREE OF CORRELATION BETWEEN MODELS
subplot(2,2,2);
rval = subXcor(tmpmdl);
rval(find(rval<0.05)) = 0.05;
bar(rval);
set(gca,'ylim',[-1 1]);
set(gca,'ytick',[-1:.1:1]);
xlabel('Model Number');
ylabel('r-value');
title('Correlation of each regressor to all');
grid on;

subplot(2,2,4);
stm=mdl.stm;
ts=getsortpars(Ses,GrpName);
ts = ts.trial;

%%%% FIX THIS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
fr=[0:size(specmdl{1}.dat,1)-1]*specmdl{1}.dx;
COL='rgbkmycrgbkmycrgbkyc';
for N=1:length(specmdl),
  fhd(N)=plot(fr, specmdl{N}.dat,'marker','s','markersize',0.5,'color',COL(N),'linewidth',2);
  [mx,mi] = max(specmdl{N}.dat);
  tmpfr(N)=fr(mi-1);
  hold on;
  lab{N}=sprintf('M%d',N);
end;
tmpfr=min(tmpfr);
idx=find(fr>=tmpfr);
idx=idx(1);
xlabel('Frequency in Hz');
hold on;
%%[ll,hl] = subGetStim(Ses,GrpName);
ll = fr(idx)*0.50;
hl = fr(end)*0.85;

s4 = sprintf('L=%3.4f/H=%3.4f', ll, hl);
s2=sprintf('T(sec): ');
s3=sprintf('%.1f ',ts.dtvol{1}*stm.voldt);
title(sprintf('%s %s [%s]', s2, s3, s4));
line([ll ll],get(gca,'ylim'), 'color','r','linewidth',2);
line([hl hl],get(gca,'ylim'), 'color','r','linewidth',2);
line((1./[stm.voldt stm.voldt])/2,get(gca,'ylim'), 'color','g','linewidth',5);
legend(fhd,lab,'location','east');
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function specmdl = subSpec(Sig)
% It is difficult to identify the frequency components by looking at the original signal. ...
% Converting to the frequency domain, the discrete Fourier transform of the noisy signal y ...
% is found by taking the 512-point fast Fourier transform (FFT): 
% Y = fft(y,512);
%
% The power spectrum, a measurement of the power at various frequencies, is 
% Pyy = Y.* conj(Y) / 512;
%
% Graph the first 257 points (the other 255 points are redundant) on a meaningful frequency axis: 
% f = 1000*(0:256)/512;
% plot(f,Pyy(1:257))
% title('Frequency content of y')
% xlabel('frequency (Hz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
specmdl = Sig;
data = detrend(Sig.dat);
Fs = 1/Sig.dx;
Nyq = Fs/2;
len = size(Sig.dat,1);
len = 256;
fdat = fft(data,len,1);
specmdl.dx = Fs/len;
p = fdat.* conj(fdat) / len;
specmdl.dat = p(floor(1:(len/2)+1));
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DOPLOT(Ses,GrpName,MODEL);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp = getgrpbyname(Ses,GrpName);

if isstruct(MODEL),  MODEL = {MODEL};   end
COL = lines(256); legtxt = {};
ofs = -(length(MODEL)*0.05)/2;
for N = 1:length(MODEL),
  ModelStr = MODEL{N}.ModelStr;
  if isfield(MODEL{N},'t') & ~isemtpy(MODEL{N}.t),
    t = MODEL{N}.t;
  else
    t = [0:length(MODEL{N}.dat)-1]*MODEL{N}.dx;
  end
  plot(t, ofs+MODEL{N}.dat,'color',COL(N,:),'linewidth',2.5);
  hold on;
  legtxt{N} = sprintf('%d',N);
  stm = MODEL{N}.stm;
  ofs = ofs + 0.05;
end
if length(MODEL) == 1,
  legend(strrep(ModelStr,'_','\_'),'location','southwest');
else
  legend(legtxt,'location','southwest');
end
grid on;
%set(gca,'ylim',[-1-ofs 1+ofs]);
set(gca,'xlim',[0 max(t)]);
xlabel('Time in sec');  ylabel('Amplitude');
title(strrep(sprintf('%s DX=%.3fs',ModelStr,MODEL{1}.dx),'_','\_'));

ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
h = [];
for N = 1:length(MODEL),
  if ~isfield(MODEL{N},'stm') | isempty(MODEL{N}.stm), continue;  end
  if length(MODEL{N}.stm.time{1}) == 1,
    MODEL{N}.stm.time{1}(2) = MODEL{N}.stm.time{1}(1) + MODEL{N}.stm.dt{1}(1);
  else
    MODEL{N}.stm.time{1}(end+1) = size(MODEL{N}.dat,1)*MODEL{N}.dx;
  end
  for S = 1:length(stm.v{1}),
    if any(strcmpi(MODEL{N}.stm.stmtypes{stm.v{1}(S)+1},{'blank','none'})),  continue;  end
    ts = MODEL{N}.stm.time{1}(S);
    te = MODEL{N}.stm.time{1}(S+1);
    tmpw = te-ts;
    if tmpw > 0,
      h(end+1) = rectangle('pos',[ts ylm(1) tmpw  tmph],...
                           'facecolor',[0.85 0.85 0.85],'linestyle','none');
    end
    line([ts ts],ylm,'color',[0 0 0]);
    if tmpw > 0,
      line([te te],ylm,'color',[0 0 0]);
    end
  end
end
% how this happens?
ylm = get(gca,'ylim');  tmph = ylm(2)-ylm(1);
for N = 1:length(h),
  pos = get(h(N),'pos');
  pos(4) = tmph;
  set(h(N),'pos',pos);
end
setback(h);
set(gca,'layer','top');
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lowlim,highlim] = subGetStim(Ses,ExpNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      ntrials: 16
%     stmtypes: {'blank'  'microstim'  'blank'}
%        voldt: 2
%            v: {[1x48 double]}
%          val: {[1x48 double]}
%           dt: {[1x48 double]}
%            t: {[1x49 double]}
%         tvol: {[1x49 double]}
%         time: {[1x48 double]}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isnumeric(ExpNo),
  grp = getgrp(Ses,ExpNo);
else
  grp = getgrpbyname(Ses,ExpNo);
  ExpNo = grp.exps(1);
end;

par = expgetpar(Ses,ExpNo);
stm=expgetstm(Ses,ExpNo);

highlim = (1/stm.voldt)/3;
for M=1:length(stm.v),
  dt = stm.dt{M} * stm.voldt;
  vx = find(stm.v{M});
  maxdt = max(dt);
  fr(M) = 1/(2*maxdt);
end;
fr = min(fr);
lowlim = fr/2;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = subXcor(model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:size(model.dat,2),
  for K=1:size(model.dat,2),
    [r(N,K), p] = mcor(model.dat(:,K),model.dat(:,N),0);
  end;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotAllModelsInOnePlot(Ses,GrpName,model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for N=1:length(model),
  if ~iscell(model{N}.mdlsct),
    model{N}.mdlsct = {model{N}.mdlsct};
  end;
end;

P=1;
for M=1:length(model),
  for N=1:length(model{M}.mdlsct),
    mdl = expmkmodel(Ses,GrpName,model{M}.mdlsct{N});

    if iscell(mdl),
      for J=1:length(mdl),
        if J==1,
          tmp=mdl{1};
        else
          tmp.dat = cat(2,tmp.dat,mdl{J}.dat);
        end;
        
        if J==length(mdl),
          mdl = tmp;
        end;
      end;
    end;

    mdl.ModelStr = model{M}.mdlsct{N};
    allmdl{P} = mdl;
    P=P+1;
  end;
end;
DOPLOT(Ses,GrpName,allmdl);

