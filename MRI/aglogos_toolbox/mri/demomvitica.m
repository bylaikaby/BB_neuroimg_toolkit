function mvitica(SESSION,ExpNo,SigName,DoPlot)
%DEMOMVITICA - Removal of resp artifacts by detecting independent sources
% MVITICA Compute the demixing matrix by using a 2nd order
% method like that of Molgedey and Schuster. The algorithm is
% called AMUSE, and it's faster than flexICA or erica.
RESPLIM1 = 0.38;
RESPLIM2 = 0.44;

if ~nargin,
  SESSION = 'g02mn1';
  ExpNo = 6;
  SigName = 'Pts';
  DoPlot = 1;
end;

if nargin & nargin < 4,
  DoPlot=1;
end;

if nargin & nargin < 3,
  SigName = 'Pts';
end;

if nargin & nargin < 2,
  error('usage: mvitica(SESSION,ExpNo,"DoPlot"\n');
end;

Ses = goto(SESSION);
filename = catfilename(Ses,ExpNo,'mat');
sname = who(SigName,'-file',filename);

if isempty(sname),
  fprintf('mvitica(WARNING): No %s in file %s\n',SigName,filename);
  return;
end;

icasig = matsigload(filename, SigName);
if 0,
for K=1:length(icasig),
  icasig{K} = tosdu(icasig{K});
end;
end;

if DoPlot,				% Keep for demo purpose
  Sig = icasig{1};
end;

for SliceNo = 1:length(icasig),

  if ~isempty(icasig{SliceNo}.dat),
	
	% COMPUTE DEMIXING MATRIX
	W = amuse(icasig{SliceNo}.dat');
	
	% USE IT TO GENERATE THE INDEPENDENT SOURCES
	demixedSources = W * icasig{SliceNo}.dat';
	
	% GET THE SPECTRA OF THE INDEPENDENT SOURCES
	tmpSig = rmfield(icasig{SliceNo},'dat');
	tmpSig.dat = demixedSources';
	[famp,fang,freq] = msigfft(tmpSig);
	
	% FIND THE INDEPENDENT SOURCE WHOSE SPECTRUM HAS A MAX IN RESPFREQ
	ix = find(freq>RESPLIM1 & freq < RESPLIM2);
	
	% WE SEARCH.. ALTHOUGH IT SEEMS THAT THE ALGORITHM IS RETURNING
	% THE MOST 'INDEPENDENT SOURCE AS FIRST COMPONENT
	for N=1:size(famp,2),
	  tmp(N) = max(famp(ix,N));
	end;
	
%	[maxtmp,k] = max(tmp);
	[stmp,six]=sort(tmp);

    NoComp = 2;
    SIX = six(end-NoComp+1:end);
	if DoPlot,
	  RespSigFft = mean(famp(:,SIX),2);
	end;
	RespSig = tmpSig.dat(:,SIX);
	
	% NO SET THE VECTOR WITH THE MAX-RESPFREQ TO ZERO
	tmp = demixedSources';
	tmp(:,SIX) = zeros(size(tmp,1),NoComp);
	
	% AND RECONSTRUCT THE SIGNAL WITHOUT THE RESP-ARTIFACT
	icasig{SliceNo}.dat = (inv(W) * tmp')';
	
	clear tmp, tmpSig;
  else
	icasig{SliceNo}.dat = icasig{SliceNo}.dat;
  end;
end;

if ~DoPlot,		% Real case...
  % SAVE THE DATA WITH A DIFFERENT NAME INTO THE SAME FILE
  name = sprintf('ica%s',SigName);
  eval(sprintf('%s=icasig;',name));
  save(filename,'-append',name);
  fprintf('mvitica: Saved Signal %s in file %s\n',...
		  name, filename);
else
  % DEMO THE RESULTS
  mfigure([100 100 800 600],sprintf('Session: %s, ExpNo: %d',Ses.name,ExpNo));
  % ORIGINAL DATA
  subplot(2,2,1);
  msigfft(Sig);
  set(gca,'xscale','linear');
  xlabel('Frequency in Hz');
  title('Spectra Power of Original Data');

  % CORRECTED DATA
  subplot(2,2,2);
  ARGS.COLOR='r';
  ARGS.WIDTH=1;
  msigfft(icasig{1},ARGS);
  set(gca,'xscale','linear');
  xlabel('Frequency in Hz');
  title('Spectra Power of ICA-Cleaned Data');

  % INDEPENDENT SOURCE REPRESENTING RESP-ART
  subplot(2,2,3);
  plot([0:size(Sig.dat,1)-1]*Sig.dx,RespSig);
  set(gca,'xlim',[100 180]);
  xlabel('Time in seconds');
  title('Independent Component Reflecting Respiration');
  
  % ITS SPECTRUM
  subplot(2,2,4);
  plot(freq,RespSigFft);
  xlabel('Frequency in Hz');
  title('Sectrum of IC Reflecting Respiration');
end;

