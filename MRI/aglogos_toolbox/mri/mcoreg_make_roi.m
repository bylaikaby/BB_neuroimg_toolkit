function ROI = mcoreg_make_roi(Ses,GrpName,INFO,ATLAS)
%MCOREG_MAKE_ROI - Subfunction to make ROIs.
%  ROI = mcoreg_make_roi() is the subfunction to make ROIs.
%
%  VERSION :
%    0.90 04.10.11 YM  pre-release
%
%  See also mratatlas2ana mrhesusatlas2ana

% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
anap = getanap(Ses,grp);


% check the size
if isfield(anap,'ImgDistort') && anap.ImgDistort == 0,
  tcImg = sigload(Ses,grp.exps(1),'tcImg');
  % slice selection
  if size(ATLAS.dat,3) ~= size(tcImg.dat,3),
    ATLAS.dat = ATLAS.dat(:,:,grp.ana{3});
  end
  % match image size
  if size(ATLAS.dat,1) ~= size(tcImg.dat,1) || size(ATLAS.dat,2) ~= size(tcImg.dat,2),
    fnx = size(tcImg.dat,1);
    fny = size(tcImg.dat,2);
    fnz = size(tcImg.dat,3);
    NEWATLAS = zeros(fnx,fny,fnz);
    for N = 1:fnz,
      NEWATLAS(:,:,N) = imresize(ATLAS.dat(:,:,N),[fnx fny],'nearest');
    end
    ATLAS.dat = NEWATLAS;
    clear NEWATLAS;
  end
  clear tcImg;
end



% create rois
nx = size(ATLAS.dat,1);  ny = size(ATLAS.dat,2);  nz = size(ATLAS.dat,3);

uniqroi = sort(unique(ATLAS.dat(:)));
ROIroi = {};
ROInames = {};
maskimg = zeros(nx,ny);
for N=1:length(uniqroi),
  roinum  = uniqroi(N);
  tmpname = '';
  for K=1:length(ATLAS.roitable),
    if ATLAS.roitable{K}{1} == roinum,
      tmpname = ATLAS.roitable{K}{3};
      break;
    end
  end
  if isempty(tmpname),  continue;  end
  if roinum < 0,
    tmpname = fprintf('%s OH',tmpname);
  end
  
  idx = find(ATLAS.dat(:) == roinum);
  if length(idx) < INFO.minvoxels,  continue;  end
  %if length(idx) < 300,  continue;  end

  [tmpx tmpy tmpz] = ind2sub([nx ny nz],idx);
  uslice = sort(unique(tmpz(:)));
  for S=1:length(uslice),
    maskimg(:) = 0;
    slice = uslice(S);
    selvox = find(tmpz == slice);
    tmpidx = sub2ind([nx ny],tmpx(selvox),tmpy(selvox));
    maskimg(tmpidx) = 1;

    tmproiroi.name  = tmpname;
    tmproiroi.slice = slice;
    tmproiroi.px    = [];
    tmproiroi.py    = [];
    tmproiroi.mask  = logical(maskimg);

    ROIroi{end+1} = tmproiroi;
  end
  ROInames{end+1} = tmpname;
end

% now add the entire brain
tmpname = 'brain';
idx = find(abs(ATLAS.dat(:)) > 0);
[tmpx tmpy tmpz] = ind2sub([nx ny nz],idx);
if length(idx) >= INFO.minvoxels,
  uslice = sort(unique(tmpz(:)));
  for S=1:length(uslice),
    maskimg(:) = 0;
    slice = uslice(S);
    selvox = find(tmpz == slice);
    tmpidx = sub2ind([nx ny],tmpx(selvox),tmpy(selvox));
    maskimg(tmpidx) = 1;

    tmproiroi.name  = tmpname;
    tmproiroi.slice = slice;
    tmproiroi.px    = [];
    tmproiroi.py    = [];
    tmproiroi.mask  = logical(maskimg);

    ROIroi{end+1} = tmproiroi;
  end
  ROInames{end+1} = tmpname;
end


% finalize "Roi" structure
tcAvgImg = sigload(Ses,grp.exps(1),'tcImg');
anaImg = anaload(Ses,grp);
GAMMA = 1.8;
ROI = mroisct(Ses,grp,tcAvgImg,anaImg,GAMMA);
ROI.roinames = ROInames;
ROI.roi = ROIroi;

return
