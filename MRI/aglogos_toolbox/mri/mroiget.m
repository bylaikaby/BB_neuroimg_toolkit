function oRoi = mroiget(Roi,Slice,RoiName,varargin)
%MROIGET - Get Roi of name RoiName for slice 'Slice'.
% oRoi = MROIGET (Roi,Slice,RoiName) is used to select a ROI (e.g. V1)
% from the superstructure ROI containing all slices and all
% possible user-defined ROIs.
% oRoi = MROIGET (Roi,Slice,RoiName) - gets one ROI of one SLICE
% oRoi = MROIGET (Roi,[],RoiName) - gets one ROI of all SLICES
% oRoi = MROIGET (Roi,Slice,[]) - gets all ROIs of one SLICE
% oRoi = MROIGET (Roi,Slice,{RoiName1,RoiName2}) - gets ROIs matches SLICE and RoiNames.
%
%  Supported options :
%    'case' : 0|1, case-sensitive or not  (0 as defalt for compatibility)
%
%  oRoi =
%       name: 'V1'
%      slice: 1
%       mask: [34x22 logical]
%         px: [26x1 double]
%         py: [26x1 double]
%    anamask: [136x88 logical]	%%% OBSOLETE
%     coords: [15x3 double]     %%% OBSOLETE
%
% See also MROI, MROICAT, ROILOAD, MAREATS, MCORANA, MTIMESERIES, HROI
%
% NKL 10.06.03
% NKL 20.11.04
% YM  08.06.05  RoiName can be a cell array, tested with "m02th1'.
% YM  24.01.12  supports 'case' for strcmp/strcmpi.
  
if nargin < 3,
  help mroiget;
  return;
end;



CASE_SENSITIVE = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'strcmp' 'case_sensitive' 'casesensitive' 'case'}
    CASE_SENSITIVE =  any(varargin{N+1});
   case {'strcmpi' 'case_insensitive' 'caseinsensitive'}
    CASE_SENSITIVE = ~any(varargin{N+1});
  end
end

if any(CASE_SENSITIVE),
  fstrcmp = @strcmp;
else
  fstrcmp = @strcmpi;
end






if ~exist('Slice','var'),   Slice = [];     end
if ~exist('RoiName','var'),  RoiName = '';  end

oRoi = Roi;
if isempty(Slice) & isempty(RoiName),  return;  end

% exchange Slice <---> RoiName if need.
if ischar(Slice) | iscell(Slice),
  tmp = Slice;
  Slice = RoiName;
  RoiName = tmp;
  clear tmp;
end

% -----------------------------------------------------------------
% now need to select


% NEW CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% selection by "RoiName"
if ~isempty(RoiName),
  if ischar(RoiName),  RoiName = { RoiName };  end
  SELIDX   = ones(1,length(oRoi.roi))*NaN;
  for iRoi = 1:length(oRoi.roi),
    if ~isfield(oRoi.roi{iRoi},'name'), continue; end
    if any(fstrcmp(RoiName,oRoi.roi{iRoi}.name));
      SELIDX(iRoi) = iRoi;
    end
  end
  idx = find(~isnan(SELIDX));
  SELIDX = SELIDX(idx);
  % pick up roi matching "ROINAME"
  oRoi.roi = oRoi.roi(SELIDX);
end


% selection by "Slice"
if ~isempty(Slice),
  SELIDX   = ones(1,length(oRoi.roi))*NaN;
  for iRoi = 1:length(oRoi.roi),
    if ~isfield(oRoi.roi{iRoi},'slice'), continue; end
    if any(Slice == oRoi.roi{iRoi}.slice);
      SELIDX(iRoi) = iRoi;
    end
  end
  idx = find(~isnan(SELIDX));
  SELIDX = SELIDX(idx);
  % pick up roi matching "SLICE"
  oRoi.roi = oRoi.roi(SELIDX);
end


return;





% OLD CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oRoi.roi = {};

RoiInc = 1;
% oRoi.coords = [];

% do selection
try,
if isempty(Slice),
  % select by name.
  for RoiNo = 1:length(Roi.roi),
    if any(strcmpi(Roi.roi{RoiNo}.name,RoiName)),
      oRoi.roi{RoiInc} = Roi.roi{RoiNo};
      %%% oRoi.coords = cat(1,oRoi.coords,Roi.roi{RoiNo}.coords);
      RoiInc = RoiInc + 1;
    end;
  end;
else
  if isempty(RoiName),
    % select by slice.
    for RoiNo = 1:length(Roi.roi),
      for SliNo = 1:length(Slice),
        if Roi.roi{RoiNo}.slice == Slice(SliNo),
          oRoi.roi{RoiInc} = Roi.roi{RoiNo};
          %%% oRoi.coords = cat(1,oRoi.coords,Roi.roi{RoiNo}.coords);
          RoiInc = RoiInc + 1;
        end;
      end;
    end;
  else
    % select by slice and name.
    for RoiNo = 1:length(Roi.roi),
      if any(strcmpi(Roi.roi{RoiNo}.name,RoiName)),
        for SliNo = 1:length(Slice),
          if Roi.roi{RoiNo}.slice == Slice(SliNo),
            oRoi.roi{RoiInc} = Roi.roi{RoiNo};
            %%% oRoi.coords = cat(1,oRoi.coords,Roi.roi{RoiNo}.coords);
            RoiInc = RoiInc + 1;
          end
        end;
      end;
    end;
  end
end;
catch,
  disp(lasterr);
  keyboard;
end;
return
