function varargout = getbandsflt(SESSION,ExpNo,SigNames)
%GETBANDSFLT - Extract Gamma/Lfp/Mua/LfpLHM by bandpass filtering
% GETBANDSFLT(SESSION,ExpNo) Extract signals the "old" way:
% Bandpass filter, rectify, lowpass filter, and resample
% See getses for ranges!
%
% SIGNALS : Gamma, Lfp, Mua, LfpL, LfpM, LfpH
% USAGE   : getbandsflt(SESSION,ExpNo,{})
%           [Gamma, Lfp] = getbandsflt(SESSION,ExpNo,{'Gamma','Lfp'})
% VERSION : 1.00 NKL, 28.04.03
%           1.01 YM,  19.09.03 improved memory usage.
%			2.00 NKL, 09.10.03
%			2.01 YM,  05.02.04 adds 'SigNames' for clean-up many codes.
%			2.02 YM,  01.03.04 improved memory usage again.
%			2.03 YM,  08.05.05 bugfix for getrf.m/siggetrf.m.
%			2.04 YM,  16.08.05 supports ses.anap.bands.conv2sdu.
%
% NOTES :
%   SDU conversion can be controled by ANAP.bands.conv2sdu in the descripion file.
%
% See also SESGETLFPMUAFLT, GETANAP, GETPOW, GETLFPMUA, SESCLNSPC, TOSDU

SD_CONVERSION = 1;	% This flag can be controled by ANAP.bands.conv2sdu in the description file.

if nargin < 2,
  error('usage: getbandsflt(SESSION,ExpNo,[SigNames])');
end;

% compute all signals if no 'SigNames'.
if nargin < 3 | isempty(SigNames),
  SigNames = {'Gamma', 'Lfp', 'Mua', 'LfpL', 'LfpM', 'LfpH'};
end

% SigNames is given by a string.
if ischar(SigNames),  SigNames = { SigNames };  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);		% Goto appropr. directory call getses
par = expgetpar(Ses,ExpNo);
bands = Ses.anap.bands;
if isfield(Ses.anap.bands,'conv2sdu') & ~isempty(Ses.anap.bands.conv2sdu),
  SD_CONVERSION = Ses.anap.bands.conv2sdu;
end

fprintf(' %s: SD_CONV=%d %s',gettimestring,SD_CONVERSION,SigNames{1});
for N = 2:length(SigNames),  fprintf(' %s',SigNames{N});  end
fprintf(' :');

tic;
matfile = catfilename(Ses,ExpNo,'mat');
fprintf(' Reading ''Cln''...',gettimestring);
Cln = sesgetsig(Ses, ExpNo,'Cln');
% Cln = sigload(Ses,ExpNo,'Cln');
if isfield(Cln,'evt'),  Cln = rmfield(Cln,'evt');  end
if isfield(Cln,'grp'),  Cln = rmfield(Cln,'grp');  end
%if isfield(Cln,'stm'),  Cln = rmfield(Cln,'stm');  end
Cln.stm = par.stm;
Cln.usr = {};

fprintf(' done.\n');

% FLAG FOR FURTHER DECIMATION, automatically updated/seen below.
CLN_DECIMATED = 0;  % required for Lfp/Gamma/LfpLMH
% FUNCTION FOR SDU CONVERSION


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXTRACT uMUA unrectified MUA
%% MUST BE COMPUTED FIRST, WITHOUT FURTHER DECIMATION OF 'CLN'.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp(SigNames,'uMua')),
  fprintf(' %s: uMua[%d-%d], CF=%dHz, Resamp=%dHz\n', gettimestring, ...
          bands.Mua(1),bands.Mua(2),bands.muacutoff, bands.samprate);
  ARGS = {'color';'k';'linestyle';'-';'linewidth';0.6};
  if length(Cln) == 1,
    uMua = DoFilterRectifyAndDecimate(Cln,'uMua',bands,ARGS);
    if SD_CONVERSION & ~isempty(uMua.stm.v),
      uMua = tosdu(uMua);
    end
  else
    for N=1:length(Cln),
      uMua{N} = DoFilterRectifyAndDecimate(Cln{N},'uMua',bands,ARGS);
      if SD_CONVERSION & ~isempty(uMua{N}.stm.v),
        uMua{N} = tosdu(uMua{N});
      end
    end;
  end;
  if nargout == 0,
    if length(uMua) == 1,
      if ~isempty(uMua.stm.v),
        uMua = rmfield(uMua,'stm');
      end
    else
    for N=1:length(uMua),
      if ~isempty(uMua{N}.stm.v),
        uMua{N} = rmfield(uMua{N},'stm');
      end
    end;
    end
    fprintf(' %s: Appending uMua to ''%s''...',gettimestring,matfile);
    if ~exist(matfile,'file'),
      save(matfile,'uMua');
    else
      save(matfile,'-append','uMua');
    end 
    clear uMua;
  end
  fprintf('done.\n');
  pack;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXTRACT MUA
