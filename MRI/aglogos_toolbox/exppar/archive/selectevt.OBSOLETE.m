function [evtimes, idx] = selectevt(data, obsp, etype, esubtype)
%SELECTEVT - Select an event with certain type/subtype
% usage: [evtimes, idx] = selectevt(data, obsp, etype, esubtype);
% data: the data structure returned by dg_read(filename)
% obsp: selected observation period
% etype: selected event type
% esubtype: selected event subtype
% evtimes: time that event occurred
% idx: indices of the requested events 
% NKL, 06.03.00
%
% See also DG_READ SELECTPRM

if nargin < 4,
  esubtype = -1;
end

if nargin < 3,
  error('usage: [evtimes, idx] = selectevt(data, obsp, etype, esubtype)');
end

if esubtype == -1,
  idx = logical(data.e_types{obsp}==etype);
  %idx = find(data.e_types{obsp}==etype);
else
  idx = logical(data.e_types{obsp}==etype&data.e_subtypes{obsp}==esubtype);
  %idx = find(data.e_types{obsp}==etype & data.e_subtypes{obsp}==esubtype);
end

evtimes = data.e_times{obsp}(idx);
