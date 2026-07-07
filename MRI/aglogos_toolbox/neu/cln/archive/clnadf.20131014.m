function varargout = clnadf(Ses,MriEvt,ObspNo,ChanNo,ANAP,DO_CLEANING)
%CLNADF - Denoise adf data
%	FILENAMES = CLNADF(Ses,ANAP,MriEvt) does the actual cleaning of MRI+Phys Data
%
% NOTES :
%   This function is usually called by CLNMAIN.  The function creates a temporally 
%   file having decimated and cleaned signal.  Cleaning is based on PCA, and PCA is done
%   by each segment/slice basis.  A sequence of cleaning is following.
%      1. prepare PCA-data.
%      2. run PCA (for 'mean' subtracted PCA-data).
%      3. find PCs that correlates with 'mean' of PCA-data.
%      4. subtracts 'mean' noise and correlated PCs from PCA-data.
%      5. adjust gaps between edges of PCA-data, if required.
%      6. decimation, if required.
%
% VERSION :	
%   1.00 03.08.05 YM  derived from clnadf.m of NKL.
%   1.01 15.08.05 YM  supports saving gradient noise too, checks gaps.
%   1.02 15.08.05 YM  bug fix of PREPCA, plot figures;
%   1.03 08.12.05 YM  modified to save PCA data for axel's papar.
%   1.04 05.03.08 YM  supports REMOVE_ES
%   1.05 07.10.10 YM  supports DO_CLEANING argument.
%   1.06 11.04.11 YM  supports reading from 2nd adfw.
%   1.07 01.06.11 YM  improved speed, 57s-->24s for 1ch-270s data.
%   1.08 31.01.12 YM  uses exppfilename()/sigfilename()
%   1.10 16.05.13 YM  call decimate() at the end for better cleaning.
%   1.11 16.05.13 YM  use sub_decimate() for the decimation with the higher low-pass filtering.
%   1.12 17.05.13 YM  removes correlated components upto the 5th devivatives.
%   1.13 30.08.13 YM  try to recover below 1Hz.
%   1.14 02.09.13 YM  support REMOVE_ECG, bug fix in DEBUG/plotting.
%   1.15 15.09.13 SE/YM supports x2 faster svds_lansvd() than svds().
%
% See also CLNMAIN, CLNADJEVT, SESGETCLN, SVDS, SVDS_LANSVD

if nargin < 5,  help clnadf; return;  end

if isfield(ANAP,'DEBUG') && ~isempty(ANAP.DEBUG),
  DEBUG = ANAP.DEBUG;
else
  DEBUG = 0;
end

if isfield(ANAP,'PREPCA') && ~isempty(ANAP.PREPCA),
  PREPCA = round(ANAP.PREPCA/MriEvt.dx);
else
  % 15.08.05 YM: PREPCA as 0.8msec seems to give a better cleaning for j04x41 
  %              where noises are not settled down during no-interference period.
  %PREPCA = round(0.002/MriEvt.dx);		% 2ms
  PREPCA = round(0.0008/MriEvt.dx);		% 0.8ms
end

if ~isfield(MriEvt,'SS_PNTS'),
  error('\nERROR %s: old ClnAdjEvt format, please run sesclnadjevt(''%s'',%d).',...
        mfilename,Ses.name,MriEvt.ExpNo);
end

mripts = MriEvt.SS_PNTS(MriEvt.SS_OBSP == ObspNo);
%ADFOFFS = min(mripts);
ADFOFFS = min(mripts) - round(0.01/MriEvt.dx);
if ADFOFFS < 1 && ADFOFFS > -round(0.01/MriEvt.dx),  ADFOFFS = 1;  end

if MriEvt.SS_OFFS(ObspNo) < ADFOFFS,
  % adf's offset must include 1st mri events of dgz.
  ADFOFFS = MriEvt.SS_OFFS(ObspNo);
end
if isfield(ANAP,'HIGHPASS') && ANAP.HIGHPASS > 0,
  % to avoid distortion by high-pass filter in early periods.
  ADFOFFS = ADFOFFS - round(1.0/ANAP.HIGHPASS/2.0/MriEvt.dx);
  if ADFOFFS <= 0,  ADFOFFS = 1;  end
end
ADFLEN = MriEvt.obslen(ObspNo) - ADFOFFS;
[uniqidx, uniqlen] = subGetUniqParams(MriEvt,ObspNo);


% now "mripts" must be relative to ADFOFFS
mripts = mripts - ADFOFFS + 1;	% +1 for matlab indexing



adffile = expfilename(Ses, MriEvt.ExpNo, 'adfw');
par = expgetpar(Ses,MriEvt.ExpNo);
IS_MICROSTIM = 0;
if any(strcmpi(par.stm.stmtypes,'microstim')),
  IS_MICROSTIM = 1;
  %tmpdx = MriEvt.dx * ANAP.DECFRAC;
  %microstim_v = zeros(1,round(ADFLEN/ANAP.DECFRAC),'int8');
  tmpdx = MriEvt.dx;
  microstim_v = zeros(1,ADFLEN,'int8');
  stmv = par.stm.v{ObspNo};
  stmt = par.stm.time{ObspNo};
  for N = 1:length(stmv),
    if strcmpi(par.stm.stmtypes(stmv(N)+1),'microstim'),
      ts = round(stmt(N)/tmpdx);
      te = round(stmt(N+1)/tmpdx)-1;
      microstim_v(ts:te) = 1;
    end
  end
  clear stmv stmt tmpdx;