%% MUST BE COMPUTED FIRST, WITHOUT FURTHER DECIMATION OF 'CLN'.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp(SigNames,'Mua')),
  fprintf(' %s: Mua[%d-%d], CF=%dHz, Resamp=%dHz\n', gettimestring, ...
          bands.Mua(1),bands.Mua(2),bands.muacutoff, bands.samprate);
  ARGS = {'color';'k';'linestyle';'-';'linewidth';0.6};
  if length(Cln) == 1,
    Mua = DoFilterRectifyAndDecimate(Cln,'Mua',bands,ARGS);
    if SD_CONVERSION & ~isempty(Mua.stm.v),
      Mua = tosdu(Mua);
    end
  else
    for N=1:length(Cln),
      Mua{N} = DoFilterRectifyAndDecimate(Cln{N},'Mua',bands,ARGS);
      if SD_CONVERSION & ~isempty(Mua{N}.stm.v),
        Mua{N} = tosdu(Mua{N});
      end
    end;
  end;
  if nargout == 0,
    if length(Mua) == 1,
      if ~isempty(Mua.stm.v),
        Mua = rmfield(Mua,'stm');
      end
    else
      for N=1:length(Mua),
        if ~isempty(Mua{N}.stm.v),
          Mua{N} = rmfield(Mua{N},'stm');
        end
      end;
    end
    fprintf(' %s: Appending Mua to ''%s''...',gettimestring,matfile);
    if ~exist(matfile,'file'),
      save(matfile,'Mua');
    else
      save(matfile,'-append','Mua');
    end
    clear Mua;
  end
  fprintf('done.\n');

  pack;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXTRACTING LFP/Gamma
