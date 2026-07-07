function mncatexps(Ses,GrpName,varargin)
%MNCATEXPS - Concatinate manganese images as a single tcImg.
%  MNCATEXPS(Ses,GrpName,...) concatinates manganese images as a single tcImg.
%  Control options should be in ANAP/GRP.xxx.anap.
%    GRP.mntc.anap.mncatexps.session  = 'ratbE2';    % source session
%    GRP.mntc.anap.mncatexps.exps     = 'mdeftinj';  % source group
%    GRP.mntc.anap.mncatexps.datclass = 'double';    % data class
%    GRP.mntc.anap.mncatexps.use_realigned = 1;
%    GRP.mntc.anap.mncatexps.imgtr   = 1;            % arbitrary value
%    GRP.mntc.anap.mncatexps.permute = [];
%    GRP.mntc.anap.mncatexps.flipdim = [];
%
%    When mn-images are coronal then the followings make horizontal images.
%    GRP.mntc.anap.mncatexps.permute = [1 3 2];
%    GRP.mntc.anap.mncatexps.flipdim = [3];
%
%
%  NOTE :
%    This function will work only when tcImg data are small enough for memory.
%
%  EXAMPLE :
%    mncatexps('ratbE3','mntc')
%
%  VERSION :
%    0.90 27.12.11 YM  pre-release
%
%  See also mnimg2tcimg


if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,GrpName);

if isfield(anap.mncatexps,'session'),
  SrcSes = anap.mncatexps.session;
else
  SrcSes = Ses.name;
end
SrcGrp = anap.mncatexps.exps;
USE_REALIGNED = anap.mncatexps.use_realigned;


goto(SrcSes);
tcImg = mnimg2tcimg(SrcSes,SrcGrp,'use_realigned',USE_REALIGNED);
tcImg.session = Ses.name;
tcImg.grpname = grp.name;
tcImg.ExpNo   = grp.exps;
par   = expgetpar(SrcSes,SrcGrp);
par.evt = {};
par.pvpar.nt = size(tcImg.dat,4);
par.stm.labels = {};
par.stm.ntrials = [];    % num. trials in obsps
par.stm.stmtypes = {};
par.stm.voldt = 0;
par.stm.v = {};
par.stm.val = {};
par.stm.dt = {};
par.stm.t = {};
par.stm.tvol = {};
par.stm.time = {};
par.stm.date = '';
par.stm.stmpars = {};
par.stm.pdmpars = {};
par.stm.hstpars = {};



goto(Ses);
if isfield(anap.mncatexps,'imgtr'),
  tcImg.dx = anap.mncatexps.imgtr;
  par.pvpar.imgtr = tcImg.dx;
  par.stm.voldt   = tcImg.dx;
end
if isfield(anap.mncatexps,'datclass') && any(anap.mncatexps.datclass)
  fprintf(' tcImg.dat(%s-->%s)...',class(tcImg.dat),anap.mncatexps.datclass);
  switch lower(anap.mncatexps.datclass)
   case {'double'}
    tcImg.dat = double(tcImg.dat);
   case {'single'}
    tcImg.dat = single(tcImg.dat);
  end
end

V_PERMUTE = [];
if isfield(anap.mncatexps,'permute') && any(anap.mncatexps.permute),
  V_PERMUTE = anap.mncatexps.permute;
  fprintf('permute[%s]...',deblank(sprintf('%d ',V_PERMUTE)));
  tcImg.dat = permute(tcImg.dat,[V_PERMUTE 4]);
  tcImg.ds  = tcImg.ds(V_PERMUTE);
end
V_FLIPDIM = [];
if isfield(anap.mncatexps,'flipdim') && any(anap.mncatexps.flipdim),
  V_FLIPDIM = anap.mncatexps.flipdim;
  fprintf('flipdim[%s]...',deblank(sprintf('%d ',V_FLIPDIM)));
  for N = 1:length(anap.mncatexps.flipdim),
    tcImg.dat = flipdim(tcImg.dat,V_FLIPDIM(N));
  end
end

matfile = catfilename(Ses,grp.exps(1),'tcImg');
fprintf(' saving ''tcImg'' to ''%s''...',matfile);
[fp fr fe] = fileparts(matfile);
if ~exist(fp,'dir'), mkdir(fp);  end
% it is better to update, since this may be used when saving data.
tcImg.dir.tcimgfile = matfile;
save(matfile,'tcImg');
fprintf(' done.\n');


vname = sprintf('exp%04d',grp.exps(1));
fprintf(' saving ''%s'' to ''SesPar.mat''...',vname);
eval(sprintf('%s = par;',vname));
if exist('SesPar.mat','file'),
  save('SesPar.mat',vname,'-append');
else
  save('SesPar.mat',vname);
end
fprintf(' done.\n');


if ~strcmpi(Ses.name,SrcSes),
  fprintf(' exporting roi...');
  sub_export_roi(Ses,GrpName,SrcSes,SrcGrp,V_PERMUTE,V_FLIPDIM);
  fprintf(' done.\n');
  fprintf(' exporting anatomy...');
  sub_export_ana(Ses,GrpName,SrcSes,SrcGrp,V_PERMUTE,V_FLIPDIM);
