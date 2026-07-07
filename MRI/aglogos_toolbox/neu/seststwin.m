function seststwin(SESSION,SigName)
%SESTSTWIN - Compute interelectrode coherence
% SESTSTWIN - Computes coherence for different distances
% SESSION USED: c98nm1 a98nm1 b02nm2 s02nm1 g02nm1
%	See also
%	SIGCOHERE EXPCOHERE

if nargin <1,
  error('usage: seststwin(SESSION)');
end

if nargin < 2,
  SigName='all';
end;

Ses = goto(SESSION);

for G=1:length(Ses.winGrps),
  for K=1:length(Ses.winGrps{G}),
	fprintf('SESSION: %s, Group: %s\n',...
			Ses.name,Ses.winGrps{G}{K});
	tstwin(Ses,Ses.winGrps{G}{K});
  end;
end;


