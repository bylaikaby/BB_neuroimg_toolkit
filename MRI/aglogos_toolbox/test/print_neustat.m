function varargout = print_neustat(Ses,EXPS)
%PRINT_NEUSTAT - prints some statistics.
%  PRINT_NEUSTAT(SES,EXPS) prints some statistics.
%
%  EXAMPLE :
%    >> [spk lfp mua] = print_neustat('j97nm1',41:50);
%    >> spk.ttest.pval'        % copy and paste printed values to excel
%    >> ...
%    >> mean(spk.base.mean,2), std(spk.base.mean,[],2)
%    >> ...
%    >> mean(spk.stim.mean,2), std(spk.stim.mean,[],2),max(spk.stim.peak,[],2)
%    >> ...
%    >> lfp.ttest.pval'
%    >> ...
%    >> mean(lfp.base.mean,2), std(lfp.base.mean,[],2)
%    >> ...
%    >> mean(lfp.stim.mean,2), std(lfp.stim.mean,[],2)
%    >> ...
%    >> mua.ttest.pval'
%    >> ...
%    >> mean(mua.base.mean,2), std(mua.base.mean,[],2)
%    >> ...
%    >> mean(mua.stim.mean,2), std(mua.stim.mean,[],2)
%    >> ...
%
%  VERSION :
%    16.07.06 YM  pre-release
%
%  See also SESGETSPK, SESGETBLP


Ses = goto(Ses);
if ~isnumeric(EXPS),
  grp = getgrp(Ses,EXPS);
  EXPS = grp.exps;
else
  grp = getgrp(Ses,EXPS(1));
end


aaaaa

spk = subDoSpike(Ses,EXPS);
[lfp mua] = subDoLfpMua(Ses,EXPS);


if nargout,
  varargout{1} = spk;
  varargout{2} = lfp;
  varargout{3} = mua;
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subDoSpike(Ses,EXPS)

BASE_MEAN = [];
STIM_MEAN = [];
BASE_PEAK = [];
STIM_PEAK = [];


% Note that Spkt.dat is histgram, counts of spikes during .dx bin.

fprintf('%s %s: ',mfilename,Ses.name);
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%d.',ExpNo);
  Spkt = sigload(Ses,ExpNo,'Spkt');
  if iscell(Spkt),
    Spkt = Spkt{end};
  end
  baseidx = getStimIndices(Spkt,'blank',0,0);
  stimidx = getStimIndices(Spkt,'anystim',0,0);

  %tidx = [0:size(Spkt.dat,1)-1]*Spkt.dx;
  tbase = length(baseidx)*Spkt.dx;
  tstim = length(stimidx)*Spkt.dx;
  
  tmpbase = Spkt.dat(baseidx,:);
  tmpstim = Spkt.dat(stimidx,:);
  
  BASE_MEAN(iExp,:) = sum(tmpbase,1) / tbase;
  STIM_MEAN(iExp,:) = sum(tmpstim,1) / tstim;
  
  BASE_PEAK(iExp,:) = max(tmpbase) / Spkt.dx;
  STIM_PEAK(iExp,:) = max(tmpstim) / Spkt.dx;
end

fprintf(' done.\n');


% do ttest
[h, PVAL] = ttest(BASE_MEAN,STIM_MEAN);


% (exp,chan) --> (chan,exp)
BASE_MEAN = BASE_MEAN';
BASE_PEAK = BASE_PEAK';
STIM_MEAN = STIM_MEAN';
STIM_PEAK = STIM_PEAK';


oSig.session = Spkt.session;
oSig.ExpNo   = EXPS;
oSig.chan    = Spkt.chan;
oSig.datdim  = {'exp','chan'};
oSig.dx      = Spkt.dx;
oSig.base.mean    = BASE_MEAN;
oSig.base.peak    = BASE_PEAK;
oSig.stim.mean    = STIM_MEAN;
oSig.stim.peak    = STIM_PEAK;
oSig.ttest.pval   = PVAL;

mbase = mean(BASE_MEAN,2);
mstim = mean(STIM_MEAN,2);
pbase = mean(BASE_PEAK,2);
pstim = max(STIM_PEAK,[],2);
  
%fprintf('ses chan ele  ttest(P)  mean-base mean-stim peak-stim\n');
%for iCh = 1:length(mbase),
%  fprintf('%s %2d %2d  %7.5f  %7.3f %7.3f %7.3f\n',...
%          Ses.name,iCh,Spkt.chan(iCh),...
%          PVAL(iCh),mbase(iCh),mstim(iCh),pstim(iCh));
%end
  

fprintf('SPIKE\n');
fprintf('ttest    :');  fprintf(' %7.4f',PVAL);   fprintf('\n');
fprintf('mean base:');  fprintf(' %7.3f',mbase);  fprintf('\n');
fprintf('     stim:');  fprintf(' %7.3f',mstim);  fprintf('\n');
fprintf('peak stim:');  fprintf(' %7.3f',pstim);  fprintf('\n');

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Lfp Mua] = subDoLfpMua(Ses,EXPS)

Lfp = [];  Mua = [];

