function Trial =  sesgettrial(SesName,GrpExp,SigName,varargin)
%SESGETTRIAL - Split observation periods into trials
% SESGETTRIAL(SesName,GrpName,SigName) - splits stimulus/trial periods into trials.
%
%  Signal to run gettrial() can be set by CTG.trialSigs
%    CTG.TrialSigs            = {'roiTs','blp'};
%
%  Parameters can be controled by ANAP.gettrial, GRPP.anap.gettrial or GRP.xxx.anap.gettrial
%    ANAP.gettrial.status     = 1;         % sort or not, 0|1
%    ANAP.gettrial.Xmethod    = 'none';    % normalization, none|tosdu|zerobase
%    ANAP.gettrial.Xepoch     = 'blank';   % normalization, blank|prestim
%    ANAP.gettrial.sort       = 'trial';   % sort by what,  trial|stimulus
%    ANAP.gettrial.Average    = 1;         % average or not, 0|1
%    ANAP.gettrial.trial2obsp = 1;         % concatinate or not after sorting, 0|1
%  If different Xmethod for different signal, then can be set like
%    ANAP.gettrial.(signame).Xmethod = 'percent';
%
%
%  EXAMPLE :
%    >> sesgettrial(SesName,GRPNAME);       % does for all CTG.TrialSigs
%    >> sesgettrial(SesName,GRPNAME,'blp')  % does only for ''blp''
%    or
%    >> blp = sigload(SesName,ExpNo,'blp');
%    >> tblp = gettrial(blp);
%
%  VERSION :
%    0.90 NKL 07.08.04
%    0.91 AC  08.11.05 supports giving SigName instead of exps
%    0.92 NKL 18.11.05 sort by trial update, "isnumeric" position change
%    0.93 YM  16.03.06 loads signals one by one to avoid memory problem.
%    0.94 YM  23.11.07 loads signals in gettrial() to avoid memory problem.
%    0.95 YM  29.04.08 supports ANAP.gettrial.(signame).
%    0.96 YM  01.03.11 updates tSig.dir.dname as t(signame).
%    1.00 RMN 10.10.15 supports digital marker sorting
%    1.01 YM  24.05.16 bug fix sort
%    1.02 YM  06.03.19 make sure always a cell array for "roiTs" data.
%    1.03 YM  15.03.19 added IBRAINMEAN to std_pars{} to avoid crash in gettrial().
%    1.04 YM  16.07.20 bug fix for tSig = tSig{1} before saving.
%    1.05 NKL 18.07.20 Adapating to new requirements.. (ctg.TrialSigs etc..)
%
% See also GETTRIAL XFORM

% Function called with no arguments ---------------------------------------
if nargin < 1,  eval(['help ' mfilename]); return;  end

Sig=[];
%Input Sig
if issig(SesName)
  Sig     = SesName;
  SesName = Sig.session;
  GrpExp  = Sig.ExpNo;
  SigName = Sig.dir.dname;
end

Ses = goto(SesName);

if ~exist('GrpExp','var') || isempty(GrpExp)
  GrpExp = getgrpnames(Ses);
end
if ~exist('SigName','var'), SigName = Ses.ctg.TrialSigs; end
if ~iscell(SigName), SigName = {SigName}; end

if ischar(GrpExp)
  % GrpExp as a group name.    
  grp = getgrp(Ses,GrpExp);
  EXPS = grp.exps;
elseif iscell(GrpExp)
  % GrpExp as a cell array of groups
  for G = 1:length(GrpExp)
    sesgettrial(Ses,GrpExp{G},SigName,varargin{:});
  end
  return
else
  % GrpExp as EXPS
  EXPS = GrpExp;
  grp = getgrp(Ses,EXPS(1));
end

%RMN 22.10.14
ANAP = getanap(SesName,grp.name);
%==========================================================================
%Function  Standard Parameters
%==========================================================================
std_pars = {'iSig',[],'status',1,'Xmethod','none',...
    'Xepoch','prestim','sort','stimulus','Average',1,'trial2obsp',0,...
    'PreT',8,'PostT',2, 'sortDM', 0, 'detrend', 0, 'IBRAINMEAN', 0};

ANAP.gettrial = sctmerge_prior(ANAP.gettrial, std_pars);  


