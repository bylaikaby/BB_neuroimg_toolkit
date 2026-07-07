function BLP = expgetblp(SesName, ExpNo, SigName, iINFO)
%EXPGETBLP - Separate the Cln signal into freqeuncy bands for SesName/ExpNo
% EXPGETBLP (SESSION, ExpNo) invokes BANDGRAM to extract band-limited signals of high
% temporal resolution.
%
% The bandgram will spling the signal in the bands shown below. Following extraction the
% signals will be Hibert-Transformed and the amplitude of the transformation will resampled
% at 500Hz. The amplitude of the Hiblert transforms is the exact envelop of the band-limited
% signal, and its resampled (after low pass filtering) form will be used for the study of
% BOLD physiology, dependecne between recording sites, spike-triggered averaging etc.
%
% TODO:
% Need to CHECK whether the number (500Hz) etc are ok for our purposes!
%
%  NOTE :
%    Use ANAP.siggetblp or (GRP).anap.siggetblp to set parameters.
%    ANAP.siggetblp.datclass  = 'double';  % 'double'|'single'
%
%    Any parameters extracting blp can be modified through the session file.
%      ANAP.siggetblp (GRP.xxx.anap.siggetblp will overwrite default settings).
%
%      ANAP.siggetblp.band{ 1}     = {[   0     4] 'Delta'   'LFP', 0};
%      ANAP.siggetblp.band{ 2}     = {[   4     8] 'Theta'   'LFP', 0};
%      ANAP.siggetblp.band{ 3}     = {[   4     8] 'ThetaR'  'LFP', 2};
%      ANAP.siggetblp.band{ 4}     = {[   8    14] 'Alpha'   'LFP', 3};
%      ANAP.siggetblp.band{ 5}     = {[  14    24] 'Beta'    'LFP', 4};
%      ANAP.siggetblp.band{ 6}     = {[  24    90] 'Gamma'   'LFP', 30};
%      ANAP.siggetblp.band{ 7}     = {[   0    90] 'LFP'     'LFP', 0};
%      ANAP.siggetblp.band{ 8}     = {[   0    90] 'LFPR'    'LFP', 30};
%      ANAP.siggetblp.band{ 9}     = {[  40   130] 'LFPN'    'LFP', 30};
%      ANAP.siggetblp.band{10}     = {[ 400  3000] 'MUA'     'MUA', 30};
%
%      ANAP.siggetblp.lcutoff      = 500;      % Before split. LFP region (avoid singularities)
%      ANAP.siggetblp.mcutoff      = 100;      % Before split. MUA region (avoid singularities)
%      ANAP.siggetblp.NewFs        = 250;      % All signals will be resampled at 250Hz
%      ANAP.siggetblp.NewFsTr      = ANAP.siggetblp.NewFs*0.08;
%
%    PARAMETERS FOR THE FIR FILTER
%      ANAP.siggetblp.flttype      = 'cheby2';
%      ANAP.siggetblp.lstop        = 1;
%      ANAP.siggetblp.mstop        = 50;
%      ANAP.siggetblp.hstop        = 50;
%      ANAP.siggetblp.dB           = 60;
%      ANAP.siggetblp.passripple   = 0.1;
%      ANAP.siggetblp.NewFsTr      = 40;       % 60dB decay width for above resampling
%
%    PARAMETERS TO MINIMIZE UNSTABLE PERIODS IN BOTH TIME EDGES
%      ANAP.siggetblp.mirror     = 1;
%
%    DETREND before normalization
%      ANAP.siggetblp..detrend   = 0;
%
%    SDU conversion
%      ANAP.siggetblp.conv2sdu   = 1;       1:tosdu,2:detrend,3:zerobase, can be char
%
%    If memory problem
%      ANAP.siggetblp.save_memory = 1;
%
%    Despiking to avoid effects of spikes on LFP
%      ANAP.siggetblp.despike     = 1;
%
%  EXAMPLE :
%    blp = expgetblp(SessionName,ExpNo)
%
%  VERSION :
%    1.00 28.07.04 NKL
%    1.10 11.02.13 YM  supports clndespike.
%    1.11 15.02.13 YM  "despike" is now in sigetblp() to have MUA.
%    1.20 23.05.13 YM  supports any "SigName", get parameters from the session file.
%    1.21 28.05.13 YM  use sigrereference().
%
%  See also siggetblp sesgetblp clndespike sigrereference


if nargin < 2,
  help expgetblp;
  return;
end;

if ~exist('iINFO','var'),  iINFO = {};  end
if ~exist('SigName','var'), SigName = 'Cln'; end;

Ses = goto(SesName);
grp  = getgrp(Ses,ExpNo);
anap = getanap(Ses,ExpNo);
fprintf('%s %s %s exp=%d: ', datestr(now,'HH:MM:SS'),mfilename,Ses.name,ExpNo);
fprintf(' loading %s.',SigName);
SIG = sigload(Ses,ExpNo,SigName);


% BACKWORD COMPATIBILITY: get parameters 
switch lower(SigName)
 case {'cln','fcln','ncln','mcln'}
  if isfield(anap,'siggetblp') && ~isempty(anap.siggetblp),
    iINFO = sctmerge(anap.siggetblp,iINFO);
  end
 case {'csd'}
  if isfield(anap,'csdgetblp') && ~isempty(anap.csdgetblp),
    iINFO = sctmerge(anap.csdgetblp,iINFO);
  else
    fprintf('No ANAP.csdgetblp structure was found\n');
    keyboard;
  end
