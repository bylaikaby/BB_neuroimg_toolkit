function prgpshow(SESSION,GrpName)
%PRGPSHOW - display data for Glass-Pattern experiments
% prgpshow(SESSION,GrpName) like all functions starting with PR_ is
% project specific. It displays the results of the GP experiments.
% NKL, 13.12.01

if nargin < 1,
	error('usage: prgpshow(SESSION,GrpName);');
end;

PPTOUT = getpptstate;

PRETIME = 6;
POSTTIME = 20;
YLIM = [-4 8];			% j02hn1
YLIM = [-4 10];			% d01hq1

Ses = goto(SESSION);
load(strcat(GrpName,'.mat'));
eval(sprintf('roinames = Ses.grp.%s.roinames;', GrpName));
eval(sprintf('stmnames = Ses.grp.%s.sname;', GrpName));
stmnames = stmnames(2:end);
titlenames = {'V1';'V2';'Other'};

% Example of stm
% Blk pcon prad pdip ptra mcona mconb mrada mradb mdip mtra
% v: [0 1 0 2 0 3 0 4 0 5 0 7 0 9 0 10 0 10 0 9 0 8 0 6 0 4 0 3 0 2 0 1 0]
% t: [15 10 10 10 10 10 10 10 .... 10];
% roinames	= {'br';'v1';'v2';'v4';'mt'};
% imgtr: 0.5000

ModelNo = 1;
imgt = [0:size(v1Pts.dat,1)-1]*v1Pts.dx;
imgt0 = find(imgt<v1Pts.stm{1}.t(1));

for N=1:length(roinames),
	eval(sprintf('img = %sPts;', roinames{N}));
	tmp = hnanmean(img.dat,2);
	m(N) = nanmean(tmp(imgt0));
	sd(N) = nanstd(tmp(imgt0));

	for K=1:length(stmnames),
		p = gettrig(img, [0 K 0], K, PRETIME, POSTTIME);
		tc{N}{K} = gettrgtrial(img,p);
	end;
end;

for N=1:length(roinames),
	for K=1:4,
		sta{N} = tc{N}{K};
	end;
	stastm{N} = sigsctcat('dat',2,sta);
	for K=5:length(stmnames),
		mov{N} = tc{N}{K};
	end;
	movstm{N} = sigsctcat('dat',2,mov);
end;

t = [0:size(stastm{1}.dat,1)-1]*stastm{1}.dx;

% MOTION AGAINST STATIC
mfigure([10 50 400 800],sprintf('Ses: %s',Ses.name));
for N=1:length(roinames),
   idx = find(t<stastm{N}.stm{1}.t(1));
   ys = hnanmean(stastm{N}.dat,2);
   ys = (ys - nanmean(ys(idx))) ./ nanstd(ys(idx));
   ym = hnanmean(movstm{N}.dat,2);
   ym = (ym - nanmean(ym(idx))) ./ nanstd(ym(idx));

   subplot(length(roinames),1,N);
   hd(1)=plot(t,ys,'k','linewidth',1.5);
   hold on
   hd(2)=plot(t,ym,'r','linewidth',1.5);

%	if exist('YLIM','var') | ~isempty(YLIM),
%		set(gca,'ylim',YLIM);
%	end;
	set(gca,'ygrid','on');
	drawstmlines(stastm{N});
	ylabel('SD Units');
	if N==length(roinames),
		xlabel('Time in sec');
	end;
	if N==1;
		[h,h1] = legend(hd,'STATIC','MOVING',1);
		set(h,'FontWeight','normal','FontSize',8);
		set(h1(1),'fontsize',7,'fontweight','bold');
	end;
	set(gca,'xlim',[0 POSTTIME+PRETIME]);

end;

if PPTOUT,
	imgfile = sprintf('%s_%s_pm2',Ses.name,GrpName);
	imgfile = hstrfext(imgfile,'');
	print('-dmeta',imgfile);
	close gcf
end;

% STATIC STIMULI
mfigure([10 50 400 800],sprintf('Ses: %s',Ses.name));
% Blk pcon prad pdip ptra mcona mconb mrada mradb mdip mtra
for N=1:length(roinames),
    idx = find(t<stastm{N}.stm{1}.t(1));

	pcon = hnanmean(tc{N}{1}.dat,2);
	pcon = (pcon - nanmean(pcon(idx)))/nanstd(pcon(idx));
