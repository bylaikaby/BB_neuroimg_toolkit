function dsprf(Sig,Frame,Contrast)
%DSPRF - Plot RF structure of a single experiment
% DSPRF(Sig,Frame) plots the RF structure computed
% on the basis of LFP/MUA activity. The variable Frame determines
% which of the frames in the averaged sequence (default -1:1, that
% is three frames with the middle one being the trigger) will be
% displayed. For the best session we shall have a sequence with 0.1
% seconds dt.
% THIS FUNCTION is the similar with dsprf, but it works with group
% files and no computation of averages/std are needed, as they are
% already done by catmovie.m
% YM & NL 20.09.03

if nargin < 3,
  Contrast = 'lum';
end;

for N=1:size(Sig.dat,5),
  msubplot(4,4,N);
  
  tmp = squeeze(Sig.dat(Frame,:,:,:,N));
  if strcmp(Contrast,'lum'),
	tmp = hnanmean(tmp,3);
  elseif strcmp(Contrast,'col'),
	R = tmp(:,:,1);
	G = tmp(:,:,2);
	B = tmp(:,:,3);
	RG = hnanmean(tmp(:,:,1:2),3);
	tmp = sqrt((R-G).^2+(B-RG).^2);
  else
	fprintf('Contrast values: "lum" or "col"\n');
  end;
  
  imagesc(tmp);
  daspect([ 1 1 1]);
  axis off;
end;

for N=1:size(Sig.dat,5),
  set(gca,'clim',[0 0.1]);
end;
tit=sprintf('Ses: %s, Group: %s, Signal: %s',...
			Sig.session, Sig.grpname, Sig.dir.dname);
suptitle(tit);