%% 'CLN' WILL BE PRE-FILTERED.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp(SigNames,'Lfp')) | any(strcmp(SigNames,'Gamma')),
  if any(strcmp(SigNames,'Gamma')), DO_GAMMA = 1; else DO_GAMMA = 0;  end
  % REDUCE BANDWIDTH TO AVOID FILTER PROBLEMS
  if bands.Lfp(2) < 300,
    if ~CLN_DECIMATED,
      fprintf(' decimating...');
      fac = round((1/Cln.dx)/(2*bands.samprate));			% prefiltering
      Cln = sigdecimate(Cln,fac);
      CLN_DECIMATED = 1;
    end
  end
  
  ARGS = {'color';'r';'linestyle';'-';'linewidth';0.6};
  
  
  if length(Cln) == 1,
    fprintf(' %s:', gettimestring);
    fprintf(' Lfp[%d-%d]...', bands.Lfp(1),bands.Lfp(2));
    Lfp = DoFilterAndDecimate(Cln,bands,ARGS);
    if DO_GAMMA,
      fprintf(' Gamma[%d-%d]...', bands.Gamma(1),bands.Gamma(2));
      Gamma = DoFilterHP(Lfp,bands.Gamma);
      if SD_CONVERSION & ~isempty(Gamma.stm.v),
        Gamma = tosdu(Gamma);
      end;
    end
    if SD_CONVERSION & ~isempty(Lfp.stm.v),
      Lfp = tosdu(Lfp);
    end;
    fprintf(' done.\n');
  else
    for N=1:length(Cln),
      fprintf(' %s:', gettimestring);
      fprintf(' Lfp[%d-%d]...', bands.Lfp(1),bands.Lfp(2));
      Lfp{N} = DoFilterAndDecimate(Cln{N},bands,ARGS);
      if DO_GAMMA,
        fprintf(' Gamma[%d-%d]...', bands.Gamma(1),bands.Gamma(2));
        Gamma{N} = DoFilterHP(Lfp{N},bands.Gamma);
        if SD_CONVERSION & ~isempty(Gamma{N}.stm.v),
          Gamma{N} = tosdu(Gamma{N});
        end;
      end
      if SD_CONVERSION & ~isempty(Lfp{N}.stm.v),
        Lfp{N} = tosdu(Lfp{N});
      end;
      fprintf(' done.\n');
    end;
  end;
  if nargout == 0,
    if length(Lfp) == 1,
      if DO_GAMMA & ~isempty(Gamma.stm.v),
        Gamma = rmfield(Gamma,'stm');
      end;
      if ~isempty(Lfp.stm.v),
        Lfp = rmfield(Lfp,'stm');
      end
    else
      for N=1:length(Lfp),
        if DO_GAMMA & ~isempty(Gamma{N}.stm.v),
          Gamma{N} = rmfield(Gamma{N},'stm');
        end
        if ~isempty(Lfp{N}.stm.v),
          Lfp{N} = rmfield(Lfp{N},'stm');
        end
      end
    end
    if DO_GAMMA
      fprintf(' %s: Appending Lfp/Gamma to ''%s''...',gettimestring,matfile);
      if ~exist(matfile,'file'),
        save(matfile,'Lfp','Gamma');
      else
        save(matfile,'-append','Lfp','Gamma');
      end
      clear Lfp Gamma;
    else
      fprintf(' %s: Appending Lfp to ''%s''...',gettimestring,matfile);
      %Lfpwide = Lfp;
      if ~exist(matfile,'file'),
        save(matfile,'Lfp');
      else
        save(matfile,'-append','Lfp');
      end
      clear Lfp;
    end
  end

  if ~CLN_DECIMATED,
    fac = round((1/Cln.dx)/(2*bands.samprate));			% prefiltering
    Cln = sigdecimate(Cln,fac);
    CLN_DECIMATED = 1;
  end
  
  fprintf(' done.\n');
  pack;
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXTRACTING LfpL, LfpM, LfpH Rectified
%% 'CLN' WILL BE PRE-FILTERED, IF NEEDED.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if any(strcmp(SigNames,'LfpL')) | any(strcmp(SigNames,'LfpM')) ...
      | any(strcmp(SigNames,'LfpH')),
  % REDUCE BANDWIDTH TO AVOID FILTER PROBLEMS
  if ~CLN_DECIMATED,
    fac = round((1/Cln.dx)/(2*bands.samprate));			% prefiltering
    Cln = sigdecimate(Cln,fac);
    CLN_DECIMATED = 1;
  end
  ARGS = {'color';'r';'linestyle';'-';'linewidth';0.8};
  if length(Cln) == 1,
    fprintf(' %s:', gettimestring);
    fprintf(' LfpL[%d-%d]...', bands.LfpL(1),bands.LfpL(2));
    LfpL = DoFilterRectifyAndDecimate(Cln,'LfpL',bands,ARGS);
    fprintf(' LfpM[%d-%d]...', bands.LfpM(1),bands.LfpM(2));
    LfpM = DoFilterRectifyAndDecimate(Cln,'LfpM',bands,ARGS);
    fprintf(' LfpH[%d-%d]...', bands.LfpH(1),bands.LfpH(2));
    LfpH = DoFilterRectifyAndDecimate(Cln,'LfpH',bands,ARGS);
    fprintf(' done.\n');
    clear Cln; pack;
    if SD_CONVERSION & ~isempty(LfpL.stm.v),
      LfpL = tosdu(LfpL);
      LfpM = tosdu(LfpM);
      LfpH = tosdu(LfpH);
    end;
  else
    for N=1:length(Cln),
      fprintf(' %s:', gettimestring);
      fprintf(' LfpL[%d-%d]... ', bands.LfpL(1),bands.LfpL(2));
      LfpL{N} = DoFilterRectifyAndDecimate(Cln{N},'LfpL',bands,ARGS);
      fprintf(' LfpM[%d-%d]... ', bands.LfpM(1),bands.LfpM(2));
      LfpM{N} = DoFilterRectifyAndDecimate(Cln{N},'LfpM',bands,ARGS);
      fprintf(' LfpH[%d-%d]...', bands.LfpH(1),bands.LfpH(2));
      LfpH{N} = DoFilterRectifyAndDecimate(Cln{N},'LfpH',bands,ARGS);
      fprintf(' done.\n');
      Cln{N} = {};
      if SD_CONVERSION & ~isempty(LfpL{N}.stm.v),
        LfpL{N} = tosdu(LfpL{N});
        LfpM{N} = tosdu(LfpM{N});
        LfpH{N} = tosdu(LfpH{N});
      end;
    end;
    clear Cln; pack;
  end;

  if nargout == 0,
    if length(LfpL) == 1,
      if ~isempty(LfpL.stm.v),
        LfpL = rmfield(LfpL,'stm');
        LfpM = rmfield(LfpM,'stm');
        LfpH = rmfield(LfpH,'stm');
      end;
    else
      for N=1:length(LfpL),
        if ~isempty(LfpL{N}.stm.v),
          LfpL{N} = rmfield(LfpL{N},'stm');
          LfpM{N} = rmfield(LfpM{N},'stm');
          LfpH{N} = rmfield(LfpH{N},'stm');
        end;
      end
    end
    fprintf(' %s: Appending LfpL/LfpM/LfpH to ''%s''...',gettimestring,matfile);
    if ~exist(matfile,'file'),
      save(matfile,'LfpL','LfpM','LfpH');
    else
      save(matfile,'-append','LfpL','LfpM','LfpH');
    end
    clear LfpL LfpM LfpH;
  end
  fprintf('done.\n');
