function SigTF = sigtimefreq(Sig,varargin)
%SIGTIMEFREQ - Apply eeglab's timefreq() function.
%  SigTF = SIGTIMEFREQ(SIG,...) applies eeglab's timefreq() function.
%
%  Supported options are :
%    'cycles'  = [real] indicates the number of cycles for the 
%                time-frequency decomposition {default: 0}
%                if 0, use FFTs and Hanning window tapering.  
%                or [real positive scalar] Number of cycles in each Morlet
%                wavelet, constant across frequencies.
%                or [cycles cycles(2)] wavelet cycles increase with 
%                frequency starting at cycles(1) and, 
%                if cycles(2) > 1, increasing to cycles(2) at
%                the upper frequency,
%                or if cycles(2) = 0, same window size at all
%                frequencies (similar to FFT if cycles(1) = 1)
%                or if cycles(2) = 1, not increasing (same as giving
%                only one value for 'cycles'). This corresponds to pure
%                wavelet with the same number of cycles at each frequencies
%                if 0 < cycles(2) < 1, linear variation in between pure 
%                wavelets (1) and FFT (0). The exact number of cycles
%                at the highest frequency is indicated on the command line.
%    'wletmethod' = ['dftfilt2'|'dftfilt3'] Wavelet method/program to use.
%                {default: 'dftfilt3'}
%                'dftfilt2' Morlet-variant or Hanning DFT (calls dftfilt2()
%                           to generate wavelets).
%                'dftfilt3' Morlet wavelet or Hanning DFT (exact Tallon 
%                           Baudry). Calls dftfilt3().
%    'ffttaper' = ['none'|'hanning'|'hamming'|'blackmanharris'] FFT tapering
%                function. Default is 'hanning'. Note that 'hamming' and 
%                'blackmanharris' require the signal processing toolbox.
%
%    'freqs'    = [min max] frequency limits. Default [minfreq srate/2],
%                minfreq being determined by the number of data points,
%                cycles and sampling frequency. Enter a single value
%                to compute spectral decompisition at a single frequency
%                (note: for FFT the closest frequency will be estimated).
%                For wavelet, reducing the max frequency reduce
%                the computation load.
%    'winsize'  = If cycles==0 (FFT, see 'wavelet' input): data subwindow
%                length (fastest, 2^n<frames);
%                if cycles >0: *longest* window length to use. This
%                determines the lowest output frequency  {~frames/8}
%    'ntimesout' = Number of output times (int<frames-winsize). Enter a
%                 negative value [-S] to subsample original time by S.
%
%
%    SigTF = 
%           session: 'e10aw1'
%           grpname: 'spont'
%             ExpNo: 1
%               dir: [1x1 struct]
%               dat: [4-D double]   <--- as (t,f,chn,...)
%                dx: 0.0023
%             dxorg: 0.0023
%           toffset: 0              <--- .times(1)        
%             times: [1x66 double]  <--- times in s  (for plotting data)
%             freqs: [1x227 double] <--- freqs in Hz (for plotting data)
%               stm: [1x1 struct]
%       sigtimefreq: [1x1 struct]
%
%
%  EXAMPLE :
%    Cln   = sigload('E10aW1',1,'Cln');
%    Cln   = sigdecimate(Cln,10);
%    ClnTF = sigtimefreq(Cln);
%
%  REQUIREMENT :
%    EEGLAB : http://sccn.ucsd.edu/eeglab/
%
%  VERSION :
%    0.90 09.03.12 YM  pre-release
%    0.91 11.03.12 YM  goes by channel for Michel's function to avoid memory problem.
%
%  See also timefreq

if nargin < 1,  eval(['help ' mfilename]); return;  end

if iscell(Sig),
  for N = 1:length(Sig),
    SigTF{N} = sigtimefreq(Sig{N},varargin{:});
  end
  return
end


% Optional settings
CYCLES      = 10;
WLETMETHOD  = 'dftfilt3';
FFTTAPER    = 'hanning';
FREQ_MINMAX = [0 200];
WINSIZE     = [];
NTIMESOUT   = [];
USE_MICHEL_FUNC = 1;

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'cycles' 'cycle'}
    CYCLES = varargin{N+1};
   case {'wletmethod' 'method'}
    WLETMETHOD = varargin{N+1};
   case {'ffttaper'}
    FFTTAPER = varargin{N+1};
   case {'freqs' 'freq' 'freqminmax'}
    FREQ_MINMAX = varargin{N+1};
   case {'winsize'}
    WINSIZE = varargin{N+1};
   case {'ntimesout'}
    NTIMESOUT = varargin{N+1};
   case {'michel' 'michelfunc' 'usemichelfunc'}
    USE_MICHEL_FUNC = varargin{N+1};
  end
end

Fs = 1/Sig.dx(1);
if isempty(FREQ_MINMAX),
  FREQ_MINMAX = [0 Fs/2];
else
  FREQ_MINMAX(2) = min(FREQ_MINMAX(2),Fs/2);
end


