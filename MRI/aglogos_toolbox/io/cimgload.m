function idat = cimgload(fname,scan,reco, crop)
%CIMGLOAD - Load Paravision 2dseq files reconstructed as complex numbers
%	OtcImg = CIMGLOAD(SesName,ExpNo,ARGS) uses read2dseq to read the
%	reconstructed MR images and preprocess them according to the flags set
%	in the structure ARGS. The file name is determined by ExpNo, which
%	indexes the expp(ExpNo).scanreco in the description file.
%
%	NKL, 21.03.06
%
% NOTE :
%  Setting parameters can be controlled by ANAP.cimgload.xxx.

if nargin < 3,  eval(sprintf('help %s;',mfilename)); return;  end
  
[idat, info] = rd2dseq(fname, scan, reco);
if exist('crop'),
  x1 = crop(1);
  y1 = crop(2);
  x2 = x1 + crop(3) - 1;
  y2 = y1 + crop(4) - 1;
  for N=1:size(idat,3),
    tmp(:,:,N) = idat(x1:x2,y1:y2,N);
  end;
  idat = tmp;
end;