end



Sig.adffile = adffile;
Sig.NoObsp  = MriEvt.NoObsp;
Sig.ChanNo  = ChanNo;
Sig.ObspNo  = ObspNo;
Sig.cln     = [];
Sig.dx      = MriEvt.dx;
Sig.adfofs  = ADFOFFS;
Sig.adflen  = ADFLEN;


fprintf(' AiCh[%2d]:', ChanNo);


fprintf(' read(%d|%d).',ADFOFFS,mripts(1));
% check NoChan
nchan1 = adf_info(adffile);
if ChanNo <= nchan1,
  ADFDAT = adf_read(adffile,ObspNo-1,ChanNo-1,ADFOFFS-1,ADFLEN);
else
  % try to read 2nd adfw
  [fp fr fe] = fileparts(adffile);
  adffile2 = fullfile(fp,strcat(fr,'_2',fe));
  clear fp fr fe;
  ADFDAT = adf_read(adffile2,ObspNo-1,ChanNo-nchan1-1,ADFOFFS-1,ADFLEN);
end
ADFDAT = ADFDAT(:);  % make sure as ADFDAT(T,1)

if isfield(ANAP,'REMOVE_ES') && ANAP.REMOVE_ES > 0,
  ADFDAT = subRemoveES(ADFDAT,MriEvt.dx);
end


% % apply low-pass
% rip = .05;	% passband ripple in dB
% [b,a] = cheby1(8, rip, .9);
% ADFDAT = filtfilt(b,a,ADFDAT);

ADFLOW = [];

% do cleaning
  
% apply high pass if required to reduce DC offset
if any(DO_CLEANING),
  if isfield(ANAP,'HIGHPASS') && ANAP.HIGHPASS > 0,
    fprintf(' HP[%gHz]',ANAP.HIGHPASS);
    [b,a] = butter(3,ANAP.HIGHPASS/(1.0/Sig.dx/2),'high');
    ADFORG = ADFDAT;
    % do mirroring
    if 1,
      tmpoffs = round(2.0/Sig.dx);
      npts    = length(ADFDAT);
      tmpidx  = [tmpoffs+1:-1:2 1:npts npts-1:-1:npts-tmpoffs];
      ADFDAT  = filtfilt(b,a,ADFDAT(tmpidx));
      tmpidx  = (1:npts) + tmpoffs;
      ADFDAT = ADFDAT(tmpidx);
      clear tmpidx npts;
    else
      ADFDAT = filtfilt(b,a,ADFDAT);
    end
    % keep the low-freq component(s) removed by high-pass.
    if isfield(ANAP,'LOWRECOVER') && ANAP.LOWRECOVER > 0
      ADFLOW = ADFORG - ADFDAT;
    end
    clear ADFORG;
  end
end

if ~any(DO_CLEANING),
  % NO CLEANING
  fprintf(' no-cleaning ');
  for N = 1:length(uniqidx),
    ibeg = mripts(uniqidx{N}) - PREPCA;
    % due to decimation, length(ADFDAT) may not fit to iend(end).
    if length(ADFDAT) < ibeg(end)+uniqlen(N),
      ADFDAT(end+1:ibeg(end)+uniqlen(N)) = 0;
    end
    fprintf('.');
  end
  Sig.cln = ADFDAT;
  
