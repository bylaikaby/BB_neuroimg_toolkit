function [cs,t,Fs] = modelpts(xcor)
%MODELPTS - Model hemodynamic responses elicited by brief stimuli.
% MODELPTS uses the mean and error of the positive time series of
% the xcor structure to model the hemodynamic response to brief
% stimulation. The model-function is the "MLDPTS".
% XCOR structure:
%   session: 'c01ph1'
%    grpname: 'polarflash'
%      ExpNo: 11
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        ana: [208x160 double]
%        epi: [52x40 double]
%       aval: 4.8077e-006
%         ds: [0.7500 0.5625]
%         dx: 0.2500
%        mdl: [1x1 struct]
%        dat: [52x40 double]
%      tosdu: [1x1 struct]
%        pts: [56x1 double]
%     ptserr: [56x1 double]
     
% NKL, 04.04.04

ONSET = 1.5;          % Hemodynamic delay
FACTOR = 12;

pts = xcor.pts;
pts = interp(pts,FACTOR);
Fs = FACTOR * (1/xcor.dx);
dt = 1/Fs;

ses = goto(xcor.session);
grp = getgrpbyname(ses,xcor.grpname);
pars = getsortpars(ses,grp.exps(1));
tmp = expgetstm(ses,xcor.grpname,'boxcar');
tmp = sigsort(tmp,pars.trial);

xdata.mx = max(pts(:));
xdata.dt = dt;
xdata.ofs = xcor.mdl.stm.dt{1}(1);      % Stim offset in seconds
xdata.dat = interp(tmp{9}.dat,FACTOR);

% INITIAL PARAMETERS
PARS = [xdata.mx 8.5 0.5];  

% LOWER END UPPER BOUNDS
lb = [xdata.mx*0.5  3.5  0.30];
ub = [xdata.mx*5.0 12.0  0.99];

NUM_OF_PARS = length(PARS);
DOPLOT		= 1;
MAXITER		= 1000;
MAXFUNEVALS = 2000*NUM_OF_PARS;
TOLFUN		= 1.0000e-006;

options=optimset('MaxFunEvals',MAXFUNEVALS,'MaxIter',MAXITER,'TolFun',TOLFUN);
pars=lsqcurvefit('mhrf',PARS,xdata,pts,lb,ub,options);
Y = mhrf(pars,xdata);
pars

% PLOT NOW
time = [0:length(pts)-1] * dt;
time = time(:);
plot(time,pts,'k');
hold on;
plot(time(1:10:end),pts(1:10:end),'ks',...
     'linestyle','none','markerfacecolor','k');
plot(time,Y,'r');
grid on;
hold off;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%mx = max(pts(:));
x
ofs = 2;

% OLD CODE FOR PLOTTING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('position',[60 70 512 750]);
% figure('Position',[20 80 600 850]);
fs = get(gcf,'defaultaxesfontsize');

subplot('position',[0.13 0.48 0.78 0.43]);
if strcmp(varname,'fmn'),
	ed = errorbar(ir.t,ir.mn,ir.sd);
	set(ed(1),'Color','k');
	set(ed(2),'LineWidth',2,'Color','b');
else
	ed = plot(ir.t,eval(sprintf('ir.%s',varname)));
	set(ed,'LineWidth',1,'Color','b');
end;
hold on
plot(ir.t,Y,'Color','r','LineWidth',2);
grid on;

set(gca,'YColor','k');
set(gca,'FontWeight','bold','FontSize',9);
set(gca,'Xlim',[ir.t(1) ir.t(end)]);

xlabel('Time in Seconds','FontWeight','bold','FontSize',9);
ylabel('Normalized Response','FontWeight','bold','FontSize',9);
title(sprintf('VARNAME: %s',varname));
subplot('position',[0.13 0.08 0.78 0.33]);
axis off;
set(gca,'ylim',[0 1000]);
set(gca,'xlim',[0 1000]);
cy = 1000 - [10:57:950]';
cx = ones(length(cy(:)),1) * 5;


VARS = cat(2,ir.vars{:});
suptitle(sprintf('irfit(ir,''%s''): Variables: %s',varname,VARS));

orient(gcf,'portrait');
set(gcf,'PaperPositionMode','auto');
set(gcf,'PaperType','A4');








