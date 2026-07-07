function Spkt = spkselect(varargin)
%SPKSELECT - classify spikes detected as real spikes or artifacts
%  Spkt = SPKSELECT(Ses,ExpNo,varargin)
%  Spkt = SPKSELECT(Spkt,varargin)
%highpass filtered of the Cln signal is used for the analysis
%two criteria are used to discard events
%1/ power 1ms around the maximum should be "powRatio" (default 3) times
%bigger than power in the time window spkwin_ms around the spike excluding
%the 1ms interval
%2/ amplitude of the pick (at spike time) should not be in the two-sides
%tale of the histogram of the spike amplitudes of the experiment:
%upper and lower ampPercentile (default 5%) are discarded
%
%  inputs
%
%	Spkt - Spike data structure.
%
%	varargin - 
%       highpassfreq : cutoff frequency in Hz of the highpass filter (default 800 Hz)
%       amppercentile : quantile (between 0 and 1) of the tale of spike amplitude histogram
%                       removed (on both sides), default .05
%       powratio : power ratio threshold (default 3)
%       spkwin_ms : time window in ms extracted around spike times (default
%       [-1.5 1.5])
%
%  outputs
%
%	Updated Spkt.times to have "real spikes".  The original .times is kept as .times_spkcdt.
%
%
% Author : Michel Besserve, MPI for Intelligent Systems, MPI for Biological Cybernetics, Tuebingen, GERMANY

if nargin < 1,  eval(['help ' mfilename]); return;  end


if isfield(varargin{1},'times') && isfield(varargin{1},'dt')
  % called like spkselect(Spkt,...)
  iOpt = 2;
  Spkt = varargin{1};
else
  % called like spkselect(Ses,ExpNo,...)
  iOpt = 3;
  Ses = getses(varargin{1});
  ExpNo = varargin{2};
  Spkt = sigload(Ses,ExpNo,'Spkt');
end


highPassFreq  =  800;
ampPercentile = .05;
powratio      = 3;
SPKWIN_MS     = [-1.5 1.5];
Cln           = [];
UPDATE_DAT    = 1;
VERBOSE       = 0;

for karg=iOpt:2:length(varargin)
  switch lower(varargin{karg})
   case 'highpassfreq'
    highPassFreq=varargin{karg+1};
   case 'amppercentile'
    ampPercentile=varargin{karg+1};
   case 'powratio'
    powratio=varargin{karg+1};
   case 'spkwin_ms'
    SPKWIN_MS=varargin{karg+1};
   case {'cln' 'clnhp' 'clnhighpass'}
    Cln = varargin{karg+1};
   case {'updatedat' 'update_dat'}
    UPDATE_DAT = varargin{karg+1};
   case {'verbose'}
    VERBOSE = varargin{karg+1};
   otherwise
    error('unknown input argument n %d')
  end
end


if isfield(Spkt,'times_spkcdt'),
  % get back the original one.
  Spkt.times = Spkt.times_spkcdt;
else
  % first time to run, keep the original for the next time.
  Spkt.times_spkcdt = Spkt.times;
end


if VERBOSE,
  fprintf(' %s:',mfilename);
end


if isempty(Cln),
  if VERBOSE, fprintf(' loading(Cln).');  end
  Cln = sigload(Spkt.session,Spkt.ExpNo(1),'Cln');
  if VERBOSE, fprintf(' highpass[%gHz].',highPassFreq);  end
  Cln = sigfiltfilt(Cln,highPassFreq,'high');
end


% converts .times in points of Cln.dx
if Cln.dx ~= Spkt.dt,
  for iCh = 1:length(Spkt.times),
    Spkt.times{iCh} = round(Spkt.times{iCh}*Spkt.dt/Cln.dx);
  end
end


if VERBOSE,
  fprintf(' select(ampPercentile=%g%% powratio=%g).',ampPercentile*100,powratio);
end

spkwin = round(SPKWIN_MS(1)/1000/Spkt.dt):round(SPKWIN_MS(2)/1000/Spkt.dt);
msindex = abs(spkwin*1000*Spkt.dt)<=.5;
%position of the spike in the window
maxInd = find(spkwin==0);

for iCh = 1:length(Spkt.times)
  tmpspk = Spkt.times{iCh};
  if length(tmpspk)*ampPercentile < 1,  continue;  end
  
  
  tmpspk = tmpspk(tmpspk + spkwin(1) > 0 & tmpspk + spkwin(end) <= size(Cln.dat,1));
  
  spkseg = zeros(length(spkwin),length(tmpspk));
  for iSpk = 1:length(tmpspk),
    spkseg(:,iSpk) = Cln.dat(spkwin+tmpspk(iSpk),iCh);
  end

  power=[mean(spkseg(msindex,:).^2); mean(spkseg(~msindex,:).^2)];
  sortpick=sort(spkseg(maxInd,:));
  try
  %selection according to Amplitude criterion
  selAmp=(spkseg(maxInd,:)<sortpick(floor((1-ampPercentile)*length(sortpick))))...
         & (spkseg(maxInd,:)>sortpick(floor((ampPercentile)*length(sortpick))));
  catch
    keyboard
  end
  
  %selection according to Power ration criterion
  selPow=(power(1,:)./power(2,:))>powratio;
  %Spkt.denoise{iCh,1}=selAmp & selPow;
  
  Spkt.times{iCh} = tmpspk(selAmp & selPow);

end



% converts back .times in points of Spkt.dt
if Cln.dx ~= Spkt.dt,
  for iCh = 1:length(Spkt.times),
    Spkt.times{iCh} = round(Spkt.times{iCh}*Cln.dx/Spkt.dt);
  end
end


if any(UPDATE_DAT)
  fprintf(' update(.dat).');
  
  BINWIDTH = Spkt.siggetspk.binwidth;
  
  % this should work for all including catexps where adf screwed up...
  EDGES = 0:BINWIDTH:(Spkt.duration*Spkt.dt + BINWIDTH/2);  % in sec
  EDGES = EDGES/Spkt.dt;  % in points
  NBINS = length(EDGES);

  Spkt.dat = zeros(length(EDGES),size(Spkt.times,1),size(Spkt.times,2));
  for iChan = 1:size(Spkt.times,1),
    for iObsp = 1:size(Spkt.times,2),
      % 22.12.04 YM: simple use of hist with NBINS will not give correct histgram.
      %[n,x] = hist(Spkt.times{iChan,iObsp},NBINS);
      if isempty(Spkt.times{iChan,iObsp}),  continue;  end
      n = histc(Spkt.times{iChan,iObsp},EDGES);
      Spkt.dat(:,iChan,iObsp) = n;
    end
  end
  
  Spkt.dx			= (EDGES(2)-EDGES(1))*Spkt.dt;
  if isfield(Cln,'dxorg'),
    Spkt.dxorg = Spkt.dx / Cln.dx * Cln.dxorg;
  end
end




if VERBOSE,  fprintf(' done.\n');  end

return