else
  % DO CLEANING
  fprintf(' clean ');
  %Sig.cln = zeros(size(ADFDAT))*NaN;
  Sig.cln = nan(size(ADFDAT));
  for N = 1:length(uniqidx),
    ibeg = mripts(uniqidx{N}) - PREPCA;
    ILEN = 1:uniqlen(N);

    % due to decimation, length(ADFDAT) may not fit to iend(end).
    if length(ADFDAT) < ibeg(end)+uniqlen(N),
      ADFDAT(end+1:ibeg(end)+uniqlen(N)) = 0;
    end

    % -------------------------------------------------------------------
    % COMPUTE NOISE COMPONENTS - DO PCA
    % PCs, Explained Variance, Projections and Mean Waveform
    % -------------------------------------------------------------------
    PCADAT = zeros(uniqlen(N),length(ibeg));
    for K = 1:length(ibeg),
      %PCADAT(:,K) = ADFDAT(ibeg(K)+1:iend(K));
      PCADAT(:,K) = ADFDAT(ILEN + ibeg(K));
    end;

  
    % subtract DC offsets
    %DCOFFS = mean(PCADAT,1);
    %PCADAT = PCADAT - repmat(DCOFFS,size(PCADAT,1),1);
    
    
    % do subtract scaled mean as a major noise component.
    mNoise = mean(PCADAT,2);
    % this scaled mean-subtraction doesn't help much
    if 1,
      mNoiseN = mNoise / norm(mNoise);
      beta = mNoiseN' * PCADAT;
      for K = 1:size(PCADAT,2),
        PCADAT(:,K) = PCADAT(:,K) - beta(K)*mNoiseN;
      end
      %mNoise = mean(PCADAT,2);
      clear mNoiseN;
    else
      for K = 1:size(PCADAT,2),
        PCADAT(:,K) = PCADAT(:,K) - mNoise;
      end
    end
    
    % apply PCA and remove grad. noise.
    if IS_MICROSTIM,
      % this may improve artifact caused by microstimulation
      not_microstim = find(microstim_v(ibeg) == 0 & microstim_v(ibeg+uniqlen(N)) == 0);
      if isempty(not_microstim),
        [PC, eVar, Proj, SigMean] = doPCA(PCADAT,ANAP.NOPCS,ANAP.USE_LANSVD);
      else
        dat = PCADAT(:,not_microstim);
        [PC, eVar, Proj, SigMean] = doPCA(dat,ANAP.NOPCS,ANAP.USE_LANSVD);
        dat = PCADAT';
        for K = 1:size(dat,2),
          dat(:,K) = dat(:,K) - SigMean(K);	% center the data
        end
        Proj = dat * PC;						% Proj centered dat onto PCs.
        clear dat;
        %fprintf('microstim');
      end
    else
      [PC, eVar, Proj, SigMean] = doPCA(PCADAT,ANAP.NOPCS,ANAP.USE_LANSVD);
    end
    
    
    [RECODAT,pcidx,pcacoef] = subGetRECODAT(PCADAT,ANAP,PC,eVar,Proj,SigMean,mNoise,ChanNo,MriEvt,ObspNo);
    fprintf('%d',length(pcidx));
    % take care of DC offsets
    %RECODAT = RECODAT + repmat(DCOFFS,size(PCADAT,1),1);
    % -------------------------------------------------------------------
    % Paste back corrected signal in the right position
    % -------------------------------------------------------------------
    for K = 1:length(ibeg),
      %Sig.cln(ibeg(K)+1:iend(K)) = RECODAT(:,K);
      Sig.cln(ILEN + ibeg(K)) = RECODAT(:,K);
    end;
    %figure;  plot(mean(PCADAT,2),'r');  hold on; plot(mean(RECODAT,2),'b');
    %figure; plot(Sig.cln);
  
    if DEBUG,
      MatFile = sprintf('%s/%s_ob%03d_ch%03d_pca_grad%d.mat',...
                        ANAP.tmpdir,ANAP.root,Sig.ObspNo,ChanNo,N);
      PCA.gradtype = MriEvt.gradtype;
      PCA.gradidx  = N;
      PCA.dx  = Sig.dx;
      PCA.dat = PCADAT;
      PCA.reco = RECODAT;
      PCA.pcacoef = pcacoef;
      PCA.pcidx = pcidx;
      PCA.mNoise = mNoise;
      PCA.pc  = PC;
      PCA.eVar = eVar;
      PCA.proj = Proj;
      PCA.SigMean = SigMean;
      save(MatFile,'PCA');
      %ShowPCA(Ses,Sig,PCADAT,RECODAT,ANAP,N,PC);
      clear PCA;
    end;
    
    fprintf('.');
    
  end	% end of "for N = 1:length(MriEvt.gradtype)"

  %figure; plot(Sig.cln);
    
  % check uncovered regions
  nanidx = find(isnan(Sig.cln));
  if ~isempty(nanidx),
    if abs(mean(ADFDAT(nanidx))) > nanstd(Sig.cln)*2,
      % sometimes DC levels of ADFDAT/Sig.cln differs due to PCA or highpass filtering.
      fprintf(' DCadj');
      Sig.cln(nanidx) = ADFDAT(nanidx) - mean(ADFDAT(nanidx)) + nanmean(Sig.cln);
    else
      Sig.cln(nanidx) = ADFDAT(nanidx);
    end
  end

  %hold on;  plot(Sig.cln,'r');

  %  Removes gaps around edges of PCA data.
  if isfield(ANAP,'PCAGAP') && ANAP.PCAGAP > 0,
    mcln = mean(Sig.cln);
    scln = std(Sig.cln);
    for N = 1:length(uniqidx),
      ibeg = mripts(uniqidx{N}) - PREPCA;
      ibeg = [ibeg(:)' ibeg(:)'+uniqlen(N)];
      tmpcln = Sig.cln(ibeg) - mcln;
      idx = find(abs(tmpcln) > scln*0.5);
      for K = 1:length(idx),
        x = ibeg(idx(K));
        Sig.cln(x) = (Sig.cln(x-1) + Sig.cln(x+1))/2;
      end
    end
  end

  
  % apply low pass of nyq. frequency to remove nose made by PCA
  %[b,a] = butter(3,0.99);
  %Sig.cln = filtfilt(b,a,Sig.cln);
    
end

if isfield(ANAP,'LOWRECOVER') && ANAP.LOWRECOVER > 0 && ~isempty(ADFLOW),
  fprintf(' LowRecover');
  Sig.cln = Sig.cln + ADFLOW;
  if DEBUG > 0,  ADFDAT  = ADFDAT  + ADFLOW;  end  % need for plotting
end
clear ADFLOW;




