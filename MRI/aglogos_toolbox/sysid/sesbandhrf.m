function RES = sesbandhrf(Ses,GrpExp,varargin)
%SESBANDHRF - Compute HRF between neural(blp) and BOLD signals.
%  RES = SESBANDHRF(SESSION,GRP/EXP,...) computes HRF between neural(blp) and BOLD signals.
%
%  Supported options are :
%    RoiName    : roi name(s)
%    EleName    : ele name(s), GRP.(grpname).namech
%    ResampleHz : resample rate in Hz
%    AddSdf     : include SDF or not
%    Method     : xcor|xcov|xcov(coef)|cra|impulse
%    PwOrder    : prewhitening order
%    HRFLength  : HRF length in sec
%    Plot       : plot the result or not
%
%  EXAMPLE :
%
%  VERSION :
%    xx.xx.2009 YM  pre-release
%    13.01.2011 YM  supports "HRFLength".
%
%  See also xcov xcor impulse cra mrineu_load

  
RoiName    = 'eleV1';
EleName    = 'hp';
ADD_SDF    = 1;
ResampleHz = 10;
METHOD     = 'xcorr';  % xcor|xcov|xcov(coef)|cra
METHOD     = 'cra';
PW_ORDER   = 5;        % pre-whitening order, 5 as default
HRFLEN_SEC = 20;

%StimGrp    = 'polar2';
StimGrp    = 'none';
DO_PLOT    = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roiname','roi'}
    RoiName = varargin{N+1};
   case {'elename','ele'}
    EleName = varargin{N+1};
   case {'resamplehz','resample'}
    ResampleHz = varargin{N+1};
   case {'sdf','addsdf','add_sdf'}
    ADD_SDF = varargin{N+1};
   case {'method'}
    METHOD = varargin{N+1};
   case {'pw','pworder','order'}
    PW_ORDER = varargin{N+1};
   case {'stimgrp','stimgroup'}
    StimGrp = varargin{N+1};
   case {'hrflen','hrflength','length'}
    HRFLEN_SEC = varargin{N+1};
   case {'plot'}
    DO_PLOT = varargin{N+1};
  end
end

Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
if isnumeric(GrpExp)
  EXPS = GrpExp;
else
  EXPS = grp.exps;
end
if isnumeric(GrpExp) && length(GrpExp) == 1,
  fprintf('%s %s: %s(%s) ExpNo=%d %s-%s(%s): ',datestr(now,'HH:MM:SS'),mfilename,...
          Ses.name,grp.name,EXPS,RoiName,EleName,METHOD);
else
  fprintf('%s %s: %s(%s) nexps=%d %s-%s(%s): ',datestr(now,'HH:MM:SS'),mfilename,...
          Ses.name,grp.name,length(EXPS),RoiName,EleName,METHOD);
end


mrimask = [];
if any(StimGrp) && ~strcmpi(StimGrp,'none'),
  fprintf(' mask(%s).',StimGrp);
  mrimask = mvoxselect(Ses,StimGrp,'all','fhemo+',[],0.01,'verbose',0);
end

fprintf('hrf');
RES = [];
for iExp = 1:length(EXPS),
  fprintf('.');
  ExpNo = EXPS(iExp);
  tmpres = sub_hrf(Ses,ExpNo,RoiName,EleName,METHOD,PW_ORDER,ResampleHz,mrimask,ADD_SDF,HRFLEN_SEC);
  if isempty(tmpres),
    fprintf(' no Roi/Ele, skipping\n');
    return;
  end
  RES = sub_cat(RES,tmpres);
end


RES.dat = nanmean(RES.dat,4);

if DO_PLOT,
  sub_plot(RES);
end
fprintf(' done.\n');
return


function HRF = sub_hrf(Ses,ExpNo,RoiName,EleName,METHOD,PW_ORDER,ResampleHz,mrimask,ADD_SDF,HRFLEN_SEC)
Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

[mrisig blp] = mrineu_load(Ses,ExpNo,'RoiName',RoiName,'EleName',EleName,...
                              'ResampleHz',ResampleHz,'AddSpike',ADD_SDF);

HRF = [];
if isempty(mrisig) || isempty(mrisig.dat),
  return
end
if isempty(blp) || isempty(blp.dat),
  return
end

% MRI data
if ~isempty(mrimask),
  mrisig = mvoxlogical(mrisig,'and',mrimask);
end
mrisig.dat = zscore(mrisig.dat);


if 1,
  mrisig.dat = nanmean(mrisig.dat,2);
else
  tmpres = exptkcca(Ses,ExpNo,'verbose',1,...
                    'RoiName','V1','EleName',EleName,...
                    'ResampleHz',ResampleHz,'AddSdf',ADD_SDF);
  SP_WEIGHT = tmpres.fmri.weights;
  
  mrisig.dat = mrisig.dat';
  mrisig.dat = SP_WEIGHT'*mrisig.dat;
  mrisig.dat = mrisig.dat';
end




%METHOD = 'multi-impulse';

