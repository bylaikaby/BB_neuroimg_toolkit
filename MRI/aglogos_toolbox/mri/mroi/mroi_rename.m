function ROISET = mroi_rename(varargin)
%MROI_RENAME - Rename ROI's name.
%  MROI_RENAME(SesName,GrpName,OldName,NewName,...) renames ROI's name.
%  ROISET = MROI_RENAME(ROISET,OldName,NewName,...)
%
%  Supported options :
%    'case' : 0|1, case-sensitive or not  (1 as defalt)
%
%  EXAMPLE :
%    RoiDef = mroi_load(ses,'RoiDef');
%    X = mroi_rename(RoiDef,'v2old','V2');
%
%  EXAMPLE :
%    mroi_rename('ratXYZ','spont',{'v1' 'v2' 'v3'},{'vis' 'vis' 'vis'});
%
%  VERSION :
%    04.01.12 YM  pre-release
%    31.05.13 YM  supports sesversion()>=2.
%    21.11.19 YM  clean-up.
%
%  See also mroi mroi_remove mroi_load mroi_save

if nargin < 3,  eval(sprintf('help %s',mfilename)); return;  end


if is_roiset(varargin{1})
  % called like mroi_rename(ROISET,OldName,NewName...)
  ROISET  = varargin{1};
  OldName = varargin{2};
  NewName = varargin{3};
  iOPT = 4;
  SAVE_ROISET = 0;
else
  % called like mroi_rename(SesName,GrpName,OldName,NewName,...)
  ses = goto(varargin{1});
  grp = getgrp(ses,varargin{2});
  OldName = varargin{3};
  NewName = varargin{4};
  ROISET = mroi_load(ses,grp.grproi);
  iOPT = 5;
  SAVE_ROISET = 1;
end


CASE_SENSITIVE = 1;
for N = iOPT:2:length(varargin)
  switch lower(varargin{N})
   case {'strcmp' 'case_sensitive' 'casesensitive' 'case'}
    CASE_SENSITIVE =  any(varargin{N+1});
   case {'strcmpi' 'case_insensitive' 'caseinsensitive'}
    CASE_SENSITIVE = ~any(varargin{N+1});
   case {'save'}
    SAVE_ROISET = varargin{N+1};
  end
end



if ischar(OldName),  OldName = { OldName };  end
if ischar(NewName),  NewName = { NewName };  end


% packing several names into a signle name
if length(OldName) > 1 && length(NewName) == 1
  NewName = repmat(NewName,[1 length(OldName)]);
end

if length(OldName) ~= length(NewName)
  error(' ERROR %s: length(OldNames) ~= length(NewNames).\n',mfilename);
end

if any(CASE_SENSITIVE)
  fstrcmp = @strcmp;
else
  fstrcmp = @strcmpi;
end

for N = 1:length(ROISET.roinames)
  tmpidx = find(fstrcmp(OldName,ROISET.roinames{N}));
  if any(tmpidx)
    ROISET.roinames{N} = NewName{tmpidx(1)};
  end
end
ROISET.roinames = unique(ROISET.roinames);

for N = 1:length(ROISET.roi)
  tmpidx = find(fstrcmp(OldName,ROISET.roi{N}.name));
  if any(tmpidx)
    ROISET.roi{N}.name = NewName{tmpidx(1)};
  end
end


if any(SAVE_ROISET) && exist('ses','var')
  mroi_save(ses,grp,ROISET);
end

return




function YESNO = is_roiset(X)
YESNO = 0;
if isstruct(X) && isfield(X,'roinames') && isfield(X,'roi') && ...
      isfield(X,'ana') && isfield(X,'img') && isfield(X,'ds')
  YESNO = 1;
end

return