%	pcon = (pcon - m(N))/sd(N);

	prad = hnanmean(tc{N}{2}.dat,2);
	prad = (prad - nanmean(prad(idx)))/nanstd(prad(idx));
%	prad = (prad - m(N))/sd(N);

	pdip = hnanmean(tc{N}{3}.dat,2);
	pdip = (pdip - nanmean(pdip(idx)))/nanstd(pdip(idx));
%	pdip = (pdip - m(N))/sd(N);

	ptra = hnanmean(tc{N}{4}.dat,2);
	ptra = (ptra - nanmean(ptra(idx)))/nanstd(ptra(idx));
%	ptra = (ptra - m(N))/sd(N);

	subplot(length(roinames),1,N);
	hold on
	hd(1) = plot(t,pcon,'r','linewidth',1.5);
	hd(2) = plot(t,prad,'g','linewidth',1.5);
	hd(3) = plot(t,pdip,'b','linewidth',1.5);
	hd(4) = plot(t,ptra,'k','linewidth',1.5);
	title(titlenames{N});
	if exist('YLIM','var') | ~isempty(YLIM),
		set(gca,'ylim',YLIM);
	end;
	set(gca,'ygrid','on');
	drawstmlines(stastm{N});
	ylabel('SD Units');
	if N==length(roinames),
		xlabel('Time in sec');
	end;
	if N==1;
		[h,h1] = legend(hd,'PCON','PRAD','PDIP','PTRA',1);
		set(h,'FontWeight','normal','FontSize',8);
		set(h1(1),'fontsize',7,'fontweight','bold');
	end;
	set(gca,'xlim',[0 POSTTIME+PRETIME]);
end;

if PPTOUT,
	imgfile = sprintf('%s_%s_stat',Ses.name,GrpName);
	imgfile = hstrfext(imgfile,'');
	print('-dmeta',imgfile);
	close gcf
end;

% MOVING STIMULI
mfigure([10 50 400 800],sprintf('Ses: %s',Ses.name));
% Blk pcon prad pdip ptra mcona mconb mrada mradb mdip mtra
for N=1:length(roinames),
    idx = find(t<stastm{N}.stm{1}.t(1));

	mcon = hnanmean(tc{N}{5}.dat,2);
	tmp = hnanmean(tc{N}{6}.dat,2);
	mcon = (mcon + tmp)./2;
	mcon = (mcon - nanmean(mcon(idx)))/nanstd(mcon(idx));
%	mcon = (mcon - m(N))/sd(N);

	mrad = hnanmean(tc{N}{7}.dat,2);
	tmp = hnanmean(tc{N}{8}.dat,2);
	mrad = (mrad + tmp)./2;
	mrad = (mrad - nanmean(mrad(idx)))/nanstd(mrad(idx));
%	mrad = (mrad - m(N))/sd(N);

	mdip = hnanmean(tc{N}{9}.dat,2);
%	mdip = (mdip - m(N))/sd(N);
	mdip = (mdip - nanmean(mdip(idx)))/nanstd(mdip(idx));

	mtra = hnanmean(tc{N}{10}.dat,2);
	mtra = (mtra - m(N))/sd(N);
	mtra = (mtra - nanmean(mtra(idx)))/nanstd(mtra(idx));

	subplot(length(roinames),1,N);
	hold on
	hd(1) = plot(t,mcon,'r','linewidth',1.5);
	hd(2) = plot(t,mrad,'g','linewidth',1.5);
	hd(3) = plot(t,mdip,'b','linewidth',1.5);
	hd(4) = plot(t,mtra,'k','linewidth',1.5);
	title(titlenames{N});
	if exist('YLIM','var') | ~isempty(YLIM),
		set(gca,'ylim',YLIM);
	end;
	set(gca,'ygrid','on');
	drawstmlines(stastm{N});
	ylabel('SD Units');
	if N==length(roinames),
		xlabel('Time in sec');
	end;
	if N==1;
		[h,h1] = legend(hd,'MCON','MRAD','MDIP','MTRA',1);
		set(h,'FontWeight','normal','FontSize',8);
		set(h1(1),'fontsize',7,'fontweight','bold');
	end;
	set(gca,'xlim',[0 POSTTIME+PRETIME]);
end;

if PPTOUT,
	imgfile = sprintf('%s_%s_mov',Ses.name,GrpName);
	imgfile = hstrfext(imgfile,'');
	print('-dmeta',imgfile);
	close gcf
end;


