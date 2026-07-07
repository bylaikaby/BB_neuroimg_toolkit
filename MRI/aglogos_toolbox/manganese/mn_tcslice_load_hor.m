function [tcImg matfile] = mn_tcslice_load_hor(SESSION,GRPNAME,H_SLICE,REALIGNED)
%MN_TCSLICE_LOAD_HOR - Loads time course of given HORIZONTAL slice.
%  TCIMG = MN_TCSLICE_LOAD_HOR(SESSION,GRPNAME,H_SLICE,[REALIGNED=1]) loads
%  time course of given HORIZONTAL slice as tcImg structure.
%  [TCIMG, MATFILE] = MN_TCSLICE_LOAD_HOR(SESSION,GRPNAME,H_SLICE,[REALIGNED=1]) also
%  loads and returns tcImg in addition to its associated filename.
%
%  EXAMPLE :
%    tcImg = mn_tcslice_load_hor('d03se1','mdeftinj',10);  % load realigned tcImg of slice 10
%    tcImg = mn_tcslice_load_hor('d03se1','mdeftinj',36);  % load tcImg of slice 36
%    mn_tcslice_load_hor('d03se1','mdeftinj',62);          % assign tcImg into "caller" workspace.
%
%
%  VERSION :
%    0.90 20.06.05 YM  pre-release
%
%  See also MN_TCSLICE_LOAD, MN_SPM2MAT, ASSIGNIN


if nargin == 0,  help mn_tcslice_load_hor; return;  end

if nargin < 4,  REALIGNED = 1;  end

if REALIGNED > 0,
  DIR_TCSLICE = 'TC_SLICE_REALIGNED';
else
  DIR_TCSLICE = 'TC_SLICE_RAW';
end

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);

NSlice = length(grp.ana{3});

IMGDAT = [];  PCADAT = [];
for iSlice = 1:NSlice,
  tcImg = mn_tcslice_load(Ses,grp,iSlice,REALIGNED);
  if isempty(IMGDAT),
    IMGDAT = zeros(size(tcImg.dat,1),length(H_SLICE),NSlice,size(tcImg.dat,4),class(tcImg.dat));
  end
  IMGDAT(:,:,iSlice,:) = tcImg.dat(:,H_SLICE,1,:);
  if isfield(tcImg,'pca_denoised') & ~isempty(tcImg.pca_denoised),
    if isempty(PCADAT),
      PCADAT = zeros(size(tcImg.dat,1),length(H_SLICE),NSlice,size(tcImg.dat,4),class(tcImg.dat));
    end
    PCADAT(:,:,iSlice,:) = tcImg.pca_denoised(:,H_SLICE,1,:);
  end
end

tcImg.slice = 1:length(grp.ana{3});
tcImg.horizontal = H_SLICE;
tcImg.dir.tcimgfile = '';
tcImg.dat   = IMGDAT;
if ~isempty(PCADAT),
  tcImg.pca_denoised = PCADAT;
end


if nargout == 0,
  assignin('caller','tcImg',tcImg);
end



return;
