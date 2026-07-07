function varargout = mvoxdisplay(ROITS,varargin)
%MVOXDISPLAY - displays roiTs/troiTs selected by mvoxselect.m
%  MVOXDISPLAY(ROITS/TROITS,...) displays roiTs/troiTs selected by mvoxselect().
%
%  EXAMPLE :
%    >> roiTs = mvoxselect('h05km1','esinj1','all','glm[1]',0.01);
%    >> mvoxdisplay(roiTs)
%
%  NOTE :
%    This function just calls dspmvoxmap().
%
%  VERSION :
%    0.90 14.11.07 YM  pre-release
%
%  See also mvoxselect dspmvoxmap

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

if nargout,
  varargout = dspmvoxmap(ROITS,varargin{:});
else
  dspmvoxmap(ROITS,varargin{:});
end

return

