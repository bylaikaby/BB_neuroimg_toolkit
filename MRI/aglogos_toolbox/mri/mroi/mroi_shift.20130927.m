function ROISET = mroi_shift(varargin)
%MROI_SHIFT - Shift ROI's name.
%  MROI_SHIFT(SesName,GrpName,XY_SHIFT,...) shifts ROIs.
%  ROISET = MROI_SHIFT(ROISET,XY_SHIFT,...)
%
%  Supported options :
%    'slices'   : slice selection
%    'xyscale'  : XY-scaling
%    'roinames' : ROI names to update
%
%  EXAMPLE :
%    RoiDef = mroi_load(ses,'RoiDef');
%    X = mroi_shift(RoiDef,[3 1]);
%
%  EXAMPLE :
%    mroi_shift('i11bb1','spont',[3 1],'slices',[13:17]);
%
%  NOTE :
%    This function can be a standalone program or subfunction of mroi().
%
%  VERSION :
%    26.09.13 YM  pre-release
%    27.09.13 YM  supports 'roinames'.
%
%  See also mroi mroi_remove mroi_load mroi_save

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


if is_roiset(varargin{1}),
  % called like mroi_rename(ROISET,OldName,NewName...)
  ROISET   = varargin{1};
  XY_SHIFT = varargin{2};
  iOPT = 3;
  SAVE_ROISET = 0;
else
  % called like mroi_rename(SesName,GrpName,OldName,NewName,...)
  ses = goto(varargin{1});
  grp = getgrp(ses,varargin{2});
  XY_SHIFT = varargin{3};
  ROISET = mroi_load(ses,grp.grproi);
  iOPT = 4;
  SAVE_ROISET = 1;
end



SLICES   = [];
XY_SCALE = [1 1];
ROINAMES = 'all';
for N = iOPT:2:length(varargin)
  switch lower(varargin{N})
   case {'slice' 'slices'}
    SLICES = varargin{N+1};
   case {'xyscale' 'scale' 'xy_scale'}
    XY_SCALE = varargin{N+1};
   case {'roi' 'roiname' 'roinames'}
    ROINAMES = varargin{N+1};
   case {'save'}
    SAVE_ROISET = varargin{N+1};
  end
end

if ischar(ROINAMES),  ROINAMES = { ROINAMES };  end


EPIDIM = size(ROISET.img);

if isempty(SLICES),
  ORG_SLICES = 1:size(ROISET.img,3);
  NEW_SLICES = ORG_SLICES;
else
  ORG_SLICES = SLICES;
  NEW_SLICES = ORG_SLICES;
end

ROISET = sub_shift_roi(ROISET,ORG_SLICES,NEW_SLICES, EPIDIM, XY_SHIFT, XY_SCALE, ROINAMES);


if any(SAVE_ROISET) && exist('ses','var'),
  mroi_save(ses,grp,ROISET);
end

return

% ============================================================
function ROI = sub_shift_roi(ROI, ORG_SLICES, NEW_SLICES, EPIDIM, XY_SHIFT, XY_SCALE, ROINAMES)
% ============================================================

if any(strcmpi(ROINAMES,'all')),
  DO_ALLROIS = 1;
else
  DO_ALLROIS = 0;
end

tmpx = EPIDIM(1)/2;
tmpy = EPIDIM(2)/2;

tmpidx = zeros(size(ROI.roi));
for N = 1:length(ROI.roi),
  % slice selection
  tmpidx = find(ORG_SLICES == ROI.roi{N}.slice);
  if isempty(tmpidx),  continue;  end
  % name selection
  if DO_ALLROIS == 0 && ~any(strcmpi(ROINAMES,ROI.roi{N}.name)),  continue;  end
  
  
  tmproi = ROI.roi{N};
  
  tmproi.slice = NEW_SLICES(tmpidx);
  %tmpx = nanmean(tmproi.px);
  %tmpy = nanmean(tmproi.py);
  tmproi.px    = (tmproi.px - tmpx) * XY_SCALE(1);
  tmproi.py    = (tmproi.py - tmpy) * XY_SCALE(2);
  tmproi.px    = tmproi.px + XY_SHIFT(1) + tmpx;
  tmproi.py    = tmproi.py + XY_SHIFT(2) + tmpy;
  tmproi.mask  = poly2mask(tmproi.px ,tmproi.py, EPIDIM(2), EPIDIM(1))';
 
  % figure;
  % subplot(1,2,1);
  % imagesc(double(ROI.roi{N}.mask)');
  % hold on;
  % plot(ROI.roi{N}.px,ROI.roi{N}.py);
  % subplot(1,2,2);
  % imagesc(double(tmproi.mask)');
  % hold on;
  % plot(tmproi.px,tmproi.py);
  % keyboard
  
  ROI.roi{N} = tmproi;
  
end


return



function YESNO = is_roiset(X)
YESNO = 0;
if isstruct(X) && isfield(X,'roinames') && isfield(X,'roi') && ...
      isfield(X,'ana') && isfield(X,'img') && isfield(X,'ds')
  YESNO = 1;
end

return



