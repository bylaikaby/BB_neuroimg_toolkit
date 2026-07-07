function mat2h5mat(Filename,varargin)
%MAT2H5MAT - Convert a matfile into an HDF5 matfile.
%  MAT2H5MAT(Filename,...) converts a matfile into an HDF5 matfile.
%  Supported options are :
%    'backup'  : 0|1, whether to make a backup or not.
%    'system'  : 0|1, use system call for renaming.
%    'verbose' : 0|1, prints messages or not.
%
%  EXAMPLE :
%    mat2h5mat(Filename)
%
%  VERSION :
%    0.90 05.06.13 YM  pre-release
%    0.91 12.06.13 YM  try system() call to rename.
%
%  See also save is_hdf5file who whos system dos

if nargin < 1,  eval(['help ' mfilename]); return;  end


if exist(Filename,'dir')
  files = dir(Filename);
  for N = 1:length(files)
    if files(N).isdir,  continue;  end
    fname = fullfile(Filename,files(N).name);
    mat2h5mat(fname,varargin{:});
  end
  return
end


% options
DO_BACKUP  = 0;
USE_SYSTEM = 1;
VERBOSE    = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'backup'}
    DO_BACKUP = varargin{N+1};
   case {'system'}
    USE_SYSTEM = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if ~exist(Filename,'file')
  error('\n ERROR %s: ''%s'' not found.\n',mfilename,Filename);
end

if any(VERBOSE),
  fprintf('%s: ''%s''',mfilename,Filename);
end

% check whether HDF5 format or not.
if is_hdf5file(Filename) > 0,
  if any(VERBOSE),  fprintf(' is an HDF5 file.\n');  end
  return;
end


if any(VERBOSE),  tStart = tic;  end


try
  if any(VERBOSE),  fprintf(' who.');  end
  VarNames = who('-file',Filename);
catch
  if any(VERBOSE),
    fprintf(' is not a matlab file or corrupted.\n');
  end
  return
end



[fp fr fe] = fileparts(Filename);
bakfile = fullfile(fp,sprintf('%s.bak%s',fr,fe));
  
Srcfile = bakfile;
Dstfile = Filename;
if any(VERBOSE),  fprintf(' rename.');  end

if any(USE_SYSTEM)
  Filename = fullfile(Filename);
  if ispc
    [fp fr fe] = fileparts(bakfile);
    bakfile2 = sprintf('%s%s',fr,fe);
    status = system(['ren ' Filename ' ' bakfile2]);
    clear fp fr fe bakfile2;
  else
    status = system(['mv -f ' Filename '' bakfile]);
  end
  if status ~= 0
    % failed... use the matlab function...
    movefile(Filename,bakfile,'f');
  end
else
  movefile(Filename,bakfile,'f');
end



if any(VERBOSE),
  fprintf(' loading(nvar=%d).',length(VarNames));
end
load(Srcfile);
if any(VERBOSE),
  fprintf(' saving %s...',sub_names(VarNames));
end
save(Dstfile,VarNames{:},'-v7.3');

if ~any(DO_BACKUP)
  delete(Srcfile);
end


if any(VERBOSE)
  fprintf(' done (%gs).\n',toc(tStart));
end

return


% -----------------------------------------------------------
function namestr = sub_names(VarNames)
if ischar(VarNames),
  namestr = VarNames; 
  return
end

namestr = '';
for N = 1:numel(VarNames)
  namestr = [namestr  VarNames{N} ','];
end
namestr = namestr(1:end-1);

return

