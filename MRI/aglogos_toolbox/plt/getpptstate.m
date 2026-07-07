function st = getpptstate
%GETPPTSTATE - it returns whether or not PPT output is required
%	state = GETPPTSTATE reads the global variable PPTSTATE and returns it to
%	the caller; if set by setpptstate(ON/OFF) Power Point output is
%	generated.
%
%	See also SETPPTSTATE
%	NKL, 25.12.02

global PPTSTATE
st = PPTSTATE;