end


return


function sub_export_ana(Ses,GrpName,SrcSes,SrcGrp,V_PERMUTE,V_FLIPDIM)

ANA = anaload(SrcSes,SrcGrp);
if any(V_PERMUTE),
  ANA.dat = permute(ANA.dat,V_PERMUTE);
  ANA.ds  = ANA.ds(V_PERMUTE);
end
if any(V_FLIPDIM),
  for N = 1:length(V_FLIPDIM),
    ANA.dat = flipdim(ANA.dat,V_FLIPDIM(N));
  end
end

Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
vname = grp.ana{1};
vidx  = grp.ana{2};
matfile = fullfile(pwd,sprintf('%s.mat',vname));

ANA.session = Ses.name;
if exist(matfile,'file'),
  load(matfile);
end

eval(sprintf('%s{%d} = ANA;',vname,vidx));
save(matfile,vname);

fprintf('\n\n');
fprintf(' Edit/Update "%s.m"\n',Ses.name);
fprintf('   GRP.%s.ana = { %s; %d; [1:%d] };\n',grp.name,vname,vidx,size(ANA.dat,3));
fprintf('\n');

return


function sub_export_roi(Ses,GrpName,SrcSes,SrcGrp,V_PERMUTE,V_FLIPDIM)

goto(SrcSes);
srcgrp = getgrp(SrcSes,SrcGrp);
matfile = fullfile(pwd,'Roi.mat');
if ~exist(matfile,'file'),  return;  end

ROI_DATA = load(matfile);
fnames = fieldnames(ROI_DATA);
ROISET_NAMES = {};
for N = 1:length(fnames),
  tmpname = fnames{N};
  tmproi  = ROI_DATA.(tmpname);
  if ~isfield(tmproi,'roi'), continue;  end
  fprintf('%s.',tmpname);
  if any(V_PERMUTE) || any(V_FLIPDIM),
    tmproi  = sub_update_roi(Ses,GrpName,tmproi,V_PERMUTE,V_FLIPDIM);
  end
  eval(sprintf('%s = tmproi;',tmpname));
  ROISET_NAMES{end+1} = tmpname;
end


if isempty(ROISET_NAMES),  return;  end
Ses = goto(Ses);
matfile = fullfile(pwd,'Roi.mat');
if exist(matfile,'file'),
  copyfile(matfile,fullfile(pwd,'Roi.mat.bak'),'f');
  save(matfile,ROISET_NAMES{:},'-append');
else
  save(matfile,ROISET_NAMES{:});
end

return


function ROI = sub_update_roi(Ses,GrpName,ROI,V_PERMUTE,V_FLIPDIM)
if isempty(V_PERMUTE) && isempty(V_FLIPDIM),
  return;
end

Ses = goto(Ses);
grp = getgrp(Ses,GrpName);

ROI_NAMES = {};
for N = 1:length(ROI.roi),
  ROI_NAMES{N} = ROI.roi{N}.name;
end
U_NAMES = unique(ROI_NAMES);
ROIDAT  = zeros(size(ROI.img),'int8');
ROIDAT  = logical(ROIDAT);
NEW_ROI = {};
for N = 1:length(U_NAMES),
  roiidx = strcmp(ROI_NAMES,U_NAMES{N});
  roiroi = ROI.roi(roiidx);
  
  ROIDAT(:) = 0;
  ROIDAT = reshape(ROIDAT,size(ROI.img));
  for K = 1:length(roiroi),
    ROIDAT(:,:, roiroi{K}.slice) = roiroi{K}.mask;
  end

  if any(V_PERMUTE),
    ROIDAT = permute(ROIDAT,V_PERMUTE);
  end
  if any(V_FLIPDIM),
    for K = 1:length(V_FLIPDIM),
      ROIDAT = flipdim(ROIDAT,V_FLIPDIM(K));
    end
  end
  tmproi = [];
  for K = 1:size(ROIDAT,3),
    tmpimg = ROIDAT(:,:,K);
    if any(tmpimg(:)),
      tmproi.name  = U_NAMES{N};
      tmproi.slice = K;
      tmproi.px    = [];
      tmproi.py    = [];
      tmproi.mask  = logical(tmpimg);
      NEW_ROI{end+1} = tmproi;
    end
  end
end
ROI.roi = NEW_ROI;


ROI.session = Ses.name;
ROI.grpname = grp.name;
ROI.exps    = grp.exps;
if any(V_PERMUTE),
  ROI.ana = permute(ROI.ana,V_PERMUTE);
  ROI.img = permute(ROI.img,V_PERMUTE);
  ROI.ds(1:3) = ROI.ds(V_PERMUTE);
end
if any(V_FLIPDIM),
  for N = 1:length(V_FLIPDIM),
    ROI.ana = flipdim(ROI.ana,V_FLIPDIM(N));
    ROI.img = flipdim(ROI.img,V_FLIPDIM(N));
  end
end
