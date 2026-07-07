function oSig = siggetblp(Sig,USE_FIR,MIRROR_EDGES,iINFO,Demo)
%SIGGETBLP - Separate the Cln signal into freqeuncy bands (10 Bands including the EEG standards)
% OSIG = SIGGETBLP (SIG) splits the singal into sequential frequency bands, very much like a
% spectrogram does, but with high temporal resolution. This function is particularly slow
% because it performs the band separation by bandpass filtering. To ensure minimum
% "filter-induced correlations" between the bands, we use FIR filters of sharp cutoffs.  The
% high-order of such filters, however, requires large kernel-sizes (and thus large number of
% multiplications) so that processing of one Cln signal may last quite long for large
% observation periods.
%
% The SIGGETBLP function corrects for the "oscillations" observed at the two ends of the signal
% (due to the high-order filters) by mirroring these ends, applyling the filtering, and then
% cutting the additional parts off. The unstable portions can be found as "oSig.unstable_sec".
%
% The bands are given below (23.12.2005). Most of them are rectified following the bandpass
% filtering. The rational of rectification is the following. LFPs include synaptic potentials,
% afterpotentials of somato-dendritic spikes, and voltage-gated membrane oscillations, that
% reflect the input of a given cortical areas as well as its local intracortical processing,
% including the activity of excitatory and inhibitory interneurons. In the case of
% oscillations, usually of several Hz, important is the change in their amplitude over time
% rather than their actual timecourse; in the case of synaptic events important is their
% frequency of occurence as well as their superposition. All these events together result into
% continuous voltage-changes of a frequency range of 0-150Hz.
%  
% The time-varying envelope of those frequencies is the measure that correlates best with
% changes in sensory stimulation. If a frequency range marks the activity of a neuronal class
% (e.g. 12Hz membrane oscillations in the deep cortical layers), then changes in the power at
% this frequency indirectly show activity-changes of the corresponding "deep-layer" neurons. In
% the same vein, if a frequency range marks the interaction between groups
% (e.g. gamma-oscillations that reflect the action of interneurons on the projections cells in
% cortex), then increase of the power at that frequency may indicate an increase in the
% excitation-inhibition ballance of cortex; and so on...  In some ways, the story is analogous
% to the well-established AM radio-frequency modulation-demodulation. The carrier identifies
% the source, while the temporal structure of the envelope is the "information" of interest.
%
% The question is how to accurately obtain the modulating function. The magnitude of the
% Hilbert transform of a narrow frequency band is the best and most precise way of doing this;
% however this does not work if the signal has a DC offect (see A. Gretton for discussion). A
% "practical" way of extracting the modulation is to obtain the absolute value of the BLP
% signal, and subsequently filter out the abs-introduced high frequencies. The selection of the
% lowpass filter cutoff can be done on the basis of the formula (max-min)/2. That is for Theta
% (8-4)/2 = 2Hz. A lowpass cuttof with 2Hz eliminates all unnecessary high-frequency of the
% modulating function.
%
% With our BLPs the lowest frequency range (0-4) is slow enough to represent stimulus
% changes and too-slow to be rectified as the optimal frequency of 2Hz would "cut off" the
% usefull 4Hz frequencies as well. This is therefore the only signal that *must* be
% evaluated in its raw form.
%
% All other signals are rectified, each with a different cutoff given in the 4th cell-column
% of the siggetblp.band cell-array below. The LFP (0-90) is provided in a raw-form only for
% analyses computing STAs or STCOVs.
%
% In short, for signal-independence the following signals should be used for analysis:
%       1. Delta
%       2. ThetaR
%       3. Alaph
%       4. Beta
%       5. Gamma
%       6. MUA
%
% Any parameters extracting blp can be modified through the session file.
%   ANAP.siggetblp (GRP.xxx.anap.siggetblp will overwrite default settings).
%
%   ANAP.siggetblp.band{ 1}     = {[   0     4] 'Delta'   'LFP', 0};
%   ANAP.siggetblp.band{ 2}     = {[   4     8] 'Theta'   'LFP', 0};
%   ANAP.siggetblp.band{ 3}     = {[   4     8] 'ThetaR'  'LFP', 2};
%   ANAP.siggetblp.band{ 4}     = {[   8    14] 'Alpha'   'LFP', 3};
%   ANAP.siggetblp.band{ 5}     = {[  14    24] 'Beta'    'LFP', 4};
%   ANAP.siggetblp.band{ 6}     = {[  24    90] 'Gamma'   'LFP', 30};
%   ANAP.siggetblp.band{ 7}     = {[   0    90] 'LFP'     'LFP', 0};
%   ANAP.siggetblp.band{ 8}     = {[   0    90] 'LFPR'    'LFP', 30};
%   ANAP.siggetblp.band{ 9}     = {[  40   130] 'LFPN'    'LFP', 30};
%   ANAP.siggetblp.band{10}     = {[ 400  3000] 'MUA'     'MUA', 30};
%
%   ANAP.siggetblp.lBands       = [1:9];    % Bands in the LFP range
%   ANAP.siggetblp.mBands       = [10];     % Bands in the MUA range
%   ANAP.siggetblp.lcutoff      = 500;      % Before split. LFP region (avoid singularities)
%   ANAP.siggetblp.mcutoff      = 100;      % Before split. MUA region (avoid singularities)
%   ANAP.siggetblp.NewFs        = 250;      % All signals will be resampled at 250Hz
%   ANAP.siggetblp.NewFsTr      = ANAP.siggetblp.NewFs*0.08;
%
%   PARAMETERS FOR THE FIR FILTER
%   ANAP.siggetblp.flttype      = 'cheby2';
%   ANAP.siggetblp.lstop        = 1;
%   ANAP.siggetblp.mstop        = 50;
%   ANAP.siggetblp.hstop        = 50;
%   ANAP.siggetblp.dB           = 60;
%   ANAP.siggetblp.passripple   = 0.1;
%   ANAP.siggetblp.NewFsTr      = 40;       % 60dB decay width for above resampling
%
%   PARAMETERS TO MINIMIZE UNSTABLE PERIODS IN BOTH TIME EDGES
%   ANAP.siggetblp.mirror     = 1;
%
%   SDU conversion
%   ANAP.siggetblp.conv2sdu   = 1;       1:tosdu,2:detrend,3:zerobase, can be char
%  
% EXAMPLE:
%    >> Cln = sigload('a98nm4',10,'Cln');  % loading the fullband signal
%    >> blp = siggetblp(Cln)  ;            % decomposing into several bands with FIR filters
%    >> blpfreqz(blp);                     % Board plots of used filters
%
% See also SESGETBLP EXPSIGGETBLP BLPFREQZ RESAMPLE FILTFILT HILBERT
%
% NKL 29.07.04
% YM  31.08.04  improved memory usage since Matlab7 seems to have memory leaks.
% YM  22.12.04  use decimate() for LFP to make the same time-length of MUA/LFP
% YM  14.02.05  supports FIR filters
% YM  24.11.05  supports the exact way extracting bands developed by Andrei/Arthur.
% YM  25.11.05  returns filter parameters as oSig.filters.
% YM  20.12.05  supports mirroring signal at both time edges to avoid unstable filtering.
% YM  20.12.05  no use of Hilbert transform suggested by Arthur.
% YM  15.01.06  supports iINFO for sesgetblpFIX
% YM  13.02.06  do MUA bands first to avoid memory problems of d01nm5,exp=9

  
if nargin < 1,  help siggetblp; return;  end;

