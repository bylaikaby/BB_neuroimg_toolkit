function sesgettrial(SESSION,EXPS,SigName)
%SESGETTRIAL - Split observation periods into trials
% SESGETTRIAL(SESSION,EXPS,SigName) - uses imgload to read, preprocess
% SESGETTRIAL(SESSION,SigName) - uses imgload to read, preprocess all valid EXPS
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
%    >> sesgettrial(SESSION,GRPNAME);       % does for all CTG.TrialSigs
%    >> sesgettrial(SESSION,GRPNAME,'blp')  % does only for ''blp''
%    or
%    >> blp = sigload(SESSION,ExpNo,'blp');
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
%
% See also GETTRIAL XFORM

if nargin < 1,
  help sesgettrial;
  return;
end;

Ses = goto(SESSION);

if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end;

if ischar(EXPS),
  % EXPS as a group name.
  grp = getgrp(Ses,EXPS);
  EXPS = grp.exps;
end

if iscell(EXPS),
  % EXPS as group names
  tmpexps = [];
  for N = 1:length(EXPS),
    if ischar(EXPS{N}),
      grp = getgrp(Ses,EXPS{N});
      tmpexps = cat(2,tmpexps,grp.exps(:)');
    else
      tmpexps = cat(2,tmpexps,EXPS{N}(:)');
    end
  end
  EXPS = unique(tmpexps);
  clear tmpexps;
end


if ~exist('SigName','var'),
  SigName = Ses.ctg.TrialSigs;
end;

if ~iscell(SigName),
  SigName = {SigName};
end;

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  anap = getanap(Ses,grp.name);

  fprintf('%s SESGETTRIAL: [%3d/%d] %s ExpNo=%d(%s)', ...
          datestr(now,'HH:MM:SS'), N, length(EXPS), Ses.name,ExpNo,grp.name);
  
  if ismanganese(grp),
    fprintf(': manganese experiment, skipping...\n');
    continue;
  end
  fprintf('\n');
  
  for S=1:length(SigName),
    if ~isimaging(grp) && any(strcmpi(SigName{S},{'roiTs','tcImg'})),
      %fprintf(' skipping empty signal(s).\n');
      continue;
    end
    if ~isrecording(grp) && any(strcmpi(SigName{S},{'Cln','Spkt','ClnSpc','blp'})),
      %fprintf(' skipping empty signal(s).\n');
      continue;
    end

    
    fprintf('%8s: ',SigName{S});
    tmpanap = anap;

    % overwrite anap.gettrial with anap.gettrial.(signame)
    if isfield(anap.gettrial,SigName{S}),
      tmpanap.gettrial = sctmerge(anap.gettrial,anap.gettrial.(SigName{S}));
    end

    if ~isfield(tmpanap,'gettrial') || tmpanap.gettrial.status == 0,
      fprintf(' has no trials; Skipping...\n');
      continue;
    end;

    % just to avoid error
    if ~isfield(tmpanap.gettrial,'trial2obsp'),
      tmpanap.gettrial.trial2obsp = 0;
    end
    
    % just to avoid error
    if ~isfield(tmpanap.gettrial,'detrend'),
      tmpanap.gettrial.detrend = 0;
    end
    
    fprintf('sort=%s detrend=%d xform=%s/%s Average=%d trial2obsp=%d\n',...
            tmpanap.gettrial.sort, tmpanap.gettrial.detrend,...
            tmpanap.gettrial.Xmethod, tmpanap.gettrial.Xepoch,...
            tmpanap.gettrial.Average, tmpanap.gettrial.trial2obsp);
 
    % NKL 08.03.2016 -- Loading of BLP is done within GETTRIAL
    % Sig = sigload(Ses,ExpNo,SigName{S});
    % tSig = gettrial(Sig);

    tSig = gettrial(Ses,ExpNo,SigName{S},tmpanap);
    if isempty(tSig),
      fprintf(' skipping empty signal(s).\n');
      continue;
    end;

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
    %   end;
    % end;
    name = sprintf('t%s',SigName{S});
    tSig = sub_fix_signame(tSig,name);
    
    if length(tSig) == 1,  tSig = tSig{1}; end;
    sigsave(Ses,ExpNo,name,tSig);
    eval(sprintf('clear %s Sig tSig;', name));
  end;
  fprintf(' done.\n');
end;
return

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = sub_fix_signame(oSig,SigName)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(oSig),
  for N = 1:length(oSig),
    oSig{N} = sub_fix_signame(oSig{N},SigName);
  end
  return
end
oSig.dir.dname = SigName;
return