end

% ANAP.(signame).siggetblp
if isfield(anap,SigName) && isfield(anap.(SigName),'siggetblp') && ~isempty(anap.(SigName).siggetblp),
  iINFO = sctmerge(anap.(SigName).siggetblp,iINFO);
end


if isfield(iINFO,'datclass') && any(strcmpi(iINFO.datclass,'single')),
  SIG.dat = single(SIG.dat);
end
if isfield(iINFO,'refchan') && any(iINFO.refchan),
  if ischar(iINFO.refchan)
    fprintf(' subtracting reference.[%s].',iINFO.refchan);
  else
    fprintf(' subtracting reference.[%s].',deblank(sprintf('%d ',iINFO.refchan)));
  end
  SIG = sigrereference(SIG,iINFO.refchan);
  
  % if any(strcmpi(iINFO.refchan,{'all','mean'})),
  %   iINFO.refchan = [1:size(SIG.dat,2)];
  % end
  % fprintf('subtracting reference.[%s].',deblank(sprintf('%d ',iINFO.refchan)));
  % if size(SIG.dat,3) > 1,
  %   refdat = squeeze(nanmean(SIG.dat(:,iINFO.refchan,:),2));
  %   for iObsp = 1:size(SIG.dat,3),
  %     for N = 1:size(SIG.dat,2),
  %       SIG.dat(:,N,iObsp) = SIG.dat(:,N,iObsp) - refdat(:,iObsp);
  %     end
  %   end
  % else
  %   refdat = squeeze(nanmean(SIG.dat(:,iINFO.refchan),2));
  %   for N = 1:size(SIG.dat,2),
  %     SIG.dat(:,N) = SIG.dat(:,N) - refdat;
  %   end
  % end
end


% if isfield(iINFO,'despike') && any(iINFO.despike)
%   Spkt = sigload(Ses,ExpNo,'Spkt');
%   if isempty(Spkt),
%     sesgetspk(Ses,ExpNo);
%     Spkt = sigload(Ses,ExpNo,'Spkt');
%   end
%   SPKWIN_MS = [-1 2];
%   fprintf(' despike(win=[%g %g]ms).',SPKWIN_MS(1),SPKWIN_MS(2));
%   SIG = clndespike(SIG,Spkt.times,'spkwin',SPKWIN_MS,'SpkDt',Spkt.dt,'verbose',0);
%   clear Spkt;
% end


LEN=size(SIG.dat,1);
LENTOTAL = round(LEN*1.1);
LENEXT = LENTOTAL - LEN;

if 0,   % Trying to revocer the lost signal because of our current-measurements
  SIG.dat = cat(1,SIG.dat,SIG.dat(1:LENEXT,:,:,:));
  SIG.dat = cumtrapz(SIG.dat,1);
  SIG.dat = SIG.dat(1:LEN,:,:,:);
  SIG.dat = detrend(SIG.dat);
end;


fprintf(' siggetblp.');
if ~isstruct(SIG),
  for N=1:length(SIG),
    BLP{N} = siggetblp(SIG{N},[],[],iINFO);
    SIG{N} = {};  % no more need of SIG{N}
  end;
else
  if size(SIG.dat,3) > 1,
    % 04.08.04 YM
    % SIG.dat for OLD DATA is SIG.dat(T,Chan,Obsp), so take mean along Obsp.
    SIGTmp = SIG;  BLPdat = [];
    for iObsp = 1:size(SIG.dat,3),
      SIGTmp.dat = squeeze(SIG.dat(:,:,iObsp));
      BLP = siggetblp(SIGTmp,[],[],iINFO);
      BLPdat = cat(4,BLPdat,BLP.dat);
    end
    switch lower(Ses.name)
     case {'b01nm3'}
      % keeps multiple observation
      BLP.dat = BLP.dat;
     otherwise
      BLP.dat = mean(BLPdat,4);
    end
  else
    BLP = siggetblp(SIG,[],[],iINFO);
  end
end;
%fprintf('\n');
clear SIG;


if iscell(BLP),
  for N=1:length(BLP),
    BLP{N}.dat(1:5,:,:,:) = BLP{N}.dat(6:10,:,:,:);
    BLP{N}.dat(end-5:end,:,:,:) = BLP{N}.dat(end-10:end-5,:,:,:);
  end;
else
  BLP.dat(1:5,:,:,:) = BLP.dat(6:10,:,:,:);
  BLP.dat(end-5:end,:,:,:) = BLP.dat(end-10:end-5,:,:,:);
end;

if ~nargout,
  if strcmpi(SigName,'Cln'),
    BLP_NAME = 'blp';
  else
    BLP_NAME = sprintf('%sblp',SigName);
    %sigsave(Ses,ExpNo,'csdblp',blp);
  end;
  BLP = sub_fixname(BLP,BLP_NAME);
  sigsave(Ses,ExpNo,BLP_NAME,BLP);
end;



return



% ==========================================================
function Sig = sub_fixname(Sig,NewName)
    
if iscell(Sig),
  for N = 1:numel(Sig),
    Sig{N} = sub_fixname(Sig{N},NewName);
  end
  return;
end
Sig.dir.dname = NewName;

return
