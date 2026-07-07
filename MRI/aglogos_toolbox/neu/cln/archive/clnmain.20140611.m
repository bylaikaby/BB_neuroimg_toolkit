function Cln = clnmain(SESSION,ExpNo,ARGS)
%CLNMAIN - Remove electromagnetic interference patterns from physiology signal.
%	CLNMAIN(SESSION,ExpNo,ARGS) uses clnadf.m to denoise the
%	physiology signal. It must be used after the MRI events have been
%	readjusted and the file ClnAdjEvt.mat or clnadj directory is created under the
%	session's home directory. CLNMAIN will use these events to separate the
%	gradient-interference patterns and compute the mean interference and
%	correlated PCs of each gradient type.  The mean interference and correlated PC
%   will be subtracted from the signal.
%
%  TIPS :
%    Analysis parameters can be set as ANAP.clnpar.xxx in the session description file.
%    If the signal is not stable enough even during no gradient noise periods, then,
%    set ANAP.clnpar.PCACOEF = xxx in the description file with lower value like 0.15.
%    GRP.xxx.anap.clnpar is also effective with highest priority.
%
%  NOTES :
%   Analysis parameter for cleaning is like follwing, and these values can be
%   set as ANAP.clnpar.xxx in the description file.
%     ANAP.clnpar.DEBUG       = 0;         % Debug flag for clnadf, not clnmain
%     ANAP.clnpar.DECFRAC     = 3;         % Decimation factor
%     ANAP.clnpar.HIGHPASS    = 1;         % Cutoff freq for high pass (in Hz)
%     ANAP.clnpar.METHOD      = 'pca';     % cleaning method, 'pca'|'regress'
%     ANAP.clnpar.LOWRECOVER  = 0;         % Recover low-freq componet(s) removed by any highpass
%     ANAP.clnpar.PREPCA      = 0.0015;    % Pre-period for PCA data in sec.
%     ANAP.clnpar.PCALAGS     = 5;         % Lags for selecting PC's to remove
%     ANAP.clnpar.PCACOEF     = 0.25;      % correlation coefficient (works fine)
%     ANAP.clnpar.NOPCS       = 6;         % Number of singular values to compute
%     ANAP.clnpar.NOREM       = 6;         % Number of PCs to remove
%     ANAP.clnpar.PCAGAP      = 1;         % Removes gaps around edges of PCA data.
%     ANAP.clnpar.OUTLIERS    = 1;         % Set if check for outliers is desired
%     ANAP.clnpar.SAVE        = 1;         % Create/Append MAT file
%     ANAP.clnpar.SAVEGRA     = 0;         % Save gradient noise
%     ANAP.clnpar.REMOVE_ES   = 0;         % try to remove microstimulation artifact
%     ANAP.clnpar.REMOVE_ECG  = 0;         % try to remove hear-beat artifact
%     ANAP.clnpar.USE_LANSVD  = 0;         % use faster svds_lansvd() than svds().
%
%   16.09.13 YM :
%     maximum diff. between USE_LANSVD=0|1 was 0.0046% while x2 faster.
%     >> tic, Cln0 = clnmain('ratjp1',1,struct('USE_LANSVD',0)); toc
%     >> tic, Cln1 = clnmain('ratjp1',1,struct('USE_LANSVD',1)); toc
%     >> d = abs(Cln0.dat - Cln1.dat);
%     >> [maxv maxi] = max(d);
%     >> for N=1:length(maxi), v0(N)=Cln0.dat(maxi(N),N); v1(N)=Cln1.dat(maxi(N),N); end
%     >> plot(maxv./abs(v0)*100);  xlabel('Channel'); ylabel('Max Diff in %');
%
%	============================================
%	Cln structure:
%	============================================
%    session: 'n00eb1'
%    grpname: 'injs'
%      ExpNo: 16
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        usr: [1x1 struct]
%         dx: 1.4400e-004
%        dat: [8575030x1 double]
%
%  VERSION :
%	1.00 24.05.05 YM  derived from clnmain.m of NKL.
%	1.01 03.08.05 YM  bug fix.
%	1.02 15.08.05 YM  checks Ses.anap.clnpar as cleaning params.  
%	1.03 05.03.08 YM  supports REMOVE_ES.
%	1.04 07.06.10 YM  uses grp.hardch for phys channels.
%	1.05 07.10.10 YM  supports grp.procch to control the cleaning procedure.
%	1.06 07.10.10 YM  bug fix of OUTLIERS, now done by channel.
%	1.07 15.02.11 YM  supports GRPP.(xxx).stimch.
%	1.08 31.01.12 YM  uses sigfilename().
%	1.10 12.04.13 YM  channel order follows grp.hardch, no sorting.
%	1.11 17.07.13 YM  use sigsave().
%	1.12 30.08.13 YM  supports "LOWRECOVER".
%	1.13 02.09.13 YM  supports "REMOVE_ECG".
%   1.14 13.09.13 SE/YM supports "USE_LANSVD" for x2 faster svds function.
%   1.15 11.06.14 YM  supports method (regress), PCA_HIGHPASS.
%
% See also sesgetcln clnadjevt clnadf sigsave 


