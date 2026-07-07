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

if iscell(Sig),
  for N = 1:length(Sig),  dsprf(Sig{N},Frame,Contrast);  end
  return;
end

if Frame > size(Sig.dat,1),
  fprintf(' WARNING %s: 1<=''Frame''<=%d\n',mfilename,size(Sig.dat,1));
  return;
end


nchans = size(Sig.dat,5);
if nchans < 2,
  ncol = 1;  nrow = 1;
elseif nchans == 2,
  ncol = 1;  nrow = 2;
elseif nchans == 3,
  ncol = 1;  nrow = 3;
elseif nchans <= 4,
  ncol = 2;  nrow = 2;
elseif nchans <= 6,
  ncol = 2;  nrow = 3;
elseif nchans <= 9,
  ncol = 3;  nrow = 3;
elseif nchans <= 12,
  ncol = 3;  nrow = 4;
else
  ncol = 4;  nrow = 4;
end


for N=1:size(Sig.dat,5),
  msubplot(nrow,ncol,N);
  
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
  %set(gca,'clim',[0 0.1]);
end;
tit=sprintf('Ses: %s, Group: %s, Signal: %s',...
			Sig.session, Sig.grpname, Sig.dir.dname);
suptitle(tit);