if isfield(ANAP,'REMOVE_ECG') && ANAP.REMOVE_ECG > 0,
  % NOTE 04.Sep.13 YM:
  %  Proj-out of ECG should be here after cleaning, removal before cleaning introduced more
  %  ECG noise.
  
  grp = getgrp(Ses,MriEvt.ExpNo);
  if ~isfield(grp,'ecgch') && isfield(grp,'ekgch'),
    grp.ecgch = grp.ekgch;
  end
  if ~isfield(grp,'ecgch'),
    error('\nERROR %s: no information of ECG channl, set GRPP.ecgch or GRP.%s.ecgch in %s.m.\n',...
          mfilename, grp.name,Ses.name);
  end
  if ~isempty(grp.ecgch)
    if grp.ecgch(1) <= nchan1,
      ECGDAT = adf_read(adffile, ObspNo-1,grp.ecgch(1)-1,       ADFOFFS-1,ADFLEN);
    else
      ECGDAT = adf_read(adffile2,ObspNo-1,grp.ecgch(1)-nchan1-1,ADFOFFS-1,ADFLEN);
    end
    ECGDAT = ECGDAT(:);
    
    % rectified
    %ECGDAT = ECGDAT - mean(ECGDAT(:));
    %ECGDAT = abs(ECGDAT);
    
    % half-rectified
    %ECGDAT = ECGDAT - mean(ECGDAT(:));
    %ECGDAT(ECGDAT < 0) = 0;
    
    % polarity reverse
    %ECGDAT = - ECGDAT;
    
    %ecg.dx = MriEvt.dx;
    %ecg.dat = ECGDAT(:);
    %[Pxx F] = pwelch(ecg.dat,round(20/ecg.dx), 0, round(20/ecg.dx), 1/ecg.dx);
    %plot(F,Pxx);
    %keyboard
 
    fprintf(' ECG[%d]',grp.ecgch(1));
    tmpdat = Sig.cln;
    tmpm   = nanmean(tmpdat(:));
    tmpdat = tmpdat - tmpm;
    
    % note that by any reason, ECG has a lag of ~38ms?
    nlags = round(0.06/Sig.dx);
    % project out Nth derivative, 0 as the original ECG.
    for D = 0:2,
      % compute the derivative each time, due to circshift()...
      tmpecg = ECGDAT;
      for K = 1:D,
        tmpecg = diff(tmpecg);  tmpecg(end+1) = tmpecg(end);
      end
      tmpecg = tmpecg - mean(tmpecg);
      tmpecg = tmpecg / norm(tmpecg);
      [tmpc tmplags] = xcov(tmpdat,tmpecg,nlags,'coeff');
      %[tmpc tmplags] = xcorr(tmpdat,tmpecg,nlags,'coeff');  % a little faster...
      [maxv maxi] = max(abs(tmpc));
      fprintf('r=%g[%d].', tmpc(maxi), tmplags(maxi));
      if tmplags(maxi) ~= 0,  tmpecg = circshift(tmpecg,tmplags(maxi));  end
      tmpb   = tmpecg(:)' * tmpdat(:);
      tmpdat = tmpdat - tmpb * tmpecg(:);
    end

    % get back the DC offset
    tmpdat = tmpdat + tmpm;
    Sig.cln = tmpdat;
    clear ECGDAT tmpecg tmpdat tmpm tmpb;
    clear nlags tmpc tmplags maxv maxi D K;
  end
end




% % notch removal
% fprintf(' notch.');
% fband = [3650 3800] / (1/Sig.dx);
% Sig.cln =  notch_reject(Sig.cln, fband, 10, 1);


% cut out data from the 1st Mri events in dgz
i0 = MriEvt.SS_OFFS(ObspNo)-ADFOFFS + 1;
Sig.cln = Sig.cln(i0:end);
if isfield(ANAP,'SAVEGRA') && ANAP.SAVEGRA > 0,
  GRADAT = adf_read(adffile,ObspNo-1,MriEvt.GradChan-1,ADFOFFS-1,ADFLEN,'int16');
  GRADAT = GRADAT(:);
  GRADAT = int16(GRADAT(i0:end));	% save as "int16", no need of "double".
  if ANAP.DECFRAC > 1,
    GRADAT = GRADAT(1:ANAP.DECFRAC:end);
  end
  Sig.gra = GRADAT;
end


if ANAP.DECFRAC > 1,
  fprintf(' deci[%d]',ANAP.DECFRAC);
  Sig.dx = Sig.dx * ANAP.DECFRAC;
  Sig.cln = sub_decimate(Sig.cln, ANAP.DECFRAC);
end