oSig = {};
if nargin < 2,  USE_FIR = [];  end
if nargin < 3,  MIRROR_EDGES = [];  end
if nargin < 4,  iINFO = {};  end


% DEFAULT VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(USE_FIR),       USE_FIR = 1;       end
if isempty(MIRROR_EDGES),  MIRROR_EDGES = 1;  end
USE_ANDREI_FUNCS = 1;
DOPLOT           = 0;

ANDREI_ARTHUR_STEFANO = 1;

if ANDREI_ARTHUR_STEFANO,
  info.band{ 1}  = {[   1     8] 'dethe'    'LFP',  0.5};
  info.band{ 2}  = {[   8    12] 'alpha'  'LFP',  4};
  info.band{ 3}  = {[  12    24] 'nm1'    'LFP',  6};
  info.band{ 4}  = {[  24    40] 'nm2'    'LFP',  8};
  info.band{ 5}  = {[  60   100] 'gamma'  'LFP', 20};
  info.band{ 6}  = {[ 120   250] 'hgamma' 'LFP', 60};
  info.band{ 7}  = {[1000  3000] 'mua'    'MUA', 60};
  info.lBands    = [1:6];            % Bands in the LFP range
  info.mBands    = [7];              % Bands in the MUA range
else  
  info.band{ 1}       = {[   0     4] 'Delta'   'LFP', 0};
  info.band{ 2}       = {[   4     8] 'Theta'   'LFP', 0};
  info.band{ 3}       = {[   4     8] 'ThetaR'  'LFP', 2};
  info.band{ 4}       = {[   8    14] 'Alpha'   'LFP', 3};
  info.band{ 5}       = {[  14    24] 'Beta'    'LFP', 4};
  info.band{ 6}       = {[  24    90] 'Gamma'   'LFP', 30};
  info.band{ 7}       = {[   0    90] 'LFP'     'LFP', 0};
  info.band{ 8}       = {[  90   130] 'LFPH'    'LFP', 30};
  info.band{ 9}       = {[  40   130] 'LFPN'    'LFP', 45};
  info.band{10}       = {[ 400  3000] 'MUA'     'MUA', 45};

  info.lBands     = [1:9];              % Bands in the LFP range
  info.mBands     = [10];              % Bands in the MUA range
end;

info.lcutoff    = 500;      % Before splitting the LFP region (to avoid singularities)
info.mcutoff    = 100;      % Before splitting the MUA region (to avoid singularities)
info.NewFs      = 250;     % All signals will be resampled at 250Hz
info.NewFsTr    = info.NewFs*0.08;

% parameters for FIR filter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info.flttype    = 'kaiser';
info.lstop      = 1;
info.mstop      = 50;
info.hstop      = 50;
info.dB         = 60;
info.passripple = 0.1;

info.NewFsTr    = info.NewFs*0.08;       % 60dB decay width for above resampling
info.LowFs      = 110;      % downsample low freq bands for filter stability
info.LowFsTr    = 10;       % 60dB decay width for low freq downsample

info.lenvelop    = 1;

% parameters to minimize unstable periods in both time edges %%%%%%%%%%%%%%%%
info.mirror     = MIRROR_EDGES;

% SDU conversion
info.conv2sdu   = 1;

% if "Sig" is "info", then return parameters only.
if ischar(Sig) & any(strcmpi(Sig,{'info','anap','default'})),
  oSig = info;
  return;
elseif ~isstruct(Sig),
  fprintf('%s expects a structure (e.g. Cln) as input\n',mfilename);
  return;
end

% if "Sig" is "info", then return parameters only.
if ischar(Sig) & any(strcmpi(Sig,{'info','anap','default'})),
  oSig = info;
  return;
elseif ~isstruct(Sig),
  fprintf('%s expects a structure (e.g. Cln) as input\n',mfilename);
  return;
end

% UPDATE "info" parameters by the session file. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Sig.session);
grp = getgrp(Ses,Sig.ExpNo(1));

