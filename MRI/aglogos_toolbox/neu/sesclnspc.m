function varargout = sesclnspc(SESSION,EXPS,LOG)
%SESCLNSPC - Make spectrograms for the Cln signal of each experiment
% The function uses sigspc.m and generates a spectrogram for each
% experiment of a session. The spectogram window is defined by the
% sampling time of the images, and it's corrected by using the MRI
% events instead of the pre-defined values in the description
% file. Hanning window is used for computing spectograms, and the
% actual (padded) window size is defined by the variable NFFT.
%
% SESCLNSPC(SesName,EXPS) - Where, EXPS are the experiments of a
% session. If all experiments will be processed, the empty array []
% can be passed as second arguments, or EXPS can be ignored completely.
%
% ClnSpc = SESCLNSPC(SesName,ExpNo) does the same thing but returns result
% without saving data if only single experiment is specified.
%  
%
% EXAMPLE :
%   >> sesclnspc('m02lx1',1);
%   >> ClnSpc = sigload('m02lx1',1,'ClnSpc');
%   >> ClnSpc
%      ClnSpc = 
%        session: 'm02lx1'
%        grpname: 'movie1'
%          ExpNo: 1
%            dir: [1x1 struct]
%            dsp: [1x1 struct]
%           chan: [1 2]
%            dat: [1560x1025x2 double]   <--- dat as (t,f,chan)
%             dx: [0.2500 3.3736]        <--- dx as (dt,df)
%          dxorg: [0.2487 3.3908]
%            err: [1x1 struct]
%          movie: [1x1 struct]
%            usr: [1x1 struct]
%            grp: [1x1 struct]
%            evt: [1x1 struct]
%            stm: [1x1 struct]
%
% Display Examples for ClnSpc
% -----------------------------
%   SHOWCLNSPC ('c98nm1',1);          - Plots NoChan subplots w/ flat specs
%   SHOWCLNSPC ('c98nm1',1,-1)        - Plots chan-mean in flat
%   SHOWCLNSPC ('c98nm1',1,[],'3d')   - Plots NoChan subplots w/ 3D specs
%   SHOWCLNSPC ('c98nm1',1,-1,'3d')   - Plots chan-mean in 3D
%
% NOTES :
%   Parameters for ClnSpc can be set as ANAP.sesclnspc.xxx or 
%   GRP.xxxx.sesclnspc.xxxx.
%     ANAP.sesclnspc.twin = ...      : time window in sec
%     ANAP.sesclnspc.overlap = ...   : overlap as the fraction of 'twin'
%    (ANAP.sesclnspc.dt = ...)       : shift in seconds, exclusive usage with 'overlap'.
%     ANAP.sesclnspc.nfft = ...      : num. FFT
%    (ANAP.sesclnspc.nfft_sec = ...) : num. FFT but in seconds, exclusive usage with 'nfft'.
%
% NOTES :
%  "TWIN" for FFT is usually the same as imaging TR, but "TWIN" can be
%  set by "ANAP.sesclnspc.twin" in the description file.
%
% VERSION :
%   1.00 10.10.02 NKL
%   1.01 16.02.04 YM  now ClnSpc is saved in 'SIGS' sub-directory.
%   1.02 16.04.04 YM  bug fix for b01nm1 where voltr <= 0...
%   1.03 17.01.05 YM  avoid error for D98.at1/at2.
%   1.04 21.07.05 YM  TWIN can be set by "ANAP.sesclnspc.twin".
%   1.05 28.01.08 YM  checks t-length if old data (grp.pvavr = 1).
%   1.06 30.01.08 YM  accepts ANAP.sesclnspc.nfft/nfft_sec/dt etc.
%   1.07 25.07.12 YM  use sigfilename().
%   1.08 25.07.12 YM  use sigsave().
%
% See also
% SIGSPC - Make spectrogram from signal iSig
% SHOWCLN - Show Cln signal
% DSPSIG - Display neural signals
% SHOWCLNSPC - Plot spectrograms as surface plots (3D or Flat)
% DSPCLNSPC - shows the spectrograms of the Cln signal (e.g. ClnSpc)
% GETLFPMUA - Extract power signals from ClnSpc (LfpPow,MuaPow)
% SESGETLFPMUA - Extract power signals from ClnSpc (LfpPow,MuaPow)


