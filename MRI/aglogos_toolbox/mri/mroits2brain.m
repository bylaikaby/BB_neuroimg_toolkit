function SIG = mroits2brain(SIG,varargin)
%MROITS2BRAIN - Convert the MRI data into the 'reference' space.
%  SIG = MROITS2BRAIN(SIG,...) converts the MRI signal into the 'reference' space.
%
%  EXAMPLE :
%    >> mana2brain('rat7e1','spont')
%    >> rproiTs = sigload('rat7e1','spont','rproiTs');
%    >> sig = mroits2brain(rproiTs);
%    >> mview(sig)
%    >> roi = mana2brain_roi('rat7e1','spont');
%
%  VERSION :
%    0.90 07.10.11 YM  pre-release
%    0.91 13.10.11 YM  supports 'permute' and 'flipdim'.
%    0.92 03.11.11 YM  supports .dat as more than 2D.
%    0.93 16.11.11 YM  bug fix for rat (template's .ds is x10).
%    0.94 04.01.12 YM  supports anap.mroits2brain.
%    0.95 01.02.12 YM  supports .stat.beta
%    0.96 17.04.13 YM  supports when .dat is empty (converting only stat).
%    0.97 12.10.19 YM  clean up, supports .stat.F.
%
%  See also mana2brain mana2brain_roi mbrain_defs

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end


DO_PERMUTE = [];
DO_FLIPDIM = [];
VERBOSE    = 1;

[tmpv, tmpinf] = issig(SIG);
Ses = goto(tmpinf.session);
grp = getgrp(Ses,tmpinf.grpname);
anap = getanap(Ses,tmpinf.grpname);
clear tmpv tmpinf
if isfield(anap,'mroits2brain')
  if isfield(anap.mroits2brain,'permute')
    DO_PERMUTE = anap.mroits2brain.permute;
  end
  if isfield(anap.mroits2brain,'flipdim')
    DO_FLIPDIM = anap.mroits2brain.flipdim;
  end
end

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'permute'}
    DO_PERMUTE = varargin{N+1};
   case {'flipdim'}
    DO_FLIPDIM = varargin{N+1};
   case {'verbose'}
    VERBOSE    = varargin{N+1};
  end
end



% Get info about coregistration.
if VERBOSE,  fprintf(' %s : loading info...',mfilename);  end
[M, NEW_ANA] = sub_coreg_info(Ses,grp);
% Get the dimension of EPI
EPIANA = sub_get_epiana(SIG);


% Get the mapping from REF to ANA to EPI
if VERBOSE,  fprintf(' ref2epi...');  end
REF2EPI = sub_ref2ana2epi(Ses,grp,M,EPIANA);

if VERBOSE,  fprintf(' convert');  end
SIG = sub_convert(SIG,NEW_ANA,REF2EPI,VERBOSE);


if any(DO_PERMUTE)
  if VERBOSE,  fprintf(' permute[%s].',deblank(sprintf('%d ',DO_PERMUTE)));  end
  SIG = sub_permute(SIG,DO_PERMUTE);
end


if any(DO_FLIPDIM)
  if VERBOSE,  fprintf(' flipdim[%s].',deblank(sprintf('%d ',DO_FLIPDIM)));  end
  SIG = sub_flipdim(SIG,DO_FLIPDIM);
end


SIG = sub_update_info(SIG,NEW_ANA,DO_PERMUTE,DO_FLIPDIM);


if VERBOSE,  fprintf(' done.\n');  end

return



% =============================================================
function SIG = sub_update_info(SIG,NEW_ANA,DO_PERMUTE,DO_FLIPDIM)
% =============================================================
if iscell(SIG)
  for N = 1:length(SIG)
    SIG{N} = sub_update_info(SIG{N},NEW_ANA,DO_PERMUTE,DO_FLIPDIM);
  end
  return
end