% first update by ANAP.siggetblp
if isfield(Ses.anap,'siggetblp') & ~isempty(Ses.anap.siggetblp),
  fnames = fieldnames(Ses.anap.siggetblp);
  for N = 1:length(fnames),
    info.(fnames{N}) = Ses.anap.siggetblp.(fnames{N});
  end
  fprintf('\n%s:Updated params(n=%d) by ANAP.siggetblp.',mfilename,length(fnames));
end

% finally ovewrite by GRP.xxx.siggetblp
if isfield(grp,'anap') & isfield(grp.anap,'siggetblp') & ~isempty(grp.anap.siggetblp),
  fnames = fieldnames(grp.anap.siggetblp);
  for N = 1:length(fnames),
    info.(fnames{N}) = grp.anap.siggetblp.(fnames{N});
  end
  fprintf('\n%s:Updated params(n=%d) by GRP.%s.anap.siggetblp.',mfilename,length(fnames),grp.name);
end

% update info structure by input argument
if exist('iINFO','var') & ~isempty(iINFO),
  fnames = fieldnames(iINFO);
  for N = 1:length(fnames),
    info.(fnames{N}) = iINFO.(fnames{N});
  end
  fprintf('\n%s:Updated params(n=%d) by iINFO',mfilename,length(fnames));
end


if exist('Demo','var'),
  info.envelop = 0;
  DOPLOT=1;
end;


% check very old data having multiple obsp.
OLD_DATA = 0;
if ndims(Sig.dat) == 3,
  % (t,chan,obsp) --> (t,chan*obsp)
  sz = size(Sig.dat);
  Sig.dat = reshape(Sig.dat,[sz(1) prod(sz(2:end))]);
  OLD_DATA = 1;
end



fprintf(' AndreiFuncs=%d...',USE_ANDREI_FUNCS);
if USE_ANDREI_FUNCS > 0,
  % Use FIR fiter develped by Andrei/Arthur.
  [oSig FiltPrms] = subGetBlpAndrei(Sig,info);
else
  % normal signal processing, can be FIR or normal IIR
  [oSig FiltPrms] = subGetBlpNormal(Sig,info, USE_FIR);
end
oSig.filters = FiltPrms;

if isfield(oSig,'dxorg'),
  oSig.dxorg = oSig.dx * Sig.dxorg / Sig.dx;
end

if OLD_DATA > 0,
  sz(1) = size(oSig.dat,1);
  sz(end+1) = size(oSig.dat,3);
  % (t,chan*obsp,band) --> (t,chan,obsp,band)
  oSig.dat = reshape(oSig.dat,sz);
  % (t,chan,obsp,band) --> (t,chan,band) by average
  oSig.dat = mean(oSig.dat,3);
  sz = [sz(1) sz(2) sz(4)];
  oSig.dat = reshape(oSig.dat,sz);
end


if DOPLOT,
  dspblp(oSig);
