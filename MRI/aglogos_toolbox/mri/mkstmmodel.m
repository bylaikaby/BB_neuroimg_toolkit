function omdl = mkstmmodel(tcImg, hemo)
%MKSTMMODEL - Use the stm field to generate models for correlation analysis
% MKSTMMODEL (tcImg) will use the stm field of the tcImg structure and a gamma-like kernel
% to generate a model corrected for hemodynamic delays.
%
% MKSTMMODEL (tcImg,'none') will return a box-car function
% 
% See also MKMODEL

if nargin < 2,
  hemo = 1;
end;

HemoDelay = 2;		% 2 seconds
DX = 0.01;

nmodels = length(tcImg.stm.v);

for NM = 1:nmodels,
  VAL = tcImg.stm.v{NM};
  T   = tcImg.stm.time{NM};
  LEN = round(sum(tcImg.stm.dt{NM})/DX);
  
  % +1 for matlab indexing
  TIDX = floor(T/DX) + 1;
  TIDX(end+1) = LEN;
  
  Wv = zeros(LEN,1);
  for N = 1:length(VAL),
    Wv(TIDX(N):TIDX(N+1)) = VAL(N);
  end;
  
  if hemo,

    IRTLEN = round(25/DX);  % 25 sec duration HRF
    IRT = [0:IRTLEN-1]*DX;
    Lamda = 10;
    Theta = 0.4089;
    IR = gampdf(IRT,Lamda,Theta);
    sel = 1:length(Wv);
    Wv = conv(Wv(:),IR(:));
    Wv = Wv(sel);

  end;
  LEN = size(tcImg.dat,4);
  if 0,
    Wv = decimate(Wv,tcImg.dx/DX);
  else
    Wv = resample(Wv,LEN,length(Wv));
  end
  if length(Wv) > LEN,  Wv = Wv(1:LEN);  end

  omdl{NM}.session      = tcImg.session;
  omdl{NM}.grpname      = tcImg.grpname;
  omdl{NM}.dir          = tcImg.dir;
  omdl{NM}.dsp          = tcImg.dsp;
  omdl{NM}.dsp.label	= {'Time in Sec'; 'SD Units'};
  omdl{NM}.dsp.func     = 'dspmodel';
  omdl{NM}.stm          = tcImg.stm;
  omdl{NM}.dx           = tcImg.dx;
  omdl{NM}.dat          = Wv;
end;
return;