end


% set outputs if required.
if nargout > 0,
  for N = 1:nargout,
    if N <= length(SigNames),
      eval(sprintf('varargout{N} = %s;',SigNames{N}));
    else
      varargout{N} = {};
    end
  end
end

time = toc;
fprintf('Elapsed time %5.2f minutes\n',time/60);
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoFilterAndDecimate(Cln,bands,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter & Rectify
Fs = 1.0 / Cln.dx;
Nyq = Fs/2;
range = bands.Lfp;

% Band-pass Filter
if bands.Lfp(1) == 0,
  %fprintf('getbandsflt: lowpass filtering [0-%d]Hz\n',range(2));
  [b,a] = butter(4, range(2)/Nyq, 'low');
else
  [b,a] = butter(4, range/Nyq, 'bandpass');
end;
% Decimation
fac = round(Fs/bands.samprate);

% prepare 'oSig'
oSig = Cln;
oSig.dat = [];
oSig.dx = Cln.dx * fac;
if isfield(Cln,'dxorg'),
  oSig.dxorg = Cln.dxorg * fac;
end
oSig.dir.dname = 'Lfp';
oSig.range = range;
oSig.dsp.args = ARGS;

for ObspNo=size(Cln.dat,3):-1:1,
  for ChanNo=size(Cln.dat,2):-1:1,
    % Band-pass filtering
    tmpdat = filtfilt(b,a,Cln.dat(:,ChanNo,ObspNo));
    % Decimation
    tmpdat = decimate(tmpdat,fac);
    % set oSig.dat
    oSig.dat(:,ChanNo,ObspNo) = tmpdat;
  end;
end;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoFilterRectifyAndDecimate(Cln,signame,bands,ARGS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter & Rectify
Fs = 1.0 / Cln.dx;
Nyq = Fs/2;
RECTIFY = 1;
switch lower(signame),
 case {'lfpl'}
  range = bands.LfpL;
  cutoff = bands.lfpcutoff;
 case {'lfpm'}
  range = bands.LfpM;
  cutoff = bands.lfpcutoff;
 case {'lfph'}
  range = bands.LfpH;
  cutoff = bands.lfpcutoff;
 case {'mua'}
  range = bands.Mua;
  cutoff = bands.muacutoff;
 case {'umua'}
  range = bands.Mua;
  cutoff = bands.muacutoff;
  RECTIFY = 0;
 otherwise
  fprintf('getbandsflt.DoFilterRectifyAndDecimate: invalid freq-bands\n');
  keyboard;
end

% Band-pass Filter
[bB,aB] = butter(4, range/Nyq, 'bandpass');
% Low-pass Filter
[bL,aL] = butter(4, cutoff/Nyq, 'low');
% Decimation
fac = round(Fs/bands.samprate);

% prepare 'oSig'
oSig = Cln;
oSig.dat = [];
oSig.dx = Cln.dx * fac;
if isfield(Cln,'dxorg'),
  oSig.dxorg = Cln.dxorg * fac;
end
oSig.dir.dname = signame;
oSig.range = range;
oSig.dsp.args = ARGS;

for ObspNo=size(Cln.dat,3):-1:1,
  for ChanNo=size(Cln.dat,2):-1:1,
    % Band-pass, and rectification
    if RECTIFY,
      tmpdat = abs(filtfilt(bB,aB,Cln.dat(:,ChanNo,ObspNo)));
    else
      tmpdat = filtfilt(bB,aB,Cln.dat(:,ChanNo,ObspNo));
    end;
    % Low-pass to get envelopes
    tmpdat = filtfilt(bL,aL,tmpdat);
    % Decimation
    tmpdat = decimate(tmpdat,fac);
    % set oSig.dat
    oSig.dat(:,ChanNo,ObspNo) = tmpdat;
  end;
end;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DoFilterHP(Sig,range)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
Fs = 1.0 / Sig.dx;
Nyq = Fs/2;
[b,a] = butter(4, range(1)/Nyq, 'high');
for ObspNo=size(Sig.dat,3):-1:1,
  for ChanNo=size(Sig.dat,2):-1:1,
    Sig.dat(:,ChanNo,ObspNo)=filtfilt(b,a,Sig.dat(:,ChanNo,ObspNo));
  end;
end;

Sig.dir.dname = 'Gamma';
Sig.range = range;
return;
