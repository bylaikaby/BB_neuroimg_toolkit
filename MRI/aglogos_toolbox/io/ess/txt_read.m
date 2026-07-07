function lines = txt_read(txtfile,keepblank)
%TXT_READ - Read a text file into a cell array of lines.
%  LINES = TXT_READ(TXTFILE,KEEPBLANK) reads the text file and
%  returns a cell array of lines.
%
%  EXAMPLE :
%    lines = txt_read(txtfile)
%
%  VERSION 
%    0.90  08.12.03 YM  modified from load_tclfile.m
%    0.91  21.12.10 YM  clean-up codes.
%
% See also fopen fclose fgetl tcl_read

if nargin < 1,  help txt_read; return;  end

if isempty(txtfile),
  [txtfile, pathname] = uigetfile(...
      {'*.txt;*.text', 'Text Files (*.txt, *.text)'; ...
       '*.*',          'All Files (*.*)'}, ...
      'Pick a text file',pwd);
  if isequal(txtfile, 0) || isequal(pathname,0), 
    fprintf(' %s: uigetfile() canceled.\n',mfilename);
    return;
  end
  txtfile = fullfile(pathname,txtfile);
end

if ~exist(txtfile,'file'),
  fprintf(' %s: ''%s'' not found.\n',mfilename,txtfile);
  return;
end

if ~exist('keepblank','var'),  keepblank = 0;  end

% clear output
lines = {};


% load the file
texts = {};
fid = fopen(txtfile,'r');
while feof(fid) == 0,
  texts = cat(2,texts,fgetl(fid));
end
fclose(fid);

for N = 1:length(texts),
  tmpline = deblank(texts{N});
  if isempty(tmpline), continue;  end
  % remove comment lines following '#','%'
  %Remove leading and trailing white-space from string
  t0 = strtrim(tmpline);
  % remove spaces, tabs at the beginning of the line
  %[t0,r0] = strtok(tmpline);
  %try
  %  t0 = strcat(t0,r0);
  %catch
  %  keyboard
  %end
  if t0(1) == '#', continue;  end
  if t0(1) == '%', continue;  end
  if keepblank,
    lines = cat(2,lines,tmpline);
  else
    lines = cat(2,lines,t0);
  end
end


return