SIG.(mfilename).anafile = NEW_ANA.file;
SIG.(mfilename).permute = DO_PERMUTE;
SIG.(mfilename).flipdim = DO_FLIPDIM;


return



% =============================================================
function [M, NEW_ANA] = sub_coreg_info(Ses,grp)
% =============================================================

% GET SOME INFO ABOUT TRANSFORMATION : mana2brain

anap = getanap(Ses,grp.name);
DO_PERMUTE    = [];
DO_FLIPDIM    = [];
BRAIN_TYPE    = '';
USE_EPI       = 0;
if isfield(anap,'mana2brain')
  if isfield(anap.mana2brain,'permute')
    DO_PERMUTE = anap.mana2brain.permute;
  end
  if isfield(anap.mana2brain,'flipdim')
    DO_FLIPDIM = anap.mana2brain.flipdim;
  end
  if isfield(anap.mana2brain,'brain')
    BRAIN_TYPE = anap.mana2brain.brain;
  end
  if isfield(anap.mana2brain,'use_epi')
    USE_EPI    = anap.mana2brain.use_epi;
  end
end


if any(USE_EPI) || (isfield(anap,'ImgDistort') && any(anap.ImgDistort))
  ananame = sprintf('epi{%d}',grp.exps(1));
  anafile = 'epi';
  anaindx = grp.exps(1);
else
  ananame = sprintf('%s{%d}',grp.ana{1},grp.ana{2});
  anafile = grp.ana{1};
  anaindx = grp.ana{2};
end


% Load conversion matrix ======================================================
DIR_NAME = 'brain';
if any(DO_PERMUTE) || any(DO_FLIPDIM)
  expfile = fullfile(pwd,DIR_NAME,sprintf('%s_%s_%03d_mod.hdr',Ses.name,anafile,anaindx));
else
  expfile = fullfile(pwd,DIR_NAME,sprintf('%s_%s_%03d.hdr',Ses.name,anafile,anaindx));
end
[fp, fr] = fileparts(expfile);
matfile = fullfile(fp,sprintf('%s_coreg_brain.mat',fr));
if ~exist(matfile,'file')
  error(' ERROR %s:  not found ''%s''.\n',mfilename,matfile);
end

M = load(matfile,'M');
M = M.M;


if ~exist(M.vgfile,'file')
  % maybe different drive...
  if any(BRAIN_TYPE)
    INFO = mbrain_defs(BRAIN_TYPE);
  else
    if any(strncmpi(Ses.name,'rat',3))
      INFO = mbrain_defs('rat');
    else
      INFO = mbrain_defs('rhesus');
    end
  end
  %reffile = fullfile(INFO.template_dir,INFO.template_file);
  [fp, fr, fe] = fileparts(M.vgfile);
  reffile = fullfile(INFO.template_dir,sprintf('%s%s',fr,fe));
  if ~exist(reffile,'file')
    error('\n ERROR %s: ''%s'' not found.\n',mfilename,reffile);
  end
  M.vgfile = reffile;
end

[img, hdr] = anz_read(M.vgfile);

% scale 'img' as 0 to 1000
img = double(img);
minv = min(img(:));
maxv = max(img(:));
img = (img - minv) / (maxv - minv);
img = img*1000;

NEW_ANA.file = M.vgfile;
NEW_ANA.dat  = img;
NEW_ANA.ds   = double(hdr.dime.pixdim(2:4));

return



% ============================================================================
function EPIANA = sub_get_epiana(SIG)
% ============================================================================
if iscell(SIG)
  EPIANA = sub_get_epiana(SIG{1});
  return;
end
EPIANA.dat = SIG.ana;
EPIANA.ds  = SIG.ds;

if strncmpi(SIG.session,'rat',3)
  EPIANA.ds = EPIANA.ds * 10;
end


return