if nargin < 1, eval(sprintf('help %s',mfilename)); return;  end


USE_ASCA=0; % (Arthur Stefano Cesare Andrei) implementation

Ses = goto(SESSION);

if nargin < 3,
  LOG = 0;
end;

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESCLNSPC_',Ses.name,'.log');	% Start log file
  diary off;										% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);									% Start the new one
end;

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp = getgrp(Ses,ExpNo);
  par = expgetpar(Ses,ExpNo);
  anap = getanap(Ses,ExpNo);

  if isfield(grp,'done') & grp.done,
	continue;
  end;

  if ~isrecording(Ses,grp.name),
	continue;
  end;
  
  fprintf('%s %s: Processing [%d/%d]: %s, %s, ExpNo=%d\n', ...
          gettimestring,mfilename,iExp,length(EXPS),...
          Ses.name,grp.name,ExpNo);
  spcfile = sigfilename(Ses,ExpNo,'clnspc');
  %load(sigfilename(Ses,ExpNo,'Cln'),'Cln');
  fprintf(' loading Cln...');
  Cln = sigload(Ses,ExpNo,'Cln');
  if isfield(Cln,'evt'),  ClnSpc = rmfield(Cln,'evt');  end
  if isfield(Cln,'grp'),  ClnSpc = rmfield(Cln,'grp');  end
  if isfield(Cln,'stm'),  ClnSpc = rmfield(Cln,'stm');  end
  Cln.usr = {};

  if isfield(par,'evt') && ~isempty(par.evt),
    % NOTE:
    % We chose window length based on the inter-volume time of
    % imaging. In the combined sessions this is taken from the
    % Paravision parameter files and stored in .voltr. In the
    % physiologyh only sessions it's the product of triggers per
    % volume with the inter-trigger time which is defined in
    % mseconds.
    TWIN = par.evt.interVolumeTime / 1000.;
  else
    % 17.01.05 YM, D98.at1/at2 will return empty 'par'.
    fprintf(' WARNING %s: no event info, set TWIN as 0.25s.\n',mfilename);
    TWIN = 0.25;
  end

  % E.G. NOVERLAP = 0.25, means 25% overlap between successive windows
  if isfield(anap,'overlap'),
    dT = TWIN * (1.0 - anap.overlap);
  elseif isfield(anap,'sesclnspc') ...
        & isfield(anap.sesclnspc,'overlap') & ~isempty(anap.sesclnspc.overlap),
    dT = TWIN * (1.0 - anap.sesclnspc.overlap);
  elseif isfield(grp,'overlap'),
    dT = TWIN * (1.0 - grp.overlap);
  else
    dT = TWIN;
  end;

  
  NFFT = [];
  if isfield(anap,'sesclnspc'),
    % TWIN
    if isfield(anap.sesclnspc,'twin') & ~isempty(anap.sesclnspc.twin),
      TWIN = anap.sesclnspc.twin;
    end
    % dT
    if isfield(anap.sesclnspc,'dt') & ~isempty(anap.sesclnspc.dt),
      dT   = anap.sesclnspc.dt;
    end
    % NFFT
    if isfield(anap.sesclnspc,'nfft'),
      NFFT = anap.sesclnspc.nfft;
    end
    if isfield(anap.sesclnspc,'nfft_sec'),
      NFFT = round(anap.sesclnspc.nfft_sec/Cln.dx);
    end
  end
  %if isempty(NFFT),  NFFT = round(TWIN/Cln.dx);  end
  if ischar(dT) && any(strcmpi(dT,{'mri','bold'})),
    dT = par.evt.interVolumeTime / 1000.;
  end
  
  
  
  if USE_ASCA,
    keyboard;
    fprintf(' sigspcASCA(Tw=%g,dT=%g)...',TWIN,dT);
    ClnSpc = subGetClnSpc_ASCA(Cln,TWIN,dT);
    ClnSpc.dir.spcfile = spcfile;
    fprintf('\n');
  else
    if length(Cln) == 1,
      ClnSpc = subGetClnSpc(Cln,TWIN,dT,NFFT);
      ClnSpc.dir.spcfile = spcfile;
    else
      for K=1:length(Cln),
        ClnSpc{K} = subGetClnSpc(Cln{K},TWIN,dT,NFFT);
        ClnSpc{K}.dir.spcfile = spcfile;
        Cln{K} = {};  % no more need, free the memory
      end;
    end;
  end;
  
  % old data
  if isfield(grp,'pvavr') & grp.pvavr > 0,
    nt_spc = size(ClnSpc.dat,1);
    nt_mri = par.pvpar.nt;
    %if ClnSpc.dx(1) == par.pvpar.imgtr & nt_spc > nt_mri,
    if ClnSpc.dx(1)-par.pvpar.imgtr<0.001 & nt_spc > nt_mri,
      fprintf(' nt[%d-->%d]...',nt_spc,nt_mri);
      ClnSpc.dat = ClnSpc.dat(1:nt_mri,:,:,:,:);
    end
  end

  if length(EXPS) == 1 & nargout > 0,
    varargout{1} = ClnSpc;
  else
    sigsave(Ses,ExpNo,'ClnSpc',ClnSpc);
    % fprintf(' saving ''ClnSpc'' to %s...',spcfile);
    % if exist(spcfile,'file'),
    %   save(spcfile,'ClnSpc','-append');
    % else
    %   % mkdir if needed
    %   mmkdir(fileparts(spcfile));
    %   save(spcfile,'ClnSpc');
    % end
    % fprintf(' done.\n');
  end
  clear Cln ClnSpc;  % no more need, free the memory
