function roiTs = mroitsmask(roiTs,MASK)
%MROITSMASK - masks .r/.p
%  roiTs = MROITSMASK(roiTs) masks .r/.p
%
%  THIS FUNCTION SHOULD BE USED BEFORE MROITSGET/MROITSSEL functions.
%
%
%
% CONTROL FLAGS, see j04yz1 for detail
%   grp.refgrp.grpexp        : group name or expno of mask data
%   grp.refgrp.reftrial
%   grp.refgrp.WhichContrast : used by GLM stuff
%
%  VERSION :
%    0.90 06.01.06 YM  pre-release
%    0.91 28.01.08 YM  can apply mask for individula exps.
%    0.92 22.09.10 YM  bug fix when the same ExpNo belongs to different groups.
%
%  See also MGETMASK DSPROITS

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[SesName, ExpNo, GrpName] = subGet_roitsinfo(roiTs);
Ses = getses(SesName);
if ~isempty(GrpName),
  grp = getgrp(Ses,GrpName);
else
  % no way to know group-name..
  % use ExpNo but it may not be correct if the same ExpNo belongs to different group....
  grp = getgrp(Ses, ExpNo(1));
end

% CHECK WHETHER NEED TO APPLY MASKING OR NOT
if isfield(grp,'refgrp') && isfield(grp.refgrp,'grpexp') && ~isempty(grp.refgrp.grpexp),
  if isnumeric(grp.refgrp.grpexp),
    % grpexp as exp number
    if isequal(ExpNo(:), grp.refgrp.grpexp(:)),
      % no need to appy masking...
      return
    end
  else
    % grpexp as group name
    if strcmpi(grp.refgrp.grpexp,grp.name),
      % the same group and grouped roiTs/troiTs.
      if length(ExpNo) > 1,  return;  end
      % the same group and no info about trial
      if ~isfield(grp.refgrp,'reftrial') || isempty(grp.refgrp.reftrial),  return;  end
    end
  end
else
  % no way to apply mask
  return;
end



% PREPARE MASK INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SUBSTITUTE = 1;
if ~exist('MASK','var') || isempty(MASK),
  % load default mask data
  if isfield(grp,'refgrp') && ~isempty(grp.refgrp),
    MASK = mgetmask(Ses,grp.refgrp.grpexp);
    if isfield(grp.refgrp,'substitute'),
      SUBSTITUTE = grp.refgrp.substitute;
    end
  else
    % no way to apply 'mask'
    return;
  end
else
  % mask is given by 2nd arg.
  SUBSTITUTE = 0;
end

% if no stimulus, need to substitute anyway.
if isstim(SesName,ExpNo(1)) == 0,
  SUBSTITUTE = 1;
end




% DO PROCESS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(grp.refgrp.grpexp),
  fprintf('%s: masking by grp=%s substitute=%d...',...
          mfilename,grp.refgrp.grpexp,SUBSTITUTE);
else
  fprintf('%s: masking by exp=%d substitute=%d...',...
          mfilename,grp.refgrp.grpexp,SUBSTITUTE);
end

% DO SUBSTITUTION, IF REQUIRED %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if SUBSTITUTE > 0,
  for R = 1:length(roiTs),
    if iscell(roiTs{R}),
      for T = 1:length(roiTs{R}),
        if isfield(MASK{R},'corana')
          for M =1:length(MASK{R}.corana),
            roiTs{R}{T}.r{M}   = MASK{R}.corana{M}.r;
            roiTs{R}{T}.p{M}   = MASK{R}.corana{M}.p;
            roiTs{R}{T}.mdl{M} = MASK{R}.corana{M}.mdl;
          end
        end
        if isfield(MASK{R},'glmcont')
          roiTs{R}{T}.glmcont = MASK{R}.glmcont;
          roiTs{R}{T}.glmoutput = MASK{R}.glmoutput;
        end
      end
    else
      if isfield(MASK{R},'corana')
        for M = 1:length(MASK{R}.corana),
          roiTs{R}.r{M}   = MASK{R}.corana{M}.r;
          roiTs{R}.p{M}   = MASK{R}.corana{M}.p;
          roiTs{R}.mdl{M} = MASK{R}.corana{M}.mdl;
        end
      end
      if isfield(MASK{R},'glmcont')
        roiTs{R}.glmoutput = MASK{R}.glmoutput;
        roiTs{R}.glmcont = MASK{R}.glmcont;
      end
    end
  end
end

% DO MASKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for R = 1:length(roiTs),
  if iscell(roiTs{R}),
    % case of troiTs
    if isfield(roiTs{R}{1},'corana')
      for M = 1:length(roiTs{R}{1}.r),
        tmpidx = find(MASK{R}.corana{M}.dat == 0);
        for T = 1:length(roiTs{R}),
          roiTs{R}{T}.r{M}(tmpidx) = 0;
          roiTs{R}{T}.p{M}(tmpidx) = 1;
        end
      end
    end
  else
    % case of roiTs
    if isfield(roiTs{R},'corana')
      for M = 1:length(roiTs{R}.r),
        tmpidx = find(MASK{R}.corana{M}.dat == 0);
        roiTs{R}.r{M}(tmpidx) = 0;
        roiTs{R}.p{M}(tmpidx) = 1;
      end
    end
  end
end

fprintf('done.\n');

return;





function [SesName, ExpNo, GrpName] = subGet_roitsinfo(roiTs)

if iscell(roiTs),
  [SesName, ExpNo, GrpName] = subGet_roitsinfo(roiTs{1});
  return;
end

GrpName = '';
SesName = roiTs.session;
ExpNo = roiTs.ExpNo;
if isfield(roiTs,'grpname'),
  GrpName = roiTs.grpname;
end


return
