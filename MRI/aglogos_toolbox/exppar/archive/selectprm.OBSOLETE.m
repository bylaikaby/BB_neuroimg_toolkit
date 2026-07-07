function [evparams, idx] = selectprm(data, obsp, etype, prmidx, esubtype)
%SELECTPRM - Returns event parameters of certain type/subtype
%  [EVPARAMS, IDX] = SELECTPRM(DATA,OBSP,ETYPE,[PRMIDX],[ESUBTYPE])
%  data     : the data structure returned by dg_read(filename)
%  obsp     : selected observation period
%  etype    : selected event type
%  esubtype : selected event subtype
%  evparams : parameter(s) that event occurred
%  idx      : indices of the requested events
% VERSION : 1.00 YM, 26.04.03  derived from getEVTObsParam.m by DAL.  
% NOTE :    some floating values may have a small offset like 1.2e-8,
%  probably, due to float->double conversion.
%  If needed, correct values before making comparisons ('==' and "~="),
%  like, for example, p = round(p/100000)*100000.  ----------30.05.03 YM
%
% See also DG_READ SELECTEVT EXPGETEVT

if nargin < 3
  %error('usage: [evparams, idx] = selectprm(data,obsp,etype,[prmidx],[esubtype])')
  eval(sprintf('help %s',mfilename));
  return
end
if nargin < 4,  prmidx = -1;  end	
if nargin < 5,  esubtype  = -1;  end

% initialize outputs
evparams = [];

% select events
if esubtype == -1 
  %select based only on etype
  idx = find(data.e_types{obsp} == etype);
else
  %select based on evtype and evsubtype
  idx = find(data.e_types{obsp} == etype & ...
			 data.e_subtypes{obsp} == esubtype);
end

if isempty(idx), return, end

% now there can be multiple trials in an obsp. 


% get parameters for all.
if prmidx <= 0,
  plist = data.e_params{obsp}{idx(1)};
  if ~isempty(plist),
	evparams = data.e_params{obsp}(idx);
  end
  return
end


% get parameters for the given prmidx.

% check parameter(s) is a string or numeric.
tmpv = data.e_params{obsp}{idx(1)};
if ischar(tmpv),
  % strings
  evparams = {};
  for k=1:length(idx)
    plist = data.e_params{obsp}{idx(k)};
    if size(plist,1) >= prmidx && ~isempty(plist)
      str = deblank(plist(prmidx,:));
    else
      str = '';
    end
    if isempty(str), break; end	
    evparams{end+1} = str;
  end
else  
  evparams = [];
  for k=1:length(idx)
    plist = data.e_params{obsp}{idx(k)};
    if length(plist) >= prmidx
      evparams = [evparams; plist(prmidx)]; 
    else 
      evparams = [evparams; -1001];
    end
  end
end