DEBUG = 0;
if nargin == 0,
  switch DEBUG
   case 1,
	SESSION = 'c01jw1';
	ExpNo = 31;
   case 2,
	SESSION	= 'j00fo1';
	ExpNo = 22;
   case 3
    SESSION = 'm02lx1';
    ExpNo = 1;
   case 4
    SESSION = 'j04x41';
    ExpNo = 3;
   otherwise
    help clnmain; return;
  end
end

% ===========================================================================
% GET BASIC INFO
% ===========================================================================
Ses	= goto(SESSION);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);


% ===========================================================================
% DEFAULT CONTROL PARAMETERS
% NOTE: IF NOREM == 0, THE PCs TO REMOVE ARE DEFINED BY CHECKING
% THE EXPLAINED VARIANCED AND THE CORRELATION WITH THE MEAN INTERFERENCE.
% ===========================================================================
ANAP.DEBUG       = 0;			% Debug flag for clnadf, not clnmain
ANAP.DECFRAC	 = 3;			% Decimation factor
ANAP.HIGHPASS    = 1;           % Cutoff freq for high pass (in Hz)
ANAP.LOWRECOVER  = 0;           % Recover low-freq componet(s) removed by any highpass.
ANAP.METHOD      = 'pca';       % cleaning method, 'pca'|'regress'
ANAP.SCALE_SUBTRACT = 0;        % scale the mean noise for subtraction.
ANAP.PREPCA      = 0.0015;		% Pre-period for PCA data in sec.
ANAP.PCA_HIGHPASS = 0;          % Apply highpass
ANAP.PCALAGS	 = 5;			% Lags for selecting PC's to remove
ANAP.PCACOEF	 = 0.25;		% correlation coefficient (works fine)
ANAP.NOPCS	     = 6;			% Number of singular values to compute
ANAP.NOREM	     = 6;			% Number of PCs to remove
ANAP.PCAGAP      = 1;			% Removes gaps around edges of PCA data.
ANAP.OUTLIERS    = 1;			% Set if check for outliers is desired

%ANAP.PCALAGS	    = 20;			% Lags for selecting PC's to remove
%ANAP.PCACOEF	    = 0.2;			% correlation coefficient (works fine)
%ANAP.NOPCS	    = 12;			% Number of singular values to compute
%ANAP.NOREM	    = 12;			% Number of PCs to remove

ANAP.SAVE	     = 1;			% Create/Append MAT file
ANAP.SAVEGRA     = 0;			% Save gradient noise

ANAP.REMOVE_ES   = 0;           % try to remove microstimulation artifact
ANAP.REMOVE_ECG  = 0;           % try to remove hear-beat artifact

ANAP.USE_LANSVD  = 0;           % use faster svds_lansvd() than svds().

if strcmpi(ANAP.METHOD,'regress')
  ANAP.PCA_HIGHPASS = 1;  % enable for "regress" as default
end

% Evaluate anap by sessions/group, if any
tmpanap = getanap(Ses,ExpNo);
if isfield(tmpanap,'clnpar'),
  if isfield(tmpanap.clnpar,'METHOD') && strcmpi(tmpanap.clnpar.METHOD,'regress')
    ANAP.PCA_HIGHPASS = 1;  % enable for "regress" as default
  end
  ANAP = sctmerge(ANAP,tmpanap.clnpar);
