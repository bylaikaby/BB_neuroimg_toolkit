function roiTs = updaterois(roiTs, RoiGroupName)
%UPDATEROIS - Updates the sequence of ROIS in Fraction or PBR/NBR plots
% Stanford, NKL 15.03.2017
  
if nargin < 2,
  RoiGroupName = 'SELROI';
end;

anap = getanap(roiTs.session, roiTs.grpname);
SELROI = anap.(RoiGroupName);

DAT = NaN*ones(size(roiTs.dat));
for N=1:length(SELROI),
  tmpidx = find(strcmpi(roiTs.roinames,SELROI{N}));
  if ~isempty(tmpidx),
    DAT(:,N,:,:) = roiTs.dat(:,tmpidx,:,:);
  end;
end;
roiTs.dat = DAT;
roiTs.roinames = SELROI;
return;

