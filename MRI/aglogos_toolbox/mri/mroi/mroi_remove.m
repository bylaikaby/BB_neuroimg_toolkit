function ROISET = mroi_remove(varargin)
%MROI_REMOVE - Remove ROIs.
%  MROI_REMOVE(SesName,GrpName,RoiNames,...) removes ROIs.
%  ROISET = MROI_REMOVE(ROISET,RoiNames,...)
%
%  Supported options :
%    'case' : 0|1, case-sensitive or not  (1 as defalt)
%    'type' : ROI's type to remove, 'polygon'|'bitmap'|'both'
%
%  EXAMPLE :
%    RoiDef = mroi_load(ses,'RoiDef');
%    X = mroi_remove(RoiDef,'V2','type','polygon');
%
%  EXAMPLE :
%    mroi_remove('ratXYZ','spont',{'v1' 'v2' 'v3'},'type','bitmap');
%
%  VERSION :
%    23.01.12 YM  pre-release
%    31.05.13 YM  supports sesversion()>=2.
%    21.11.19 YM  clean-up.
%
%  See also mroi mroi_rename mroi_load mroi_save

if nargin < 3,  eval(sprintf('help %s',mfilename)); return;  end


if is_roiset(varargin{1})
  % called like mroi_remove(ROISET,RoiNames,...)
  ROISET  = varargin{1};
  RoiNames = varargin{2};
  iOPT = 3;
  SAVE_ROISET = 0;
else
  % called like mroi_remove(SesName,GrpName,RoiNames,...)
  ses = goto(varargin{1});
  grp = getgrp(ses,varargin{2});
  RoiNames = varargin{3};
  ROISET = mroi_load(ses,grp);
  iOPT = 4;
  SAVE_ROISET = 1;
end


ROI_TYPE       = 'bitmap';   % 'polygon'|'bitmap'|'both'
CASE_SENSITIVE = 1;
for N = iOPT:2:length(varargin)
  switch lower(varargin{N})
   case {'strcmp' 'case_sensitive' 'casesensitive' 'case'}
    CASE_SENSITIVE =  any(varargin{N+1});
   case {'strcmpi' 'case_insensitive' 'caseinsensitive'}
    CASE_SENSITIVE = ~any(varargin{N+1});
   case {'roitype' 'type'}
    ROI_TYPE = varargin{N+1};
   case {'save'}
    SAVE_ROISET = varargin{N+1};
  end
end

if ischar(RoiNames),  RoiNames = { RoiNames };  end


if any(CASE_SENSITIVE)
  fstrcmp = @strcmp;
else
  fstrcmp = @strcmpi;
end


keepidx = ones(size(ROISET.roi));
if all(strcmpi(RoiNames,'all'))
  CHECK_NAME = 0;
else
  CHECK_NAME = 1;
end
    
for N = 1:length(ROISET.roi)
  switch lower(ROI_TYPE)
   case {'bitmap' 'atlas'}
    if isempty(ROISET.roi{N}.px)
      if CHECK_NAME == 0 || any(fstrcmp(RoiNames,ROISET.roi{N}.name))
        keepidx(N) = 0;
      end
    end
   case {'polygon' 'hand'}
    if ~isempty(ROISET.roi{N}.px)
      if CHECK_NAME == 0 || any(fstrcmp(RoiNames,ROISET.roi{N}.name))
        keepidx(N) = 0;
      end
    end
   case {'both' 'all'}
    if CHECK_NAME == 0 || any(fstrcmp(RoiNames,ROISET.roi{N}.name))
      keepidx(N) = 0;
    end
   otherwise
    % do nothing for safe...
  end
end
if all(keepidx > 0)
  % no need to do anything
  SAVE_ROISET = 0;
else
  ROISET.roi = ROISET.roi(keepidx > 0);
end


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
