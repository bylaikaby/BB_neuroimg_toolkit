function [varargout] = matsigsave(varargin)
%MATSIGSAVE - Saves Sig to MAT file named catfilename(Ses,ExpNo,Sig)
%	[varargout] = MATSIGSAVE(varargin), saves structures in file
%	usage: [varnames_saved] = matsigsave(filename, structure)
%	usage: [varnames_saved] = matsigsave(filename, varname, value,...)
%	usage: [varnames_saved] = matsigsave(filename, APPEND,...)
%
%	NKL, 10.10.02

if length(varargin{1})<5 | ~strcmp( varargin{1}(end-3:end),'.mat'),
   varargin{1} = strcat(varargin{1},'.mat');
end;

if (length(varargin{2})>3) & isa(varargin{2},'char'),
   switch lower(varargin{end}(1:4)),
   case {'-app'},
      varargin{2} = 1;
   case {'-ove'},
      varargin{2} = 0;
   otherwise,
      varargin = cat(1,varargin(1),{1},varargin(2:end));	% Append by default.
   end;
end;
if ~isa(varargin{2},'double'),
   varargin = cat(1,varargin(1),{1},varargin(2:end));	% Append by default.
end;   

varargout = cell(0,1);
% Process name value pairs...
while length(varargin(:)) > 3,
   eval( sprintf('%s = varargin{4};', varargin{3}));
   varargout = cat(1,varargout(:),{varargin{3}});
   varargin(3:4) = [];
end;
% Process remaining odd input as structure...
if length(varargin(:)) > 2,
   pareval(varargin{3});
   varargout = cat(1,varargout(:),fieldnames(varargin{3}));
end;

if varargin{2} & ~isempty(dir(varargin{1})),
   save(varargin{1}, varargout{:}, '-append');
else,
   save(varargin{1}, varargout{:});
end;

varargout{1} = varargout;

return;

%%% SCRATCH:
while length(varargin) > 1,
   pareval(varargin{2});
   varargout = fieldnames(varargin{2});
   
   if exist(varargin{1},'file'),
      save( varargin{1}, varargout{:},'-append');
   else,
      save( varargin{1}, varargout{:});
   end;
   varargin(2) = [];
end;

return;
