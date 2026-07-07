function Res = sigmyfunc(Sig,varargin)
%SIGMYFUNC - does xxx.
%  Res = sigmyfunc(Sig,...) does xxx.
%
%  Supported options are :
%    MYOPTION1   : option1 ...
%    MYOPTION2   : option2 ...
%
%  EXAMPLE :
%    >> Res = sigmyfunc(Sig,'myoption1','aaa','myoption2',1);
%    >> dspmyfunc(res)
%
%  NOTE :
%    Sig.dx as sampling time in sec
%    Sig.dat must be (time,channel) ?
%
%  VERSION :
%    0.90 dd.mm.yy who what
%
%  See also dspmyfunc

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

if iscell(Sig),
  for N = 1:length(Sig),
    Res{N} = sigmyfunc(Sig{N},NEWDX,varargin{:});
  end
  return
end

% DEFAULT VALUES FOR OPTIONS
MYOPTION1    = 'aaa';    % do xxxx
MYOPTION2    = 0;        % do xxxx

% UPDATE OPTIONAL SETTINGS
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'myoption1'}
    MYOPTION1 = varargin{N+1};
   case {'myoption2'}
    MYOPTION2 = varargin{N+1};
  end
end


% =======================================================
% Do processing of "myfunc"
% Sig.dx : sampling time in sec
% Sig.dat : data as (time,channel)
Res = myfunc(Sig,MYOPTION1,MYOPTION2);


% do something here...

% =======================================================



% store some information
Res.(mfilename).myoption1 = MYOPTION1;
Res.(mfilename).myoption2 = MYOPTION2;


return
