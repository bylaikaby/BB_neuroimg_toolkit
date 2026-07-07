function oroiTs = mroitsreshape(roiTs)
%MROITSRESHAPE - Reshape roiTs in multidimensional array (usually for Rivalry-Waves)
% roiTs = MROITSRESHAPE(roiTs) converts the typical cell array structure of roiTs into a
% multidimensional array as shown below:
%
% The format of the original roiTs is a cell array, with slice number and area name. The
% reshaped oroiTs has the format:
%
% [1x1 struct]    [1x1 struct], where the number of cells is equal to the number of cortical
% areas. Each cell has the format:
%
%     session: 'n03qv1'
%     grpname: 'rivalryleft'
%       ExpNo: 1
%         dir: [1x1 struct]
%         dsp: [1x1 struct]
%         grp: [1x1 struct]
%         evt: [1x1 struct]
%         ele: {[1x1 struct]  [1x1 struct]}
%          ds: [0.3750 0.3750 2]
%          dx: 0.2500
%         ana: [76x56x2 double]
%        name: 'v1'
%       slice: 1
%      coords: [0x3 double]
%         dat: [70x10x2 double]
%           r: {[1x0 double]}
%       tosdu: [1x1 struct]
%         stm: [1x1 struct]
%        
% The dimensions of the dat field are: Time X Roi X Slices
%        
% NKL 04.07.04
  
if nargin < 1,
  help mroitsreshape;
  return;
end;

if ~iscell(roiTs),
  fprintf('mroitsgetpars: expects a CELL ARRAY input\n');
  return;
end;

SesName = roiTs{1}.session;
GrpName = roiTs{1}.grpname;
ExpNo = roiTs{1}.ExpNo;

if length(ExpNo) > 1,
  fprintf('MROITSRESHAPE: works on single experiments!\n');
  fprintf('ExpNo was found to be:\n');
  ExpNo
  keyboard
end;

Ses = goto(SesName);
THR = 0.1;
roiTs = mroitssel(roiTs, THR);
sortpar = getsortpars(Ses, ExpNo);

for N=1:length(roiTs),
  roiTs{N} = sigsort(roiTs{N},sortpar.trial);
  roiTs{N}.dat = hnanmean(roiTs{N}.dat,3);
end;

%  nareas: 2
%   areas: {'v1'  'v2'}
% nslices: 2
%   nrois: {[10 1]  [10 1]}    
pars = mroitsgetpars(roiTs);

for A=1:pars.nareas,
  for S=1:pars.nslices,
    tmp{A}{S} = mroitsget(roiTs,S,pars.areas{A});
    for nroi=1:pars.nrois{S}(A),
      if nroi==1,
        rts{A}{S} = tmp{A}{S}{nroi};
        rts{A}{S}.dat = hnanmean(rts{A}{S}.dat,2);
      else
        m = hnanmean(tmp{A}{S}{nroi}.dat,2);
        rts{A}{S}.dat = cat(2,rts{A}{S}.dat,m);
      end;
    end;
  end;
end;

K=1;
for A=1:pars.nareas,
  for S=1:pars.nslices,
    len(K) = size(rts{A}{S}.dat,1);
    K=K+1;
  end;
end;
len = min(len);

for A=1:pars.nareas,
  for S=1:pars.nslices,
    if S==1,
      oroiTs{A} = rts{A}{S};
      oroiTs{A}.dat = oroiTs{A}.dat(1:len,:);
    else
      oroiTs{A}.dat = cat(3,oroiTs{A}.dat,rts{A}{S}.dat(1:len,:));
    end;
  end;
end;

