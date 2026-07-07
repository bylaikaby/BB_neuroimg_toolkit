function varargout = getlfpmua(SESSION,ExpNo)
%GETLFPMUA - Extract power signals from ClnSpc (LfpPow,MuaPow)
% varargout = GETLFPMUA(SESSION,ExpNo) reads the ClnSpc structure of an
% experiemnt and generate averages in the standard frequency bands we
% work with.
%
% The difference from GETPOW is only the range of each band. This
% is an intermediate situation between the too-detailed eeg.bands
% and the lfp1/lfp/mua1/mua we have been using in the first
% studies. See getses for ranges!
%
% VERSION : 1.00 NKL, 28.04.03
%
% See also SESGETLFPMUA, GETBANDSFLT, SESCLNSPC

if nargin < 2,
	error('usage: getlfpmua(SESSION,ExpNo)');
end;

Ses = goto(SESSION);				% Goto appropr. directory call hgetses
par = expgetpar(Ses,ExpNo);

filename = catfilename(Ses,ExpNo,'mat');

try,
  ClnSpc = sesgetsig(Ses, ExpNo,'ClnSpc');
  if isfield(ClnSpc,'evt'),  ClnSpc = rmfield(ClnSpc,'evt');  end
  if isfield(ClnSpc,'grp'),  ClnSpc = rmfield(ClnSpc,'grp');  end
  %if isfield(ClnSpc,'stm'),  ClnSpc = rmfield(ClnSpc,'stm');  end
  ClnSpc.stm = par.stm;
catch,
  fprintf('Signal "ClnSpc" or File %s was not found\n',filename);
  fprintf('Session: %s -- Skipping Experiment %d\n', Ses.name,ExpNo);
  return;
end;

if length(ClnSpc) == 1,
  g.pLfpL  = DoGetlfpmua(ClnSpc, Ses.anap.bands.LfpL, 'pLfpL');
  g.pLfpM  = DoGetlfpmua(ClnSpc, Ses.anap.bands.LfpM, 'pLfpM');
  g.pLfpH  = DoGetlfpmua(ClnSpc, Ses.anap.bands.LfpH, 'pLfpH');
  g.pMua   = DoGetlfpmua(ClnSpc, Ses.anap.bands.Mua,  'pMua');
else
  for K = 1:length(ClnSpc),
	g.pLfpL{K} = DoGetlfpmua(ClnSpc{K}, Ses.anap.bands.LfpL, 'pLfpL');
	g.pLfpM{K} = DoGetlfpmua(ClnSpc{K}, Ses.anap.bands.LfpM, 'pLfpM');
	g.pLfpH{K} = DoGetlfpmua(ClnSpc{K}, Ses.anap.bands.LfpH, 'pLfpH');
	g.pMua{K}  = DoGetlfpmua(ClnSpc{K}, Ses.anap.bands.Mua,  'pMua');
    ClnSpc{K}  = {};
  end;
end;
clear ClnSpc;

APPEND = 1;
if ~nargout,
  matsigsave(filename, APPEND, g);
  fprintf('getlfpmua: added power signals to %s\n',filename);
else
  names = fieldnames(g);
  for N=1:length(names),
	eval(sprintf('varargout{%d} = g.%s;',N,names{N}));
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SigPow = DoGetlfpmua(Spc, lims, SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f = xsigdim(Spc,2);
if isempty(lims),	lims = [f(1) f(end)];	end;

names.pLfpL  = {'pLfpL';  {'color';'b';'linestyle';'-';'linewidth';0.6}};
names.pLfpM  = {'pLfpM';  {'color';'r';'linestyle';'-';'linewidth';0.6}};
names.pLfpH  = {'pLfpH';  {'color';'m';'linestyle';'-';'linewidth';0.6}};
names.pMua   = {'pMua';  {'color';'k';'linestyle';'-';'linewidth';0.6}};

eval(sprintf('CurName = names.%s;',SigName));
SigPow				= Spc;
SigPow.dir.dname	= char(CurName{1});
SigPow.dsp.func		= 'dspsig';
SigPow.dsp.args		= CurName{2};
SigPow.dsp.label	= {'Time in sec'; 'SD Units'};
SigPow.range		= lims;

SigPow.dat = zeros(size(Spc.dat,1),size(Spc.dat,3),size(Spc.dat,4));
SigPow.dx = SigPow.dx(1);
if isfield(SigPow,'dxorg'),
  SigPow.dxorg = SigPow.dxorg(1);
end

pnts = find(f >= lims(1) & f <= lims(2));
NoChan = size(Spc.dat,3);
NoObsp = size(Spc.dat,4);
for ObspNo = NoObsp:-1:1,
  for ChanNo = NoChan:-1:1,
	SigPow.dat(:,ChanNo,ObspNo) = hnanmean(Spc.dat(:,pnts,ChanNo,ObspNo),2);
  end;
end;

%
% SigPow = sigdetrend(SigPow);
%
SigPow = tosdu(SigPow,'dat','prestm');

SigPow = rmfield(SigPow,'stm');

return;




