function sinfo = h5mat_sig1info(varargin)
%H5MAT_SIG1INFO - Get information of the signal structure.
%  INFO = H5MAT_SIG1INFO(Ses,Grp,SigName,...)
%  INFO = H5MAT_SIG1INFO(Ses,Exp,SigName,...)
%  INFO = H5MAT_SIG1INFO(Filename,SigName,...) gets information about the signal 
%  structure.
%
%  Supported options are :
%    'fields' : field names to read.
%
%  NOTE :
%   -If the given signal is an array, then returns information about the first
%    signal structure.
%   -The file must be an HDF5 file, saved with '-v7.3' option.
%   - size of "Sig.dat" is given as "INFO.datsize".
%
%  EXAMPLE :
%    sinfo = h5mat_sig1info(filename,'mysig')
%    sinfo = h5mat_sig1info('E10jz1',1,'Cln')
%
%  VERSION :
%    0.90 04.06.13 YM  pre-release
%    0.91 05.06.13 YM  bug fix.
%    0.92 07.06.13 YM  limit fields to get.
%
%  See also siginfo h5mat_varinfo h5mat_derefinfo is_hdf5file h5info h5read save

if mod(length(varargin),2) == 1,
  % called like h5mat_sig1info(Ses,GrpExp,SigName,...)
  Filename = sigfilename(varargin{1},varargin{2},varargin{3});
  SigName  = varargin{3};
  iOpt = 4;
else
  % called like h5mat_sig1info(Filename,SigName,...)
  Filename = varargin{1};
  SigName  = varargin{2};
  iOpt = 3;
end


% set options
fields = {'session' 'grpname' 'ExpNo' 'exps' ...
          'dx' 'dxorg' 'dat' ...
          'ds' 'ana' 'name' 'coords'};
for N = iOpt:2:length(varargin)
  switch lower(varargin{N})
   case {'field' 'fields'}
    fields = varargin{N+1};
  end
end
if ischar(fields) && ~isempty(fields),  fields = { fields };  end




sinfo = [];

vinfo = h5mat_varinfo(Filename,SigName);

%vinfo = whos('-file',Filename,SigName);
%sigclass = vinfo.class;


switch lower(vinfo.class)
 case {'struct'}
  sinfo = sub_sig1load_struct(Filename,SigName,vinfo,fields);
 case {'cell'}
  while strcmpi(vinfo.class,'cell')
    if prod(vinfo.size) > 1
      tmpinfo = h5mat_derefinfo(Filename,vinfo.Name,[1 1],[1 1]);
    else
      tmpinfo = h5mat_derefinfo(Filename,vinfo.Name);
    end
    vinfo = tmpinfo;
    vinfo.class = sub_get_matclass(tmpinfo);
    vinfo.size  = sub_get_size(tmpinfo);
  end
  
  sinfo = sub_sig1load_struct(Filename,SigName,vinfo,fields);
 
 otherwise
  fprintf(' WARNING %s: %s is not supported.\n',mfilename,vinfo.class);
end





return

% -------------------------------------------------------------------------------
function cname = sub_get_matclass(info)
cname = 'unknown';
if ~isfield(info,'Attributes'),  return;  end
for N = 1:length(info.Attributes)
  if strcmpi(info.Attributes(N).Name,'MATLAB_class')
    cname = info.Attributes(N).Value;
    break;
  end
end

return


% -------------------------------------------------------------------------------
function csize = sub_get_size(info)
csize = [];
if ~isfield(info,'Attributes'),  return;  end
if isfield(info,'Dataspace') && ~isempty(info.Dataspace)
  csize = info.Dataspace.Size;
elseif isfield(info,'Datasets') && ~isempty(info.Datasets)
  % likely "VarName" as 'struct'
    for N = 1:length(info.Datasets)
      switch(info.Datasets(N).Datatype.Class)
       case 'H5T_ENUM'
        continue;
       case 'H5T_STRING'
        continue;
       case 'H5T_OPAQUE'
        continue;
       case 'H5T_REFERENCE' 
        csize = info.Datasets(1).Dataspace.Size;
        break;
       otherwise
        csize = [1 1];
        break;
      end
    end
    if isempty(csize)
      fprintf(' WARNING %s: cannot find size of %s...\n',mfilename,info.Name);
    end
end

return


% -------------------------------------------------------------------------------
function sinfo = sub_sig1load_struct(Filename,SigName,vinfo,FIELDS)

sinfo = [];

Dataset = vinfo.Name;
if Dataset(1) ~= '/', Dataset = ['/' Dataset];  end

if prod(vinfo.size) > 1
  start = [1 1];
  count = [1 1];
else
  start = [];
  count = [];
end

% read only "dataset", no "group"
dnames = cell(1,length(vinfo.Datasets));
for N = 1:length(vinfo.Datasets)
  tmpname = vinfo.Datasets(N).Name;
  sep = strfind(tmpname,'/');
  if any(sep),  tmpname = tmpname(sep(end)+1:end);  end
  dnames{N} = tmpname;
end
fnames = {};
for N = 1:length(vinfo.Attributes)
  if strcmpi(vinfo.Attributes(N).Name,'MATLAB_fields')
    fnames = vinfo.Attributes(N).Value;
  end
end
[C ia ib] = intersect(fnames,dnames);
fnames = fnames(sort(ia));

% limit fields to access for fast reading
if ~isempty(FIELDS),
  [C ia ib] = intersect(fnames,FIELDS);
  fnames = fnames(sort(ia));
end

% get fields
sinfo.signame = SigName;
for N = 1:length(fnames)
  tmpf = fnames{N};
  tmppath = sprintf('%s/%s',Dataset,tmpf);
  if any(start),
    tmpinfo = h5mat_derefinfo(Filename,tmppath,start,count);
  else
    tmpinfo = h5mat_derefinfo(Filename,tmppath);
  end
  if isempty(tmpinfo),  continue;  end
  % likely array of cell/struct, ignore
  if iscell(tmpinfo),  continue;  end
  
  % ignore the field which is a cell array
  tmpclass = sub_get_matclass(tmpinfo);
  if strcmpi(tmpclass,'cell'),  continue;  end
  
  if strcmpi(tmpf,'dat'),
    sinfo.datsize = tmpinfo.Dataspace.Size;
  else
    if any(start)
      tmpv = h5read(Filename,tmppath,start,count);
    else
      tmpv = h5read(Filename,tmppath);
    end
    if any(count)
      if iscell(tmpv) && numel(tmpv) == 1,  tmpv = tmpv{1};  end
    end
    switch lower(tmpclass),
     case {'char'}
      tmpv = char(tmpv);
     otherwise
    end
    sinfo.(tmpf) = tmpv;
  end
end

return