NLAGS = round(HRFLEN_SEC/blp.dx);
for iCh = size(blp.dat,2):-1:1,
  if any(strcmpi(METHOD,'multi-impulse')),
    % this takes forever...
    
    % multiple inputs and single output
    tic
    NEUDAT = zscore(squeeze(blp.dat(:,iCh,:)));
    tmpdata = iddata(mrisig.dat(:),NEUDAT,blp.dx(1));
    tmpmod  = impulse(tmpdata,'pw',PW_ORDER,[0 NLAGS*blp.dx(1)]);
    [ir t ysd] = impulse(tmpmod);
    lags = [0:length(ir)-1];
    toc
    keyboard
  else
    % single input and single output
    for iBand = size(blp.dat,3):-1:1,
      MRIDAT = mrisig.dat;
      NEUDAT = zscore(blp.dat(:,iCh,iBand));

      %
      % Pre-whiten the data based directly on SVD
      % X as (chan,time)
      if 0,
        X = [MRIDAT(:)'; NEUDAT(:)'];  % as (mri/neu, time)
        [UU,S,VV]=svd(X(:,:)',0);
        Q= pinv(S)*VV';
        X(:,:)=Q*X(:,:);
        MRIDAT = X(1,:)';
        NEUDAT = X(2,:)';
      end
    
      switch lower(METHOD),
       case {'xcorr', 'xcor'}
        % use 'xcorr' for testing, xcorr(OUT,IN)
        [ir lags] = xcorr(MRIDAT,NEUDAT,NLAGS,'coef');
        tmpidx = find(lags >= 0);
        lags = lags(tmpidx);
        ir = ir(tmpidx);
        METHOD = 'xcor';
       case {'xcov','xcov(unbiased)'}
        % use 'xcov' for testing,  xcov(OUT,IN)
        [ir lags] = xcov(MRIDAT,NEUDAT,NLAGS,'unbiased');
        tmpidx = find(lags >= 0);
        lags = lags(tmpidx);
        ir = ir(tmpidx);
        METHOD = 'xcov';
       case {'xcov(coef)','xcov(coeff)'}
        % use 'xcov' for testing,  xcov(OUT,IN)
        [ir lags] = xcov(MRIDAT,NEUDAT,NLAGS,'coef');
        tmpidx = find(lags >= 0);
        lags = lags(tmpidx);
        ir = ir(tmpidx);
        METHOD = 'xcov(coef)';
       case {'impulse'}
        tmpdata = iddata(MRIDAT(:),NEUDAT(:),blp.dx(1));
        tmpmod  = impulse(tmpdata,'pw',PW_ORDER,[0 NLAGS*blp.dx(1)]);
        [ir t ysd] = impulse(tmpmod);
        lags = [0:length(ir)-1];

       case {'cra_mod'}
        [ir R CL] = cra_mod([MRIDAT(:) NEUDAT(:)],NLAGS,5,0);
        lags = [0:length(ir)-1];
        METHOD = 'cra_mod';
        
       otherwise
        % higher order looks more 'spk' contribution? 11.08.09, check it later.
        %[ir R CL] = cra([MRIDAT(:) NEUDAT(:)],NLAGS,2,0);
        %[ir R CL] = cra([MRIDAT(:) NEUDAT(:)],NLAGS,4,0);
        %[ir R CL] = cra([MRIDAT(:) NEUDAT(:)],NLAGS,100,0);
        %[ir R CL] = cra([MRIDAT(:) NEUDAT(:)],NLAGS,5,0);  % default
        [ir R CL] = cra([MRIDAT(:) NEUDAT(:)],NLAGS,PW_ORDER,0);
        lags = [0:length(ir)-1];
        METHOD = 'cra';
      end
      DATA(:,iCh,iBand) = ir(:);
    end
  end
end


HRF.session = Ses.name;
HRF.grpname = grp.name;
HRF.exps    = ExpNo;
HRF.dx      = mrisig.dx;
HRF.dat     = DATA;
HRF.lags    = lags;
HRF.elename = blp.elename;
HRF.band    = blp.info.band;
HRF.method  = METHOD;
return



function RES = sub_cat(RES,newres)
if isempty(RES),
  RES = newres;  return;
end

RES.exps = cat(2,RES.exps,newres.exps);
RES.dat  = cat(4,RES.dat,newres.dat);
return


function sub_plot(RES)
figure('Name',sprintf('%s %s %s(%s)',datestr(now,'HH:MM:SS'),mfilename,RES.session,RES.grpname));

for K=1:length(RES.band),
  yticklabel{K}=sprintf('%s [%d-%d]',RES.band{K}{2},RES.band{K}{1}(1),RES.band{K}{1}(2));
end


NCh = size(RES.dat,2);
for iCh = 1:NCh,
  subplot(NCh,1,iCh);
  tmpdat = squeeze(RES.dat(:,iCh,:));
  imagesc(RES.lags*RES.dx,1:size(tmpdat,2),tmpdat');
  if strcmpi(RES.method,'cra'),
    set(gca,'clim',[-0.05 0.05]);
  else
    set(gca,'clim',[-0.1 0.1]);
  end
  set(gca,'ydir','normal')
  set(gca,'ytick',1:length(yticklabel),'yticklabel',yticklabel)
  xlabel('Lags in seconds');
end


return

