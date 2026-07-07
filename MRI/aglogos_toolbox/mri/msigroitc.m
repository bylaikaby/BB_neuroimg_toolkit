function oSig = msigroitc(tcImg,RoiRoi)
%MSIGROITC - Select time series based on predefined ROIs
% MSIGROITC (tcImg, RoiRoi) is a new function created after
% Yusuke and I changed the ROI generation and created the
% mroigui. The function accepts a cell array of ROIs and returns
% a cell array of time series.
%
% NKL & YM, 09.03.04
%
% See also MROIGUI MROISCT
  
if nargin < 2,
  help msigroitc;
  return;
end;

for RoiNo = 1:length(RoiRoi),
  oSig{RoiNo}.session		= tcImg.session;
  oSig{RoiNo}.grpname		= tcImg.grpname;
  oSig{RoiNo}.ExpNo         = tcImg.ExpNo;
  oSig{RoiNo}.dir			= tcImg.dir;
  oSig{RoiNo}.stm			= tcImg.stm;
  oSig{RoiNo}.dx			= tcImg.dx;
  oSig{RoiNo}.name			= RoiRoi{RoiNo}.name;
  oSig{RoiNo}.slice			= RoiRoi{RoiNo}.slice;
  oSig{RoiNo}.dat           = getroitc(tcImg,RoiRoi{RoiNo}.mask);
end;

if ~exist('oSig','var') | isempty(oSig),
  oSig = {};
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tcols = getroitc(tcImg,mask)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mask = imresize(double(mask),[size(tcImg.dat,1) size(tcImg.dat,2)]);
tcols = mreshape(tcImg.dat);
tcols = tcols(:,find(mask(:)));

