function lines = tcl_read(tclfile,varargin)
%TCL_READ - load a Tcl file into a cell array of lines.
%  LINES = TCL_READ(TCLFILE) loads the tcl file into a cell array of lines.
%  Supported options are
%    'verbose' : 0|1, verbose or not.
%    'comment' : 0|1, include comments or not.
%
%  EXAMPLE :
%    lines = tcl_read(tclfile)
%
%  VERSION :
%    1.00 30.05.01 YM  first release
%    1.01 27.04.03 YM  adapted to MRI
%    1.02 10.12.03 YM  bug fix.
%    1.02 21.12.10 YM  clean-up codes.
%
% See also fopen fclose fgetl txt_read

if nargin < 1,  help tcl_read; return;  end  


VERBOSE = 1;
NO_COMMENT = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
   case {'nocomment','no comment'}
    NO_COMMENT = varargin{N+1};
   case {'comment','comments'}
    NO_COMMENT = ~varargin{N+1};
  end
end

% clear output
lines = {};

if isempty(tclfile),
  [tclfile, pathname] = uigetfile(...
      {'*.tcl', 'Tcl Files (*.tcl)'; ...
       '*.*',   'All Files (*.*)'}, ...
      'Pick a Tcl file',pwd);
  if isequal(tclfile, 0) || isequal(pathname,0), 
    fprintf(' %s: uigetfile() canceled.\n',mfilename);
    return;
  end
  tclfile = fullfile(pathname,tclfile);
end


if ~exist(tclfile,'file'),
  if VERBOSE,
    fprintf(' %s: ''%s'' not found.\n',mfilename,tclfile);
  end
  return;
end


% load the file
texts = {};
fid = fopen(tclfile,'r');
while 1,
  if feof(fid),  break,  end;
  texts = cat(2,texts,fgetl(fid));
end
fclose(fid);


% remove comments, spaces etc.
for N = 1:length(texts),
  tmpline = strtrim(deblank(texts{N}));
  if isempty(tmpline), continue;  end
  if NO_COMMENT,
    % remove comments following '#'
    if tmpline(1) == '#', continue;  end
  end
  lines = cat(2,lines,tmpline);
end


return
