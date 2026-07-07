function sesbrsttrigavr(SESSION,EXPS,SpkName,SigName)
%SESBRSTTRIGAVR - computes spike triggered averages of Blp
%  SESBRSTTRIGAVR(SESSION,EXPS/GRPNAME)
%  SESBRSTTRIGAVR(SESSION,EXPS/GRPNAME,SPKNAME,SIGNAME)
%    'Spkt','atSpkt' can be used as SPKNAME.
%    'blp' and 'Cln' can be used as SIGNAME.
%
%  EXAMPLE :
%   sesbrsttrigavr('s02nm1',[],'Spkt','Cln');	% spike-triggered average of Cln
%   sesbrsttrigavr('s02nm1',[],'Spkt','Cln',1);  % burst-triggered average of Cln
%
%  VERSION : 18.01.05 YM  pre-release, mofified from sesspktrigavr.m
%            25.01.05 YM  functins are merged sesbrsttrigavr.m
%
%  See also SIGSPKTRIGAVR, SESBRSTTRIGAVR, SIGGETBURST
  
if nargin == 0,  help sesbrsttrigavr; return;  end

if nargin < 2,  EXPS = [];     end
if nargin < 3,  SpkName = '';  end
if nargin < 4,  SigName = '';  end


CONV_TO_BURST = 1;

fprintf('%s %s\n',gettimestring,mfilename);
sesspktrigavr(SESSION,EXPS,SpkName,SigName,CONV_TO_BURST);


return;
