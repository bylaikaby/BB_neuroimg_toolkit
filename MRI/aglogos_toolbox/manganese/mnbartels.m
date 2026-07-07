function varargout = mnbartels(SESSION,GRPNAME,IMGCROP,SLICROP)
%MNBARTELS - Exports tcImg stucture for A.Bartels' SPM analysis.
%  MNBARTELS(SESSION,GRPANME) exports tcImg stucture for SPM analysis.
%  MNBARTELS(SESSION,GRPANME,IMGCROP,SLICROP) does the same thing with cropping data.
%
%  NOTES :
%    IMGCORP = [x y width height]   SLICROP = [s length]
%
%  VERSION :
%    0.90 24.06.05 YM   pre-release
%
%  See also MN_DAT2SPM SPM

if nargin < 2,  help mnbartels; return;  end

if nargin < 3,  IMGCROP = [];  end
if nargin < 4,  SLICROP = [];  end

MODELS = { 'plgn','mlgn','sc','v1','mt',...
           'eye','opn','xasm','opt','pul','pituitary',...
           'cer','muscle','clgn','clgn','arteries',...
           'norm' };


% FLAGS, SETTING etc %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EXPORT_DIR    = 'spmtest';
USE_REALIGNED = 1;
USE_PCA       = 0;

DO_EXPORT_IMAGE = 0;
DO_EXPORT_MODEL = 1;



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

if nargin < 3,
  switch lower(Ses.name),
   case {'d03se1'}
    %SLICROP = [21 130];
  end
end

fprintf('%s %s: %s %s ',datestr(now,'HH:MM:SS'),mfilename,Ses.name,grp.name);
fprintf(' IMGCROP=[');
if length(IMGCROP) > 1,
  fprintf('%d',IMGCROP(1));  fprintf(' %d',IMGCROP(2:end));
end
fprintf(']');
fprintf(' SLICROP=[');
if length(SLICROP) > 1,
  fprintf('%d %d',SLICROP(1),SLICROP(2));
end
fprintf(']');
fprintf('\n');




% LOAD ANATOMY TO GET DIMENSIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anaImg = anaload(Ses,grp);
nX = size(anaImg.dat,1);  nY = size(anaImg.dat,2);  nS = size(anaImg.dat,3);
nT = length(grp.exps);

clear anaImg;


% LOAD DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT_IMAGE > 0,
  fprintf(' loading[%d %d %d %d]...',nX,nY,nS,nT);
  if USE_PCA > 0,
    datname = 'pca_denoised';
  else
    datname = 'dat';
  end
  IMGDAT = zeros(nX,nY,nS,nT,'int16');
  for iSlice = 1:nS,
    tcImg = mn_tcslice_load(Ses,grp,iSlice,USE_REALIGNED);
    IMGDAT(:,:,iSlice,:) = tcImg.(datname);
  end

  xres = tcImg.ds(1);  yres = tcImg.ds(2);  zres = tcImg.ds(3);
  clear tcImg;
end


% DO CROPPING IF NEEDED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT_IMAGE > 0,
  fprintf(' cropping');
  if ~isempty(IMGCROP),
    selidx = [1:IMGCROP(3)] + IMGCROP(1) - 1;
    IMGDAT = IMGDAT(selidx,:,:,:);
    selidx = [1:IMGCROP(4)] + IMGCROP(2) - 1;
    IMGDAT = IMGDAT(:,selidx,:,:);
  end
  if ~isempty(SLICROP),
    selidx = [1:SLICROP(2)] + SLICROP(1) - 1;
    IMGDAT = IMGDAT(:,:,selidx,:);
  end
  % update dimensions
  nX = size(IMGDAT,1);  nY = size(IMGDAT,2);  nS = size(IMGDAT,3);  nT = size(IMGDAT,4);
  fprintf('[%d %d %d %d]',nX,nY,nS,nT);
end


% EXPORT AS ANALYZA-7 FORMAT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT_IMAGE > 0,
  fprintf(' exporting(%s)...',EXPORT_DIR);
  if exist(fullfile(pwd,EXPORT_DIR),'dir') == 0,
    mkdir(pwd,EXPORT_DIR);
  end

  pixdim = [3 xres yres zres 0 0 0 0];	% must be 8 elements
  dim    = [3 nX nY nS 0 0 0 0];			% must be 8 elements
  HDR = hdr_init('dim',dim,'datatype','int16','pixdim',pixdim,'glmax',intmax('int16'));

  for iT = 1:size(IMGDAT,4),
    froot   = sprintf('%s_%s_T%03d',Ses.name,grp.name,iT);
    hdrfile = sprintf('%s/%s.hdr',EXPORT_DIR,froot);
    imgfile = sprintf('%s/%s.img',EXPORT_DIR,froot);

    tmpimg = IMGDAT(:,:,:,iT);
  
    hdr_write(hdrfile,HDR);
    fid = fopen(imgfile,'wb');
    fwrite(fid, tmpimg, 'int16');
    fclose(fid);
  end

  clear IMGDAT;
end



% EXPORT MODELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if DO_EXPORT_MODEL > 0,
  if ischar(MODELS),  MODELS = { MODELS };  end
  MODELS = unique(MODELS);
  fprintf(' saving models(%d)...',length(MODELS));
  matfile = sprintf('%s/models.mat',EXPORT_DIR);
  cmdstr = 'save(matfile';
  for N = 1:length(MODELS),
    roiname = MODELS{N};
    if any(strcmpi({'norm','global'},roiname)),
      tmpts = load('tcglobal.mat',grp.name);
      tmpts = tmpts.(grp.name);
    else
      tmpts = mn_roits_cat(mn_roits_get(Ses,grp,roiname,[],USE_PCA));
      tmpts.model = mean(double(tmpts.dat),2);
    end
    eval(sprintf('%s = tmpts;',roiname));
    cmdstr = sprintf('%s,''%s''',cmdstr,roiname);
  end
  cmdstr = sprintf('%s,''-v6'');',cmdstr);
  eval(cmdstr);
end


fprintf(' done.\n');




return;





