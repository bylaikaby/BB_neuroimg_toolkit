function ClnCor = getlfpmua4corr(SESSION,ExpNo)
%GETLFPMUA4CORR - Returns TS of the average MUA and all frequencies in LFP range
% powsig = GETLFPMUA4CORR(SESSION,ExpNo) reads the ClnSpc structure of an
% experiment and generates a new ClnCor structure containing the original signals and
% their correlations.
%
% NKL, 29.01.05
%
% See also SESCLNSPC CLNSPC

if nargin < 2,
	error('usage: getlfpmua4corr(SESSION,ExpNo)');
end;

LFPRANGE = [0 200];
MUARANGE = [400 3000];

Ses = goto(SESSION);				% Goto appropr. directory call hgetses

filename = catfilename(Ses,ExpNo,'mat');

try,
	ClnSpc = sesgetsig( Ses, ExpNo,'ClnSpc');
catch,
	fprintf('Signal "ClnSpc" or File %s was not found\n',filename);
	fprintf('Session: %s -- Skipping Experiment %d\n', Ses.name,ExpNo);
	return;
end;

ClnCor				= ClnSpc;
ClnCor.dat          = [];
ClnCor.dir.dname	= 'ClnCor';
ClnCor.dsp.func		= 'dspclncor';
ClnCor.dsp.args		= [];
ClnCor.dsp.label	= {'Time in sec'; 'SD Units'};
ClnCor.range		= {LFPRANGE; MUARANGE};

f = xsigdim(ClnSpc,2);
pnts = find(f >= LFPRANGE(1) & f <= LFPRANGE(2));
NPNTS = length(pnts);
mpnts = find(f >= MUARANGE(1) & f <= MUARANGE(2));
NoChan = size(ClnSpc.dat,3);

ClnCor.lfp = zeros(size(ClnSpc.dat,1),NPNTS,NoChan);
for ChanNo = 1:NoChan,
	ClnCor.lfp(:,:,ChanNo) = ClnSpc.dat(:,pnts,ChanNo);
    ClnCor.mua(:,ChanNo) = hnanmean(ClnSpc.dat(:,mpnts,ChanNo),2);
end;

[lfp, mua] = sigwhiten(ClnCor.lfp, ClnCor.mua);

nlags = 15;

% Correlation between the raw signals
[ClnCor.r,ClnCor.p] = lmcor(ClnCor.mua,ClnCor.lfp,nlags,0.01);

% Correlation between the prewhitened raw signals
[ClnCor.ur,ClnCor.up] = lmcor(mua,lfp,nlags,0.01);
ClnCor.f = f(pnts);

if 0,
for ChanNo = 1:NoChan,
  for Bnd = 1:NPNTS,
    Sig1.dat = ClnCor.lfp(:,Bnd,NoChan);
    Sig1.dx = ClnCor.dx(1);
    Sig2.dat = ClnCor.mua(:,NoChan);
    Sig2.dx = ClnCor.dx(1);
    ir = lfpmuairf(Sig1,Sig2);
  end;
end;
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [r,p] = lmcor(x,y,nlags,alpha)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p = zeros(size(y,2),1); r = p; dx = p;
   
% FIRST COMPUTE MAX(r) BY SHIFTING MODEL/DATA
for N=1:length(p),
  [tmpr,lags] = xcorr(x,y(:,N),nlags,'coef');
  [mx,mxi] = max(tmpr);
  dx(N) = lags(mxi);
end;

% NOW USE THE SHIFTED DATA TO COMPUTE CORRCOEFF
nanbuf = NaN * ones(size(x));
for N=1:length(p),
  if (dx(N)<=0),
    sy = nanbuf;
    sy(1:end+dx(N)) = y(1-dx(N):end,N);
    [tmpr,tmpp] = corrcoef(x(:),sy,'rows','pairwise');
  else
    sx = nanbuf;
    sx(1:end-dx(N)) = x(dx(N)+1:end);
    [tmpr,tmpp] = corrcoef(sx,y(:,N),'rows','pairwise');
  end;
  r(N) = tmpr(1,2); p(N) = tmpp(1,2);
end;

if exist('alpha','var') & alpha,
  idx = find(abs(p)>=alpha);
  r(idx) = 0;
end;
return;



