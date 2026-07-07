function ROISET = mroi_clean(varargin)
%MROI_CLEAN - Clean duplicated ROIs.
%  MROI_CLEAN(SesName,GrpName) cleans duplicated ROIs.
%  ROISET = MROI_CLEAN(ROISET)
%
%  EXAMPLE :
%    RoiDef = mroi_load(Ses,'RoiDef');
%    X = mroi_clean(RoiDef);
%
%  EXAMPLE :
%    mroi_clean('ratXYZ','spont');
%
%  VERSION :
%    31.05.13 YM  pre-release
%    21.11.19 YM  clean-up.
%
%  See also mroi mroi_rename mroi_remove mroi_load mroi_save

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end


if is_roiset(varargin{1})
  % called like mroi_clean(ROISET,...)
  ROISET = varargin{1};
  SAVE_ROISET = 0;
else
  % called like mroi_clean(SesName,GrpName,,...)
  ses = goto(varargin{1});
  grp = getgrp(ses,varargin{2});
  ROISET = mroi_load(ses,grp.grproi);
  SAVE_ROISET = 1;
end



roinames = cell(1,length(ROISET.roi));
for N = 1:length(ROISET.roi)
  roinames{N} = ROISET.roi{N}.name;
end

unames = unique(roinames);

ROIKEEP = ones(1,length(ROISET.roi));
for N = 1:length(unames)
  roiidx = find(strcmp(roinames,unames{N}));
  for K = 1:length(roiidx)
    R = roiidx(K);
    if ROIKEEP(R) == 0,  continue;  end
    tmproi = ROISET.roi{R};
    for X = K+1:length(roiidx)
      if isequal(tmproi,ROISET.roi{roiidx(X)})
        ROIKEEP(roiidx(X)) = 0;
      end
    end
  end
end


ROISET.roi = ROISET.roi(ROIKEEP > 0);




if any(SAVE_ROISET) && exist('ses','var')
  mroi_save(ses,grp.grproi,ROISET);
end


return



function YESNO = is_roiset(X)
YESNO = 0;
if isstruct(X) && isfield(X,'roinames') && isfield(X,'roi') && ...
      isfield(X,'ana') && isfield(X,'img') && isfield(X,'ds')
  YESNO = 1;
end

return
