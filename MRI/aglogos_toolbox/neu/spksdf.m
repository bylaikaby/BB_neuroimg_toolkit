function Sdf = spksdf(Spkt,Fs,sdSec)
%SPKSDF - Make spike density functions
%	Sdf = spksdf(Spkt,Fs)
%	Creates a spike density function (SDF) for a given series
%	of spike events (spike times extracted by thresholding or
%	by cluster cutting).
%	IMPORTANT: Sdf are given in SD UNITS of PRESTIM !!!!!!!!!!!!!!!!!!!!!!
%
%   VERSION :
%	  1.00 14.10.00 NKL
%     1.01 01.03.04 YM  improved memory usage, adds 'decFrac' to save memory.
%
%  See also siggetspk sesgetspk sigresample

if nargin < 3,
  sdSec = 0.005;		% SD = 5 ms
end;

if nargin < 2,  Fs = 250;  end


Sdf = MkSdf(Spkt,Fs,sdSec);

return;	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sdf = MkSdf(Spk,Fs,sdSec)
% Create Spike Density Function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sd = round(sdSec/Spk.dt);				% COMPUTE KERNEL
meanx = sd * 3;
ksize = 2 * meanx + 1;
x = [1:ksize]';
m = exp(-((x - meanx).*(x - meanx))/(2*sd*sd));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS HERE WAS A MISTAKE.
% It turns out conv does the normalization so, we should not be passing the fractional
% coefficients for the convolution kernel
% m = m ./ sum(m);
% NKL 13.08.06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ofs = meanx;
NoChan = size(Spk.times,1);
NoObsp = size(Spk.times,2);

%Sdf = zeros(Spk.duration,NoChan,NoObsp);
tsel = (1+ofs):(Spk.duration+ofs);


% tmpspk = zeros(Spk.duration,1);
% for ChanNo = NoChan:-1:1,
%   for ObspNo = NoObsp:-1:1,
%     Sdf(Spk.times{ChanNo,ObspNo},ChanNo,ObspNo) = 1;
%     tmpsdf = conv(Sdf(:,ChanNo,ObspNo),m);
%     tmpspk(:) = 0;
%     tmpspk(Spk.times{ChanNo,ObspNo}) = 1;
%     tmpsdf = conv(tmpspk,m);
%     Sdf(:,ChanNo,ObspNo) = tmpsdf(tsel);
%   end;
% end
%
% if ~isempty(Fs) & Fs > 1,
%   do resample
%   tmpsig.dx = Spk.dt;
%   tmpsig.dat = Sdf;
%   tmpsig = sigresample(tmpsig,Fs);
%   Sdf = tmpsig.dat;
% end


if ~isempty(Fs) && Fs > 1,
  % do resample
  [p,q] = rat(Fs*Spk.dt,0.0000001);
  for ChanNo = NoChan:-1:1,
    for ObspNo = NoObsp:-1:1,
      %Sdf(Spk.times{ChanNo,ObspNo},ChanNo,ObspNo) = 1;
      %tmpsdf = conv(Sdf(:,ChanNo,ObspNo),m);
      tmpsdf = zeros(Spk.duration,1);
      tmpsdf(Spk.times{ChanNo,ObspNo}) = 1;
      tmpsdf = conv(tmpsdf,m);
      Sdf(:,ChanNo,ObspNo) = resample(tmpsdf(tsel),p,q);
    end;
  end;
else
  % no resample
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