end
clear tmpanap;
% Evaluate ARGS, if any
if exist('ARGS','var'),
  if isfield(ARGS,'METHOD') && strcmpi(ARGS.METHOD,'regress')
    ANAP.PCA_HIGHPASS = 1;  % enable for "regress" as default
  end
  ANAP = sctmerge(ANAP,ARGS);
end;

% Evaluate Ses.anap.clnpar, if any
%if isfield(Ses.anap,'clnpar'),  ANAP = sctmerge(ANAP,Ses.anap.clnpar);  end
% Evaluate grp.anap.clnpar, if any
%if isfield(grp,'anap') && isfield(grp.anap,'clnpar'),  ANAP = sctmerge(ANAP,grp.anap.clnpar);  end


if ~ismicrostimulation(Ses,ExpNo),  ANAP.REMOVE_ES = 0;  end

% ===========================================================================
% READ THE CORRECTED MRI EVENTS FROM THE ClnAdjEvt.mat FILE
% ===========================================================================
if sesversion(Ses) >= 2,
  fname = sigfilename(Ses,ExpNo,'clnadj');
  if ~exist(fname,'file'),
    fprintf(' %s: no MRI event data, doing clnadjevt()...',mfilename);
    clnadjevt(Ses,ExpNo,0);
    fprintf(' done.\n');
  end
  MriEvt = load(fname,'clnadj');
  MriEvt = MriEvt.clnadj;
else
  MriEvtName = sprintf('exp%03d',ExpNo);
  if ~exist('ClnAdjEvt.mat','file') || isempty(who('-file','ClnAdjEvt.mat',MriEvtName)),
    fprintf(' %s: no MRI event data, doing clnadjevt()...',mfilename);
    clnadjevt(Ses,ExpNo,0);
    fprintf(' done.\n');
  end
  MriEvt = load('ClnAdjEvt.mat', MriEvtName);
  MriEvt = MriEvt.(MriEvtName);
end



% =================================================================
% PREPARE for cleaning
% =================================================================
dirs = getdirs;
ANAP.root   = sprintf('tmpcln_%s_%03d',Ses.name,ExpNo);
ANAP.tmpdir = dirs.TMP;
clear dirs;
if exist(ANAP.tmpdir,'dir') == 0,
  %[fp,fr,fe] = fileparts(ANAP.tmpdir);
  if mkdir(ANAP.tmpdir) == 0,
    fprintf('%s ERROR: can not find/create %s\n',mfilename,ANAP.tmpdir);
    return;
  end
end

%delete(fullfile(ANAP.tmpdir,sprintf('%s*.mat',ANAP.root)));
%delete(fullfile(ANAP.tmpdir,'tmpcln*.mat'));
% delete only the current one to keep other ones used by another MATLAB process.
delete(fullfile(ANAP.tmpdir,sprintf('%s_*.mat',ANAP.root)));


%VALID_CHAN = sort(grp.hardch);
VALID_CHAN = grp.hardch;  % channel order follows grp.hardch

if isfield(grp,'procch') && ~isempty(grp.procch),
  PROC_CHAN = grp.procch;  % binary flag, something like [1 0... 1]
else
  PROC_CHAN = ones(size(VALID_CHAN));
end

% =================================================================
% PRINT INFO
% =================================================================
fprintf(' %s: %s Exp=%d  NObs=%d NCh=%d ',...
        mfilename,Ses.name,ExpNo,MriEvt.NoObsp,length(VALID_CHAN));
fprintf(' Dec=%d SaveGra=%d RemoveES=%d RemoveECG=%d\n',...
        ANAP.DECFRAC,ANAP.SAVEGRA,ANAP.REMOVE_ES,ANAP.REMOVE_ECG);
switch lower(ANAP.METHOD)
 case {'pca'}
  fprintf('     PCA: NPCs=%d NRem=%d PCACoef=%.2f PrePCA=%.1fms PcaHP=%d UseLANSVD=%d ScaleSubtract=%d',...
          ANAP.NOPCS,ANAP.NOREM,ANAP.PCACOEF,ANAP.PREPCA*1000,ANAP.PCA_HIGHPASS,ANAP.USE_LANSVD,ANAP.SCALE_SUBTRACT);
 case {'regress'}
  fprintf(' REGRESS: NPCs=%d PrePCA=%.1fms PcaHP=%d UseLANSVD=%d',...
          ANAP.NOPCS,ANAP.PREPCA*1000,ANAP.PCA_HIGHPASS,ANAP.USE_LANSVD);
 otherwise
  error(' ERROR %s: unknown method(''%s'') of cleaning, must be either ''pca'' or ''regress''.\n',mfilename,ANAP.METHOD);
