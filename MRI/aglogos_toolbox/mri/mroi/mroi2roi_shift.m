function mroi2roi_shift(SesRef,GrpRef,SesExp,GrpExp,varargin)
%MROI2ROI_SHIFT - Shift/Export reference-ROI to exp-ROI.
%  MROI2ROI_SHIFT(SesRef,GrpRef,SesExp,GrpExp,...) shifts/exports reference-ROI to exp-ROI.
%
%  Supported options are :
%    'RefSlices' : slice numbers for ref-ROI.
%    'ExpSlices' : slice numbers for exp-ROI.
%    'XYShift'   : xy shift in EPI pixels.
%    'XYScale'   : xy scale.
%    'Replace'   : 0 to append, 1 to replace.
%    'RoiNames'  : a cell array of ROI names to update.
%    'RoiKeep'   : a call array of ROI names to keep.
%
%  NOTE :
%    E10.aW1, G10.aX1, I11.bu1 as templates.
%
%  EXAMPLE :
%    mroi2roi_shift('E10.aW1','spont','E10.ha1','spont','xyshift',[0 0])
%
%  VERSION :
%    0.90 13.02.13 YM  pre-release
%    0.91 31.05.13 YM  clean-up duplicated ROIs.
%    0.92 26.08.13 YM  potential bug fix when loading ROIs.
%    0.93 09.04.19 YM  XYShift/Scale can be a cell array (with the length of ExpSlices).
%    0.94 21.11.19 YM  clean-up.
%
%  See also mroi2roi_coreg mroi_file mroi_save mroi_clean poly2mask
%           mana2epi matlas2roi mana2brain


REF_SLICES = [];
EXP_SLICES = [];

XY_SHIFT   = [  0   0];
XY_SCALE   = [1.0 1.0];

DO_REPLACE = 1;

ROI_TO_UPDATE = {};
ROI_TO_KEEP   = {'hele' 'cele' 'thele'};

for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case { 'refslices' 'ref_slices'}
    REF_SLICES = varargin{N+1};
   case { 'expslices' 'exp_slices'}
    EXP_SLICES = varargin{N+1};
   case { 'xyshift' 'shift' 'xy'}
    XY_SHIFT = varargin{N+1};
   case { 'xyscale' 'scale'}
    XY_SCALE = varargin{N+1};
   case { 'replace'}
    DO_REPLACE = varargin{N+1};
   case { 'append'}
    DO_REPLACE = ~any(varargin{N+1});
   case {'roiupdate'}
    ROI_TO_UPDATE = varargin{N+1};
   case { 'roikeep' 'keeproi'}
    ROI_TO_KEEP = varargin{N+1};
  end
end



SesRef = goto(SesRef);
GrpRef = getgrp(SesRef,GrpRef);

SesExp = goto(SesExp);
GrpExp = getgrp(SesExp,GrpExp);

fprintf(' REF: %s(%s) %s\n',SesRef.name, GrpRef.name, mroi_file(SesRef,GrpRef.grproi));
fprintf(' Loading ROI-Ref(%s,%s)...',SesRef.name,GrpRef.grproi);
RoiRef = sub_load_roi(SesRef,GrpRef);
fprintf(' done.\n');

fprintf(' EXP: %s(%s) %s\n',SesExp.name, GrpExp.name, mroi_file(SesExp,GrpExp.grproi));
fprintf(' Loading ROI-Exp(%s,%s)...',SesExp.name,GrpExp.grproi);
RoiExp = sub_load_roi(SesExp,GrpExp);
fprintf(' done.\n');

if isempty(EXP_SLICES)
  EXP_SLICES = 1:size(RoiExp.img,3);
end
if isempty(REF_SLICES)
  REF_SLICES = 1:size(RoiRef.img,3);
end
RoiRef = sub_select_slices(RoiRef,REF_SLICES);


RoiRef = sub_exclude_bitmaps(RoiRef);
RoiRef = sub_exclude_roi(RoiRef,[],ROI_TO_KEEP);



if isempty(ROI_TO_UPDATE)
  ROI_TO_UPDATE = cell(size(RoiRef.roi));
  for N = 1:length(RoiRef.roi)
    ROI_TO_UPDATE{N} = RoiRef.roi{N}.name;
  end
  ROI_TO_UPDATE = unique(ROI_TO_UPDATE);
end

if isempty(ROI_TO_KEEP)
  fprintf(' RoiKeep: (none)\n');
else
  fprintf(' RoiKeep: %s\n',sub_text(ROI_TO_KEEP));
end

fprintf(' RoiUpdate: %s\n',sub_text(ROI_TO_UPDATE));

fprintf(' RefSlices: [%s]\n',deblank(sprintf('%d ',REF_SLICES)));
fprintf(' ExpSlices: [%s]\n',deblank(sprintf('%d ',EXP_SLICES)));


fprintf(' Shifting/Scaling ROI-Ref(%s,%s)',SesRef.name,GrpRef.grproi);
if iscell(XY_SHIFT)
fprintf(' xyshift=[cell(%d)]',length(XY_SHIFT));
else
fprintf(' xyshift=[%g %g]',XY_SHIFT(1),XY_SHIFT(2));
end
if iscell(XY_SCALE)
fprintf(' xyscale=[cell(%d)]',length(XY_SCALE));
else
fprintf(' xyscale=[%g %g]',XY_SCALE(1),XY_SCALE(2));
end
EPIDIM = size(RoiExp.img);
RoiRef = sub_shift_roi(RoiRef, REF_SLICES, EXP_SLICES,...
                        EPIDIM, XY_SHIFT, XY_SCALE);
