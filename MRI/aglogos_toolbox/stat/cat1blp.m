function sct = cat1blp(SesName,EXPS)
%CAT1BLP - Concatanate along the first dimension all experiments to compute r for the channel
% CAT1BLP (SesName,EXPS,DOPLOT) Concatanates all data along the first dimension (time)
% generating a supervector that is size(blp.dat,1) X Number of experiments. We do this to
% estimate the r value and its significance level for a channel (instead of estimating the
% probability of getting an experiments with a given chan-1/chan-0 configuration.
%  
% NKL, 04.08.04

if nargin < 3,
  DOPLOT=0;
end;

Ses = goto(SesName);

if ~exist('EXPS','var') | isempty(EXPS),
  [EXPS, SPOEXPS] = getactspont(Ses);
end;

% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

fprintf('Processing %s ',Ses.name);
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp=getgrp(Ses,ExpNo);
  [cblp, roiTs] = sigload(Ses,ExpNo,'cblp','roiTs');
  roiTs = mroitsget(roiTs,[],'ele');
  roiTs = mroitscat(roiTs);
keyboard  
  
  
  roiTs = roiTs{1};
  roiTs.dat = mean(roiTs.dat,2);
  cblp.dat = squeeze(mean(cblp.dat,2));
  
  if N==1,
    sct.roiTs = roiTs;
    sct.cblp = cblp;
    sct.ExpNo = EXPS;
  else
    sct.roiTs.dat = cat(1,sct.roiTs.dat,roiTs.dat);
    sct.cblp.dat = cat(1,sct.cblp.dat,cblp.dat);
  end;
  fprintf('.');
end;
fprintf('Done!\n');

keyboard
for N=1:size(cblp.dat,2),
  [sct.r(N), sct.p(N)] = corrcoef(sct.cblp.dat(:,N),sct.roiTs.dat(:,N));
end;




    
