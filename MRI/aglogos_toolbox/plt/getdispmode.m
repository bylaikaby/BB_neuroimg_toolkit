function st = getdispmode
%GETDISPMODE - it returns whether or not PPT output is required
%	state = GETDISPMODE reads the global variable DISPMODE and returns it to
%	the caller; if set by setdispmode(ON/OFF) Power Point output is
%	generated.
%
%	See also SETDISPMODE
%	NKL, 25.12.02

global DISPMODE
st = DISPMODE;

