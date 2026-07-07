function [evparams, idx] = selectdgprm(DG, obsp, etype, prmidx, esubtype)
%SELECTDGPRM - Returns event parameters of certain type/subtype
%  [EVPARAMS, IDX] = SELECTPRM(DG,OBSP,ETYPE,[PRMIDX],[ESUBTYPE])
%
%        DG : the data structure returned by dg_read(filename)
%      obsp : selected observation period
%     etype : selected event type
%  esubtype : selected event subtype
%
%  evparams : parameter(s) that event occurred
%       idx : indices of the requested events
%
%  VERSION :
%    1.00 YM 26.04.03  derived from getEVTObsParam.m by DAL.  
%    1.10 YM 12.11.19  renamed as selectdgprm from selectprm to avoid name-conflict.
%
%  NOTE :    some floating values may have a small offset like 1.2e-8,
%    probably, due to float->double conversion.
%    If needed, correct values before making comparisons ('==' and "~="),
%    like, for example, p = round(p/100000)*100000.  ----------30.05.03 YM
%
% See also expgetevt dg_read selectdgevt

if nargin < 3
  %error('usage: [evparams, idx] = selectdgprm(DG,obsp,etype,[prmidx],[esubtype])')
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
  idx = find(DG.e_types{obsp} == etype);
else
  %select based on evtype and evsubtype
  idx = find(DG.e_types{obsp} == etype & ...
			 DG.e_subtypes{obsp} == esubtype);
end

if isempty(idx), return, end

% now there can be multiple trials in an obsp. 


% get parameters for all.
if prmidx <= 0
  plist = DG.e_params{obsp}{idx(1)};
  if ~isempty(plist)
	evparams = DG.e_params{obsp}(idx);
  end
  return
end


% get parameters for the given prmidx.

% check parameter(s) is a string or numeric.
tmpv = DG.e_params{obsp}{idx(1)};
if ischar(tmpv)
  % strings
  evparams = {};
  for k=1:length(idx)
    plist = DG.e_params{obsp}{idx(k)};
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
    plist = DG.e_params{obsp}{idx(k)};
    if length(plist) >= prmidx
      evparams = [evparams; plist(prmidx)]; 
    else 
      evparams = [evparams; -1001];
    end
  end
end
