function [evtimes, idx] = selectdgevt(DG, obsp, etype, esubtype)
%SELECTDGEVT - Select an DG-event with certain type/subtype
% usage: [evtimes, idx] = selectevt(DG, obsp, etype, esubtype);
%
%       DG: the data structure returned by dg_read(filename)
%     obsp: selected observation period
%    etype: selected event type
% esubtype: selected event subtype
%
%  evtimes: time that event occurred
%      idx: indices of the requested events 
%
% NKL, 06.03.00
% YM,  12.11.19  renamed as selectdgevt from selectevt to avoid name-conflict.
%
% See also expgetevt dg_read selectdgprm

if nargin < 4
  esubtype = -1;
end

if nargin < 3
  error('usage: [evtimes, idx] = selectdgevt(DG, obsp, etype, esubtype)');
end

if esubtype == -1
  idx = logical(DG.e_types{obsp} == etype);
  %idx = find(DG.e_types{obsp} == etype);
else
  idx = logical(DG.e_types{obsp} == etype & DG.e_subtypes{obsp}==esubtype);
  %idx = find(DG.e_types{obsp}==etype & DG.e_subtypes{obsp}==esubtype);
end

evtimes = DG.e_times{obsp}(idx);