end
if isfield(ANAP,'DEBUG') && ~isempty(ANAP.DEBUG),
  fprintf(' DEBUG=%d',ANAP.DEBUG);
end
fprintf(' tmpdir=%s\n',ANAP.tmpdir);
fprintf('          GradPattern=%d:[', length(MriEvt.gradtype));
for N = 1:length(MriEvt.gradtype),
  if N == length(MriEvt.gradtype),
    fprintf('%d', MriEvt.gradtype(N));
  else
    fprintf('%d-', MriEvt.gradtype(N));
  end
end
fprintf(']\n');


% =================================================================
% RUN cleaning
% =================================================================
TMPFILES = {};
for iObsp = 1:MriEvt.NoObsp,
  for iChan = 1:length(VALID_CHAN),
    TMPFILES{end+1} = clnadf(Ses,MriEvt,iObsp,VALID_CHAN(iChan),ANAP,PROC_CHAN(iChan));
  end
end


% FILL Cln STRUCTURE !!
Cln = getcln(Ses,ExpNo);
%Cln.usr = anap;		% anap := expXXX
Cln.usr.adfoffset         = par.adf.adfoffset;
Cln.usr.adflen            = par.adf.adflen;
Cln.usr.args.decfrac	  = ANAP.DECFRAC;
Cln.usr.args.highpass	  = ANAP.HIGHPASS;
Cln.usr.args.lowrecover   = ANAP.LOWRECOVER;
Cln.usr.args.method       = ANAP.METHOD;
Cln.usr.args.scale_subtract = ANAP.SCALE_SUBTRACT;
Cln.usr.args.use_lansvd   = ANAP.USE_LANSVD;
Cln.usr.args.pca_highpass = ANAP.PCA_HIGHPASS;
Cln.usr.args.pcalags	  = ANAP.PCALAGS;
Cln.usr.args.pcacoef	  = ANAP.PCACOEF;
Cln.usr.args.nopcs		  = ANAP.NOPCS;
Cln.usr.args.norem		  = ANAP.NOREM;
Cln.usr.args.outliers	  = ANAP.OUTLIERS;


fprintf(' %s: tfactor=%g, offs/len=%g/%gsec...',...
        mfilename,par.adf.tfactor,Cln.usr.adfoffset,Cln.usr.adflen);

ADF_TFACTOR = par.adf.tfactor;
[Cln.dat DX GRADAT] = subGetClnData(TMPFILES,Cln.usr.adfoffset,Cln.usr.adflen,ADF_TFACTOR,VALID_CHAN);
% must be corrected to use universal stimulus/event timings.
Cln.dxorg = DX;
Cln.dx = Cln.dxorg * ADF_TFACTOR;
fprintf('\n');


if ANAP.DEBUG == 0,
  for N=1:length(TMPFILES),
    if exist(TMPFILES{N},'file'),  delete(TMPFILES{N});  end
  end
end



