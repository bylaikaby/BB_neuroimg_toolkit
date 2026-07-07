function tcImg = roiTs2tcImg(roiTs,varargin)
%ROITS2TCIMG - Converts roiTs to tcImg structure.
%  tcImg = roiTs2tcImg(roiTs) converts roiTs to tcImg structure.
%  Voxels that are not in roiTs will be filled as NaN.
%
%  VERSION :
%    0.90 28.11.07 YM  pre-release
%
%  See also

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

tcImg = {};
if iscell(roiTs) & iscell(roiTs{1}),
  % troiTs..
  % make roiTs for each trials
  troiTs = roiTs;
  for iTrial = 1:length(roiTs{1}),
    roiTs = {};
    for N = 1:length(roiTs),
      roiTs{N} = troiTs{N}{iTrial};
    end
    tcImg{iTrial} = sub_roiTs2tcImg(roiTs);
    tcImg{iTrial}.(mfilename).trial = iTrial;
  end
else
  tcImg = sub_roiTs2tcImg(roiTs);
end

% SAVE NECESSARY INFO
%           session: 'h05jd1'
%            grpname: 'visesmix'
%              ExpNo: [1 2 3 4 5 6 7 9 10 26 27 28 29 30 31 32 33 34 35]
%                dir: [1x1 struct]
%                dsp: [1x1 struct]
%                grp: [1x1 struct]
%                evt: [1x1 struct]
%                ele: {}
%                 ds: [0.7500 0.7500 2]
%                 dx: 0.2500
%                ana: [90x100x2 double]
%           centroid: [3x1200 double]
%               name: 'V1'
%              slice: -1
%             coords: [919x3 double]
%          roiSlices: [1 2]
%                dat: [240x919 double]
%                  r: {[919x1 double]}
%                  p: {[919x1 double]}
%               info: [1x1 struct]
%                stm: [1x1 struct]
%            sigsort: [1x1 struct]
%              xform: [1x1 struct]
%          glmoutput: [1x1 struct]
%            glmcont: [1x5 struct]
%     DesignMatrices: {[240x3 double]}


% tcImg.(mfilename) = rmfield(roiTs,'dat');


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to convert roiTs{X} to tcImg
function tcImg = sub_roiTs2tcImg(roiTs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isstruct(roiTs),  roiTs = { roiTs };  end

tcImg.session = roiTs{1}.session;
tcImg.grpname = roiTs{1}.grpname;
tcImg.ExpNo   = roiTs{1}.ExpNo;
tcImg.dir.dname = 'tcImg';
tcImg.dat     = [];
tcImg.ds      = roiTs{1}.ds;
tcImg.dx      = roiTs{1}.dx;
tcImg.stm     = roiTs{1}.stm;
if isfield(roiTs{1},'xform'),
  tcImg.xform = roiTs{1}.xform;
end

% tcImg.dat as (xyz,time)
imgsz = size(roiTs{1}.ana);
% tcImg.dat = NaN([prod(imgsz) size(roiTs{1}.dat,1)],class(roiTs{1}.dat));
tcImg.dat = zeros([prod(imgsz) size(roiTs{1}.dat,1)],class(roiTs{1}.dat));
roiname = {};
for N = 1:length(roiTs),
  tmpcoords = roiTs{N}.coords;
  tmpidx = sub2ind(imgsz,tmpcoords(:,1),tmpcoords(:,2),tmpcoords(:,3));
  tcImg.dat(tmpidx,:) = roiTs{N}.dat';
  roiname{N} = roiTs{N}.name;
end
% tcImg.dat as (x,y,z,time)
tcImg.dat = reshape(tcImg.dat,[imgsz size(roiTs{1}.dat,1)]);

return
