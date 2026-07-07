function dspmoviettest(Sig)
%DSPMOVIETTEST - show sesroi results (ROIs xcor data etc.) for group
% DSPMOVIETTEST(SESSION,GrpName) - shows correlation maps superimposed on
% anatomical scans, and if exists also the activated voxels in different
% regions of interest, such as different visual areas etc.
%
% NKL, 25.10.02
NoSlice = length(Sig);
Y=2;
X=round(NoSlice/Y)+1;

for SliceNo = 1:NoSlice,
  if ~isnan(Sig{SliceNo}.tipx),
	Sig{SliceNo}.map(Sig{SliceNo}.tipx,Sig{SliceNo}.tipy)...
		= max(Sig{SliceNo}.map(:));
  end;
  
  msubplot(X,Y,2*(SliceNo-1)+1);
  dspfused(Sig{SliceNo});
  subplot(X,Y,2*SliceNo);
  dspTc(Sig{SliceNo});
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dspTc(sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = [0:size(sig.dat,1)-1]*sig.dx;
y = hnanmean(sig.dat,2);
plot(t, y,'r');
set(gca,'xlim',[t(1) t(end)]);
set(gca,'ygrid','on');
xlabel('Time in seconds');
ylabel('SD Units');
drawstmlines(sig,'color','k','linestyle',':');
title('Time Course of Activated Voxels');
return;



