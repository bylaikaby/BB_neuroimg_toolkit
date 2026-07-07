function [Lfp, Mua] = atgetlfpmuaflt(SESSION,ExpNo,SigName)
%ATGETLFPMUAFLT - Extract LFP/MUA by bandpass filtering
% GETLFPMUALFT(SESSION,ExpNo) Extract LFP/MUA the "old" way:
% Bandpass filter, rectify, lowpass filter, and resample
% See getses for ranges!
%
% VERSION : 1.00 NKL, 28.04.03
%           1.01 YM,  19.09.03 improved memory usage.
%
% See also GETLFPMUALFT SESSIGPOW SESGETLFPMUALFT

if nargin < 3,
  SigName == 'all';
end;

if strcmp(SigName,'all'),
  DOSIG = 0;
elseif strcmp(SigName,'lfp'),
  DOSIG = 1;
elseif strcmp(SigName,'mua'),
  DOSIG = 2;
else
  error('SigName can be all/lfp/mua');
end;

if nargin < 2,
	error('usage: getlfpmualft(SESSION,ExpNo)');
end;

Ses = goto(SESSION);				% Goto appropr. directory call hgetses

tic;

if isfield(Ses,'frband'),
  bands = Ses.frband;
else
  bands = Ses.anap.bands;
end;

fprintf(' atgetlfpmuaflt: Lfp[%d-%d], Mua[%d-%d], CF=%d, LFPCF=%d, Resamp=%dHz\n',...
        bands.lfpflt(1),bands.lfpflt(2),...
        bands.muaflt(1),bands.muaflt(2),...
        bands.cutoff, bands.lfpcutoff, bands.samprate);


clnfile = catfilename(Ses,ExpNo,'mat');
matfile = catfilename(Ses,ExpNo,'mat');
fprintf('  %s: Reading ''Cln'' from ''%s''...',gettimestring,clnfile);
Cln = sesgetsig( Ses, ExpNo,'Cln');
fprintf(' done.\n');

if ~DOSIG | DOSIG==1,
  fprintf('  %s: Extracting LFPs...', gettimestring);
  ARGS = {'color';'r';'linestyle';'-';'linewidth';0.6};
  if length(Cln) == 1,
	%Lfp = DoFilter(Cln,bands.lfpflt,'Lfp',ARGS);
	%Lfp = DoDecimate(Lfp, bands);
	Lfp = DoFilterAndDecimate(Cln,'Lfp',bands,ARGS);
	Lfp = tosdu(Lfp);
  else
	for N=1:length(Cln),
	  %Lfp{N} = DoFilter(Cln{N},bands.lfpflt,'Lfp',ARGS);
	  %Lfp{N} = DoDecimate(Lfp{N}, bands);
	  Lfp{N} = DoFilterAndDecimate(Cln{N},'Lfp',bands,ARGS);
	  Lfp{N} = tosdu(Lfp{N});
	end;
  end;
  if nargout == 0,
    fprintf(' adding to ''%s''...',matfile);
    if ~exist(matfile,'-file'),
      save(matfile,'Lfp');
    else
      save(matfile,'-append','Lfp');
    end
	clear Lfp;
  end
  fprintf('done.\n');
end;
if nargout == 1,  return;  end  % no need to compute MUA.

if ~DOSIG | DOSIG==2,
  fprintf('  %s: Extracting MUAs...', gettimestring);
  ARGS = {'color';'k';'linestyle';'-';'linewidth';0.6};
  if length(Cln) == 1,
	%Mua = DoFilter(Cln,bands.muaflt,'Mua',ARGS);
	%Mua = DoDecimate(Mua, bands);
	Mua = DoFilterAndDecimate(Cln,'Mua',bands,ARGS);
	Mua = tosdu(Mua);
  else
	for N=1:length(Cln),
	  %Mua{N} = DoFilter(Cln{N},bands.muaflt,'Mua',ARGS);
	  %Mua{N} = DoDecimate(Mua{N}, bands);
	  Mua{N} = DoFilterAndDecimate(Cln{N},'Mua',bands,ARGS);
	  Mua{N} = tosdu(Mua{N});
	end;
  end;
  clear Cln;
  if nargout == 0,
	fprintf(' adding to ''%s''...',matfile);
    if ~exist(matfile,'-file'),
      save(matfile,'Mua');
    else
      save(matfile,'-append','Mua');
    end
	clear Mua;
  end;
  fprintf('done.\n');
