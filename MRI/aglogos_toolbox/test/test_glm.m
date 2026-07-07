
% TEMPLATE...
% \\win58\ydisk\DataMatlab\Anatomy\Rhesus_Atlas_Paxinos-CoCoMac\rhesus_7_model-MNI_Xflipped_1mm_brain.img



load('\\win58\ydisk\Global\Ripples\monkey_spont_glm(fVal)_rpfroiTs.mat');



RES = rpfroiTs;
% RES = 
%          session: {1x8 cell}
%          grpname: {1x8 cell}
%            ExpNo: {1x8 cell}
%              dir: [1x1 struct]
%              ana: [60x80x48 single]  <-- volume
%              ele: {1x9 cell}
%              snr: [60x80x48 single]
%               ds: [1 1 1]
%               dx: 2
%              dat: [40x230400x8 single] <--  (time,voxel,trials)
%             name: 'all'
%           coords: [230400x3 double] <-- (vox,xyz) coordinates
%              stm: [1x1 struct]
%          sigsort: [1x1 struct]
%             stat: [1x1 struct]
%           epiana: 1
%     mroits2brain: [1x1 struct]  <-- permute/flipdim
%            xform: [1x1 struct]
%              rsp: [230400x8 single] <-- (voxel,trials)  % response?



MAP = nanmean(RES.rsp,2);

IMG = zeros(size(RES.ana),class(MAP));
idx = sub2ind(size(RES.ana),RES.coords(:,1),RES.coords(:,2),RES.coords(:,3));
IMG(idx) = MAP;

IMG = single(IMG);

minv = min(IMG(:));
maxv = max(IMG(:));

IMG = (IMG - minv) / (maxv - minv);

IMG = round(IMG * single(intmax('int16')));
IMG = int16(IMG);


dim =    [4 size(IMG,1) size(IMG,2) size(IMG,3) 1];
pixdim = [3 RES.ds(1) RES.ds(2) RES.ds(3)];



% undo permute/flipdim
if isfield(RES,'mroits2brain'),
  % flipdim first
  if any(RES.mroits2brain.flipdim),
    for N=1:length(RES.mroits2brain.flipdim),
      IMG = flipdim(IMG,RES.mroits2brain.flipdim(N));
    end
  end
  if any(RES.mroits2brain.permute),
    IMG = permute(IMG,RES.mroits2brain.permute);
    tmpds = RES.ds(RES.mroits2brain.permute);
    dim =    [4 size(IMG,1) size(IMG,2) size(IMG,3) 1];
    pixdim = [3 tmpds(1) tmpds(2) tmpds(3)];
  end
end



HDR = hdr_init('dim',dim,'datatype','int16','pixdim',pixdim,'glmax',intmax('int16'));


imgfile = 'D:/Temp/result.img';

anz_write(imgfile,HDR,IMG);
