function varargout = statload(Ses,GrpExp,SigName,StatName,varargin)
%STATLOAD - Loads statistical data
%  STATLOAD(Ses,GrpExp,SigName,StatName,...) loads statistical data.
%
%  VERSION :
%    0.90 01.02.12 YM  pre-release
%    0.91 06.02.12 YM  renames as statload
%
%  See also statfilename statsave

if nargin < 4,  help statload; return;  end

VERBOSE = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case { 'verbose' }
    VERBOSE = varargin{N+1};
  end
end


Ses = getses(Ses);

filename = statfilename(Ses,GrpExp,SigName,StatName);
if ~exist(filename,'file'),
  if any(VERBOSE),
    error('\n  ERROR %s: file not found, ''%s''.\n',mfilename,filename);
  end
  varargout{1} = {};
  return;
end

switch lower(StatName)
 case { 'glmregr' 'glmoutput' 'glmout' }
  V = load(filename,'glmregr');
  V = V.glmregr;
 case { 'glmcont' 'cont' }
  V = load(filename,'glmcont');
  V = V.glmcont;
 case { 'corana' 'cor' }
  V = load(filename,'corana');
  V = V.corana;
 
 otherwise
  error('\n ERROR %s : no entry for''StatName=%s''.\n',mfilename,StatName);
end


varargout{1} = V;
