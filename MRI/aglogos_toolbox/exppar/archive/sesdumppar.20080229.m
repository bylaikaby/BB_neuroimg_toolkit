function sesdumppar(SESSION,EXPS,LOG)
%SESDUMPPAR - Get/Load all experimental parameteters of the session.
% SESDUMPPAR(SESSION) - uses EXPGETPAR to read, preprocess
% (if defined in ARGS) and dump parameters into the MAT file (SesPar.mat).
%
% NKL, 13.10.02
% YM,  13.04.04  save all kinds of parameters into the matfile.
% YM,  28.04.05  force to include "autoplot" group.
%
% See also EXPGETPAR, IMGLOAD, SESPARDUMP, SESPARLOAD

if nargin < 1,  eval(sprintf('help %s;',mfilename)); return;  end  

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if nargin < 3,  LOG  = 0;               end

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
  if isfield(Ses.grp,'autoplot') & ~isempty(Ses.grp.autoplot.exps),
    EXPS = [EXPS(:)' Ses.grp.autoplot.exps(:)'];
  end
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end



% SETUP LOG, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if LOG,
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

fprintf('sesdumppar: ''%s'', NEXPS=%d\n ',Ses.name,length(EXPS));
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  expgetpar(Ses,ExpNo,1);
  if mod(N,10) == 0,
    fprintf('%d',N);
    %if N == 100 & length(EXPS) ~= 100, fprintf('\n '); end
  else
    fprintf('.');
  end
  
  % set flag for sesclnadjevt()
  if isimaging(Ses,ExpNo) && isrecording(Ses,ExpNo),
    RUN_CLNADJEVT = 1;
  end
end

fprintf('\nsesdumppar: DONE.\n');


if LOG,  diary off;  end


return;

% QUERY THE USER TO RUN SESCLNADJEVT OR NOT. %%%%%%%%%%%%%%%%%%%%%%%
if RUN_CLNADJEVT == 1,
  c = input('\n Run sesclnadjevt() ? Y/N[N]: ','s');
  if isempty(c), c = 'N'; end
  if strcmpi(c,'y'),
    sesclnadjevt(SESSION,EXPS,LOG)
  end
end