fprintf(' done.\n');

if any(DO_REPLACE)
  fprintf(' Making ROI(%s,%s)-REPLACE',SesExp.name,GrpExp.grproi);
  RoiExp = sub_exclude_roi(RoiExp,EXP_SLICES,ROI_TO_UPDATE);
else
  fprintf(' Making ROI(%s,%s)-APPEND',SesExp.name,GrpExp.grproi);
end

RoiExp.roi = cat(2,RoiExp.roi,RoiRef.roi);

RoiExp = mroi_clean(RoiExp);  % clean-up duplicated ROIs.


fprintf(' done.\n');

mroi_save(SesExp,GrpExp.grproi,RoiExp,'verbose',1,'backup',1);



return


% ============================================================
function TXT = sub_text(CELL_TXT)
% ============================================================
if ischar(CELL_TXT),  TXT = CELL_TXT;  return;  end
if isempty(CELL_TXT), TXT = '';  return;  end

TXT = CELL_TXT{1};
for N = 2:numel(CELL_TXT)
  TXT = sprintf('%s %s',TXT,CELL_TXT{N});
end


return



% ============================================================
function ROI = sub_load_roi(Ses,Grp)
% ============================================================

roifile = mroi_file(Ses,Grp.grproi);
if ~exist(roifile,'file') || ~any(strcmp(who('-file',roifile),Grp.grproi))
  fprintf('\n--------------------------------------------\n');
  fprintf(' WARNING %s: no ''%s'' in %s.\n',mfilename,Grp.grproi,roifile);
  fprintf('   Please run ANOTHER MATLAB and MROI(''%s'')\n',Ses.name);
  fprintf('   Push "SAVE" button to make "%s" structure.\n',Grp.grproi);
  fprintf('   Come back here and go with "dbcont".\n');
  keyboard
end


ROI = load(roifile,Grp.grproi);
ROI = ROI.(Grp.grproi);

return


% ============================================================
function ROI = sub_select_slices(ROI, SLICES)
% ============================================================
if isempty(SLICES),  return;  end
tmpidx = zeros(size(ROI.roi));
for N = 1:length(ROI.roi)
  if any(SLICES == ROI.roi{N}.slice)
    tmpidx(N) = 1;
  end
end
ROI.roi = ROI.roi(tmpidx > 0);


% ============================================================
function ROI = sub_include_roi(ROI, SLICES, RoiNames)
% ============================================================

tmpidx = zeros(size(ROI.roi));
for N = 1:length(ROI.roi)
  % roi-keep
  if any(strcmpi(RoiNames,'all')) || any(strcmp(RoiNames,ROI.roi{N}.name))
    if isempty(SLICES) || any(SLICES == ROI.roi{N}.slice)
      tmpidx(N) = 1;
    end
  end
end

ROI.roi = ROI.roi(tmpidx > 0);

return;


% ============================================================
function ROI = sub_exclude_roi(ROI, SLICES, RoiNames)
% ============================================================

tmpidx = ones(size(ROI.roi));
for N = 1:length(ROI.roi)
  % roi-exclude
  if any(strcmpi(RoiNames,'all')) || any(strcmp(RoiNames,ROI.roi{N}.name))
    if isempty(SLICES) || any(SLICES == ROI.roi{N}.slice)
      tmpidx(N) = 0;
    end
  end
end

ROI.roi = ROI.roi(tmpidx > 0);

return;


% ============================================================
function ROI = sub_exclude_bitmaps(ROI)
% ============================================================

tmpidx = ones(size(ROI.roi));
for N = 1:length(ROI.roi)
  % bitmap-exclude
  if isempty(ROI.roi{N}.px)
    tmpidx(N) = 0;
  end
end

ROI.roi = ROI.roi(tmpidx > 0);

return;




% ============================================================
function ROI = sub_shift_roi(ROI, ORG_SLICES, NEW_SLICES, EPIDIM, iXY_SHIFT, iXY_SCALE)
% ============================================================


tmpx = size(ROI.img,1)/2;
tmpy = size(ROI.img,2)/2;

%tmpidx = zeros(size(ROI.roi));
for N = 1:length(ROI.roi)
  tmpidx = find(ORG_SLICES == ROI.roi{N}.slice);
  if isempty(tmpidx),  continue;  end
  
  tmproi = ROI.roi{N};
  
  if iscell(iXY_SHIFT)
    XY_SHIFT = iXY_SHIFT{NEW_SLICES(tmpidx)};
  else
    XY_SHIFT = iXY_SHIFT;
  end
  if iscell(iXY_SCALE)
    XY_SCALE = iXY_SCALE{NEW_SLICES(tmpidx)};
  else
    XY_SCALE = iXY_SCALE;
  end
  
  
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



% ============================================================
function ROI = sub_update_roi(ROI, REF_SLICES, EXP_SLICES, X_SHIFT, Y_SHIFT, ROI_TO_UPDATE)
% ============================================================

% slice selection
tmpidx = zeros(size(ROI.roi));
for N = 1:length(ROI.roi)
  if isempty(ROI.roi{N}.px),  continue;  end
  tmpslice = find(REF_SLICES == ROI.roi{N}.slice);
  if isempty(tmpslice),  continue;  end
  if ~any(strcmp(ROI_TO_UPDATE,ROI.roi{N}.name)),  continue;  end

  ROI.roi{N}.slice = EXP_SLICES(tmpslice);
  ROI.roi{N}.mask  = [];
  
  tmpidx(N) = 1;
end
ROI.roi = ROI.roi(tmpidx > 0);


return
