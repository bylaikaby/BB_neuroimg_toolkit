function oroiTs = mroitscat(roiTs)
%MROITSCAT - Concatanate roiTs structures with same name in the same slice
% oRoi = MROITSCAT (roiTs) concatanates all roiTs into one mask by using
% an OR logical operation.
% *********************************  
% roiTs - Structure
% *********************************  
%    session: 'f01pr1'
%    grpname: 'p125c100'
%      ExpNo: 1
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        grp: [1x1 struct]
%        evt: [1x1 struct]
%        stm: [1x1 struct]
%        ele: {}
%         ds: [0.3750 0.3750 2]
%         dx: 0.2500
%        ana: [84x84x2 double]
%       name: 'v1'
%      slice: 1
%     coords: [969x3 double]
%        dat: [256x969 double]
%          r: {[969x1 double]}
%
% YM  06.04.06 supports troiTs.

if nargin < 1,
  help mroitscat;
  return;
end;

if ~iscell(roiTs),
  fprintf('mroitscat: expects a CELL ARRAY input\n');
  return;
end;


oroiTs = {};
if iscell(roiTs{1}),
  % roiTs as troiTs.
  for N=1:length(roiTs),
    nname{N} = roiTs{N}{1}.name;
  end;
  uname = unique(nname);
  for T = 1:length(roiTs{1}),
    tmpTs = {};
    for R = 1:length(roiTs),
      tmpTs{R} = roiTs{R}{T};
    end
    for N = 1:length(uname),
      tmp = roitscat(tmpTs,uname{N});
      oroiTs{N}{T} = tmp;
    end
  end
else
  for N=1:length(roiTs),
    nname{N} = roiTs{N}.name;
  end;
  uname = unique(nname);
  for N=1:length(uname),
    oroiTs{N} = roitscat(roiTs,uname{N});
  end;
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rts = roitscat(roiTs,AreaName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
K=1;
for N=1:length(roiTs),
  if strcmp(lower(roiTs{N}.name),lower(AreaName)),
    tmp{K} = roiTs{N};
    K = K + 1;
  end;
end;

if ~exist('tmp') | isempty(tmp),
  rts = {};
  return;
end;

rts = tmp{1};
rts.slice = -1;
%      slice: 1
%     coords: [969x3 double]
%        dat: [256x969 double]
%          r: {[969x1 double]}
for N=2:length(tmp),
  rts.coords = cat(1,rts.coords,tmp{N}.coords);
  rts.dat = cat(2,rts.dat,tmp{N}.dat);
  for K=1:length(rts.r),
    rts.r{K} = cat(1,rts.r{K},tmp{N}.r{K});
  end;
  for L=1:length(rts.p),
	rts.p{L} = cat(1,rts.p{L},tmp{N}.p{L});
  end;
end;
[rts.coords,idx] = sortrows(rts.coords,3);
if isvector(rts.r{1}),
  % .r/.p can be either (Vox,1) or (1,Vox)
  for K=1:length(rts.r),
    rts.r{K} = rts.r{K}(idx);
    rts.p{K} = rts.p{K}(idx);
  end
else
  % Note that old catsig makes .r/.p as (Vox,ExpNo)
  for K=1:length(rts.r),
    % rts.r{K} = rts.r{K}(:,idx);
    % rts.p{K} = rts.p{K}(:,idx);
    rts.r{K} = rts.r{K}(idx,:);
    rts.p{K} = rts.p{K}(idx,:);
  end
end;
rts.dat = rts.dat(:,idx,:);




return;


