function dspanaimg(sig, NSlice)
%DSPANAIMG - Display multi-slice anatomical scans
%	DSPANAIMG(sig) is used to display volumes, such as our
%	anatomical or EPI13 scans.
%	NKL, 13.12.01

if nargin < 2,
	NSlice = 0;
end;

if nargin < 1,
	error('usage: dspanaimg(sig);');
end;

sig.dat = mean(sig.dat,4);

if isfield(sig,'subset'),
	tmp = sig.dat(:,:,sig.subset);
	sig.dat = [];
	for N=1:length(sig.subset),
		sig.dat = cat(2,sig.dat,tmp(:,:,N));
	end;
	dspimg(sig);
	return;
end;


L = size(sig.dat,3);
if L==1,
	imagesc(squeeze(sig.dat)');
	colormap(gray);
	daspect([1 1 1]);
	axis off;
	if isfield(sig,'elepos'),
	  hold on;
	  for E=1:length(sig.elepos),
		plot(sig.elepos{E}(1),sig.elepos{E}(2),'y+','markersize',18);
	  end;
	end;
	return;
end;

if L <=4,
	X=2; Y=2;
elseif L <= 13,
	X=4; Y=4;
else
	X=6; Y=ceil(L/X);
end;
mfigure([50 50 1200 1000]);		% When META is saved
set(gcf,'color',[0 0 0]);

if NSlice
    if L > 1
        if length(NSlice)>1
            m1 = NSlice(1);
            m2 = NSlice(2);
        else
            m1 = min(min(min(sig.dat(:,:,NSlice,:))));
            m2 = max(max(max(sig.dat(:,:,NSlice,:))));
        end

        for N=1:L,
            msubplot(X,Y,N);
            imagesc(sig.dat(:,:,N)', [m1 m2]);
            text(20,20,sprintf('%4d',N),'color','r');
            colormap(gray);
            daspect([1 1 1]);
            if isfield(sig,'elepos'),
                hold on;
                for E=1:length(sig.elepos),
                    plot(sig.elepos{E}(1),sig.elepos{E}(2),'w+');
                end;
            end;
            axis off;
        end;
    end
else        %if NSlice
    for N=1:L,
        subplot(X,Y,N);
        imagesc(sig.dat(:,:,N)');
        text(20,20,sprintf('%4d',N),'color','g','fontsize',24,'fontweight','bold');
        colormap(gray);
        daspect([1 1 1]);
        if isfield(sig,'elepos'),
            hold on;
            for E=1:length(sig.elepos),
                plot(sig.elepos{E}(1),sig.elepos{E}(2),'w+');
            end;
        end;
        axis off;
    end;
end

[lab,txt] = mgetimginfo(sig);
L=length(txt);
MyTitle = '';
for N=1:L,
  MyTitle = strcat(MyTitle,sprintf('%s%s --', lab{N}, txt{N}));
end;
MyTitle = MyTitle(1:end-3);
figtitle(MyTitle,'color','c','fontsize',10);