if DEBUG > 0,
  fprintf(' plotting. ');
  
  tmptxt = sprintf('%s: %s Exp:%d Chan:%d',mfilename,Ses.name,MriEvt.ExpNo,ChanNo);
  tmpprm = sprintf('Lags=%d PCACoef=%.2f NPCs=%d NRem=%d PrePCA=%.2fms',...
                   ANAP.PCALAGS,ANAP.PCACOEF,ANAP.NOPCS,ANAP.NOREM,ANAP.PREPCA*1000);
  MAX_TSEC = 0;
  if length(Sig.cln)*Sig.dx > 1*60,
    MAX_TSEC = 1*60;	% 1min max
  end

  
  figure('Name',sprintf('%s TIME COURSE/SPECTRUM',tmptxt));
  % plot time course %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(2,1,1);
  % plot gradient noises, if exist
  if isfield(ANAP,'SAVEGRA') && ANAP.SAVEGRA > 0,
    selidx = 1:length(Sig.gra);
    if MAX_TSEC > 0 && length(selidx)*Sig.dx > MAX_TSEC,
      selidx = selidx(1:round(MAX_TSEC/Sig.dx));
    end
    plot((0:length(selidx)-1)*Sig.dx,Sig.gra(selidx),'color','green');
    hold on;
  end
  % plot un-cleaned data
  i0 = MriEvt.SS_OFFS(ObspNo)-ADFOFFS + 1;
  %i0 = round((MriEvt.SS_OFFS(ObspNo)-ADFOFFS)/ANAP.DECFRAC) + 1;
  selidx = i0:length(ADFDAT);
  if MAX_TSEC > 0 && length(selidx)*MriEvt.dx > MAX_TSEC,
    selidx = selidx(1:round(MAX_TSEC/MriEvt.dx));
  end
  plot((0:length(selidx)-1)*MriEvt.dx,ADFDAT(selidx),'color','red');
  hold on;
  % plot cleaned data
  selidx = 1:length(Sig.cln);
  if MAX_TSEC > 0 && length(selidx)*Sig.dx > MAX_TSEC,
    selidx = selidx(1:round(MAX_TSEC/Sig.dx));
  end
  plot((0:length(selidx)-1)*Sig.dx,Sig.cln(selidx),'color','blue');
  grid on;
  % plot pca-periods
  ylm = get(gca,'ylim');
  for N = 1:length(uniqidx),
    ibeg = mripts(uniqidx{N}) - PREPCA - i0;
    ILEN = uniqlen(N);
    ibeg = ibeg * MriEvt.dx;
    ILEN = ILEN * MriEvt.dx;
    if MAX_TSEC > 0,
      ibeg = ibeg(ibeg < MAX_TSEC);
    end
    for K = 1:length(ibeg),
      line([ibeg(K),ibeg(K)],ylm,'color',[0.8 0.8 0.8]);
      %line([ibeg(K),ibeg(K)]+ILEN,ylm,'color',[0.8 0.8 0.8]);
    end;
  end
  title(strrep(sprintf('%s TIME COURSE',tmptxt),'_','\_'));
  text(0.01,0.05,tmpprm,'units','normalized');
  xlabel('Time in seconds');  ylabel('ADC unit');
  if isfield(ANAP,'SAVEGRA') && ANAP.SAVEGRA > 0,
    legend('Grad. Noise','Un-Cleaned','Cleaned');
  else
    legend('Un-Cleaned','Cleaned');
  end

  % plot power spectral density %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(2,2,3);
  TWIN = 0.2;  % 0.2sec
  TWIN = 1.0;  % 1.0sec
  
  if isfield(ANAP,'SAVEGRA') && ANAP.SAVEGRA > 0,
    DX = Sig.dx;
    NFFT = 2^nextpow2(TWIN/DX); NOVERLAP = round(NFFT*0.2);  Fs   = 1.0/DX;
    [Pxx,f] = pwelch(double(GRADAT)-mean(double(GRADAT)),NFFT,NOVERLAP,NFFT,Fs);
    plot(f,Pxx,'green');  hold on;
  end
  DX = MriEvt.dx;
  NFFT = 2^nextpow2(TWIN/DX); NOVERLAP = round(NFFT*0.2);  Fs   = 1.0/DX;
  [Pxx,f] = pwelch(ADFDAT,NFFT,NOVERLAP,NFFT,Fs);
  plot(f,Pxx,'red');  hold on;
  DX = Sig.dx;
  NFFT = 2^nextpow2(TWIN/DX); NOVERLAP = round(NFFT*0.2);  Fs   = 1.0/DX;
  [Pxx,f] = pwelch(Sig.cln-mean(Sig.cln(:)),NFFT,NOVERLAP,NFFT,Fs);
  plot(f,Pxx,'blue');
  grid on;
  title(strrep(sprintf('%s POWER SPECTRAL DENSITY',tmptxt),'_','\_'));
  xlabel('Frequency in Hz');  ylabel('Power Specral Density');
  set(gca,'yscale','log');
  text(0.01,0.05,tmpprm,'units','normalized');
  if isfield(ANAP,'SAVEGRA') && ANAP.SAVEGRA > 0,
    legend('Grad. Noise','Un-cleaned','Cleaned');
  else
    legend('Un-cleaned','Cleaned');
  end
  subplot(2,2,4);
  if isfield(ANAP,'SAVEGRA') && ANAP.SAVEGRA > 0,
    DX = Sig.dx;
    NFFT = 2^nextpow2(TWIN/DX); NOVERLAP = round(NFFT*0.2);  Fs   = 1.0/DX;
    [S,F,T] = spectrogram(double(GRADAT),NFFT,NOVERLAP,NFFT,Fs);
    plot(F,mean(abs(S),2),'green');  hold on;
  end
  DX = MriEvt.dx;
  NFFT = 2^nextpow2(TWIN/DX); NOVERLAP = round(NFFT*0.2);  Fs   = 1.0/DX;
  [S,F,T] = spectrogram(ADFDAT,NFFT,NOVERLAP,NFFT,Fs);
  plot(F,mean(abs(S),2),'red');  hold on;
  DX = Sig.dx;
  NFFT = 2^nextpow2(TWIN/DX); NOVERLAP = round(NFFT*0.2);  Fs   = 1.0/DX;
  [S,F,T] = spectrogram(Sig.cln,NFFT,NOVERLAP,NFFT,Fs);
  plot(F,mean(abs(S),2),'blue');
  grid on;
  title(strrep(sprintf('%s MEAN SPECTROGRAM',tmptxt),'_','\_'));
  xlabel('Frequency in Hz');  ylabel('Mean Spectrogram');
  set(gca,'yscale','log');
  text(0.01,0.05,tmpprm,'units','normalized');
  if isfield(ANAP,'SAVEGRA') && ANAP.SAVEGRA > 0,
    legend('Grad. Noise','Un-cleaned','Cleaned');
  else
    legend('Un-cleaned','Cleaned');
  end
  [fp fr fe] = fileparts(sigfilename(Ses,MriEvt.ExpNo,'Cln'));
  mmkdir(fp);
  figfile = fullfile(fp,sprintf('%s_CH%02d.fig',fr,ChanNo));
  saveas(gcf,figfile);
  close(gcf);
