function dumpdgz(dgzdata, trials, showMri)
%DUMPDGZ - print event information in given trials of DGZ.
% DUMPDGZ(DGZ,TRIALS)
% DUMPDGZ(DGZ,TRIALS,0) prints events in TRIALS without MRI evnets.
% DUMPDGZ(DGZ,TRIALS,1) prints all events in TRIALS.
% DUMPDGZ(DGZ,[],1) prints all events in all trials.
%
% DGZ can be a dgz-file or a structure returned by DG_READ.
%
% VERSION : 1.00  May-2000 YM  first release
%           1.01  05.05.04 YM  show/hide mri events
%
% See also DG_READ, DGZVIEWER

if nargin == 0,  help dumpdgz;  return;  end

if nargin < 2,  trials = [];  end
if nargin < 3,  showMri = 0;  end

% dgzdata is given by a filename.
if ischar(dgzdata),  dgzdata = dg_read(dgzdata);  end

if isempty(trials)
  trials = 1:length(dgzdata.e_types);
end

fprintf('\nSystem: %s',dgzdata.e_pre{1}{2});  % name of the state system
fprintf('\nEvt  Trial   Time  Type SubT NPrms  Notes');

for t=trials
  n_evts = length(dgzdata.e_types{t});
  for N = 1:n_evts
    e_time    = dgzdata.e_times{t}(N);
    e_type    = dgzdata.e_types{t}(N);
    e_sub     = dgzdata.e_subtypes{t}(N);
    e_params  = dgzdata.e_params{t}{N};
    e_nparams = size(e_params,1);
    notes = dgzdata.e_names(e_type+1, :);
    if ~showMri & e_type == 46,  continue;  end 
    if e_type == 4,
      if e_params(length(e_params)) == 10,
        e_params = e_params(1:length(e_params)-1);
      end
      fprintf('\n%4d  %4d %6d   %3d  %3d   %3d  Trace: %s', ...
              N, t, e_time, e_type, e_sub, e_nparams, e_params);
    else 
      fprintf('\n%4d  %4d %6d   %3d  %3d   %3d  %s', ...
              N, t, e_time, e_type, e_sub, e_nparams, notes);
    end
  end
end

fprintf('\n');
