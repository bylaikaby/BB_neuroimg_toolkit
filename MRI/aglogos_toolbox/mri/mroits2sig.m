function roiSig = mroits2sig(roiTs,AreaName,SliceNo,rThr);
%MROITS2SIG - convert the roiTs structure into regular signal
% roiSig = MROITS2SIG (roiTs,AreaName,SliceNo,rThr) converts the
% roiTs to signal for using it w/ all our xform-like functions.
%
% roiTs = 
%    session: 'f01pr1'
%    grpname: 'p125c100'
%      ExpNo: 11
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        grp: [1x1 struct]
%        evt: [1x1 struct]
%        stm: [1x1 struct]
%        ele: {}
%         ds: [0.3750 0.3750 2]
%         dx: 0.2500
%        ana: [84x84x2 double]
%        roi: {[1x1 struct]  [1x1 struct]}
%
% roiTs.roi{1}
%    session: 'f01pr1'
%    grpname: 'polarflash'
%      ExpNo: 11
%        dir: [1x1 struct]
%       name: 'v1'
%       mask: [84x84x2 double]
%        ntc: {[1 969]  [970 2011]}
%         ix: [2011x1 double]
%     coords: [2011x3 double]
%        dat: [384x2011 double]
%         dx: 0.2500
%          r: {[1x2011 double]}
%        dsp: [1x1 struct]
%      tosdu: [1x1 struct]
%
% NKL, 30.04.04

if nargin < 4,
  rThr = 0;
end;

if nargin < 3,
  SliceNo = -1;     % get all of them
end;

if nargin < 2,
  help mroits2sig;
  roiSig = {};
  return;
end;

%%%%% YUSUKE: this is UUUUUUUGLY!!!
%%% we should find a solution
tmp = roiTs.roi;
for N=1:length(roiTs.roi),
  if ~strcmp(roiTs.roi{N}.name,AreaName), continue; end;
  roiSig = rmfield(roiTs,{'roi' 'ele'});

  if SliceNo > 0,
    r = tmp{N}.r{1}(1,[tmp{N}.ntc{SliceNo}(1): ...
                     tmp{N}.ntc{SliceNo}(end)]);
    roiSig.coords = ...
        tmp{N}.coords([tmp{N}.ntc{SliceNo}(1):tmp{N}.ntc{SliceNo}(end)]);
  end;
  if rThr,
    roiSig.dat = roiSig.dat(:,find(tmp{N}.r{1}>rThr));
  else
    roiSig.dat = tmp{N}.dat;
  end;
  
  roiSig.coords = tmp{N}.coords(find(tmp{N}.r{1}>rThr),:);
  roiSig.dat = tmp{N}.dat;
  break;
end;

    

