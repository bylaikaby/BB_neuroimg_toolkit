function sesgetmask(SesName,GRPEXPS)
%SESGETMASK - Creates mask on the basis of p/r values of reference group to select time-series
% SESGETMASK(SesName, EXPS) creates mask data for troiTs/roiTs that will be used in
% MROITSSEL fucntion. 
%  
% VERSION :
%   0.90 04.01.06 YM  pre-release
%
% See also MGETMASK SESCORANA MROITSSEL

if nargin < 1,  eval(sprintf('help %s;',mfilename)); return;  end

Ses = goto(SesName);

if sesversion(Ses) >=2,  return;  end


if ~exist('GRPEXPS','var') | isempty(GRPEXPS),
  GRPEXPS = getgrpnames(Ses);
end
if ischar(GRPEXPS), GRPEXPS = { GRPEXPS };  end


% Checks grp.refgrp to which data should be run
[runEXPS runGRPS] = subCheckRefGrp(Ses,GRPEXPS);

% cases where grp.refgrp.grpexp is a single experiment
for N = 1:length(runEXPS),
  fprintf('%s %s [%3d/%d]: %s ExpNo=%d\n',datestr(now,'HH:MM:SS'),mfilename,...
          N,length(runEXPS)+length(runGRPS),Ses.name,runEXPS(N));
  mgetmask(Ses,runEXPS(N),1);
end

% cases where grp.refgrp.grpexp is a group name
for N = 1:length(runGRPS),
  fprintf('%s %s [%3d/%d]: %s Grp=%s\n',datestr(now,'HH:MM:SS'),mfilename,...
          N+length(runEXPS),length(runEXPS)+length(runGRPS),Ses.name,runGRPS{N});
  mgetmask(Ses,runGRPS{N},1);
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get groups and exps for masking
function [EXPS GRPS] = subCheckRefGrp(Ses,GRPEXPS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

GRPS = cell(size(GRPEXPS));
EXPS = zeros(size(GRPEXPS));
for N = 1:length(GRPEXPS),
  if iscell(GRPEXPS),
    % GRPEXPS as a cell array of groups
    grp = getgrp(Ses,GRPEXPS{N});
  else
    % GRPEXPS as experiment numbers
    grp = getgrp(Ses,GRPEXPS(N));
  end
  GRPS{N} = '';
  if isfield(grp,'refgrp') & ~isempty(grp.refgrp),
    grpexp = grp.refgrp.grpexp;
    if ischar(grpexp),
      GRPS{N} = grpexp;
    else
      EXPS(N) = grpexp;
    end
  end
end

GRPS = unique(GRPS);
GRPS = GRPS(find(~strcmpi(GRPS,'')));
EXPS = unique(EXPS);
EXPS = EXPS(find(EXPS ~= 0));

return;

