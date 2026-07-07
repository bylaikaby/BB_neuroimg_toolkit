function sesbru2trial(SESSION,GRPEXP,DOCAT,DO_CROP)
%SESBRU2TRIAL - sorts out 2dseq by trial
%  SESBRU2TRIAL(SESSION,GRPNAME,DOCAT=1,DO_CROP=1) sorts out 2dseq by trial.
%
%  EXAMPLE :
%    >>sesbru2trial('d02Gz1','vis');
%
%  VERSION :
%    0.90 26.03.07 YM  pre-release
%
%  See also sigsort expmkmodel

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 2,  GRPEXP  = [];  end
if nargin < 3,  DOCAT   = [];   end
if nargin < 4,  DO_CROP = 1;  end

if isempty(DOCAT),  DOCAT = 1;  end


Ses = goto(SESSION);
if isempty(GRPEXP),
  EXPS = validexps(Ses);
elseif ischar(GRPEXP)
  grp = getgrp(Ses,GRPEXP);
  EXPS = grp.exps;
elseif isnumeric(GRPEXP),
  EXPS = GRPEXP;
end

if DOCAT > 0,
  % cancatinates all trial within the group
  grpnames = {};
  for iExp = 1:length(EXPS),
    grp = getgrp(Ses,EXPS(iExp));
    grpnames{end+1} = grp.name;
  end
  grpnames = unique(grpnames);
  for iGrp = 1:length(grpnames),
    Sig = [];
    grp = getgrp(Ses,grpnames{iGrp});
    EXPS = grp.exps;
    fprintf('%s %3d/%d: %s(nexp=%d)',mfilename,iGrp,length(grpnames),grp.name,length(EXPS));
    for iExp = 1:length(EXPS),
      fprintf('.');
      ExpNo = EXPS(iExp);
      tmpsig = sub_getsig(Ses,ExpNo,DO_CROP);
      if iExp == 1,
        Sig = tmpsig;
      else
        Sig.dat = cat(5,Sig.dat,tmpsig.dat);
        Sig.sigsort.nrepeats = Sig.sigsort.nrepeats + tmpsig.sigsort.nrepeats;
      end
    end
    Sig.ExpNo = EXPS;
    matfile = sprintf('%s_%s_bru2trial.mat',Ses.name,grp.name);
    fprintf(' saving ''Sig'' to %s...',matfile);
    save(matfile,'Sig');
    clear Sig;
    fprintf(' done.\n');
  end
else
  for iExp = 1:length(EXPS),
    ExpNo = EXPS(iExp);
    grp = getgrp(Ses,ExpNo);
    fprintf('%s %3d/%d: ExpNo=%d(%s)...',mfilename,iExp,length(EXPS),ExpNo,grp.name);
    Sig = sub_getsig(Ses,ExpNo,DO_CROP);
    matfile = sprintf('%s_%03d_bru2trial.mat',Ses.name,ExpNo);
    fprintf(' saving ''Sig'' to %s...',matfile);
    save(matfile,'Sig');
    clear Sig;
    fprintf(' done.\n');
  end
end

return




function Sig = sub_getsig(Ses,ExpNo,DO_CROP)
Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);
anap = getanap(Ses,ExpNo);

imgfile = expfilename(Ses,ExpNo,'2dseq');
imgdat = pvread_2dseq(imgfile);
if DO_CROP > 0 & isfield(grp,'imgcrop') & ~isempty(grp.imgcrop),
  ix = [1:grp.imgcrop(3)] + grp.imgcrop(1) - 1;
  iy = [1:grp.imgcrop(4)] + grp.imgcrop(2) - 1;
  imgdat = imgdat(ix,iy,:,:);
  clear ix iy;
end


Sig.session = Ses.name;
Sig.grpname = grp.name;
Sig.ExpNo   = ExpNo;
Sig.dir.imgfile = imgfile;
Sig.dir.dname   = 'tcImg';
Sig.dx      = par.pvpar.imgtr;
Sig.dat     = imgdat;
Sig.stm     = par.stm;

spar = getsortpars(Ses,ExpNo);
PreT = [];  PostT = [];
if isfield(anap.gettrial,'PreT'),
  PreT = anap.gettrial.PreT;
end
if isfield(anap.gettrial,'PostT'),
  PostT = anap.gettrial.PostT;
end
CheckJawPo = 0;
if isfield(anap.gettrial,'CheckJawPo'),
  CheckJawPo = anap.gettrial.CheckJawPo;
end

Sig = sigsort(Sig,spar.trial,PreT,PostT,CheckJawPo);
mdl = expmkmodel(Ses,ExpNo,'boxcar','HemoDelay',0,'HemoTail',0);

if iscell(Sig),
  for N = 1:length(Sig),
    Sig{N}.dat   = double(Sig{N}.dat);
    Sig{N}.dim   = {'x','y','slice','time','repeat'};
    Sig{N}.model = mdl{N}.dat;
  end
else
  if iscell(mdl),  mdl = mdl{1};  end
  Sig.dat   = double(Sig.dat);
  Sig.dim   = {'x','y','slice','time','repeat'};
  Sig.model = mdl.dat;
end

return
