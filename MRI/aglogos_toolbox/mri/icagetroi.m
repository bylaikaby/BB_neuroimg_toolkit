function roi = icagetroi(Sig,varargin)
%ICAGETROI - Get ROIs from the ICA activation
% roi = icagetroi(Sig) returns the masks for the positive and negative weights
%       of spatial ICA (Bell & Sejnowski).
% roi = icagetroi(SesName,GrpName) returns the masks for the positive and negative weights,
%       but the Sig is read from the ICA_name file.
%
% NKL 21.05.07
%

if nargin < 1,
  help icagetroi;
  return;
end;

if ischar(Sig),
  if nargin < 2,
    help icagetroi;
    return;
  end;
  
  Ses = goto(Sig);
  grp = getgrp(Ses,varargin{1});
  anap = getanap(Ses,grp);
  fname = sprintf('ICA_%s_%s.mat', anap.ica.dim,GrpName);
  Sig = matsigload(fname,'oSig');
  Sig = icaselect(Sig);
end;
  
NoComponents    = Sig.anapica.NoComponents;
DISP_THRESHOLD  = Sig.anapica.DISP_THRESHOLD;
if strcmp(Sig.ica_dim,'spatial');
  icomp = Sig.ica.icomp;
else
  icomp = Sig.ica.icomp';
end;
COORDS          = Sig.ica.coords;
IMGSIZE         = size(Sig.ana);

% construct real images ([x,y,z,n])
icamap = NaN([IMGSIZE, size(icomp,1)]);

for N = 1:size(icomp,2),
  for K = 1:size(icomp,1),
    % ASSIGNING THE WEIGHTS TO THE 2D SLICE-MAP
    icamap(COORDS(N,1),COORDS(N,2),COORDS(N,3),K) = icomp(K,N);  
  end;
end;

if DISP_THRESHOLD > 0,
  idx = find(abs(icamap) <= DISP_THRESHOLD);
  if ~isempty(idx),  icamap(idx) = NaN;  end
end

pmap = icamap;
nmap = icamap;
pidx = find(icamap<0);
nidx = find(icamap>0);
pmap(pidx) = NaN;
nmap(nidx) = NaN;

pmap(isnan(pmap)) = 0;
nmap(isnan(nmap)) = 0;
pmap(find(pmap)) = 1;
nmap(find(nmap)) = 1;
pmap = logical(pmap);
nmap = logical(nmap);

for N=1:size(pmap,4),
  ptxt{N} = sprintf('pIC%d',Sig.anapica.icomp(N));
end;
for N=1:size(nmap,4),
  ntxt{N} = sprintf('nIC%d',Sig.anapica.icomp(N));
end;

roi.roinames = {};
roi.roi = {};

for M=1:size(pmap,4),       % Components
  for N=1:size(pmap,3),     % Slices
    tmproi.name = ptxt{M};
    tmproi.slice = N;
    tmproi.px = [];
    tmproi.py = [];
    tmproi.mask = pmap(:,:,N,M);
    roi.roi{end+1} = tmproi;
  end;
  roi.roinames{end+1} = ptxt{M};
end;

for M=1:size(nmap,4),
  for N=1:size(nmap,3),
    tmproi.name = ntxt{M};
    tmproi.slice = N;
    tmproi.px = [];
    tmproi.py = [];
    tmproi.mask = nmap(:,:,N,M);
    roi.roi{end+1} = tmproi;
  end;
  roi.roinames{end+1} = ntxt{M};
end;

% load('Roi.mat');
if ~exist('grp'),
  grp = getgrpbyname(Sig.session,Sig.grpname);
end;
if exist('Roi.mat','file'),
  ROI = load('Roi.mat',grp.grproi);  ROI = ROI.(grp.grproi);
else
  ROI.session = Sig.session;
  ROI.img     = Sig.ana;
end
ROI.roinames = roi.roinames;
ROI.roi = roi.roi;
ROI.ExpNo   = Sig.ExpNo;
roi = ROI;

if ~nargout,
  dsproi(roi);
end;
