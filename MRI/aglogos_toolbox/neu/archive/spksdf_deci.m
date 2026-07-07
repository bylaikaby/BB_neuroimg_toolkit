function Sdf = spksdf_deci(Spkt,decFrac)
%SPKSDF_DECI - Make spike density functions
%	Sdf = spksdf(Spkt,sdSec, decFrac)
%	Creates a spike density function (SDF) for a given series
%	of spike events (spike times extracted by thresholding or
%	by cluster cutting).
%	IMPORTANT: Sdf are given in SD UNITS of PRESTIM !!!!!!!!!!!!!!!!!!!!!!
%	NKL, 14.10.00
%   YM,  01.03.04 improved memory usage, adds 'decFrac' to save memory.
%
% See also SIGGETSPK SESGETSPK

sdSec = 0.005;		% SD = 5 ms

if nargin < 2,  decFrac = 1;  end


Sdf = MkSdf(Spkt,sdSec,decFrac);

return;	

%%% Create SDF
function Sdf = MkSdf(Spk,sdSec,decFrac)
sd = round(sdSec/Spk.dt);				% COMPUTE KERNEL
meanx = sd * 3;
ksize = 2 * meanx + 1;
x = [1:ksize]';
m = exp(-((x - meanx).*(x - meanx))/(2*sd*sd));
m = m ./ sum(m);
ofs = meanx;
NoChan = size(Spk.times,1);
NoObsp = size(Spk.times,2);

%Sdf = zeros(Spk.duration,NoChan,NoObsp);
tsel = (1+ofs):(Spk.duration+ofs);

if decFrac > 1,
  % do decimation
  for ChanNo = NoChan:-1:1,
    for ObspNo = NoObsp:-1:1,
      %Sdf(Spk.times{ChanNo,ObspNo},ChanNo,ObspNo) = 1;
      %tmpsdf = conv(Sdf(:,ChanNo,ObspNo),m);
      tmpsdf = zeros(Spk.duration,1);
      tmpsdf(Spk.times{ChanNo,ObspNo}) = 1;
      tmpsdf = conv(tmpsdf,m);
      Sdf(:,ChanNo,ObspNo) = decimate(tmpsdf(tsel),decFrac);
    end;
  end;
else
  % no decimation
  for ChanNo = NoChan:-1:1,
    for ObspNo = NoObsp:-1:1,
      %Sdf(Spk.times{ChanNo,ObspNo},ChanNo,ObspNo) = 1;
      %tmpsdf = conv(Sdf(:,ChanNo,ObspNo),m);
      tmpsdf = zeros(Spk.duration,1);
      tmpsdf(Spk.times{ChanNo,ObspNo}) = 1;
      tmpsdf = conv(tmpsdf,m);
      Sdf(:,ChanNo,ObspNo) = tmpsdf(tsel);
    end;
  end;
end


return;

