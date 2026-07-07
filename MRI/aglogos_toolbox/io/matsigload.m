function [varargout] = matsigload(File, varargin)
%MATSIGLOAD - Loads Sig from MAT file named catfilename(Ses,ExpNo,Sig)
%	[varargout] = MATSIGLOAD(File, varargin)
%	matsigload: Load vars from mat-file directly into vars in workspace.
%	usage: [varargout] = matsigload(File, varargin):
%	NKL, 10.10.02
%
% See also LOAD

for n = 1:length(varargin(:)),
  s = load(File,varargin{n});
  varargout{n} = getfield(s, varargin{n});
end;
return;
