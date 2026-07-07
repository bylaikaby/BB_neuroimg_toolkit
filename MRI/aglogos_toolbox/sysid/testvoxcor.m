function RES = testvoxcor(Ses,GrpName,varargin)
%TESTVOXCOR - Needs documentation ???

RoiName    = 'eleV1';
METHOD     = 'corr';
StimGrp    = 'polar';
DO_PLOT    = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roiname','roi'}
    RoiName = varargin{N+1};
   case {'method'}
    METHOD = varargin{N+1};
   case {'stimgrp','stimgroup'}
    StimGrp = varargin{N+1};
   case {'plot'}
    DO_PLOT = varargin{N+1};
  end
end
  


Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
EXPS = grp.exps;

fprintf('%s %s: %s(%s) nexps=%d %s(%s): ',datestr(now,'HH:MM:SS'),mfilename,...
        Ses.name,grp.name,length(EXPS),RoiName,METHOD);


mrimask = [];
if any(StimGrp) && ~strcmpi(StimGrp,'none'),
  fprintf(' mask(%s).',StimGrp);
  mrimask = mvoxselect(Ses,StimGrp,'all','fhemo+',[],0.01,'verbose',0);
end

fprintf('corr');
RES = [];
for iExp = 1:length(EXPS),
  fprintf('.');
  ExpNo = EXPS(iExp);
  tmpres = sub_voxcor(Ses,ExpNo,RoiName,METHOD,mrimask);  
  if isempty(tmpres),
    fprintf(' no Roi, skipping\n');
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



function RES = sub_voxcor(Ses,ExpNo,RoiName,METHOD,mrimask)
Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);

% load MRI data
mrisig = mvoxselect(Ses,ExpNo,RoiName,'none',[],1.0,'verbose',0);
if ~isempty(mrimask),
  mrisig = mvoxlogical(mrisig,'and',mrimask);
end


nvox  = size(mrisig.dat,2);
pairs = combnk(1:nvox,2);
xyz   = mrisig.coords;
xyz(:,1) = xyz(:,1) * mrisig.ds(1);
xyz(:,2) = xyz(:,2) * mrisig.ds(2);
xyz(:,3) = xyz(:,3) * mrisig.ds(3);
dist = xyz(pairs(:,1),:) - xyz(pairs(:,2),:);
dist = sqrt(sum(dist.^2,2));


RVAL = zeros(1,size(pairs,1));
PVAL = ones(size(RVAL));
for N=1:size(pairs,1),
  vox1 = pairs(N,1);
  vox2 = pairs(N,2);
  [tmpr tmpp] = corrcoef(mrisig.dat(:,vox1),mrisig.dat(:,vox2));
  RVAL(N) = tmpr(1,2);
  PVAL(N) = tmpp(1,2);
end



RES.session = Ses.name;
RES.grpname = grp.name;
RES.exps    = ExpNo;
RES.dx      = mrisig.dx;
RES.dat     = RVAL;
RES.p       = PVAL;
RES.dist_mm = dist;
RES.roiname = RoiName;


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
  imagesc(RES.lags,1:size(tmpdat,2),tmpdat');
  set(gca,'clim',[-0.1 0.1]);
  set(gca,'ydir','normal')
  set(gca,'ytick',1:length(yticklabel),'yticklabel',yticklabel)
  xlabel('Lag in seconds');
end


return