end



MATFILE = sprintf('%s_ob%03d_ch%03d.mat',...
                  ANAP.root,Sig.ObspNo,ChanNo);
MATFILE = fullfile(ANAP.tmpdir,MATFILE);


fprintf(' tmpfile=%s...',MATFILE);
if DEBUG,
  i0 = MriEvt.SS_OFFS(ObspNo)-ADFOFFS + 1;
  ADF.dx = MriEvt.dx;
  ADF.dat = ADFDAT(i0:end);
  if ANAP.DECFRAC > 0
    ADF.dx = ADF.dx * ANAP.DECFRAC;
    ADF.dat = sub_decimate(ADF.dat, ANAP.DECFRAC);
  end
  ADF.dat = int16(round(ADFDAT));
  save(MATFILE,'Sig','ADF');
  clear ADF;
else
  save(MATFILE,'Sig');
end

clear ADFDAT PCADAT RECODAT GRADAT;


if nargout,
  varargout{1} = MATFILE;
  if nargout > 1,
    varargout{2} = Sig;
  end
end


fprintf(' done.\n');


return;




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get unique parameter of MRI events
function [uniqidx, uniqlen] = subGetUniqParams(MriEvt,ObspNo)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inobsp = find(MriEvt.SS_OBSP == ObspNo);
diffpts = diff(MriEvt.SS_PNTS);
if length(diffpts) < max(inobsp),
  diffpts = diffpts(inobsp(1:end-1));
else
  diffpts = diffpts(inobsp);
end

if max(inobsp) > length(MriEvt.grd),
  fprintf(' WARNING %s: more triggers(%d) than expected(%d)...\n  ',...
          mfilename,max(inobsp),length(MriEvt.grd));
  inobsp = inobsp(inobsp <= length(MriEvt.grd));
end




nsli = length(find(MriEvt.gradtype == 1));
nseg = max(MriEvt.gradtype);


CLEAN_BY_WHAT = '';

switch lower(CLEAN_BY_WHAT),
 case {'segment' 'segments'}
  % PCA by segments: This is the 2nd best.
  GRDSEQ = repmat(1:nseg, [nsli 1]);
  GRDSEQ = GRDSEQ(:)';

 case {'slice' 'slices'}
  % PCA by slices: this is the 3rd.
  GRDSEQ = repmat(1:nsli, [1 nseg]);
  
 otherwise
  % PCA by segments/slices: this is the best.
  GRDSEQ = 1:nsli*nseg;
end

GRDSEQ = repmat(GRDSEQ,[1 MriEvt.NoVol]);
GRDSEQ = GRDSEQ(1:length(MriEvt.grd));
GRDUNQ = sort(unique(GRDSEQ));

uniqidx = cell(1,length(GRDUNQ));
avglen  = zeros(1,length(GRDUNQ));
maxlen  = zeros(size(avglen));
minlen  = zeros(size(avglen));
uniqlen = zeros(size(avglen));

for N = 1:length(GRDUNQ),
  tmppat = zeros(size(GRDSEQ));

  %tmppat(N:length(MriEvt.gradtype):length(MriEvt.grd)) = 1;
  tmppat(GRDSEQ == GRDUNQ(N)) = 1;
 
  tmppat = tmppat(inobsp);
  uniqidx{N} = find(tmppat);
  if length(diffpts) < max(uniqidx{N}),
    avglen(N) = mean(diffpts(uniqidx{N}(1:end-1)));
    maxlen(N) = max(diffpts(uniqidx{N}(1:end-1)));
    minlen(N) = min(diffpts(uniqidx{N}(1:end-1)));
  else
    avglen(N) = mean(diffpts(uniqidx{N}));
    maxlen(N) = max(diffpts(uniqidx{N}));
    minlen(N) = min(diffpts(uniqidx{N}));
  end
  if (maxlen(N)-minlen(N))*MriEvt.dx*1000 > 2,
    % if more than 2msec,
    uniqlen(N) = round(avglen(N));
  else
    uniqlen(N) = minlen(N);
  end
end


return;




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PC, eVar, Proj, SigMean] = doPCA(dat, nopcs, USE_LANSVD)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dat		= dat';							% transpose dat (T,N)->(N,T)
SigMean	= mean(dat,1);					% mean value along N
for N = 1:size(dat,2),
  dat(:,N) = dat(:,N) - SigMean(N);		% center the data
end

