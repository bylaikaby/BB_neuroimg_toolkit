function showres(SESSION,PRNOUT)
%SHOWRES - Show all data for the SFN03 analysis
% SHOWRES performs the following functions:
%
% NKL 13.10.03
  
if ~nargin,
  SESSION = 'c98nm1';
  PRNOUT = 0;
end;

if nargin & nargin < 2,
  PRNOUT = 0;
end;

Ses = goto(SESSION);
grps = getgroups(Ses);

showsigfft(Ses,grps{1}.exps(1));		% SHOW THE SPECTRA OF SIGNALS
DoPrint(PRNOUT);

getelepos(Ses,grps{1}.name);			% SHOW DISTANCES FOR COH/CONFUNC
DoPrint(PRNOUT);

% SHOW RESULTS
for N=1:length(grps),
  % PHYSIOLOGY
  if strncmp(grps{N}.name,'movie',5),
	tmp = who('-file',strcat(grps{N}.name,'.mat'));
	if any(strncmp(tmp,'VMua',4)),
	  showrf(Ses,grps{N}.name,1,'lum');	% RF STRUCTURE
	  DoPrint(PRNOUT);
	  showrf(Ses,grps{N}.name,1,'mix');
	  DoPrint(PRNOUT);
	end;
  end;
  
  showch(Ses,grps{N}.name);				% COHERENCE RESULTS
  DoPrint(PRNOUT);
  showcf(Ses,grps{N}.name);				% CONTRAST FUNCTIONS
  DoPrint(PRNOUT);

  % IMAGING
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoPrint(prnout)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if prnout,
  print;
  close gcf;
end;