% ============================================================================
function REF2EPI = sub_ref2ana2epi(Ses,grp,M,EPIANA)
% ============================================================================
% get the coordinates from anatomy to epi
episz = size(EPIANA.dat);
anasz = size(M.ind_in_ana);
x = 1:anasz(1);
y = 1:anasz(2);
z = 1:anasz(3);
[R, C, P] = ndgrid(x,y,z);
RCP = zeros(4,length(R(:)));  % allocate memory first to avoid memory problem
RCP(1,:) = R(:);  clear R;
RCP(2,:) = C(:);  clear C;
RCP(3,:) = P(:);  clear P;


% slice selection
if anasz(3) ~= episz(3)
  NEWV = RCP(3,:);
  NEWV(:) = NaN;
  dz = EPIANA.ds(3)/M.pixdim_ana(3);
  for N = 1:length(grp.ana{3})
    tmpz = grp.ana{3}(N);
    tmpidx = RCP(3,:) >= tmpz-dz/2 & RCP(3,:) <= tmpz+dz/2;
    NEWV(tmpidx) = N;
  end
  RCP(3,:) = NEWV;
  tmpidx = isnan(RCP(1,:).*RCP(2,:).*RCP(3,:));
  RCP(:,tmpidx) = NaN;
end

% match image size
for N = 1:2
  if anasz(N) ~= episz(N)
    tmpi = 0:anasz(N)-1;
    tmpi = tmpi/(anasz(N)-1);  % 0 to 1
    tmpi = round(tmpi*(episz(N)-1)) + 1;  % 1 to episz(1)
    tmpidx = find(~isnan(RCP(N,:)));
    RCP(N,tmpidx) = tmpi(RCP(N,tmpidx));
  end
end


ANA2EPI = NaN(anasz);
tmpidx = ~isnan(RCP(1,:).*RCP(2,:).*RCP(3,:));
ANA2EPI(tmpidx) = sub2ind(episz,RCP(1,tmpidx),RCP(2,tmpidx),RCP(3,tmpidx));
ANA2EPI = reshape(ANA2EPI,anasz);

REF2ANA = M.ind_in_ref;
REF2EPI = NaN(size(REF2ANA));
tmpidx = ~isnan(REF2ANA(:));
REF2EPI(tmpidx) = ANA2EPI(REF2ANA(tmpidx));
REF2EPI = reshape(REF2EPI,size(M.ind_in_ref));


return



% ============================================================================
function SIG = sub_convert(SIG,NEW_ANA,REF2EPI,VERBOSE)
% ============================================================================
if iscell(SIG)
  for N = 1:length(SIG)
    SIG{N} = sub_convert(SIG{N},NEW_ANA,REF2EPI,VERBOSE);
  end
  return
end

if VERBOSE,  fprintf('.');  end

epiidx = sub2ind(size(SIG.ana),SIG.coords(:,1),SIG.coords(:,2),SIG.coords(:,3));

voxsel = zeros(size(REF2EPI));
voxind = zeros(size(REF2EPI));
for N = 1:length(epiidx)
  tmpidx = find(REF2EPI(:) == epiidx(N));
  if any(tmpidx)
    voxsel(tmpidx) = N;
    voxind(tmpidx) = tmpidx;
  end
end
tmpidx = voxsel > 0;
voxsel = voxsel(tmpidx);
voxind = voxind(tmpidx);

if any(voxsel)
  if ~isempty(SIG.dat)
    SIG.dat = SIG.dat(:,voxsel,:,:,:);  % there may be more than 2D...
  else
    SIG.dat = [];
  end
  [tmpx, tmpy, tmpz] = ind2sub(size(REF2EPI),voxind);
  SIG.coords = [tmpx(:) tmpy(:) tmpz(:)];
else
  SIG.dat = [];
  SIG.coords = [];
end

SIG.ana = single(NEW_ANA.dat);
SIG.ds  = double(NEW_ANA.ds);
if strncmpi(SIG.session,'rat',3)
  SIG.ds = SIG.ds/10;