end;

if LOG,
  diary off;
end;
return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ClnSpc = subGetClnSpc(Cln,T,dT,NFFT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
% The input arguments T and dT are both equal to TR because there is no "overlap" in the
% shifted windows.
if nargin < 4,  NFFT = [];  end

% 16.04.04 YM
% in some cases (b01nm1), voltr < 0, set T as 0.25sec.
if T <= 0,  T = 0.25;  end

if isempty(NFFT) || any(NFFT <= 0),
  % T/Cln.dx  usuall 1(sec) / Cln.dx.. rounding to next power-of-two is 8192
  NFFT = getpow2(T/Cln.dx,'ceiling');
end

try,
  fprintf(' sigspc(Tw=%g,dT=%g,Nfft=%d)...',T,dT,NFFT);
  ClnSpc = sigspc(Cln, T, dT, NFFT, 'hanning');
catch
  fprintf('\n%s\n',lasterr);
  fprintf(' sesclnspc:  If memory problem, then try to run MATLAB without\n');
  fprintf('  java support setting ''-nojvm'' option.  Java seems to me \n');
  fprintf('  to cause memory fragmentation which results in failure of \n');
  fprintf('  allocation of large amount of memory, say ~0.5G.\n');
  fprintf('                                     29.02.04 yusuke\n');
  keyboard
end
fprintf('\n');

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ClnSpc = subGetClnSpc_ASCA(Cln,TWIN,dT)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [Cln.dat Fs]=filtercln(Cln.dat,1/Cln.dx,[0 250]);
  Cln.dx=1/Fs;
  winlen=ceil(TWIN*Fs);
  nfft=getpow2(winlen,'ceiling');
  params.overlap=winlen-ceil(dT*Fs);
  params=getsaparams(params);
  
  for ch=1:size(Cln.dat,2)
    P(:,:,ch)=getmtPSD(Cln.dat(:,ch),winlen,nfft,Fs,params);
  end;
  ClnSpc=Cln;
  ClnSpc.dat=P;
  ClnSpc.dx(1)=winlen/Fs;
  ClnSpc.dx(2)=Fs/2/size(ClnSpc.dat,2);
  
  ClnSpc.dir.dname	= 'ClnSpc';
  ClnSpc.dsp.func		= 'dspclnspc';
  ClnSpc.dsp.args		= '1D';
  ClnSpc.dsp.label	= {};
  ClnSpc.dsp.label{1}	= sprintf('spectral power');
  ClnSpc.dsp.label{2}	= sprintf('time (dt= %g sec.)',ClnSpc.dx(1));
  ClnSpc.dsp.label{3}	= sprintf('freq. (df= %gHz)',ClnSpc.dx(2));
  
  
  
  ClnSpc.usr.(mfilename).nfft = nfft;
  ClnSpc.usr.(mfilename).noverlap = params.overlap;
  ClnSpc.usr.(mfilename).saparams = params;
  ClnSpc.usr.(mfilename).winfunc = 'multitaper';
  ClnSpc.usr.(mfilename).window = winlen;