for N = 1:length(EXPS)
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
    
  if isempty(grp) || (~isrecording(Ses,grp.name) && ~isimaging(Ses,grp.name)), continue; end
  
  fprintf('%s SESGETTRIAL: [%3d/%d] %s ExpNo=%d(%s)', ...
          datestr(now,'HH:MM:SS'), N, length(EXPS), Ses.name,ExpNo,grp.name);
  
  if ismanganese(grp)
    fprintf(': manganese experiment, skipping...\n');
    continue;
  end
    
  fprintf('\n');
  % MAKE TRIALS FOR EVERY SIGNALS
  for S=1:length(SigName)
    if ~isimaging(grp) && any(strcmpi(SigName{S},{'roiTs','froiTs','tcImg'}))
      %fprintf(' skipping empty signal(s).\n');
      continue;
    end
    if ~isrecording(grp) && any(strcmpi(SigName{S},{'Cln','Spkt','Sdf','ClnSpc','blp'}))
      %fprintf(' skipping empty signal(s).\n');
      continue;
    end        
    fprintf('%8s: ', SigName{S});
    tmpanap = ANAP;
        
    % overwrite anap.gettrial with anap.gettrial.(signame)
    if isfield(ANAP.gettrial,SigName{S})
      tmpanap.gettrial = sctmerge(ANAP.gettrial,ANAP.gettrial.(SigName{S}));
    end
    % overwrite with "varargin".
    if ~isempty(varargin)
      tmpanap.gettrial = sctmerge_prior(varargin, tmpanap.gettrial);
    end
    
    if ~isfield(tmpanap,'gettrial') || tmpanap.gettrial.status == 0
      fprintf(' has no trials; Skipping...\n');
      continue;
    end
    
    fprintf('sort=%s detrend=%d xform=%s/%s Average=%d trial2obsp=%d\n',...
            tmpanap.gettrial.sort, tmpanap.gettrial.detrend,...
            tmpanap.gettrial.Xmethod, tmpanap.gettrial.Xepoch,...
            tmpanap.gettrial.Average, tmpanap.gettrial.trial2obsp);        

    %I will make the avarege here and not into "gettrial".
    DM_AVERAGE = tmpanap.gettrial.Average;
    if tmpanap.gettrial.sortDM && any(DM_AVERAGE)
      tmpanap.gettrial.Average = 0;
    end
    
    % NKL 08.03.2016 -- Loading of BLP is done within GETTRIAL; % tSig = gettrial(Sig);
    if strcmpi(SigName{S},'blp'),
      tSig = gettrial(Ses,ExpNo,SigName{S},tmpanap);
    else
      Sig = sigload(SesName,ExpNo,SigName{S});
      tSig = gettrial(Sig,tmpanap);
    end  

    if isempty(tSig)
      fprintf(' skipping empty signal(s).\n');
      continue;
    end

    % ===============================================================
    % NKL 14.11.2011
    % ===============================================================
    % This is new: it removes the brain's mean roiTs (excludeing stimulus-correlated series)
    % from each of the ROIs. For Rat this makes a bit difference, with much of the noise
    % strongly reduced!
    % ===============================================================
    % NKL 08.03.2016
    % ===============================================================
    % I have removed this sesgettrial, as we now do the BRAIN-MEAN-REMOVAL with the PCA
    % approach in the MAREATS!!!!
    % if isfield(tmpanap.gettrial,'IBRAINMEAN') & tmpanap.gettrial.IBRAINMEAN,
    %   if isimaging(grp) && any(strcmpi(SigName{S},{'roiTs','troiTs','froiTs','tfroiTs'})),
    %     tSig = rembrainmean(tSig);
    %   end
    % end
    name = sprintf('t%s',SigName{S});
    tSig = sub_fix_signame(tSig,name);
    %RMN: I modified the way to present the parameters in the DF
    %=========
    % Option - Sort Digital Markers
    %=========
    if tmpanap.gettrial.sortDM
      tSig = sortDM(tSig);
      %=========
      % Option - Condition for Averaging
      %=========
      if any(DM_AVERAGE)
        for aa = 1:length(tSig)
          tSig{aa}.dat = ...
              hnanmean(tSig{aa}.dat,length(size(tSig{aa}.dat)));
        end
      end
    end
    %---------
    if iscell(tSig) &&  length(tSig) == 1 && ~any(regexpi(SigName{S},'roiTs')),  tSig = tSig{1}; end
    sigsave(Ses,ExpNo,name,tSig);
    if nargout>0, Trial = tSig; end
    eval(sprintf('clear %s Sig tSig;', name));
  end    
  % MAKE TRIALS FOR EVERY SIGNALS - END
  fprintf(' done.\n');
  
% REPEAT FOR ALL EXPERIMENTS
end
%==========================================================================
% Cat grp
%==========================================================================
% if ischar(iGrpExp)||iscell(iGrpExp), catdmsig(SesName, iGrpExp, ['t' SigName]); end
return

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = sub_fix_signame(oSig,SigName)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(oSig)
  for N = 1:length(oSig)
    oSig{N} = sub_fix_signame(oSig{N},SigName);
  end
  return
end
oSig.dir.dname = SigName;
return