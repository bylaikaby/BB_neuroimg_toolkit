function sct = sigupdate(sct)
%SIGUPDATE - Updates the info.date/time structure of our signals
% NKL 03.08.04

if iscell(sct),
  % if a cell array then call recursively.
  for N = 1:length(sct),
    sct{N} = sigupdate(sct{N});
  end
  return;
end


if isfield(sct,'info'),  
  sct.info.date = date;
  sct.info.time = gettimestring;
end;