end;
fprintf('\n');
return;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make "blp" with FIR filtering.
function [oSig FiltPrms] = subGetBlpAndrei(Cln,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = {};  FiltPrms = {};

USE_FIR = 1;

% EXTRACT LFP BANDS
if ~isempty(info.lBands),  fprintf('\n%s:LFP(FIR=%d) ',mfilename, USE_FIR);  end
info.envelop = info.lenvelop;

% Resample before 1Hz cutoff - highly reduce computation time
tSig = resampSig(Cln,info.NewFs,info.NewFsTr,info);
% Restore original LFP
tSig = sublfprestore(tSig,info);
for B=info.lBands,
  [Lfp fprms] = subAndrei_fltlow(tSig,info,B);
  oSig = DoCat(oSig,Lfp);
  FiltPrms{B} = fprms;
  clear Lfp;
end

% 2008.03.10. YM: bug fix on small difference of .dx
% between resamp-lowpass-upsamp and lowpass
if ~isempty(oSig),  oSig.dx = tSig.dx;  end


% NOW EXACTRACT MUA
if ~isempty(info.mBands),  fprintf('\n%s:MUA(FIR=%d) ',mfilename,USE_FIR);  end
info.envelop = 0;
for B=info.mBands,
  band = info.band{B};
  fprintf('BP[%d-%d].',band{1}(1),band{1}(2));

  [Mua,fprms] = subAndrei_filterSig(Cln,info.band{B}{1},info.hstop,info);
  Mua.dat = abs(Mua.dat);
  %[Mua,fprms] = subAndrei_filterSig(Mua,info.NewFs,info.NewFsTr,info);
  % WHY low pass then resample and NOT JUST resample???
  [Mua,fprms] = subAndrei_filterSig(Mua,[0 info.NewFs/2],info.hstop,info);
  Mua         = resampSig(Mua,info.NewFs,info.NewFsTr,info);
  oSig = DoCat(oSig,Mua);
  
  % 2008.03.10. YM: bug fix on small difference of .dx between Lfp and Mua
  if oSig.dx ~= Mua.dx,
    fprintf(' %s.subGetBlpAndrei: dx as Mua.dx...',mfilename);
    oSig.dx = Mua.dx;
  end
  
  FiltPrms{B} = fprms;
  clear Mua;
end
  

oSig.dsp.func   = 'dspblp';
oSig.dir.dname  = 'blp';
oSig.info       = info;
oSig.info.date  = date;
oSig.info.time  = gettimestring;
%oSig.info.func  = dir(which(mfilename));
oSig.filters    = FiltPrms;


% Do normalization if required.
if isnumeric(info.conv2sdu),
  tmpstr = 'none';
  if info.conv2sdu == 1,
    tmpstr = 'tosdu';
  elseif info.conv2sdu == 2,
    tmpstr = 'detrend';
  elseif info.conv2sdu == 3,
    tmpstr = 'zerobase';
  end
  info.conv2sdu = { tmpstr '' };
elseif ischar(info.conv2sdu),
  info.conv2sdu = { info.conv2sdu '' };
end
if ~isempty(info.conv2sdu),
  tmpmethod = info.conv2sdu{1};
  tmpepoch  = '';
  if length(info.conv2sdu) > 1,
    tmpepoch = info.conv2sdu{2};
  end
  if ~isempty(tmpmethod) & ~any(strcmpi({'none','no'},tmpmethod)),
    fprintf(' xform(%s,%s)...',tmpmethod,tmpepoch);
    oSig = xform(oSig,tmpmethod,tmpepoch);
  end
end



return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to make "blp" with normal filtering.
function [oSig FiltPrms] = subGetBlpNormal(Sig,info, USE_FIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = {};  FiltPrms = {};  fprms = [];

DECI = 8;
SAVE_MEMORY = 0;
if numel(Sig.dat)*8 > 768e+6,  SAVE_MEMORY = 1;  end

% DO MUA bands first to avoid memory error of d01nm5/exp9
% NOW EXACTRACT MUA
if ~isempty(info.mBands),
  fprintf('\n%s:MUA(FIR=%d,MIRROR=%d) ',mfilename, USE_FIR, info.mirror);
end
%mSig = Sig;
mSig = DoFilter(Sig,info.mcutoff,'high',[],info,0,SAVE_MEMORY);
if SAVE_MEMORY > 0,
  fprintf('saving temp...');
  DIRS = getdirs;
  TEMPFILE = fullfile(DIRS.TMP,'temp_siggetblp.mat');
  save(TEMPFILE,'Sig');  Sig = [];  pack;
end
SAME_SIG = [];  MUA_SIG = {};
for B=info.mBands,
  band = info.band{B};
  % band pass filtering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('BP[%d-%d].',band{1}(1),band{1}(2));
  if isempty(SAME_SIG),
    [tmp fprms] = DoFilter(mSig,band{1},'bandpass',info.mstop,info,USE_FIR,SAVE_MEMORY);
  else
    fprintf('=');
    tmp = SAME_SIG;
  end
  if B < length(info.band) & all(band{1} == info.band{B+1}{1}),
    SAME_SIG = tmp;
  else
    SAME_SIG = [];
  end

  % resample() requires 'double'...
  if strcmpi(class(tmp.dat),'single'),  tmp.dat = double(tmp.dat);  end
  
  % rectification if needed %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if band{4} > 0,
    % MUA band [400 3000] is too broad to apply Hilbert ransform.
    % It would be appropriate to use the conventional method using abs().

	%fprintf('Hil.');
    %[tmp fprms] = DoFilterHilbert(mSig,band{1},'bandpass',info.NewFs,info.KEEP_PHASE,...
    %                              info.mstop,info,USE_FIR);

    fprintf('Abs.');
    tmp.dat = abs(tmp.dat);
    fw = ceil((band{1}(2) - band{1}(1))/2);  % half width
    if band{4} > fw,
      fprintf('%s WARNING:  RectHz(%.2f) is higher than band pass width(%.2f).!!! ',...
              mfilename,band{4},fw);
    else
      fw = band{4};
    end
    % to match the signal length use resample twice
    %tmp = DoDecimate(tmp,1/tmp.dx/DECI);
    tmp = DoResample(tmp,1/tmp.dx/DECI,info.NewFsTr,info,USE_FIR,SAVE_MEMORY);
    tmp = DoFilter(tmp,[0 fw],'bandpass',info.lstop,info,USE_FIR,SAVE_MEMORY);
    tmp = DoResample(tmp,info.NewFs,info.NewFsTr,info,0);  % USE_FIR=1 takes forever
    %size(tmp.dat), size(oSig.dat)
  else
    % to match the signal length use resample twice
    tmp = DoResample(tmp,1/tmp.dx/DECI,info.NewFsTr,info,USE_FIR);
    tmp = DoResample(tmp,info.NewFs,info.NewFsTr,info,0);  % USE_FIR=1 takes forever
  end;
  %oSig = DoCat(oSig,tmp);
  MUA_SIG{B} = tmp;
  FiltPrms{B} = fprms;
  clear tmp;
end;

clear mSig tmp SAME_SIG;

if SAVE_MEMORY > 0,
  fprintf('loading temp...');
  Sig = load(TEMPFILE);  Sig = Sig.Sig;
  delete(TEMPFILE);
end


% Reduce BandWidth Before Extracting LFPs
fprintf('\n%s:LFP LP[%dHz].',mfilename,info.lcutoff);
lSig = DoFilter(Sig,info.lcutoff,'low',[],info,0,SAVE_MEMORY);
% use decimation to avoid mismatch of time length to MUA
fprintf('DECIM[%.1fHz].',1/lSig.dx/DECI);
lSig = DoDecimate(lSig,1/lSig.dx/DECI);
%fprintf('RESAMP[%dHz].',info.lcutoff*2);
%lSig = DoResample(lSig,info.lcutoff*2);          % It filters, DECIMATES, etc.

if ~isempty(info.lBands),
  fprintf('\n%s:LFP(FIR=%d,MIRROR=%d) ',mfilename, USE_FIR, info.mirror);
end
SAME_SIG = [];
% RESTORE ORIGINAL LFP BY 1Hz HP and INTEGRATE IFF COMBINDED NEURO
% MRI SESSION
ilSig = sublfprestore(lSig,info);
for B=info.lBands,
  band = info.band{B};
  % band pass filtering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('BP[%d-%d].',band{1}(1),band{1}(2));
  if isempty(SAME_SIG),
    [tmp fprms] = DoFilter(ilSig,band{1},'bandpass',info.lstop,info,USE_FIR,SAVE_MEMORY);
  else
    fprintf('=');
    tmp = SAME_SIG;
  end

  if B < length(info.band) & all(band{1} == info.band{B+1}{1}),
    SAME_SIG = tmp;
  else
    SAME_SIG = [];
  end
  
  % resample() requires 'double'...
  if strcmpi(class(tmp.dat),'single'),  tmp.dat = double(tmp.dat);  end

  % do rectification if needed. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if band{4} > 0,
    % Hilbert transform is not appropriate to get envelopes,
    % so do abs() and low-pass the signals.

    %fprintf('Hil.');
    %[tmp fprms] = DoFilterHilbert(lSig,band{1},'bandpass',info.NewFs,info.KEEP_PHASE,...
    %                              info.lstop,info,USE_FIR);

    fprintf('Abs.');
    tmp.dat = abs(tmp.dat);
    fw = ceil((band{1}(2) - band{1}(1))/2);  % half width
    if band{4} > fw,
      fprintf('%s WARNING:  rectHz(%.2f) is higher than band pass width(%.2f).!!! ',...
              mfilename,band{4},fw);
    else
      fw = band{4};
    end
    tmp = DoFilter(tmp,[0 fw],'bandpass',info.lstop,info,USE_FIR,SAVE_MEMORY);
  end;
  
  % resample to designed Fs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  tmp = DoResample(tmp,info.NewFs,info.NewFsTr,info,0);
  oSig = DoCat(oSig,tmp);
  FiltPrms{B} = fprms;
  clear tmp;
end;
clear lSig SAME_SIG tmp;


% NOW APPEND MUA
for B=info.mBands,
  oSig = DoCat(oSig,MUA_SIG{B});
  MUA_SIG{B} = {};
end
clear MUA_SIG;



oSig.dsp.func   = 'dspblp';
oSig.dir.dname  = 'blp';
oSig.info       = info;
oSig.info.date  = date;
oSig.info.time  = gettimestring;
%oSig.info.func  = dir(which(mfilename));
oSig.filters    = FiltPrms;


% gettting information for unstable periods caused by filtering.
f_orderSec = [];
for N = 1:length(oSig.filters),
  f_orderSec(N) = oSig.filters{N}.order/oSig.filters{N}.Fs;
end
f_orderSec = max(f_orderSec);
oSig.unstable_sec = f_orderSec;

if USE_FIR > 0,
  if info.mirror > 0,
    fprintf(' --WARNING: mirrored(%.3fsec)',f_orderSec);
  else
    fprintf(' --WARNING: UNSTABLE PERIODS(%.3fsec)',f_orderSec);
  end
else
end


% Do normalization if required.
if isnumeric(info.conv2sdu),
  tmpstr = 'none';
  if info.conv2sdu == 1,
    tmpstr = 'tosdu';
  elseif info.conv2sdu == 2,
    tmpstr = 'detrend';
  elseif info.conv2sdu == 3,
    tmpstr = 'zerobase';
  end
  info.conv2sdu = { tmpstr '' };
elseif ischar(info.conv2sdu),
  info.conv2sdu = { info.conv2sdu '' };
end
if ~isempty(info.conv2sdu),
  tmpmethod = info.conv2sdu{1};
  tmpepoch  = '';
  if length(info.conv2sdu) > 1,
    tmpepoch = info.conv2sdu{2};
  end
  if ~isempty(tmpmethod) & ~any(strcmpi({'none','no'},tmpmethod)),
    fprintf(' xform(%s,%s)...',tmpmethod,tmpepoch);
    oSig = xform(oSig,tmpmethod,tmpepoch);
  end
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Sig fprms] = DoFilterHilbert(Sig,lim,mode,Fs,KEEP_PHASE,edgeFlt,info,USE_FIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nyq = (1/Sig.dx)/2;
if USE_FIR == 0,
  fname  = 'butter';
  ftype  = mode;;
  forder = 4;
  % USE NORMAL FILTER
  % called like DoFilterHilbert(Sig,lim,mode,Fs,KEEP_PHASE)
  if lim(1) == 0,
    [b,a] = butter(4,lim(2)/nyq,'low'); % for the Delta range!
    %[b,a] = cheby1(8,0.01,lim(2)/nyq,'low');
    ftype  = 'low';
  else
    [b,a] = butter(4,lim/nyq,mode);
    %[b,a] = cheby1(8,0.01,lim/nyq,mode);
  end;
else
  % USE FIR FILTER
  % called like DoFilterHilbert(Sig,lim,mode,Fs,KEEP_PHASE,edgeFlt,info)
  [b,a,fname,ftype,forder] = subDesignFIRFilter(1/Sig.dx,lim,mode,edgeFlt,info);
end


s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
if info.mirror > 0,
  mirror = max([length(b),length(a)]);
  idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
  idxsel = [1:size(Sig.dat,1)] + mirror;
  if KEEP_PHASE,
    for N=size(Sig.dat,2):-1:1,
      datmir = hilbert(filtfilt(b,a,Sig.dt(idxmir,N)));
      sigdat(:,N) = datmir(idxsel);
    end
    Sig.dat = sigdat;
    clear sigdat;
  else
    for N=size(Sig.dat,2):-1:1,
      datmir = abs(hilbert(filtfilt(b,a,Sig.dat(idxmir,N))));
      Sig.dat(:,N) = datmir(idxsel);
    end
  end
  clear datmir idxmir idxsel;
else
  if KEEP_PHASE,
    for N=size(Sig.dat,2):-1:1,
      sigdat(:,N) = hilbert(filtfilt(b,a,Sig.dat(:,N)));
    end
    Sig.dat = sigdat;
    clear sigdat;
  else
    for N=size(Sig.dat,2):-1:1,
      Sig.dat(:,N) = abs(hilbert(filtfilt(b,a,Sig.dat(:,N))));
    end
  end
end
Sig.dat = reshape(Sig.dat,s);


fprms.band  = lim;
fprms.Fs    = 1.0/Sig.dx;
fprms.fname = fname;
fprms.type  = ftype;
fprms.order = forder;
fprms.b     = b;
fprms.a     = a;


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Sig fprms] = DoFilter(Sig,lim,mode,edgeFlt,info,USE_FIR,SAVE_MEMORY)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist('SAVE_MEMORY','var'),  SAVE_MEMORY = 0;  end

nyq = (1/Sig.dx)/2;
if USE_FIR == 0,
  fname  = 'butter';
  ftype  = mode;
  forder = 4;
  % USE NORMAL FILTER
  % called like DoFilter(Sig,lim,mode)
  if lim(1) == 0,
    [b,a] = butter(4,lim(2)/nyq,'low'); % for the Delta range!
    %[b,a] = cheby1(8,0.01,lim(2)/nyq,'low');
    ftype  = 'low';
  else
    [b,a] = butter(4,lim/nyq,mode);
    %[b,a] = cheby1(8,0.01,lim/nyq,mode);
  end;
else
  % USE FIR FILTER
  % called like DoFilter(Sig,lim,mode,edgeFlt,info)
  [b,a,fname,ftype,forder] = subDesignFIRFilter(1/Sig.dx,lim,mode,edgeFlt,info);
end

s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
if USE_FIR, % OPTIMIZED FILTERING
  if info.mirror > 0,
	fprintf('*NEW_FILT*');
	mirror = max([length(b),length(a)]);
	idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
	% JUST TESTING
	%idxsel = [1:size(Sig.dat,1)] + (mirror + round(mirror/2) - 1);
	idxsel = [1:size(Sig.dat,1)] + mirror;
	if SAVE_MEMORY > 0,
	  if strcmpi(class(Sig.dat),'single'),
		for N = size(Sig.dat,2):-1:1,
		  datmir = s_filter(double(Sig.dat(idxmir,N)),b);
		  datmir = datmir(size(datmir,1):-1:1,:);
		  datmir = s_filter(datmir,b);
		  datmir = datmir(size(datmir,1):-1:1,:);
		  Sig.dat(:,N) = single(datmir(idxsel));
		end
	  else
		for N = size(Sig.dat,2):-1:1,
		  datmir = s_filter(Sig.dat(idxmir,N),b);
		  datmir = datmir(size(datmir,1):-1:1,:);
		  datmir = s_filter(datmir,b);
		  datmir = datmir(size(datmir,1):-1:1,:);			  
		  Sig.dat(:,N) = datmir(idxsel);
		end
	  end
	else
	  %datmir = filter(b,a,Sig.dat(idxmir,:));
	  datmir = s_filter(Sig.dat(idxmir,:),b);
	  datmir = datmir(size(datmir,1):-1:1,:);
	  %datmir = filter(b,a,datmir);
	  datmir = s_filter(datmir,b);
	  datmir = datmir(size(datmir,1):-1:1,:);
	  %datmir=[zeros(length(b)-1,size(datmir,2)); datmir];
	  Sig.dat = datmir(idxsel,:);
	end
	clear datmir idxmir idxsel;
  else
	Sig.dat = filtfilt(b,a,Sig.dat);
  end;
else % OLD FILTERING
  if info.mirror > 0,
	fprintf('*OLD_FILT*');
	mirror = max([length(b),length(a)]);
	idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
	idxsel = [1:size(Sig.dat,1)] + mirror;
	if SAVE_MEMORY > 0,
	  if strcmpi(class(Sig.dat),'single'),
		for N = size(Sig.dat,2):-1:1,
		  datmir = filtfilt(b,a,double(Sig.dat(idxmir,N)));
		  Sig.dat(:,N) = single(datmir(idxsel));
		end
	  else
		for N = size(Sig.dat,2):-1:1,
		  datmir = filtfilt(b,a,Sig.dat(idxmir,N));
		  Sig.dat(:,N) = datmir(idxsel);
		end
	  end
	else
	  datmir = filtfilt(b,a,Sig.dat(idxmir,:));
	  Sig.dat = datmir(idxsel,:);
	end
	clear datmir idxmir idxsel;
  else
	Sig.dat = filtfilt(b,a,Sig.dat);
  end;
end;
Sig.dat = reshape(Sig.dat,s);


fprms.band  = lim;
fprms.Fs    = 1.0/Sig.dx;
fprms.fname = fname;
fprms.type  = ftype;
fprms.order = forder;
fprms.b     = b;
fprms.a     = a;

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoDecimate(Sig,NewFs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nyq = (1/Sig.dx)/2;
FRAC = round(1/Sig.dx/NewFs);
s = size(Sig.dat);
oSig = rmfield(Sig,'dat');
oSig.dx = Sig.dx * FRAC;
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
if strcmpi(class(Sig.dat),'single'),
  for N=size(Sig.dat,2):-1:1,
    oSig.dat(:,N) = single(decimate(double(Sig.dat(:,N)),FRAC));
  end;
else
  for N=size(Sig.dat,2):-1:1,
    oSig.dat(:,N) = decimate(Sig.dat(:,N),FRAC);
  end;
end
s(1)=size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,s);

clear Sig;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoResample(Sig,NewFs,NewFsTr,info,USE_FIR,SAVE_MEMORY)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%NOTE: using FIR may cause small rippling at both ends.
%
%We use our own filter here, rather than Matlab's filter for
%resample, as Matlab's filter has only 6dB attenuation at the new
%Nyquist frequency, which could cause a small amount of
%aliasing. Our method results in 60dB attenuation at the new
%Nyquist frequency. In addition our filter stipulates a flat (to
%within 0.1dB) response up to 125Hz, which is the highest freq band
%for which we use the signals with 310Hz resampling.

if ~exist('SAVE_MEMORY','var'),  SAVE_MEMORY = 0;  end
  
oSig = rmfield(Sig,'dat');

oSig.dx = 1/NewFs;
[p,q] = rat(Sig.dx/oSig.dx,0.0001);
oSig.dx = Sig.dx*q/p;  %26.02.08 YM this must be correct, but keep as it was...

%nyq = (1/Sig.dx)/2;
if USE_FIR > 0,
  % called like DoResample(Sig,NewFs,NewFsTr,info,1)
  transband = NewFsTr; %transition width from passband to stopband
  fsamp = p/Sig.dx;  %note: freq of UPSAMPLED signal!
  fcuts = [NewFs/2-transband NewFs/2]; %we want cutoff to start transband before nyquist
  mags = [1 0];
  devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  %offset due to filtering in sec
  if isfield(oSig,'fltcutoff'),
    oSig.fltcutoff = oSig.fltcutoff+length(b)/fsamp; 
  else
    oSig.fltcutoff = length(b)/fsamp; 
  end;
end


s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
if USE_FIR > 0,
  if info.mirror > 0,
    pqmax = max(p,q);
    siglen = length(resample(double(Sig.dat(:,1)),p,q,b));

    mirror = ceil(length(b)/pqmax)*pqmax;
    idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
    idxsel = [1:siglen] + round(mirror*p/q);
    if SAVE_MEMORY > 0,
      for N = size(Sig.dat,2):-1:1,
        datmir = resample(Sig.dat(idxmir,N),p,q,b);
        oSig.dat(:,N) = datmir(idxsel);
      end
    else
      datmir = resample(Sig.dat(idxmir,:),p,q,b);
      oSig.dat = datmir(idxsel,:);
    end
  else
    if SAVE_MEMORY > 0,
      for N = size(Sig.dat,2):-1:1,
        oSig.dat(:,N) = resample(Sig.dat(:,N),p,q,b);
      end
    else
      oSig.dat = resample(Sig.dat,p,q,b);
    end
  end
else
  if info.mirror > 0,
    % NOTE :
    % resample() will use firls with a Kaise window as default.
    % followig code was taken from Matlab's resample() function.
    bta = 5;    N = 10;     pqmax = max(p,q);
    if( N>0 )
      fc = 1/2/pqmax;
      L = 2*N*pqmax + 1;
      h = p*firls( L-1, [0 2*fc 2*fc 1], [1 1 0 0]).*kaiser(L,bta)' ;
      % h = p*fir1( L-1, 2*fc, kaiser(L,bta)) ;
    else
      L = p;
      h = ones(1,p);
    end
    siglen = length(resample(double(Sig.dat(:,1)),p,q));
    
    mirror = ceil(length(h)/pqmax)*pqmax;
    idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
    idxsel = [1:siglen] + round(mirror*p/q);
    if SAVE_MEMORY > 0,
      for N = size(Sig.dat,2):-1:1,
        datmir = resample(Sig.dat(idxmir,N),p,q);
        oSig.dat(:,N) = datmir(idxsel);
      end
    else
      datmir = resample(Sig.dat(idxmir,:),p,q);
      oSig.dat = datmir(idxsel,:);
    end
  else
    if SAVE_MEMORY > 0,
      for N = size(Sig.dat,2):-1:1,
        oSig.dat(:,N) = resample(Sig.dat(:,N),p,q);
      end
    else
      oSig.dat = resample(Sig.dat,p,q);
    end
  end
end

s(1)=size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,s);

