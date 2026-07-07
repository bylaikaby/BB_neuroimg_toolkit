function dSig = sigfilt(Sig,lims,ftype,poles)
%SIGFILT - Filters the signal within limits 'lims' and type 'ftype'
% dSig = SIGFILT(Sig,lims,ftype) uses Matlab's filtfilt function to filter the signal.
% FILTFILT Zero-phase forward and reverse digital filtering.
%    Y = FILTFILT(B, A, X) filters the data in vector X with the filter described
%    by vectors A and B to create the filtered data Y.  The filter is described 
%    by the difference equation:
% 
%      y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb)
%                       - a(2)*y(n-1) - ... - a(na+1)*y(n-na)
% 
% 
%    After filtering in the forward direction, the filtered sequence is then 
%    reversed and run back through the filter; Y is the time reverse of the 
%    output of the second filtering operation.  The result has precisely zero 
%    phase distortion and magnitude modified by the square of the filter's 
%    magnitude response.  Care is taken to minimize startup and ending 
%    transients by matching initial conditions.
% 
%    The length of the input x must be more than three times
%    the filter order, defined as max(length(b)-1,length(a)-1).
% 
%    Note that FILTFILT should not be used with differentiator and Hilbert FIR
%    filters, since the operation of these filters depends heavily on their
%    phase response.

if nargin < 4,
  poles = 4;
end;

if length(lims) == 2,
  if lims(1) == 0,
    ftype = 'low';
    lims = lims(2);
  elseif lims(2) == 0,
    ftype = 'high';
    lims = lims(1);
  end
end

WAS_STRUCT=0;
if isstruct(Sig),
  WAS_STRUCT=1;
  Sig = {Sig};
end;

nyq = (1/Sig{1}.dx)/2;
if strcmp(ftype,'bandpass'),
  [b,a] = butter(poles,lims/nyq,'bandpass');
elseif strcmp(ftype,'stop'),
  [b,a] = butter(poles,lims/nyq,'stop');
elseif strcmp(ftype,'low'),
  [b,a] = butter(poles,lims/nyq,'low');
else
  [b,a] = butter(poles,lims/nyq,'high');
end;

dlen   = size(Sig{1}.dat,1);
flen   = 2*max([length(b),length(a)]);
idxfil = [flen+1:-1:2 1:dlen dlen-1:-1:dlen-flen-1];
idxsel = [1:dlen] + flen;

LEN = length(size(Sig{1}.dat));

if LEN==2,
  for M = 1:length(Sig),
    for N=1:size(Sig{M}.dat,2),
      tmp = Sig{M}.dat(idxfil,N);
      tmp = filtfilt(b,a,tmp);
      Sig{M}.dat(:,N) = tmp(idxsel);
    end;
  end;
elseif LEN==3,
  for M = 1:length(Sig),
    for N=1:size(Sig{M}.dat,3),
      for K=1:size(Sig{M}.dat,2),
        tmp = Sig{M}.dat(idxfil,K,N);
        tmp = filtfilt(b,a,tmp);
        Sig{M}.dat(:,K,N) = tmp(idxsel);
      end;
    end;
  end;
elseif LEN==4,
  for M = 1:length(Sig),
    for N=1:size(Sig{M}.dat,4),
      for K=1:size(Sig{M}.dat,3),
        for J=1:size(Sig{M}.dat,2),
          tmp = Sig{M}.dat(idxfil,J,K,N);
          tmp = filtfilt(b,a,tmp);
          Sig{M}.dat(:,J,K,N) = tmp(idxsel);
        end;
      end;
    end;
  end;
end;

if WAS_STRUCT,
  Sig = Sig{1};
end;
dSig = Sig;

% CHECK THIS BECAUSE THERE IS DISCREPANCY BETWEEN MAREATS DN THE dosigfilt
% dSig = dosigfilt(Sig,lims,ftype,poles);
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = dosigfilt(Sig,lims,ftype,poles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(Sig),
  for N = 1:length(Sig),
    Sig{N} = dosigfilt(Sig{N},lims,ftype,poles);
  end
  return
end
NoChan = size(Sig.dat,2);
NoObsp = size(Sig.dat,3);
LEN = size(Sig.dat,1);
L=round(LEN/10);
Sig.dat = cat(1,Sig.dat(1:L,:,:),Sig.dat,fliplr(Sig.dat(end-L:end,:,:)));

[b,a] = butter(poles,lims/((1/Sig.dx)/2),ftype);
for ObspNo = NoObsp:-1:1,
  for ChanNo = NoChan:-1:1,
	Sig.dat(:,ChanNo,ObspNo) = filtfilt(b,a,(Sig.dat(:,ChanNo,ObspNo)));
  end;
end;
% Get rid of edge artifacts
Sig.dat = Sig.dat(L+1:L+LEN,:,:);
Sig.dat = Sig.dat(1:LEN,:,:);

return
