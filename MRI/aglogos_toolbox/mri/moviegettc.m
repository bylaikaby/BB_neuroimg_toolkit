function moviegettc(SESSION,ExpNo,izsts,DENOISE)
%MOVIEGETTC - Extracts Time series from each experiments tcImg
% MOVIEGETTC (SESSION,ExpNo,map,stm) extracts the time series on the
% basis of a map obtained from an experiment or group file. The
% argment izsts is the statistics of a refence session.

if nargin < 4,
  DENOISE=1;
end;

Ses = goto(SESSION);
filename = catfilename(Ses,ExpNo,'mat');
grp = getgrp(Ses,ExpNo);

tcImg = matsigload(filename,'tcImg');
tcImg = DetrendImg(tcImg);

refzsts = izsts;
for SliceNo=1:size(tcImg.dat,3),
  refzsts{SliceNo}.dat = ...
	  getpts(squeeze(tcImg.dat(:,:,SliceNo,:)),izsts{SliceNo}.map,1);
  refzsts{SliceNo} = tosdu(refzsts{SliceNo},'dat');
end;

fprintf('moviegettc: ICA-Denoising...');
refzsts = msigicadenoise(refzsts);
fprintf(' Done!\n');

save(filename,'-append','refzsts');
fprintf('Appended "refzsts" in file %s\n', filename);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ts = getpts(img,mask,modtyp);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ts = [];
ts = mreshape(img);
switch modtyp
 case -1
  ts = ts(:,find(mask(:)<0));
 case 1
  ts = ts(:,find(mask(:)>0));
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DetrendImg(Sig,son,sof)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SIZE=squeeze(size(Sig.dat(:,:,1,:)));
for SliceNo=1:size(Sig.dat,3),
  tmpimg = squeeze(Sig.dat(:,:,SliceNo,:));
  tmpimg = mreshape(tmpimg);
  for N=1:size(tmpimg,2),
	tmpimg(:,N)=detrend(tmpimg(:,N));
  end;
  Sig.dat(:,:,SliceNo,:) = mreshape(tmpimg,SIZE,'m2i');
end;