clear Sig;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoUpsample(Sig,NewFs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = size(Sig.dat);
oSig = rmfield(Sig,'dat');


oSig.dx = 1/NewFs;
[p,q] = rat(Sig.dx/oSig.dx,0.0001);   %upsampled freq is p/Sig.dx
oSig.dx = Sig.dx*q/p;  %26.02.08 YM this must be correct, but keep as it was...

Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
oSig.dat = resample(Sig.dat,p,q);
s(1)=size(oSig.dat,1);
oSig.dat = reshape(oSig.dat,s);

s = size(Sig.hildat);
Sig.hildat = reshape(Sig.hildat,[s(1) prod(s(2:end))]);
oSig.hildat = resample(Sig.hildat,p,q);
s(1)=size(oSig.hildat,1);
oSig.hildat = reshape(oSig.hildat,s);

clear Sig;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = DoCat(Sig,NewSig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Sig),
  Sig = NewSig;
  return;
end
  
s = size(Sig.dat);
if size(Sig.dat,1)>size(NewSig.dat,1),
  dlen = size(Sig.dat,1) - size(NewSig.dat,1);
  NewSig.dat = cat(1,NewSig.dat,NewSig.dat(1:dlen,:));
elseif size(Sig.dat,1)<size(NewSig.dat,1),
  NewSig.dat = NewSig.dat(1:size(Sig.dat,1),:);
end;
Sig.dat = cat(3,Sig.dat,NewSig.dat);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [b,a,fname,ftype,forder] = subDesignFIRFilter(Fs,lim,mode,edgeFlt,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  fsamp = 1/Sig.dx;
if lim(1) ==  0, % for the Delta range
  mode = 'low';
end
  
switch lower(mode),
 case {'lowpass','lp','low'}
  if lim(1) == 0,
    fcuts = [lim(2) (lim(2)+edgeFlt)];
  else
    fcuts = [lim(1) (lim(1)+edgeFlt)];
  end
  mags = [1 0];
  devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;
 case {'highpass','hp','high'}
  if (lim(1)-edgeFlt)<0,
	edgeFlt=lim(1);
  end;
  fcuts = [lim(1)-edgeFlt lim(1)];
  mags = [0 1];
  devs = [10^(-info.dB/20) abs(1-10^(info.passripple/20))];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1; 
 case {'bandpass','bp','band'}
  if (lim(1)-edgeFlt)<0,
	edgeFlt=lim(1);
  end;
  fcuts = [(lim(1)-edgeFlt) lim(1) lim(2) (lim(2)+edgeFlt)];
  mags = [0 1 0];
  devs = [10^(-info.dB/20)  abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;
end

fname  = 'fir1-kaiser';
%ftype = ..., % given by above kaiserord().
forder = n;

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION for subAndrei_fltlow, copied from fltlow.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Lfp fprms] = subAndrei_fltlow(tSig,info,B)
fprintf('BP[%d-%dHz].',info.band{B}{1}(1),info.band{B}{1}(2));
if info.band{B}{1}(2)< info.LowFs/2,
  Lfp = resampSig(tSig,info.LowFs,info.LowFsTr,info);
  [Lfp, fprms] = subAndrei_filterSig(Lfp,info.band{B}{1},info.lstop,info);
  if info.envelop
    Lfp.dat = abs(hilbert(Lfp.dat));
  end;
  Lfp = upsampSig(Lfp,info.NewFs);
else
  [Lfp,fprms] = subAndrei_filterSig(tSig,info.band{B}{1},info.lstop,info);
  if info.envelop
    Lfp.dat = abs(hilbert(Lfp.dat));
  end;
end;
%Lfp = windowSig(Lfp);
%tmp.dat = tmp.dat(getStimIndices(tmp,'stim',0,0),:);
%tmp.dat = sigprep(tmp.dat,'cr',order);

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION for subGetBlpAndrei, copied from filterSig.m
function [Sig,fprms] = subAndrei_filterSig(Sig,lim,fltedge,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% FILTERSIG - filter signal with new defined (10.02.05) FIR filters
nyq = (1/Sig.dx)/2;
if lim(1) == 0, % LOWPASS filtering
  fsamp = 1/Sig.dx;
  fcuts = [lim(2) (lim(2)+fltedge)];
  mags = [1 0];
  devs = [abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;

elseif  (lim(2)+0.5) > nyq, % HIGHPASS filtering
  fsamp = 1/Sig.dx;
  if (lim(1)-fltedge) < 0,
	fltedge = lim(1);
  end;
  fcuts = [lim(1)-fltedge lim(1)];
  mags = [0 1];
  devs = [10^(-info.dB/20) abs(1-10^(info.passripple/20))];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1; 

else % BANDPASS filtering
  if (lim(1)-fltedge) < 0,
	fltedge = lim(1);
  end;
  fsamp = 1/Sig.dx;
  fcuts = [(lim(1)-fltedge) lim(1) lim(2) (lim(2)+fltedge)];
  mags = [0 1 0];
  devs = [10^(-info.dB/20)  abs(1-10^(info.passripple/20)) 10^(-info.dB/20)];
  [n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,fsamp);
  n = n + rem(n,2);
  b = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
  a = 1;
end;

% fltcutoff is the cut length of the signal due to filter artifacts
% at the beginning and end of filtered signal
if isfield(Sig,'fltcutoff'), 
  Sig.fltcutoff = Sig.fltcutoff+length(b)*Sig.dx;
else
  Sig.fltcutoff = length(b)*Sig.dx; 
end;

if info.mirror > 0,
  mirror = max([length(b),length(a)]);
  idxmir = [mirror+1:-1:2 1:size(Sig.dat,1) size(Sig.dat,1)-1:-1:size(Sig.dat,1)-mirror-1];
  idxsel = [1:size(Sig.dat,1)] + mirror;
  datmir = filtfilt(b,a,Sig.dat(idxmir,:));
  Sig.dat = datmir(idxsel,:);
  clear datmir idxmir idxsel;
else
  Sig.dat=filtfilt(b,a,Sig.dat);
end

% filter parameters
fprms.band  = lim;
fprms.Fs    = 1.0/Sig.dx;
fprms.fname = 'fir1-kaiser';
fprms.ftype = ftype;
fprms.order = n;
fprms.b     = b;
fprms.a     = a;

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig=sublfprestore(Sig,info)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  ses=getses(Sig.session);
  fprintf('\n%s:LFP 1Hz HP.',mfilename);
  %oSig = subAndrei_filterSig(Sig,[1 99999],info.lstop,info);
  oSig = DoFilter(Sig,1,'high',info.lstop,info,1,0);
  if isfield(ses.anap,'siggetblp') & isfield(ses.anap.siggetblp,'restore') & ses.anap.siggetblp.restore,
	fprintf('%s:LFP Integrate.',mfilename);
	%fprintf('%s testing high pass filtering',mfilename);
	%oSig = DoFilter(Cln,1,'high',[],info,0);
	oSig = subintegrate(oSig);
  end;
return;
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function Sig=subintegrate(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  fprintf('Integrate.');
  Sig.dat=cumtrapz(Sig.dat);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outdat=s_filter(sigdat,fdat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0,
  ns=size(sigdat,1);
  nchan=size(sigdat,2);
  nfft=2^nextpow2(ns);
  S_fft=fft(sigdat,nfft);
  clear sigdat;
  F_fft=fft(fdat,nfft);
  % Avoid memory overflow
  %SxF_fft=S_fft.*repmat(F_fft',1,size(sigdat,2));
  for chNo=1:nchan
	SxF_fft(:,chNo)=S_fft(:,chNo).*F_fft';
  end;
  outdat=ifft(SxF_fft,nfft);
  outdat=outdat(1:ns,:);
end;
outdat=fftfilt(fdat',sigdat);
