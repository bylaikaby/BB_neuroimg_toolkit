function PARAMS = nscan_strconv(PARAMS,ModeStr,varargin)
%NSCAN_STRCONV - Convert string params of Curry7(neuroscan).
%  PARAMS = NSCAN_STRCONV(PARAMS,ModeStr,...) converts string parameters of
%  Curry7(neuroscan)
%
%  EXAMPLE :
%    params = nscan_strconv(params,'str2num','fields',{'KeyName'})
%    params = nscan_strconv(params,'numlist')
%
%  VERSION :
%    0.90 24.01.14 YM  pre-release, MPI Tuebingen
%    0.91 10.02.14 YM  clean-up.
%
%  See also nscan_loadpar7 nscan_loadtxt

%  COPYRIGHT (C) 2014 Yusuke Murayama,  Max Planck Institute for Biological Cybernetics
%  Simplified BSD License, see readme.txt for detail.


if nargin < 2, eval(['help ' mfilename]); return;  end

FNAMES = {};
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'field' 'fields' 'fieldname' 'fieldnames'}
    FNAMES = varargin{N+1};
  end
end
if ischar(FNAMES),  FNAMES = { FNAMES };  end



switch lower(ModeStr)
 case {'str2num' 'conv2num' 'number' 'numbers'}
  PARAMS = sub_conv2num(PARAMS,FNAMES);
 case {'numlist' 'conv2numlist'}
  PARAMS = sub_convlist(PARAMS,1);
 case {'strlist' 'conv2strlist'}
  PARAMS = sub_convlist(PARAMS,0);
 otherwise
  error(' ERROR %s: mode=''%s'' not supported.\n',mfilename,ModeStr);
end


return


% =================================================================
function PARAMS = sub_conv2num(PARAMS, fnames)
% =================================================================
for N = 1:length(fnames)
  tmpf = fnames{N};
  if ~isfield(PARAMS,tmpf),  continue;  end
  if any(PARAMS.(tmpf))
    PARAMS.(tmpf) = str2double(PARAMS.(tmpf));
  else
    PARAMS.(tmpf) = [];
  end
end

return



% =================================================================
function iList = sub_cell2num(cList)
% =================================================================
iList = nan(size(cList));
for N = 1:numel(cList)
  if any(cList{N})
    iList(N) = str2num(cList{N});
  end
end

return



% =================================================================
function PARAMS = sub_convlist(PARAMS,IsNumericList)
% =================================================================
fnames = {...
    'ListNrColumns',...
    'ListNrRows',...
    'ListNrTimepts',...
    'ListNrBlocks',...
    'ListBinary',...
    'ListType',...
    'ListTrafoType',...
    'ListGridType',...
    'ListFirstColumn',...
    'ListIndexMin',...
    'ListIndexMax',...
    'ListIndexAbsMax',...
         };
PARAMS = sub_conv2num(PARAMS,fnames);
if any(IsNumericList) && isfield(PARAMS,'List')
  PARAMS.List = sub_cell2num(PARAMS.List);
end

return