end;
time=toc;
fprintf('Elapsed time %5.2f minutes\n',time/60);
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS FUNCTION WILL SAVE MEMORY
function oSig = DoFilterAndDecimate(Cln,name,bands,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter & Rectify
Fs = 1.0 / Cln.dx;
Nyq = Fs/2;
switch name,
 case { 'LFP', 'Lfp', 'lfp' }
  range = bands.lfpflt;
  cutoff = bands.lfpcutoff;
 case { 'MUA', 'Mua', 'mua' }
  range = bands.muaflt;
  cutoff = bands.cutoff;
 otherwise
  fprintf('atgetlfpmuaflt: invalid freq-bands\n');
  keyboard;
end
[b,a] = butter(4, range/Nyq, 'bandpass');

for ObspNo=size(Cln.dat,3):-1:1,
  for ChanNo=size(Cln.dat,2):-1:1,
    Cln.dat(:,ChanNo,ObspNo)=abs(filtfilt(b,a,Cln.dat(:,ChanNo,ObspNo)));
  end;
end;
Cln.dir.dname = name;
Cln.range = range;
Cln.dsp.args = ARGS;

% Lowpass Filter
[b,a] = butter(4, cutoff/Nyq, 'low');
for ObspNo=size(Cln.dat,3):-1:1,
  for ChanNo=size(Cln.dat,2):-1:1,
	Cln.dat(:,ChanNo,ObspNo)= filtfilt(b,a,Cln.dat(:,ChanNo,ObspNo));
  end;
end;

% now decimate and make 'oSig'.
fac = round(Fs/bands.samprate);
oSig = Cln;
oSig.dat = [];
oSig.dx = Cln.dx * fac;
for ObspNo=size(Cln.dat,3):-1:1,
  for ChanNo=size(Cln.dat,2):-1:1,
    oSig.dat(:,ChanNo,ObspNo)=decimate(Cln.dat(:,ChanNo,ObspNo),fac);
  end;
end;

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Cln = DoFilter(Cln,range,name,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter & Rectify
%%%%%%%%%%%%%%%%%%%%%%%%%%%
Fs = 1.0 / Cln.dx;
Nyq = Fs/2;
[b,a] = butter(4, range/Nyq, 'bandpass');
for ObspNo=1:size(Cln.dat,3),
  for ChanNo=1:size(Cln.dat,2),
    Cln.dat(:,ChanNo,ObspNo)=abs(filtfilt(b,a,Cln.dat(:,ChanNo,ObspNo)));
  end;
end;
Cln.dir.dname = name;
Cln.range = range;
Cln.dsp.args = ARGS;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoDecimate(Sig,bands)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lowpass Filter & resample
%%%%%%%%%%%%%%%%%%%%%%%%%%%
Fs = 1.0 / Sig.dx;
Nyq = Fs/2;
[b,a] = butter(4, bands.cutoff/Nyq, 'low');
for ObspNo=size(Sig.dat,3):-1:1,
  for ChanNo=size(Sig.dat,2):-1:1,
    tmpw = filtfilt(b,a,Sig.dat(:,ChanNo,ObspNo));;
    Sig.dat(:,ChanNo,ObspNo)= tmpw(:);
  end;
end;
clear tmpw;

fac = round(Fs/bands.samprate);
oSig = Sig;
oSig.dat = [];
oSig.dx = Sig.dx * fac;

for ObspNo=size(Sig.dat,3):-1:1,
  for ChanNo=size(Sig.dat,2):-1:1,
    oSig.dat(:,ChanNo,ObspNo)=decimate(Sig.dat(:,ChanNo,ObspNo),fac);
  end;
end;




