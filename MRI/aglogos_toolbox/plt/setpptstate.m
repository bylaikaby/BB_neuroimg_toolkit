function setpptstate(state)
%SETPPTSTATE - It returns whether or not PPT output is required
%	SETPPTSTATE(state) reads the global variable PPTSTATE and returns it to
%	the caller; if set by setpptstate(ON/OFF) Power Point output is
%	generated.
%	NKL, 25.12.02

global PPTSTATE
if ~nargin,
  state=1;
end;

PPTSTATE = state;

assignin('base','PPTSTATE',PPTSTATE);



