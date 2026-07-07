function powsig = getgrplfpmua(SESSION,GrpName)
%GETGRPLFPMUA - Extract power signals from the ClnSpc of a group-file
%	powsig = GETGRPLFPMUA(SESSION,GrpName) reads the ClnSpc structure of a
%	group and generate averages in the standard frequency bands we
%	work with.
%	VERSION : 1.00 NKL, 28.04.03
%
%	See also GETLFPMUA SESSIGPOW

if nargin < 2,
	error('usage: getgrplfpmua(SESSION,ExpNo)');
end;

Ses = goto(SESSION);				% Goto appropr. directory call hgetses
name = strcat(GrpName,'.mat');
load(name,'GrpClnSpc');

if length(GrpClnSpc) == 1,
  g.gLfpL  = DoGetLfpMua(GrpClnSpc, Ses.anap.bands.lfpL, 'gLfpL');
  g.gLfpM  = DoGetLfpMua(GrpClnSpc, Ses.anap.bands.lfpM, 'gLfpM');
  g.gLfpH  = DoGetLfpMua(GrpClnSpc, Ses.anap.bands.lfpH, 'gLfpH');
  g.gMua  = DoGetLfpMua(GrpClnSpc, Ses.anap.bands.mua, 'gMua');
else
  for K=1:length(GrpClnSpc),
	g.gLfpL{K} = DoGetLfpMua(GrpClnSpc{K}, Ses.anap.bands.lfpL,  'gLfpL');
	g.gLfpM{K} = DoGetLfpMua(GrpClnSpc{K}, Ses.anap.bands.lfpM,  'gLfpM');
	g.gLfpH{K} = DoGetLfpMua(GrpClnSpc{K}, Ses.anap.bands.lfpH,  'gLfpH');
	g.gMua{K} = DoGetLfpMua(GrpClnSpc{K}, Ses.anap.bands.mua,  'gMua');
  end;
end;

APPEND = 1;
if ~nargout,
	matsigsave(name, APPEND, g);
	fprintf('GetLfpMua: added power signals to %s\n',name);
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SigPow = DoGetLfpMua(Spc, lims, SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f = xsigdim(Spc,2);
if isempty(lims),	lims = [f(1) f(end)];	end;

names.gLfpL  = {'gLfpL';  {'color';'b';'linestyle';'-';'linewidth';0.6}};
names.gLfpM  = {'gLfpM';  {'color';'r';'linestyle';'-';'linewidth';0.6}};
names.gLfpH  = {'gLfpH';  {'color';'m';'linestyle';'-';'linewidth';0.6}};
names.gMua  = {'gMua';  {'color';'k';'linestyle';'-';'linewidth';0.6}};

eval(sprintf('CurName = names.%s;',SigName));
SigPow				= Spc;
SigPow.dir.dname	= char(CurName{1});
SigPow.dsp.func		= 'dspsigpow';
SigPow.dsp.args		= CurName{2};
SigPow.dsp.label	= {'Time in sec'; 'SD Units'};
SigPow.range		= lims;

SigPow.dat = zeros(size(Spc.dat,1),size(Spc.dat,3),size(Spc.dat,4));
SigPow.dx = SigPow.dx(1);

pnts = find(f >= lims(1) & f <= lims(2));
dat = Spc.dat;
NoChan = size(Spc.dat,3);
for ChanNo = 1:NoChan,
	SigPow.dat(:,ChanNo) = squeeze(hnanmean(dat(:,pnts,ChanNo),2));
end;
SigPow = tosdu(SigPow,'dat','prestm');
return;




