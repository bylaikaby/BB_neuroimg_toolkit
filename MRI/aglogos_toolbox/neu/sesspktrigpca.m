function sesspktrigpca(SESSION,EXPS,SpkName,SigName,CONV_TO_BURST)
%SESSPKTRIGPCA - computes spike triggered PCA of signal
%  SESSPKTRIGPCA(SESSION,EXPS/GRPNAME)
%  SESSPKTRIGPCA(SESSION,EXPS/GRPNAME,SPKNAME,SIGNAME)
%  SESSPKTRIGPCA(SESSION,EXPS/GRPNAME,SPKNAME,SIGNAME,CONV_TO_BURST)
%    'Spkt','atSpkt' can be used as SPKNAME.
%    'blp' and 'Cln' can be used as SIGNAME.
%     To use bursts of spikes, set CONV_TO_BURST as 1.
%
%  EXAMPLE :
%   sesspktrigpca('s02nm1',[],'Spkt','Cln');	% spike-triggered average of Cln
%   sesspktrigpca('s02nm1',[],'Spkt','Cln',1);  % burst-triggered average of Cln
%
%  VERSION : 08.02.05 YM  pre-release
%
%  See also SESSPKTRIGAVR

if nargin == 0,  help sesspktrigpca; return;  end

if nargin < 2,  EXPS = [];  end
if nargin < 3,  SpkName = '';  end
if nargin < 4,  SigName = '';  end
if nargin < 5,  CONV_TO_BURST = 0;  end

fprintf('%s: %s BEBIN ====================================\n',gettimestring,mfilename);
sesspktrigavr(SESSION,EXPS,SpkName,SigName,CONV_TO_BURST,1);
fprintf('%s: %s DONE  ====================================\n',gettimestring,mfilename);
