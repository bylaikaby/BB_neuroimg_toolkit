function corshow(Ses,GrpExp)
%CORSHOW - Show group data from the hyperc project (quick view of fMRI data)
% corshow(Ses, GrpExp) calls dsproits to show the data. It's good for a quick view of
% trial-based data, such as the variable contrast groups etc.
%
%  See also DSPROITS GLMSHOW

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);  
grp = getgrp(Ses,GrpExp);


if isnumeric(GrpExp),
  tmptxt = sprintf('%s: %s(%s,%d)',datestr(now), mfilename,Ses.name,GrpExp);
else
  tmptxt = sprintf('%s: %s(%s,%s)',datestr(now), mfilename,Ses.name,grp.name);
end

mfigure([5 150 1250 800]);
set(gcf,'Name',tmptxt);
if isfield(grp,'anap') & isfield(grp.anap,'gettrial') & grp.anap.gettrial.status > 0,
  troiTs = sigload(Ses,GrpExp,'troiTs');
  for iTrial = 1:length(troiTs{1}),
    dsproits(troiTs,'TrialNo',iTrial);
  end
else
  roiTs = sigload(Ses,GrpExp,'roiTs');
  dsproits(roiTs);
end


return;
