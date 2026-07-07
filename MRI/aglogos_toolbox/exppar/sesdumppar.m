function sesdumppar(SESSION,EXPS,LOG)
%SESDUMPPAR - Get/Load all experimental parameteters of the session.
% SESDUMPPAR(SESSION) - uses EXPGETPAR to read, preprocess
% (if defined in ARGS) and dump parameters into the MAT file (SesPar.mat).
%
%  VERSION :
%    1.00 13.10.02 NKL
%    1.01 13.04.04 YM  save all kinds of parameters into the matfile.
%    1.02 28.04.05 YM  force to include "autoplot" group.
%    2.00 30.01.12 YM  uses csession.
%    2.01 31.01.12 YM  supports old style also
%
% See also EXPGETPAR IMGLOAD SESPARDUMP SESPARLOAD

if nargin < 1,  eval(sprintf('help %s;',mfilename)); return;  end  

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if nargin < 3,  LOG  = 0;               end

if ~exist('EXPS','var') || isempty(EXPS)
  EXPS = validexps(Ses);
  if isgroup(Ses,'autoplot')
    EXPS = [EXPS(:)' getexps(Ses,'autoplot')];
    EXPS = unique(EXPS);
  end
end
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end



% SETUP LOG, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if LOG
  LogFile=strcat('SESDUMPPAR_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end


% RUN CHECKING ROUTINE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if ~exist('SesPar.mat','file'),
%   IsOK = sescheck(Ses.name,2);
%   if IsOK == 0,
%     fprintf('\n sesdumppar/sescheck: error(s) found in ''%s.m''.\n',Ses.name);
%     return;
%   end
% end



% NOW DUMP EXPERIMENT PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RUN_CLNADJEVT = 0;
try
  fprintf('sesdumppar: ''%s'', NEXPS=%d\n ',Ses.name,length(EXPS));
  for N = 1:length(EXPS)
    ExpNo = EXPS(N);
    grp = getgrp(Ses,ExpNo);
    if iscatexps(grp)
      % GRP.xxx.catexps.exps = ...
      % sescatexps() will take care of it.
      fprintf('x');
      continue;
    end
    %if isfield(grp,'mnimgloadavr') && ~isempty(grp.mnimgloadavr),
    %  % mnimgloadavr() will take care of it.
    %  fprintf('x');
    %  continue;
    %end

    
    if isa(Ses,'csession')
      scan = Ses.scanreco(ExpNo);
      if Ses.needadf(ExpNo)
        filename = Ses.exppfile(ExpNo,'phys');
      elseif Ses.needdgz(ExpNo)
        filename = Ses.exppfile(ExpNo,'dgz');
      else
        filename = 'unknown';
      end
    else
      if isfield(Ses.expp(ExpNo),'scanreco') && any(Ses.expp(ExpNo).scanreco)
        scan = Ses.expp(ExpNo).scanreco(1);
      else
        scan = -1;
      end
      if isfield(Ses.expp(ExpNo),'physfile')
        filename = Ses.expp(ExpNo).physfile;
      elseif isfield(Ses.expp(ExpNo),'evtfile')
        filename = Ses.expp(ExpNo).evtfile;
      else
        filename = 'not_assigned';
      end
    end    
    expgetpar(Ses,ExpNo,1);
    if mod(N,10) == 0
      fprintf('%d',N);
      %if N == 100 & length(EXPS) ~= 100, fprintf('\n '); end
    else
      fprintf('.');
    end
    % set flag for sesclnadjevt()
    if isimaging(Ses,ExpNo) && isrecording(Ses,ExpNo)
      RUN_CLNADJEVT = 1;
    end
  end
catch
  disp(lasterr);
  fprintf('<ERROR!> Group: %s, ExpNo:%5d, Scan: %5d, File: %s\n',grp.name,ExpNo, scan, filename);
  keyboard;
end

fprintf('\nsesdumppar: DONE.\n');


if LOG,  diary off;  end


return;

% QUERY THE USER TO RUN SESCLNADJEVT OR NOT. %%%%%%%%%%%%%%%%%%%%%%%
if RUN_CLNADJEVT == 1
  c = input('\n Run sesclnadjevt() ? Y/N[N]: ','s');
  if isempty(c), c = 'N'; end
  if strcmpi(c,'y')
    sesclnadjevt(SESSION,EXPS,LOG)
  end
end