% 03.08.05 YM:
% Matlab's cov() will cause memory problem if 'dat' is a large matrix.
%tmpcov	= cov(dat);						% compute covariance matrix
tmpcov = sub_mycov(dat);
% flag   = 0;
% Ndata  = size(dat,1);
% Ndims  = size(dat,2);
% tmpcov = zeros(Ndims,Ndims);
% if flag == 0,  Ndata = Ndata - 1;  end
% for iX = 1:Ndims,
%   %x = dat(:,iX) - SigMean(iX);
%   x = dat(:,iX);
%   tmpcov(iX,iX) = sum(x .* x) / Ndata;
%   for iY = iX+1:Ndims,
%     %y = dat(:,iY) - SigMean(iY);
%     y = dat(:,iY);
%     tmpcov(iX,iY) = sum(x .* y) / Ndata;
%     tmpcov(iY,iX) = tmpcov(iX,iY);
%   end
% end


% [U,eVar,PC] = SVDS(dat,nopcs) computes the the nopcs first singular
% vectors of dat. If A is NT-by-N and K singular values are
% computed, then U is NT-by-K with orthonormal columns, eVar is K-by-K
% diagonal, and V is N-by-K with orthonormal columns.

if any(USE_LANSVD)
  %%Sonja%% svds_lansvd uses symmetric Lanczos algorithm with reorthogonalization
  %%Sonja%% Lanczos algorithm provides a good and fast approximation of the
  %%Sonja%% largest and smallest eigenvalues and
  %%eigenvectors of a symmetic matrix
  [U, eVar, PC] = svds_lansvd(tmpcov, nopcs, 'L');
else
  [U, eVar, PC] = svds(tmpcov, nopcs);	% find singular values
end
clear tmpcov;

eVar  = diag(eVar);						% turn diagonal mat into vector.
SigMean = SigMean(:);					% return mean
Proj = dat * PC;						% Proj centered dat onto PCs.

return;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUB_MYCOV Covariance matrix.
%   SUB_MYCOV() IS LESS MEMORY EATING VERSION OF MATLAB'S COV().
function xy = sub_mycov(x,varargin)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% See also COV

if nargin==0 
  error('sub_mycov:NotEnoughInputs','Not enough input arguments.'); 
end
if nargin>3, error('mycov:TooManyInputs', 'Too many input arguments.'); end
if ndims(x)>2, error('mycov:InputDim', 'Inputs must be 2-D.'); end

nin = nargin;

% Check for cov(x,flag) or cov(x,y,flag)
if (nin==3) || ((nin==2) && (length(varargin{end})==1));
  flag = varargin{end};
  nin = nin - 1;
else
  flag = 0;
end

if nin == 2,
  x = x(:);
  y = varargin{1}(:);
  if length(x) ~= length(y), 
    error('mycov:XYlengthMismatch', 'The lengths of x and y must match.');
  end
  x = [x y];
end

if length(x)==numel(x)
  x = x(:);
end

[m,n] = size(x);

if m==1,  % Handle special case
  xy = zeros(class(x));

