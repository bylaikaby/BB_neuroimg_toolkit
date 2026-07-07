function [es tstart tend] = atgetcheetahevt(SESSION,ExpNo)
%ATGETCHEETAHEVT - get cheetah event info
%
%  VERSION : 0.90 04.03.05 YM  pre-release
%
%  See also ATSESCONVERT, ATGETCLN, READ_EVENTS, READ_CR

  
if nargin ~= 2,  help atgetcheetahevt; return;  end

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);


% RAW FILE INFO
sesdir              = fullfile(Ses.sysp.DataNeuro,Ses.sysp.dirname);
xclust_spike_folder = Ses.expp(ExpNo).xclust_spike_folder;
cheetah_folder      = Ses.expp(ExpNo).cheetah_folder;
cht_start           = Ses.expp(ExpNo).cht_start;
cht_end             = Ses.expp(ExpNo).cht_end;
datasize            = Ses.expp(ExpNo).datasize;
dataoffs            = Ses.expp(ExpNo).dataoffs;

% Read cheetah events and files start time and end time of data to be clustered
es = read_events(fullfile(sesdir, cheetah_folder, 'Events.Nev'));

if nargout > 1,
  ind = strmatch([cht_start], lower(es.es )); 
  tstart = es.t(ind(1));
  ind = strmatch([cht_end], lower(es.es ));
  tend = es.t(ind(1));
end


if nargout == 0,
  fprintf('%s: %s ExpNo=%d  %s\n',mfilename,Ses.name,ExpNo,cheetah_folder);
  fprintf('index:  time(sec)  event\n');
  for N = 1:length(es.es),
    if strncmpi(es.es{N},'RecID:',5),  continue;  end
    fprintf('%5d: %10.3f  %s\n',N,es.t(N)/1000,es.es{N});
  end
end
