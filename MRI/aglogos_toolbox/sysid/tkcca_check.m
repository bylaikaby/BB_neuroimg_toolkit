function tkcca_check(RES)
%TKCCA_CHECK - Quick check of tkCCA results
%
%
tmpres = RES;
tmpres.fmri.weights = nanmean(tmpres.fmri.weights,2);
for N = 1:length(tmpres.ephys),
  tmpres.ephys(N).weights = nanmean(tmpres.ephys(N).weights,3);
  tmpres.ephys(N).xcorr   = nanmean(tmpres.ephys(N).xcorr,  2);
end
plot_tkcca(tmpres);