if ndims(Sig.dat) > 2
  szdat = size(Sig.dat);
  Sig.dat = reshape(Sig.dat,[szdat(1) prod(szdat(2:end))]);
else
  szdat = [];
end

%tlen = (size(Sig.dat,1)-WINSIZE)*Sig.dx(1);
%NTIMESOUT = floor(tlen/0.01);  % 10ms step desired
%NTIMESOUT = max(NTIMESOUT,400);


%tic;
if USE_MICHEL_FUNC,
  tf = [];
  % for N = 1:size(Sig.dat,2),
  %   if mod(N,10) == 0,
  %     if mod(N,100) == 0,
  %       fprintf('%d',N);
  %     else
  %       fprintf('.');
  %     end
  %   end
  %   [tmptf freqs times] = timefreqMB(Sig.dat(:,N),Fs,'cycles',CYCLES,...
  %                                    'wletmethod',WLETMETHOD,...
  %                                    'freqs',FREQ_MINMAX,...
  %                                    'ffttaper',FFTTAPER,...
  %                                    'verbose','off');
  %   if isempty(tf),
  %     tf = zeros([size(tmptf,1) size(tmptf,2) size(Sig.dat,2)],class(tmptf));
  %   end
  %   tf(:,:,N) = tmptf;
  % end
  % if abs(times(end) - size(Sig.dat,1)*Sig.dx(1)) < 1,
  %   % likely "times" as sec, convert into msec to macth with timefreq().
  %   times = times*1000;   % in ms
  % end

  if any(szdat)
    % avoid memory problem...
    NCh = szdat(2);
    tf = [];   n = size(Sig.dat,2)/NCh;
    for iCh = 1:NCh,
      is = (iCh-1)*n + 1;
      ie = is + n - 1;
      tmpdat = Sig.dat(:,is:ie);
      
      %       newlength=2^(ceil(log2(size(Sig.dat,1))));
      %       tmpdattmp=zeros(newlength,size(tmpdat,2));
      %       tmpdattmp(1:size(tmpdat,1),:)=tmpdat;
      %       tmpdat=tmpdattmp;
      %tmpdat = single(tmpdat);
      [tmptf freqs times] = timefreqMB(tmpdat,Fs,'cycles',CYCLES,...
                                       'wletmethod',WLETMETHOD,...
                                       'freqs',FREQ_MINMAX,...
                                       'ffttaper',FFTTAPER,...
                                       'winsize',WINSIZE,...
                                       'verbose','off');
      % avoid memory problem..
      % times = times(1:2:end);
      % tmptf = tmptf(:,1:2:end,:);
      % tmpdat=tmpdat(1:size(Sig.dat,1),:);
      tmptf = single(tmptf);
      
      tf = cat(3,tf,tmptf);
    end
  else
    [tf freqs times] = timefreqMB(Sig.dat,Fs,'cycles',CYCLES,...
                                  'wletmethod',WLETMETHOD,...
                                  'freqs',FREQ_MINMAX,...
                                  'ffttaper',FFTTAPER,...
                                  'winsize',WINSIZE,...
                                  'verbose','off');
  end
else
  [tf freqs times] = timefreq(Sig.dat,Fs,'cycles',CYCLES,...
                              'wletmethod',WLETMETHOD,...
                              'freqs',FREQ_MINMAX,...
                              'ffttaper',FFTTAPER,...
                              'ntimesout',NTIMESOUT,...
                              'winsize',WINSIZE);
end
%toc


% [tf freqs times] = timefreq(Sig.dat,Fs,'cycles',CYCLES,...
%                             'wletmethod',WLETMETHOD,...
%                             'freqs',FREQ_MINMAX,...
%                             'ffttaper',FFTTAPER);


tf = permute(tf,[2 1 3]);  % (f,t,...) --> (t,f,...)


if any(szdat)
  Sig.dat = reshape(Sig.dat,szdat);
  tf = reshape(tf,[size(tf,1) size(tf,2) szdat(2:end)]);
end



SigTF.session   = Sig.session;
SigTF.grpname   = Sig.grpname;
SigTF.ExpNo     = Sig.ExpNo;
SigTF.dir.dname = sprintf('%sTF',Sig.dir.dname);
SigTF.dat       = tf;
SigTF.dx        = (times(2)-times(1))/1000;
if isfield(Sig,'dxorg')
SigTF.dxorg     = SigTF.dx * (Sig.dxorg/Sig.dx(1));
end
SigTF.toffset   = times(1)/1000;
SigTF.times     = times/1000;
SigTF.freqs     = freqs;
if isfield(Sig,'stm')
SigTF.stm       = Sig.stm;
end

SigTF.(mfilename).cycles     = CYCLES;
SigTF.(mfilename).wletmethod = WLETMETHOD;
SigTF.(mfilename).freqs      = FREQ_MINMAX;
SigTF.(mfilename).ffttaper   = FFTTAPER;
SigTF.(mfilename).ntimesout  = NTIMESOUT;
SigTF.(mfilename).winsize    = WINSIZE;

return
