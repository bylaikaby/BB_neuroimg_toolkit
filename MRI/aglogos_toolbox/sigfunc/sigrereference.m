function Sig = sigrereference(Sig,REF_CHAN,varargin)
%SIGREREFERENCE - Re-reference signals.
%  SIG = SIGREREFERENCE(SIG,REF_CHAN,...) re-references signals.
%  'REF_CHAN' can be a numeric vector for channels, 'all' or 'exclusive'.
%   If channel-vector, this funciton subtracts average of the given channels from the
%   signals.  If 'all', this subtracts the average of all channels.  If 'exclusive',
%   this subtracts the average of all channels except its own.
%
%  EXAMPLE :
%    Sig = sigrereference(Sig,1:2)
%    Sig = sigrereference(Sig,'exclusive')
%
%  VERSION :
%    0.90 27.05.13 YM  pre-release.
%    0.91 28.05.13 YM  improved speed for 'exclusive'.
%
%  See also nanmean expgetblp

if nargin < 2,  eval(['help ' mfilename]); return;  end

if iscell(Sig)
  for N = 1:length(Sig)
    Sig{N} = sigrereference(Sig{N},REF_CHAN,varargin{:});
  end
  return;
end


% OPTIONS
for N = 1:2:length(varargin)
  switch lower(varargin{N})
  end
end



if ischar(REF_CHAN),
  switch lower(REF_CHAN)
   case {'all' 'mean'}
    REF = nanmean(Sig.dat,2);
   case {'exclusive'}
    REF = 'exclusive';
   otherwise
    error('\n ERROR %s:  REF_CHAN=''%s'' not supported.\n',mfilename,REF_CHAN);
  end
else
  REF = nanmean(Sig.dat(:,REF_CHAN),2);
end


if isequal(REF,'exclusive')
  % chans = 1:size(Sig.dat,2);
  % origdat = Sig.dat;
  % for N = 1:size(Sig.dat,2)
  %   tmpm = nanmean(origdat(:,chans~=N),2);
  %   Sig.dat(:,N) = Sig.dat(:,N) - tmpm;
  % end

  % this is much faster, difference to above method is as small as eps().
  % exdat = n/(n-1)*(dat - mdat).
  tmpm = nanmean(Sig.dat,2);
  for N = 1:size(Sig.dat,2)
    Sig.dat(:,N) = Sig.dat(:,N) - tmpm;
  end
  a = size(Sig.dat,2)/(size(Sig.dat,2) - 1);
  Sig.dat = a * Sig.dat;
  
else
  for N = 1:size(Sig.dat,2)
    Sig.dat(:,N) = Sig.dat(:,N) - REF;
  end
end



Sig.(mfilename).refchan = REF_CHAN;


return
