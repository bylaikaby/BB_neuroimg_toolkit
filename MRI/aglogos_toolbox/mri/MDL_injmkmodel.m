function injmkmodel(SesName, GrpName, DOPLOT, varargin)
%INJMKMODEL - Make models for injection experiments with the Rauch-Protocol
% function injmkmodel(SesName, GrpName)
% Session used for debugging: B06LV1
%  
% NKL 26.07.09
  
DEBUG   = 0;
ROINAME = {'V1','V2'};
MDLNAME = {'V1','V2'};
MDLNAME = {};
ALPHA   = [0.001 0.001];
GETMDL  = 0;
  
if nargin < 1,  SesName = 'b06lp1'; end;
if nargin < 2,  GrpName = 'esinj';  end;

es_goto;
load InjModelResponses;

SELIDX = [1 1 1 0 1 0 1 0];     % Best responses
injTs.dat = nanmean(injTs.dat(:,:,find(SELIDX)),3);
injTs.SESSION = injTs.SESSION(find(SELIDX));
injTs.EXPS = injTs.EXPS(find(SELIDX));
injTs.nvox = injTs.nvox(find(SELIDX),:);

% SELECT and ORDER according to the GLM models in ESINJGETPARS
% injTs is {'INJ' 'V1'  'V2' 'IPZ'}
tmp(:,1) = injTs.dat(:,1);                          % INJ
y.dat = (injTs.dat(:,3) - injTs.dat(:,4))/2;     % Average V1+V2
y.dx = injTs.dx;
y = sigfilt(y,0.01, 'high');
tmp(:,2) = y.dat;
tmp(:,3) = injTs.dat(:,2);                          % IPZ
tmp(:,4) = y.dat;
tmp(:,5) = y.dat;
tmp(128:end,4) = 0;
tmp(1:415,5) = 0;
tmp(1:128,2) = 0;
tmp(415:end,2) = 0;

model = injTs;
model.name = {'INJ','V1','V2','IPZ','PRE','PST'};
model.dat = tmp;
clear tmp;

Ses = goto(SesName);
model.(mfilename).info = {'INJ-V1-V2-IPZ-PRE-PST'};
save(sprintf('Mdl_%s.mat',GrpName),'model');
fprintf('INJMKMODEL: Saved "model" in file %s\n', sprintf('Mdl_%s.mat',GrpName));
return;

