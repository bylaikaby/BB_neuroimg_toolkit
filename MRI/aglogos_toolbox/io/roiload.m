function Roi = roiload(Ses,ExpNo,RoiVar,Slice,RoiName)
%ROILOAD - load ROI for Ses, ExpNo/GrpName
%   ROI = ROILOAD(SES,EXPNO/GRPNAME)
%   ROI = ROILOAD(SES,EXPNO/GRPNAME,'') loads default ROIs set by grp.grproi.
%
%   ROI = ROILOAD(SES,EXPNO/GRPNAME,ROIVAR) loads a ROI variable (ROIVAR)
%   in the roifile.  If ROIVAR is a empty string, ROILOAD will use
%   grp.grproi or 'RoiDef' as a ROI variable name.
%
%   ROI = ROILOAD(SES,EXPNO/GRPNAME,ROIVAR,SLICE)
%   ROI = ROILOAD(SES,EXPNO/GRPNAME,ROIVAR,ROINAME) load the ROIs
%   based on SLICE or ROINAME.  If SLICE == [] or ROINAME == '',
%   then ROILOAD will return all ROIs.
%
%   ROI = ROILOAD(SES,EXPNO/GRPNAME,ROIVAR,SLICE,ROINAME) load the
%   ROIs based on both SLICE and ROINAME.  If SLICE == [], then
%   ROILOAD selects ROIs based on ROINAME.  If ROINAME == '', then
%   ROILOAD selects ROIs based on SLICE.
%
%   You may use MROIGET for further selection of ROI.
%
% VERSION :
%   0.90 25.04.04 YM   first release
%   0.91 28.11.07 YM   RoiName can be a cell array.
%   0.92 05.07.12 YM   use mroi_file().
%
% See also hroi mroiget mroi

if nargin < 2,  help roiload;  return;  end

Ses = goto(Ses);

ROIFILE = mroi_file(Ses,ExpNo);

if ~exist('RoiVar','var'),  RoiVar = '';   end
if ~exist('Slice','var'),   Slice = [];    end
if ~exist('RoiName','var'), RoiName = '';  end

if isempty(RoiVar),
  grp = getgrp(Ses,ExpNo);
  if isfield(grp,'grproi') && ~isempty(grp.grproi),
    RoiVar = grp.grproi;
  else
    RoiVar = 'RoiDef';
  end
end

if isempty(who('-file',ROIFILE,RoiVar)),
  fprintf(' roiload ERROR: ''%s'' is not found in %s.\n',RoiVar,ROIFILE);
  fprintf(' See help of sesroi, then run sesroi.\n');
  keyboard
end

%Roi = matsigload(ROIFILE,RoiVar);
Roi = load(ROIFILE,RoiVar);
Roi = Roi.(RoiVar);


% ROI = ROILOAD(SES,EXPNO/GRPNAME)
% no roi selection, return all.
if isempty(Slice) && isempty(RoiName),
  return;
end

% ------------------------------------------------------------------
% now we need to select ROIs.
RoiRoi = Roi.roi;
Roi.roi = {};

% exchange Slice <--> RoiName if needed.
if ischar(Slice) || iscell(Slice),
  tmp = Slice;
  Slice = RoiName;
  RoiName = tmp;
  clear tmp;
end

% do selection
if isempty(Slice),
  % select only by name.
  for N = 1:length(RoiRoi),
    if any(strcmpi(RoiRoi{N}.name,RoiName)),
      Roi.roi{end+1} = RoiRoi{N};
    end
  end
else
  if isempty(RoiName),
    % select only by slice.
    for N = 1:length(RoiRoi),
      for K = 1:length(Slice),
        if RoiRoi{N}.slice == Slice(K),
          Roi.roi{end+1} = RoiRoi{N};
        end
      end
    end
  else
    % select by slice and name
    for N = 1:length(RoiRoi),
      if any(strcmpi(RoiRoi{N}.name,RoiName)),
        for K = 1:length(Slice),
          if RoiRoi{N}.slice == Slice(K),
            Roi.roi{end+1} = RoiRoi{N};
          end
        end
      end
    end
  end
end

return;
