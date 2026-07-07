function setdispmode(state)
%SETDISPMODE - it returns whether or not PPT output is required
%	SETDISPMODE(state) reads the global variable DISPMODE and returns it to
%	the caller; if set by setdispmode(ON/OFF) Power Point output is
%	generated.
%
%	See also SETDISPMODE
%	NKL, 25.12.02

global DISPMODE
if state,
	DISPMODE = 1;
else
	DISPMODE = 0;
end;
assignin('base','DISPMODE',DISPMODE);