fprintf('%s %s: ',mfilename,Ses.name);
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%d.',ExpNo);
  blp = sigload(Ses,ExpNo,'blp');
  if iscell(blp),
    blp = blp{end};
  end
  if ~isfield(blp,'xform'),
    % no way to convert into  mV, uV
    return;
  end
  
  lfpidx = [];  muaidx = [];
  for N = 1:length(blp.info.band),
    switch lower(blp.info.band{N}{2}),
     %case {'lfp'}
     % if blp.info.band{N}{4} == 0,
     %   lfpidx = N;
     % end
     case {'lfpr'}
      lfpidx = N;
     case {'mua'}
      muaidx = N;
    end
  end
  
  if isempty(lfpidx) | isempty(muaidx),  continue;  end
  
  lfpdat = blp.dat(:,:,lfpidx);
  muadat = blp.dat(:,:,muaidx);
  
  if blp.info.conv2sdu > 0,
    m = reshape(blp.xform.mean,[size(blp.dat,2) size(blp.dat,3)]);
    s = reshape(blp.xform.std, [size(blp.dat,2) size(blp.dat,3)]);
    for iCh = 1:size(lfpdat,2),
      lfpdat(:,iCh) = lfpdat(:,iCh) * s(iCh,lfpidx) + m(iCh,lfpidx);
      muadat(:,iCh) = muadat(:,iCh) * s(iCh,muaidx) + m(iCh,muaidx);
    end
  end
  
  grp = getgrp(Ses,ExpNo);
  if ~isfield(grp,'recgain'),  return;  end
  
  v_per_adc = 10.0 / 65536;
  for iCh = 1:size(lfpdat,2),
    lfpdat(:,iCh) = lfpdat(:,iCh) * v_per_adc / grp.recgain(iCh);
    muadat(:,iCh) = muadat(:,iCh) * v_per_adc / grp.recgain(iCh);
  end
  lfpdat = lfpdat * 1000000;  % in uV
  muadat = muadat * 1000000;  % in uV
  
  
  
  %baseidx = getStimIndices(blp,'blank',0,0);
  baseidx = getStimIndices(blp,'prestim',0,0);
  stimidx = getStimIndices(blp,'anystim',0,0);
  
  % limit to 10 secs
  if length(baseidx)*blp.dx > 10,
    baseidx = baseidx(1:round(10/blp.dx));
  end
  if length(stimidx)*blp.dx > 10,
    stimidx = stimidx(1:round(10/blp.dx));
  end
  
  % remove DC offsets
  %for iCh = 1:size(lfpdat,2),
  %  lfpdat(:,iCh) = lfpdat(:,iCh) - mean(lfpdat(:,iCh),1);
  %  muadat(:,iCh) = muadat(:,iCh) - mean(muadat(:,iCh),1);
  %end
  
  tmpbase_lfp = lfpdat(baseidx,:);
  tmpstim_lfp = lfpdat(stimidx,:);

  tmpbase_mua = muadat(baseidx,:);
  tmpstim_mua = muadat(stimidx,:);

  %LFP_BASE_MEAN(iExp,:) = max(tmpbase_lfp,[],1) - min(tmpbase_lfp,[],1);
  %LFP_STIM_MEAN(iExp,:) = max(tmpstim_lfp,[],1) - min(tmpstim_lfp,[],1);

  LFP_BASE_MEAN(iExp,:) = mean(tmpbase_lfp,1);
  LFP_STIM_MEAN(iExp,:) = mean(tmpstim_lfp,1);
  %LFP_BASE_MEAN(iExp,:) = max(tmpbase_lfp,[],1);
  %LFP_STIM_MEAN(iExp,:) = max(tmpstim_lfp,[],1);

  MUA_BASE_MEAN(iExp,:) = mean(tmpbase_mua,1);
  MUA_STIM_MEAN(iExp,:) = mean(tmpstim_mua,1);
  
end

fprintf(' done.\n');


% do ttest
[h, PVAL_LFP] = ttest(LFP_BASE_MEAN,LFP_STIM_MEAN);
[h, PVAL_MUA] = ttest(MUA_BASE_MEAN,MUA_STIM_MEAN);



% (exp,chan) --> (chan,exp)
LFP_BASE_MEAN = LFP_BASE_MEAN';
LFP_STIM_MEAN = LFP_STIM_MEAN';
MUA_BASE_MEAN = MUA_BASE_MEAN';
MUA_STIM_MEAN = MUA_STIM_MEAN';



Lfp.session = blp.session;
Lfp.ExpNo   = EXPS;
Lfp.chan    = blp.chan;
Lfp.datdim  = {'exp','chan'};
Lfp.dx      = blp.dx;
Lfp.base.mean    = LFP_BASE_MEAN;
Lfp.stim.mean    = LFP_STIM_MEAN;
Lfp.ttest.pval   = PVAL_LFP;



Mua.session = blp.session;
Mua.ExpNo   = EXPS;
Mua.chan    = blp.chan;
Mua.datdim  = {'exp','chan'};
Mua.dx      = blp.dx;
Mua.base.mean    = MUA_BASE_MEAN;
Mua.stim.mean    = MUA_STIM_MEAN;
Mua.ttest.pval   = PVAL_MUA;


fprintf('LFP\n');
fprintf('ttest    :');  fprintf(' %7.4f',PVAL_LFP);   fprintf('\n');
fprintf('mean base:');  fprintf(' %8.3f',mean(LFP_BASE_MEAN,2));  fprintf('\n');
fprintf('     stim:');  fprintf(' %8.3f',mean(LFP_STIM_MEAN,2));  fprintf('\n');

fprintf('MUA\n');
fprintf('ttest    :');  fprintf(' %7.4f',PVAL_MUA);   fprintf('\n');
fprintf('mean base:');  fprintf(' %8.3f',mean(MUA_BASE_MEAN,2));  fprintf('\n');
fprintf('     stim:');  fprintf(' %8.3f',mean(MUA_STIM_MEAN,2));  fprintf('\n');



return;

  



