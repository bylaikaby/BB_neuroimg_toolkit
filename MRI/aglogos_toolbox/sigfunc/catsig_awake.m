function oSig = catsig_awake(SESSION, GrpName, SigName, RoiNames)
%CATSIG - Concatanate signals from mat files
% CATSIG is a subroutine called by the group-maker grpmake.m.
%
%  SIG = CATSIG(SESSION,GRPNAME/EXPS,SIGNAME) returns a concatinated
%  "SIGNAME" of specified "SESSION" and "GRPNAME" or "EXPS".
%
%  VERSION :
%    0.90 07.10.06 YM  modified from catsig.m
%    0.91 09.10.06 YM  calls trial2obsp if needed 
%
% See also GRPMMAKE, SESGRPMAKE, SESSUPGRP, TRIAL2OBSP

if nargin < 3,  help catsig_awake; return;  end
if nargin < 4,  RoiNames = {};  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if ischar(GrpName),
  grp = getgrpbyname(Ses,GrpName);
  EXPS = grp.exps;
else
  EXPS = GrpName;
  grp = getgrp(Ses,EXPS(1));
end
anap = getanap(Ses,grp);

% if not trial-based, then call normal catsig.m %%%%%%%%%%%%%%%%%%%
if isawake(grp) & isfield(anap,'gettrial') & anap.gettrial.status > 0,
else
  oSig = catsig(SESSION,GrpName,SigName,RoiNames);
  return;
end


fprintf('<CATSIG_AWAKE>: %s %s "%s", ExpNo: ',Ses.name,grp.name,SigName);
oSig = [];

for iExp = 1:length(EXPS),
  clear Sig;
  
  ExpNo = EXPS(iExp);

  fprintf('%d.',ExpNo);
  
  [isok filename] = sigexist(Ses,ExpNo,SigName);
  if ~isok,
	fprintf('!! catsig WARNING: %s was not found in %s\n',SigName,filename);
	oSig = {};
	return;
  end;

  Sig = sigload(Ses,ExpNo,SigName);

  if isempty(Sig),
    fprintf('CATSIG: Skipping empty signal %s\n', SigName);
    oSig = Sig;
    return;
  end;

  if isstruct(Sig), % make it cell array even if a single condition...
    Sig = { Sig };
  end;

  % PROCESS ACCORDING TO SIGNAL STRUCTURE
  switch SigName,

   case { 'rpblp'},
    anap = getanap(Ses,ExpNo);
    if iExp == 1,
      oSig = Sig;
      DIM = length(size(Sig{1}.dat))+1;
      for K = 1:length(oSig),
        oSig{K}.ExpNo = grp.exps;
      end
    elseif iExp == length(EXPS),
      for K = 1:length(oSig),
        oSig{K}.dat = oSig{K}.dat/length(EXPS);
      end;
    else
      for K = 1:length(oSig),
        if size(oSig{K}.dat,1) > size(Sig{K}.dat,1),
          oSig{K}.dat = oSig{K}.dat(1:size(Sig{K}.dat,1),:,:,:);
        elseif size(oSig{K}.dat,1) < size(Sig{K}.dat,1),
          Sig{K}.dat = Sig{K}.dat(1:size(oSig{K}.dat,1),:,:,:);
        end
        oSig{K}.dat = oSig{K}.dat+Sig{K}.dat;
      end;
    end;
    
   case {'rproiTs','gmroiTs','swroiTs','droiTs','throiTs'}
    if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end
    if iExp == 1,
      oSig = Sig;
    else
      for R = 1:length(oSig),
        oSig{R}.dat  = cat(3,oSig{R}.dat,Sig{R}.dat);
        if isfield(oSig{R},'rnd'),
          oSig{R}.rnd  = cat(3,oSig{R}.rnd,Sig{R}.rnd);
        end;
        if isfield(oSig{R},'r'),
          for M = 1:length(oSig{R}.r),
            oSig{R}.r{M} = cat(2,oSig{R}.r{M},Sig{R}.r{M});
          end
        end
      end;
    end
   
   case {'troiTs'}
    % .r/.p ignored
    %% if ~isempty(RoiNames), Sig = mroitsget(Sig,[],RoiNames); end
    oSig = subDoAverage(oSig,Sig);

    if iExp == length(EXPS),
      anap = getanap(Ses,ExpNo);
      if isfield(anap.gettrial,'trial2obsp') & anap.gettrial.trial2obsp > 0,
        if anap.gettrial.Average,
          oSig = trial2obsp(oSig,'mean');
        else
          oSig = trial2obsp(oSig,'none');
        end
      end
    end
    
   otherwise,
    %fprintf(' CATSIG: Unknown Signal\n');
    %return;
    if iExp == 1,
      fprintf(' CATSIG_AWAKE: Unknown Signal, averaging .dat only\n');
      oSig = Sig;
      for K = 1:length(oSig),  oSig{K}.ExpNo = grp.exps;  end
    else
      for K = 1:length(oSig),
        oSig{K}.dat = oSig{K}.dat + Sig{K}.dat;
      end
      if iExp == length(EXPS),
        for K = 1:length(oSig),
          oSig{K}.dat = oSig{K}.dat / length(EXPS);
        end
      end
    end
  end;
end;

fprintf(' done.\n');
return;



function oSig = subDoAverage(oSig,iSig)
if isempty(oSig),  oSig = iSig; return;  end

if iscell(iSig),
  for N = 1:length(iSig),
    oSig{N} = subDoAverage(oSig{N},iSig{N});
  end
  return;
end


if isfield(oSig,'sigsort'),
  n1 = oSig.sigsort.nrepeats;
  n2 = iSig.sigsort.nrepeats;

  oSig.dat = (oSig.dat*n1 + iSig.dat*n2) / (n1 + n2);
  oSig.sigsort.nrepeats = n1 + n2;
else
  n1 = length(oSig.ExpNo);
  n2 = length(iSig.ExpNo);
  n1 = n1 / (n1+n2);
  n2 = n2 / (n1+n2);

  oSig.dat = oSig.dat*n1 + iSig.dat*n2;
end

oSig.ExpNo(end+1:end+length(iSig.ExpNo)) = iSig.ExpNo;
oSig.ExpNo = sort(oSig.ExpNo);


return
