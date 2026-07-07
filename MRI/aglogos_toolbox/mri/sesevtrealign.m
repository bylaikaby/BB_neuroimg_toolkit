function sesevtrealign(SESSION,EXPS,LOG)
%SESEVTREALIGN - Realign signals/evt to the first Exp of the eacth group
%  SESEVTREALIGN(SESSION,GRPNAME,LOG) realigns signals/evt to the first Exp
%  of the each group.
%
%  NOTE :
%    The program updates the original 'tcImg' and dgz/stm.
%
%  EXAMPLE :
%    >> sesevtrealign('i07431');
%
%  VERSION :
%    0.90 20.09.10 YM  pre-release
%
%  See also sigevtrealign

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

Ses = goto(SESSION);

if nargin < 3,
  LOG = 0;
end;


if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

if LOG,
  LogFile=strcat('SESEVTREALIGN_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  grp   = getgrp(Ses,ExpNo);
  anap  = getanap(Ses,ExpNo);
  
  fprintf('%s: [%3d/%d] processing %s Exp=%d(%s)\n',...
          mfilename,iExp,length(EXPS),Ses.name,ExpNo,grp.name);

  UPDATED = 0;
  if isimaging(grp),
    tcImg0 = 
    
    [tcImg par] = sigevtrealign(
    
    eval(sprintf('%s = par;',vname));
    if 
    
    save('SesPar.mat',vname,'-append');
    
    end
  end
  
  if UPDATED > 0,
    matfile = fullfile(pwd,'SesPar.mat');
    bakfile = fullfile(pwd,'SesPar.mat.bak');
    if ~exist(bakfile,'file'),
      copyfile(matfile,bakfile);
    end
    PNAME0 = sprintf('exp%04d',grp.exps(1));
    PNAME1 = sprintf('exp%04d',ExpNo);
    PAR = load(matfile,PNAME0);
    eval(sprintf('%s = PAR;',PNAME1));
    save(matfile,PNAME1,'-append');
  end
    
  
  fprintf(' done.\n');
end;

if LOG,
  diary off;
end;

