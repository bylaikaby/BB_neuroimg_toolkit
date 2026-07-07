function [varargout] = expsigload(SESSION,ExpNo, varargin)
%EXPSIGLOAD - Loads Sig from matfile of SESSION and ExpNo
%	[varargout] = EXPSIGLOAD(File, varargin)
%	expsigload: Load vars from mat-file directly into vars in workspace.
%	usage: [varargout] = expsigload(File, varargin):
%	NKL, 10.10.02

Ses = goto(SESSION);
File = catfilename(Ses,ExpNo,'mat');

if isempty(varargin),
  s = load(File);
  tmp = fieldnames(s);
  for n = 1:length(tmp),
	assignin('caller', tmp{n}, getfield(s,tmp{n}));
  end;
  return;
end;

tmp = load( File, varargin{:});

for n= 1:length(varargin(:)),
   try,
      varargout{n} = getfield(tmp,varargin{n});
   catch,
      varargout{n} = [];
      fprintf('expsigload: no "%s" not in "%s"\n',varargin{n},File);
   end;
end;
return;
