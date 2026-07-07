function dspgrprf(Sig,Frame)
%DSPGRPRF - Plot RF structure of a single experiment
% DSPGRPRF(Sig,Frame) plots the RF structure computed
% on the basis of LFP/MUA activity. The variable Frame determines
% which of the frames in the averaged sequence (default -1:1, that
% is three frames with the middle one being the trigger) will be
% displayed. For the best session we shall have a sequence with 0.1
% seconds dt.
% THIS FUNCTION is the similar with dsprf, but it works with group
% files and no computation of averages/std are needed, as they are
% already done by catmovie.m
% YM & NL 20.09.03

alpha = 0.01;
alpha = alpha/(length(Sig.dat(:)));
Sig.dat(abs(Sig.pval)>alpha)=0;

for N=1:size(Sig.dat,4),
  msubplot(4,4,N);
  imagesc(squeeze(Sig.dat(Frame,:,:,N)));
  daspect([ 1 1 1]);
  axis off;
  muaclim(:,N) = get(gca,'clim')';
end;
clim = [min(muaclim(1,:)) max(muaclim(2,:))];
for N=1:size(Sig.dat,4),
  set(gca,'clim',clim(:)');
end;
tit=sprintf('Ses: %s, Group: %s, Signal: %s',...
			Sig.session, Sig.grpname, Sig.dir.dname);
suptitle(tit);

