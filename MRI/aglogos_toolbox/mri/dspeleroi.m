function dspeleroi(Sig)
%DSPELEROI - Display anatomical scan w/ selected ROIs
%	DSPELEROI(Sig) display the selected anatomical scan (usually the GEFI
%	scan) and plots on it all selected ROIs, including the brain/electrode
%	and visual area ROIs.
%
%	NKL, 03.01.03

NoSlice = size(Sig.dat,3);

if NoSlice==1,
	X=1; Y=1;
elseif NoSlice > 1 & NoSlice <= 4,
	X=2; Y=2;
elseif NoSlice> 4 & NoSlice <= 13,
	X=4; Y=4;
else
	X=6; Y=ceil(NoSlice/X);
end;

mfigure([50 50 1000 900]);
suptitle(sprintf('Ses: %s, Group: %s',Sig.session,Sig.grpname));
set(gcf,'color',[0 0 0]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	ELEROI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      mask: [300x220 logical]
%         x: [11x1 double]
%         y: [11x1 double]
%       pix: [832x1 double]
%      area: [832x1 double]
%    radius: [832x1 double]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try,
for SliceNo=1:NoSlice,
	subplot(X,Y,SliceNo);
	imagesc(Sig.img{SliceNo}');
	colormap(gray);
	axis off;
	hold on;

	for E=1:length(Sig.tip)
	  if Sig.tip{E}(3) == SliceNo,
		plot(Sig.markers{E}(1),Sig.markers{E}(2),'r+','markersize',18);
	  end;
	end;

	hold on;
	for RoiNo=1:length(Sig.dat),
	  if ~isempty(Sig.dat{RoiNo}{SliceNo}.x),
		plot(Sig.dat{RoiNo}{SliceNo}.x,Sig.dat{RoiNo}{SliceNo}.y,'g');
	  end;
	end;
end;
catch,
  disp(lasterr);
  keyboard;
end;







