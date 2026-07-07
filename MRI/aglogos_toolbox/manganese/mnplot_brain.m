function mnplot_brain(SESSION,GRPNAME)
%MNPLOT_BRAIN plots XYZ profiles of the brain
%  MNPLOT_BRAIN(SESSION,GRPNAME) plots XYZ profiles of the brain defined in ROI.
%
%  VERSION :
%    0.90 20.09.05 YM  pre-release
%    0.91 06.02.12 YM  use mroi_file().
%
%  See also

if nargin < 2,  help mnplot_brain; return;  end



SPM_DIR = 'spm';

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


maskvol = subGetMaskVolume(Ses,grp,'brain');
nanidx  = find(maskvol(:) == 0);

nx = size(maskvol,1);
ny = size(maskvol,2);
nz = size(maskvol,3);

Xprof = zeros(nx,length(grp.exps));
Yprof = zeros(ny,length(grp.exps));
Zprof = zeros(nz,length(grp.exps));



for iExp = 1:length(grp.exps),
  ExpNo = grp.exps(iExp);
  imgfile = sprintf('%s/r%s_%03d.img',SPM_DIR,Ses.name, ExpNo);
  hdrfile = sprintf('%s/r%s_%03d.hdr',SPM_DIR,Ses.name, ExpNo);

  fid = fopen(imgfile,'rb');
  tmpimg = fread(fid,inf,'int16');
  fclose(fid);
  
  tmpimg(nanidx) = NaN;
  tmpimg = reshape(tmpimg,[nx ny nz]);
  
  Xprof(:,iExp) = squeeze(nanmean(squeeze(nanmean(tmpimg,2)),2));
  Yprof(:,iExp) = squeeze(nanmean(squeeze(nanmean(tmpimg,1)),2));
  Zprof(:,iExp) = squeeze(nanmean(squeeze(nanmean(tmpimg,1)),1))';
end

keyboard




return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a mask volume
function maskvol = subGetMaskVolume(Ses,grp,ROINAME)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% LOAD 'ROINAME' regions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
ROI = mroiget(ROI,[],ROINAME);
ROI = mroicat(ROI);

% sort by slice
ROISLICE = zeros(1,length(ROI.roi));
for N = 1:length(ROI.roi),
  ROISLICE(N) = ROI.roi{N}.slice;
end
[ROISLICE, idx] = sort(ROISLICE);
ROI.roi = ROI.roi(idx);

nx = size(ROI.img,1);
ny = size(ROI.img,2);
nz = size(ROI.img,3);

maskvol = zeros(nx*ny,nz,'int8');


for iRoi = 1:length(ROI.roi),
  tmproi = ROI.roi{iRoi};
  iz = ROI.roi{iRoi}.slice;
  idx = find(ROI.roi{iRoi}.mask(:) > 0);
  maskvol(idx,iz) = 1;
end


maskvol = reshape(maskvol,[nx ny nz]);

return;
