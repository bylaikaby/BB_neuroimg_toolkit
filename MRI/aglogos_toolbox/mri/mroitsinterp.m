function oTs = mroitsinterp(roiTs,newdx)
%MROITSINTERP - Interpolate/resample with new sampling time "newdx"
% oTs = ROITSINTERP(roiTs,newdx)
% newdx = new sampling rate
% NKL 18.04.07
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dx = round(10*roiTs.dx)/10;
R = round(dx/newdx);
roiTs.stm.voldt = roiTs.dx;
if R ~= dx/newdx,
  fprintf('MROITSINTERP: subInterp won''t be able to accurately resample\n');
  fprintf('MROITSINTERP: Check newdx/roiTs.dx values\n');
  oTs = {};
  return
end;
    
oTs = roiTs;
oTs.dat = [];
for G=size(roiTs.dat,4):-1:1,
  for N=size(roiTs.dat,3):-1:1,
    for M=size(roiTs.dat,2):-1:1,
      oTs.dat(:,M,N,G) = interp(roiTs.dat(:,M,N,G),R);
    end;
  end;
end;

oTs.dx = newdx;
oTs.sigsort.len_pts = oTs.sigsort.len_pts * R;
oTs.stm.voldt = newdx;

%   stimv = Sig.stm.v{1};
%   stimt = Sig.stm.time{1};  stimt(end+1) = sum(Sig.stm.dt{1});
%   stimdt = Sig.stm.dt{1};

return;

