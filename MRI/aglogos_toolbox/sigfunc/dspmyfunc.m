function varargout = dspmyfunc(Res,varargin)
%DSPMYFUNC - does xxx.
%  HAXES = dspmyfunc(Res,...) does xxx.
%
%  Supported options are :
%    axes        : the axes handle to plot.
%    MYOPTION1   : option1 ...
%    MYOPTION2   : option2 ...
%
%  EXAMPLE :
%    >> Res = sigmyfunc(Sig,'myoption1','aaa','myoption2',1);
%    >> dspmyfunc(res)
%
%  NOTE :
%    aaa bbb cccc
%
%  VERSION :
%    0.90 dd.mm.yy who what
%
%  See also sigmyfunc


% CONTROL FLAGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H_AXES    =  [];
MYOPTION1    = 'aaa';    % do xxxx
MYOPTION2    = 0;        % do xxxx


% parse inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'axes'}
    H_AXES = varargin{N+1};
   case {'myoption1'}
    MYOPTION1 = varargin{N+1};
   case {'myoption2'}
    MYOPTION2 = varargin{N+1};
  end
end


if isempty(H_AXES) || ~ishandle(H_AXES),
  figure('Name',mfilename);
  H_AXES = axes;
else
  axes(H_AXES);
end


% =======================================================
% plot ...

% plot something here...


% =======================================================




% return the axes handle(s)
if nargout
  varargout{1} = H_AXES;
end

return