% CHECK HERE FOR LARGE ARTIFACTS OF ANY SORT
if ANAP.OUTLIERS,
  SDX = 7;
  if 1,
    for iCh = 1:size(Cln.dat,2),
      if ~any(PROC_CHAN(iCh)),  continue;  end
      y = abs(prod(Cln.dat(:,iCh,:),3));  % dim 3 as multiple obsp.
      m = nanmean(y(:));
      s = nanstd(y(:));
      crit = m + s * SDX;
      idx = find(y>=crit);
      
      if ~isempty(idx),
        idx = cat(1,idx,idx+1,idx-1);
        idx(idx<1)=1;
        for K = 1:size(Cln.dat,3),
          newy = nanmean(Cln.dat(y<crit,iCh,K));
          Cln.dat(idx,:,K) = newy;
        end
        Cln.err(iCh).dat  = Cln.dat(idx,iCh,:);
        Cln.err(iCh).idx  = idx;
        Cln.err(iCh).mean = m;
        Cln.err(iCh).std  = s;
        Cln.err(iCh).p    = length(idx)/size(Cln.dat,1);
        fprintf(' %s: WARNING OUTLIERS(Ch=%2d) %7d/%d ponts (p=%g)\n',...
                mfilename,iCh,length(idx), size(Cln.dat,1), Cln.err(iCh).p);
      else
        Cln.err(iCh).dat  = [];
        Cln.err(iCh).idx  = [];
        Cln.err(iCh).mean = m;
        Cln.err(iCh).std  = s;
        Cln.err(iCh).p    = 0;
      end
      
      
    end
    
    
  else
    y = abs(prod(prod(Cln.dat,2),3));  % dim 3 as multiple obsp.
    m = mean(y(:));
    s = std(y(:));
    crit = m + s * SDX;
    idx = find(y>=crit);
  
    if ~isempty(idx),
      fprintf(' %s: WARNING OUTLIERS...',mfilename);
      idx = cat(1,idx,idx+1,idx-1);
      idx(idx<1)=1;
      m = mean(Cln.dat(y<crit,:,:));
      newy = repmat(m,[length(idx) 1]);
      Cln.dat(idx,:,:)=newy;
      Cln.err.dat = Cln.dat(idx,:,:);
      Cln.err.idx = idx;
      Cln.err.mean = m;
      Cln.err.std = s;
      Cln.err.p = length(idx)/size(Cln.dat,1);
      fprintf(' %d/%d Values (p=%4.8f)\n',...
              length(idx), size(Cln.dat,1), Cln.err.p);
    end;
  end
end;

if ANAP.SAVEGRA && ~isempty(GRADAT),
  Cln.gra = GRADAT;
end;


if isfield(grp,'stimch') && ~isempty(grp.stimch) && ~isempty(grp.stimch{1}),
  Cln.stimch = getstimchan(Ses,ExpNo,ANAP.DECFRAC,...
                               MriEvt.SS_OFFS(1),MriEvt.obslen(1)-MriEvt.SS_OFFS(1),ADF_TFACTOR);
end


% ===========================================================================
% SAVE in MAT file if regular process..
% ===========================================================================
if ~nargout && ANAP.SAVE,
  sigsave(Ses,ExpNo,'Cln',Cln);
  % fname = sigfilename(Ses,ExpNo,'Cln');
  % if ~exist(fname,'file'),
  %   % mkdir if needed
  %   mmkdir(fileparts(fname));
  %   fprintf('  Saving "Cln" into %s ...', fname);
  %   save(fname,'Cln');
  % else
  %   fprintf('  Appending "Cln" into %s', fname);
  %   save(fname,'Cln','-append');
  % end
  % fprintf(' done.!\n');
  % no need to hold data
  clear Cln;
end;


return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get cleaned data from temporaly files
function [CLNDAT DX GRADAT] = subGetClnData(TMPFILES,adfoffset,adflen,ADF_TFACTOR,VALID_CHAN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CLNDAT = [];  GRADAT = [];
% use decimal 4digits of ADF_TFACTOR to avoid individual small difference in lengths.
ADF_TFACTOR = round(ADF_TFACTOR*10000)/10000;

for N = 1:length(TMPFILES),
  Sig = load(TMPFILES{N},'Sig');
  Sig = Sig.Sig;
  DX  = Sig.dx;
  if isempty(CLNDAT),
    iadfofs = round(adfoffset/DX/ADF_TFACTOR) + 1;
    iadflen = round(adflen/DX/ADF_TFACTOR);
    if iadflen > length(Sig.cln),
      iadflen = length(Sig.cln);
      fprintf(' %.3f-->%.3fs',adflen,iadflen*DX*ADF_TFACTOR);
    end
    CLNDAT = zeros(iadflen,length(TMPFILES),Sig.NoObsp,class(Sig.cln));
    if length(iadfofs) < Sig.NoObsp,
      iadfofs = ones(1,size(Sig.NoObsp,3))*iadfofs(1);
    end
    sel = 0:iadflen-1;
    if isfield(Sig,'gra'),
      GRADAT = zeros(iadflen,1,Sig.NoObsp,class(Sig.gra));
    end
  end
  %iChan = Sig.ChanNo;
  iChan = N;
  iObsp = Sig.ObspNo;
  CLNDAT(:,iChan,iObsp) = Sig.cln(sel+iadfofs(iObsp));
  if isfield(Sig,'gra'),
    GRADAT(:,1,iObsp) = Sig.gra(sel+iadfofs(iObsp));
  end
  clear Sig;
end

return;