else
  % mofified HERE: BEGIN==========================================
  % ORIGINAL CODE
  %xc = x - repmat(sum(x)/m,m,1);  % Remove mean
  % 07.09.04 YM: to avoid memory problem, use a for-loop
  xc = x;  clear x;
  sumx = sum(xc)/m;
  for N = m:-1:1,
    xc(N,:) = xc(N,:) - sumx;
  end
  clear sumx;
  % mofified HERE: END============================================
  
  if flag
    xy = xc' * xc / m;
  else
    xy = xc' * xc / (m-1);
  end
  xy = 0.5*(xy+xy');
end

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [RECODAT, pcidx, pcacoef] = subGetRECODAT(PCADAT,ANAP,PC,eVar,Proj,SigMean,mNoise,ChanNo,MriEvt,ObspNo,CHECK)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('CHECK','var'),  CHECK = 1;  end
  
FracVar = eVar / sum(eVar);

% -------------------------------------------------------------------
% SELECT RELEVANT PCs/ICs BY CHECKING THEIR COR W/ AVG INTERFERENCE
% -------------------------------------------------------------------
clear pcacoef;

NDer = 5;  % max order of the derivatives
pcacoef = zeros(size(PC,2),NDer+1);  % +1 for the original waveform
cNoise  = zeros(size(PC,1),NDer+1);  % +1 for the original waveform
cNoise(:,1) = mNoise(:);
for K = 2:size(cNoise,2),
  cNoise(:,K) = diff([cNoise(1,K-1); cNoise(:,K-1)]);
end
for iPC = 1:size(PC,2),
  %tmp = xcov(SigMean,PC(:,iPC),ANAP.PCALAGS,'coeff');
  for K = 1:size(cNoise,2)
    tmp = xcov(cNoise(:,K),PC(:,iPC),ANAP.PCALAGS,'coeff');
    pcacoef(iPC,K) = max(abs(tmp));
  end
end
pcacoef = max(pcacoef,[],2);


if ANAP.NOREM <= 0,
  % Selects automatically the top eigenvalues and those xcor with mean
  pcidx = find(FracVar(:) > 0.02 & pcacoef(:) > ANAP.PCACOEF);
else
  if ANAP.NOREM > ANAP.NOPCS,
    fprintf('NOREM cannot be greated then computed PCs (NOPCS)\n');
    fprintf('Using NOREM=NOPCS\n');
    ANAP.NOREM = ANAP.NOPCS;
  end;
  % Get first "norem" PCs and Select somewhat correlated
  %pcidx = 1:ANAP.NOREM;
  %pcidx = find(pcacoef(1:ANAP.NOREM) > 0.1);
  pcidx = find(pcacoef(1:ANAP.NOREM) > ANAP.PCACOEF);
end;

if CHECK == 1 && isempty(pcidx),
  fprintf('%s[WARNING]:\n',mfilename);
%  fprintf('Exp=%d, Obsp=%d, Ch=%d, Grad=%d\n',...
%          MriEvt.ExpNo, ObspNo, ChanNo, MriEvt.gradtype(N));
  fprintf('Exp=%d, Obsp=%d, Ch=%d\n',...
          MriEvt.ExpNo, ObspNo, ChanNo);
  fprintf('No PC was found that is significantly\n');
  fprintf('correlated with mean interference!!\n');
  fprintf('PCs explaining more than 0.02 of variance:\n');
  fprintf('%s\n', num2str(FracVar));
  fprintf('PCs with r > %5.3f\n',ANAP.PCACOEF);
  fprintf('%s\n', num2str(pcidx));
end;		

% -------------------------------------------------------------------
% Subtract from orig. signal fragment their PCs selected above.
% -------------------------------------------------------------------
% 03.08.05 YM, to avoid memory problem, do one by one....
%RECODAT = PCADAT - repmat(SigMean,[1,size(PCADAT,2)]);
RECODAT = PCADAT;
for N = 1:size(PCADAT,2),
  RECODAT(:,N) = PCADAT(:,N) - SigMean;
end

Interference = PC(:,pcidx) * squeeze(Proj(:,pcidx))';
RECODAT = RECODAT - Interference;

return;




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction to remove microstimulation artifact
function ADFDAT = subRemoveES(ADFDAT,DX, THR_ADC)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3,  THR_ADC = 32700;  end
fprintf(' removing ES(thr=%g)',THR_ADC);

%esidx = find(abs(ADFDAT) > 32700);
esidx = find(abs(ADFDAT) > THR_ADC);
if isempty(esidx),
  fprintf('no artifact beyond thr.');
  return;
end

tdiff = diff(esidx)*DX;  % in seconds
tdiff(end+1) = length(ADFDAT)*DX;
esidx = esidx(tdiff > 0.002);   % must be 2ms apart each other
clear tdiff;

fprintf('(%d)...',length(esidx));
if ~isempty(esidx),
  selwin  = (0:round(0.0012/DX)) - round(0.0007/DX);  % 1.2ms window
  selbase = cat(2,(-5:1)+min(selwin), (1:5)+max(selwin));
  nwin = length(selwin);
  for N = 1:length(esidx),
    tmpi   = selbase + esidx(N);
    tmpi   = tmpi(tmpi > 0);
    if isempty(tmpi),  continue;  end
    tmpadf = double(ADFDAT(tmpi));
    tmpm   = mean(tmpadf(:));
    tmps   = std(tmpadf(:));
    tmpdat = (rand(1,nwin)*2-1)*tmps + tmpm;
    tmpi   = selwin+esidx(N);
    tmpi   = tmpi(tmpi > 0);
    if isempty(tmpi),  continue;  end
    ADFDAT(selwin+esidx(N)) = tmpdat(:);
  end
end



return


% -------------------------------------------------------------------
function odata = sub_decimate(idata,r,nfilt,option)
% -------------------------------------------------------------------
% This subfunciton is modified from MATLAB's decimate().
% The MATALB's decimate() has low-pass filtering of .8xNyqF,
% while here I have .9xNuqF.

% Validate required inputs 
validateinput(idata,r);

if fix(r) == 1
  odata = idata;
  return
end

if nargin == 2
  nfilt = 8;
end

if nfilt > 13
  warning(message('signal:decimate:highorderIIRs'));
end

nd = length(idata);
m = size(idata,1);
nout = ceil(nd/r);
  

% IIR filter
rip = .05;	% passband ripple in dB
[b,a] = cheby1(nfilt, rip, .9/r);
while all(b==0) || (abs(filtmag_db(b,a,.9/r)+rip)>1e-6)
  nfilt = nfilt - 1;
  if nfilt == 0
    break
  end
  [b,a] = cheby1(nfilt, rip, .9/r);
end
if nfilt == 0
  error(message('signal:decimate:InvalidRange'))
end

% be sure to filter in both directions to make sure the filtered data has zero phase
% make a data vector properly pre- and ap- pended to filter forwards and back
% so end effects can be obliterated.
odata = filtfilt(b,a,idata);
nbeg = r - (r*nout - nd);
odata = odata(nbeg:r:nd);

return

%--------------------------------------------------------------------------
function H = filtmag_db(b,a,f)
%FILTMAG_DB Find filter's magnitude response in decibels at given frequency.

nb = length(b);
na = length(a);
top = exp(-1i*(0:nb-1)*pi*f)*b(:);
bot = exp(-1i*(0:na-1)*pi*f)*a(:);

H = 20*log10(abs(top/bot));

%--------------------------------------------------------------------------
function validateinput(x,r)
% Validate 1st two input args: signal and decimation factor

if isempty(x) || issparse(x) || ~isa(x,'double'),
    error(message('signal:decimate:invalidInput', 'X'));
end

if (abs(r-fix(r)) > eps) || (r <= 0)
    error(message('signal:decimate:invalidR', 'R'));
end

