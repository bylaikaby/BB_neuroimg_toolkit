function varargout = blp2sig(Blp,SigType,oSigNames)
%BLP2SIG - Averages bands into traditional signal (Lfp, Mua, etc.)
% BLP2SIG (Blp, SigType) averages the bands according to SigType
%
%   ANY PARAMETERS EXTRACTING BLP CAN BE MODIFIED THROUGH THE SESSION FILE.
%   ====================================================
%   info.band{ 1}  = {[   0     4] 'ep'    'LFP',  0};  % Evoked potential
%   info.band{ 2}  = {[   4    12] 'stmnm' 'LFP',  2};  % Stim-related & Neuromodulatory?
%   info.band{ 3}  = {[  15    60] 'nm'    'LFP',  4};  % Stim-unrelated; Neuromodulatory
%   info.band{ 4}  = {[  70   110] 'stm'   'LFP',  4};  % Stim-related; independent of MUA (50%)
%   info.band{ 5}  = {[  10   110] 'lfp'   'LFP',  4};  % Traditional LFPs
%   info.band{ 6}  = {[ 500  3000] 'mua'   'MUA', 45};  % Traditional Analog MUA
%   info.lBands    = [1:5];                             % Bands in the LFP range
%   info.mBands    = [6];                               % Bands in the MUA range
%
%   PARAMETERS FOR FIR FILTER
%   ====================================================
%   ANAP.siggetblp.flttype    = 'cheby2';
%   ANAP.siggetblp.lstop      = 1;
%   ANAP.siggetblp.mstop      = 50;
%   ANAP.siggetblp.hstop      = 50;
%   ANAP.siggetblp.dB         = 60;
%   ANAP.siggetblp.passripple = 0.1;
%   ANAP.siggetblp.NewFsTr    = 40;       % 60dB decay width for above resampling
%  
%   PARAMETERS TO MINIMIZE UNSTABLE PERIODS IN BOTH TIME EDGES
%   ====================================================
%   ANAP.siggetblp.mirror     = 1;
%  
% See also EXPBLP2SIG
%
% NKL 29.07.04

if nargin < 1,
  help blp2sig;
  varargout = {};
  return;
end;

if nargin < 3,
  oSigNames = {'LfpL','LfpM','LfpH','Mua'};
end;

if nargin < 2,
  SigType = {'stmnm','nm','stm','mua'};
end;

SIG_IS_STRUCT = 0;
if isstruct(Blp) == 1,
  SIG_IS_STRUCT = 1;
  Blp = {Blp};
end;

for N=1:length(Blp{1}.info.band),
  SIGTYPES{N} = lower(Blp{1}.info.band{N}{2});
end;
SigType = lower(SigType);

if ~iscell(SigType),
  SigType = {SigType};
end;

for SigNo = 1:length(Blp),
  
  Sig = Blp{SigNo};
  
  for N=1:length(SigType),
    if strcmp(SigType{N},'lfprmua'),
      idx = [8 9];
    else
      if ~any(find(strcmp(SigType{N},SIGTYPES))),
        fprintf('BLP2SIG: Signal not known\n');
        keyboard;
      end;
      idx = find(strcmp(SIGTYPES,SigType{N}));
    end;
    
    % DATA FIELD   Time X Chan X Freq X ExpNo
    tmpout{SigNo}{N} = rmfield(Sig,'dat');
    tmpout{SigNo}{N}.dat = hnanmean(Sig.dat(:,:,idx,:),3);
    if isfield(Sig,'raw'),
      tmpout{SigNo}{N}.raw = hnanmean(Sig.raw(:,:,idx,:),3);
    end;
    if isfield(Sig,'org'),
      tmpout{SigNo}{N}.org = hnanmean(Sig.org(:,:,idx,:),3);
    end;
    
    if strcmp(SigType{N},'lfprmua'),
      tmpout{SigNo}{N}.info.band = 'LFPRMUA';
    else
      tmpout{SigNo}{N}.info.band = tmpout{SigNo}{N}.info.band{idx};
    end;
    tmpout{SigNo}{N}.dir.dname = SigType{N};
    if exist('oSigNames','var'),
      tmpout{SigNo}{N}.dir.dname = oSigNames{N};
    end;
    
    tmpout{SigNo}{N}.dsp.func = 'dspsig';
  end;

end;

clear Sig;
if length(SigType) == 1,
  for N=1:length(Blp),
    Sig{N} = tmpout{N}{1};
  end;
else
  Sig = tmpout;
end;

if nargout == 0,
  COL = 'cbgrkmcbgrkmcbgrkmcbgrkmcbgrkm';
  mfigure([100 200 800 600]);
  if length(Sig{1}) == 1,
    for N=1:length(Blp),
      subDspSig(Sig{N},'color',COL(N));
      hold on;
    end;
    grid on;
    title(sprintf('dspsig(%s,%s)',Sig{1}.session,Sig{1}.grpname));
    xlabel('Time in sec');
    ylabel('Signal in SD Units');
    grid on;
  else
  end;
  return;
end;

if SIG_IS_STRUCT,
  Sig = Sig{1};
end;
varargout = Sig;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function hd = subDspSig(Sig,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s = size(Sig.dat);
Sig.dat = reshape(Sig.dat,[s(1) prod(s(2:end))]);
Sig.err = std(Sig.dat,1,2)/sqrt(size(Sig.dat,2));
Sig.dat = mean(Sig.dat,2);

s = size(Sig.org);
Sig.org = reshape(Sig.org,[s(1) prod(s(2:end))]);
Sig.org = mean(Sig.org,2);

to = [0:size(Sig.org,1)-1]*Sig.orgdx(1); to=to(:);
t  = [0:size(Sig.dat,1)-1]*Sig.dx(1); t=t(:);
[ax,ohd,hd] = plotyy(to,Sig.org,t,Sig.dat);

set(ohd,varargin{:},'linewidth',0.5,'linestyle',':');
set(hd, varargin{:},'linewidth',2);

set(gca,'xlim',[t(1) t(end)]);