end


SIG.epiana = 1;


if isfield(SIG,'snr') && ~isempty(SIG.snr)
  tmpsnr = zeros(size(NEW_ANA.dat));
  tmpidx = ~isnan(REF2EPI(:));
  tmpsnr(tmpidx) = SIG.snr(REF2EPI(tmpidx));
  SIG.snr = tmpsnr;
  SIG.snr = single(SIG.snr);
end




if isfield(SIG,'glmcont')
  SIG.glmcont = sub_update_glm(SIG.glmcont,voxsel);
end

if isfield(SIG,'stat')
  SIG.stat.p   = SIG.stat.p(voxsel);
  SIG.stat.dat = SIG.stat.dat(voxsel);
  if isfield(SIG.stat,'beta')
    SIG.stat.beta = SIG.stat.beta(voxsel);
  end
  if isfield(SIG.stat,'F')
    % for getmevent/evtroits
    SIG.stat.F = SIG.stat.F(voxsel);
  end
end

if isfield(SIG,'resp')
  fnames = {'base','mean','max','min'};
  for N = 1:length(fnames)
    tmpf = fnames{N};
    if isfield(SIG.resp,tmpf)
      SIG.resp.(tmpf) = SIG.resp.(tmpf)(voxsel);
    end
  end
end

if isfield(SIG,'r')
  for N = 1:length(SIG.r)
    SIG.r{N} = SIG.r{N}(voxsel);
  end
end
if isfield(SIG,'p')
  for N = 1:length(SIG.p)
    SIG.p{N} = SIG.p{N}(voxsel);
  end
end


return



% ============================================================================
function glmNEW = sub_update_glm(glmcont,voxsel)
% ============================================================================
for N = 1:length(glmcont)
  tmpglm = glmcont(N);
  [tmpidx, loc] = ismember(voxsel,tmpglm.selvoxels);
  loc = loc(tmpidx);
  tmpnew.selvoxels = find(tmpidx);
  tmpnew.statv     = tmpglm.statv(loc);
  tmpnew.pvalues   = tmpglm.pvalues(loc);
  tmpnew.cont      = tmpglm.cont;
  if ~isempty(tmpglm.BetaMag)
    tmpnew.BetaMag   = tmpglm.BetaMag(loc);
  else
    tmpnew.BetaMag   = [];
  end
  glmNEW(N) = tmpnew;
end
return



% ============================================================================
function SIG = sub_permute(SIG,DO_PERMUTE)
% ============================================================================
if iscell(SIG)
  for N = 1:length(SIG)
    SIG{N} = sub_permute(SIG{N},DO_PERMUTE);
  end
  return
end

SIG.ana    = permute(SIG.ana,DO_PERMUTE);
SIG.ds     = SIG.ds(DO_PERMUTE);
if ~isempty(SIG.coords)
  SIG.coords = SIG.coords(:,DO_PERMUTE);
end
if isfield(SIG,'snr') && ~isempty(SIG.snr)
  SIG.snr  = permute(SIG.snr,DO_PERMUTE);
end


return


% ============================================================================
function SIG = sub_flipdim(SIG,DO_FLIPDIM)
% ============================================================================
if iscell(SIG)
  for N = 1:length(SIG)
    SIG{N} = sub_flipdim(SIG{N},DO_FLIPDIM);
  end
  return
end

imgsz = size(SIG.ana);
for K = 1:length(DO_FLIPDIM)
  tmpdim = DO_FLIPDIM(K);
  SIG.ana = flipdim(SIG.ana,tmpdim);
  if ~isempty(SIG.coords)
    SIG.coords(:,tmpdim) = imgsz(tmpdim) - SIG.coords(:,tmpdim) + 1;
  end
  if isfield(SIG,'snr') && ~isempty(SIG.snr)
    SIG.snr = flipdim(SIG.snr,tmpdim);
  end
end

return
