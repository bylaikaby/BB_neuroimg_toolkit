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
%    0.93 05.07.19 YM  can read fields of the structure/cell array.
%
%  See also siginfo h5mat_varinfo h5mat_derefinfo is_hdf5file h5info h5read save

if mod(length(varargin),2) == 1
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
          'info' ...
          'ds' 'ana' 'name' 'coords'};
for N = iOpt:2:length(varargin)
  switch lower(varargin{N})
   case {'field' 'fields'}
    fields = varargin{N+1};
   case {'addfield' 'addfields'}
    tmpf = varargin{N+1};
    if ~isempty(tmpf)
      if ischar(tmpf),  tmpf = { tmpf };  end
      fields = cat(2,fields,tmpf(:)');
    end
  end
end
if ischar(fields) && ~isempty(fields),  fields = { fields };  end



% h5infoc(mex) since MATLAB-2013a at least, not in MATLAB-2011b
% %if verLessThan('MATLAB','8.1')
%   vinfo = h5mat_varinfo_old_matlab(Filename,SigName);
% else
%   % have h5infoc (mex)
%   vinfo = h5mat_varinfo(Filename,SigName);
% end

vinfo = h5mat_varinfo(Filename,SigName);


%vinfo = whos('-file',Filename,SigName);
%sigclass = vinfo.class;


sinfo = [];
switch lower(vinfo.class)
 case {'struct'}
  sinfo = sub_load_sig1_struct(Filename,SigName,vinfo,fields);
 case {'cell'}
  while strcmpi(vinfo.class,'cell')
    if prod(vinfo.size) > 1
      tmpinfo = h5mat_derefinfo(Filename,vinfo.Name,[1 1],[1 1]);
      if iscell(tmpinfo),  tmpinfo = tmpinfo{1};  end
    else
      tmpinfo = h5mat_derefinfo(Filename,vinfo.Name);
    end
    vinfo = tmpinfo;
    vinfo.class = sub_get_matclass(tmpinfo);
    vinfo.size  = sub_get_size(tmpinfo);
  end
  sinfo = sub_load_sig1_struct(Filename,SigName,vinfo,fields);
 
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
function fnames = sub_get_fieldnames(info)

fnames = {};
for N = 1:length(info.Attributes)
  if strcmpi(info.Attributes(N).Name,'MATLAB_fields')
    fnames = info.Attributes(N).Value;  break;
  end
end

return




% -------------------------------------------------------------------------------
function sinfo = sub_load_sig1_struct(Filename,SigName,vinfo,FIELDS)

sinfo = [];

Dataset = vinfo.Name;  % de-referenced name
if Dataset(1) ~= '/', Dataset = ['/' Dataset];  end

if prod(vinfo.size) > 1
  start = [1 1];
  count = [1 1];
else
  start = [];
  count = [];
end


fnames = sub_get_fieldnames(vinfo);

% % read only "dataset", no "group"
% dnames = cell(1,length(vinfo.Datasets));
% for N = 1:length(vinfo.Datasets)
%   tmpname = vinfo.Datasets(N).Name;
%   sep = strfind(tmpname,'/');
%   if any(sep),  tmpname = tmpname(sep(end)+1:end);  end
%   dnames{N} = tmpname;
% end
% [C ia ib] = intersect(fnames,dnames);
% fnames = fnames(sort(ia));

% limit fields to access for fast reading
if ~isempty(FIELDS)
  [C, ia, ib] = intersect(fnames,FIELDS);
  fnames = fnames(sort(ia));
end

% get fields
sinfo.signame = SigName;
for N = 1:length(fnames)
  location = [Dataset '/' fnames{N}];
  if any(start)
    dinfo = h5mat_derefinfo(Filename,location,start,count);
    if iscell(dinfo),  dinfo = dinfo{1};  end
  else
    dinfo = h5mat_derefinfo(Filename,location);
  end
  if strcmpi(fnames{N},'dat')
    % do not load ".dat"
    sinfo.datsize = dinfo.Dataspace.Size;
  else
    % if iscell(dinfo)
    %   fprintf('\n%2d: %s (cell-array[%d])...',N,location,length(dinfo));
    % else
    %   fprintf('\n%2d: %s (%s)...',N,location,dinfo.Name);
    % end
    % if any(start)
    %   [tmpv, status] = sub_h5read(Filename,dinfo,start,count);
    % else
    %   [tmpv, status] = sub_h5read(Filename,dinfo);
    % end
    [tmpv, status] = sub_h5read(Filename,dinfo);
    if any(status),  sinfo.(fnames{N}) = tmpv;  end
  end
end

return


function [val, status] = sub_h5read(Filename,dinfo,start,count,stride)
switch(nargin)
 case 2
  start = [];
  count = [];
  stride = [];
 case 4
  stride = [];
 case 5    
  %
 otherwise
  error(message('MATLAB:imagesci:validate:wrongNumberOfInputs'));	   
end

val = [];  status = 0;
if isempty(dinfo),  return;  end

% likely a cell array of data...
if iscell(dinfo)
  val = cell(size(dinfo));
  for N = 1:numel(dinfo)
    tmplocation = dinfo{N}.Name;
    %fprintf('%3d: %s\n', N,tmplocation);
    % if any(start)
    %   tmpinfo = h5mat_derefinfo(Filename,tmplocation,start,count);
    %   val{N} = sub_h5read(Filename,tmpinfo,start,count);
    % else
    %   tmpinfo = h5mat_derefinfo(Filename,tmplocation);
    %   val{N} = sub_h5read(Filename,tmpinfo);
    % end
    tmpinfo = h5mat_derefinfo(Filename,tmplocation);
    val{N} = sub_h5read(Filename,tmpinfo);
  end
  status = 1;
  return;
end


matclass = sub_get_matclass(dinfo);

% if "empty" value, do not try to read...
for N = 1:length(dinfo.Attributes)
  if strcmpi(dinfo.Attributes(N).Name,'MATLAB_empty')
    %dinfo.Datasets(1).Dataspace.Size
    % dinfo.Attributes(N).Value
    %h5mat_info_size(dinfo)
    tmpdim = h5read(Filename,dinfo.Name); % it seems h5read() gives dimensions...
    if sum(double(tmpdim)) > 0
      val = eval([ matclass '([' sprintf('%d ',tmpdim) '])']);
    elseif strcmpi(matclass,'cell')
      val = {};
    else
      val = eval([ matclass '([])']);
    end
    status = 1;
    return
  end
end


switch lower(matclass)
 case {'struct'}
  fnames = sub_get_fieldnames(dinfo);
  %keyboard
  for N = 1:length(fnames)
    %tmplocation = [location '/' fnames{N}];
    tmplocation = [dinfo.Name '/' fnames{N}];
    % if any(start)
    %   tmpinfo = h5mat_derefinfo(Filename,tmplocation,start,count);
    %   [tmpv,tmps] = sub_h5read(Filename,tmpinfo,start,count);
    % else
    %   tmpinfo = h5mat_derefinfo(Filename,tmplocation);
    %   [tmpv,tmps] = sub_h5read(Filename,tmpinfo);
    % end
    tmpinfo = h5mat_derefinfo(Filename,tmplocation);
    [tmpv,tmps] = sub_h5read(Filename,tmpinfo);
    if any(tmps),  val.(fnames{N}) = tmpv;  end
  end
  if isempty(dinfo.Datasets(1).Attributes)
    % I guess it's a structure array...
    fnames = fieldnames(val);
    tmpc = cell(length(fnames),numel(val.(fnames{1})));
    for N = 1:length(fnames)
      tmpc(N,:) = [val.(fnames{N})];
    end
    newval = cell2struct(tmpc,fnames);
    clear tmpc;
    % clear newval;
    % for N = 1:numel(val.(fnames{1}))
    %   for K = 1:length(fnames)
    %     newval(N).(fnames{K}) = val.(fnames{K}){N};
    %   end
    % end
    newval = reshape(newval,dinfo.Datasets(1).Dataspace.Size);
    val = newval;
  end
 
 case {'cell'}
  dinfo2 = h5mat_derefinfo(Filename,dinfo.Name);
  if iscell(dinfo2)
    val = cell(size(dinfo2));
    for N = 1:numel(dinfo2)
      [tmpv,tmps] = sub_h5read(Filename,dinfo2{N});
      if any(tmps),  val{N} = tmpv;  end
    end
  else
    if any(start)
      val = h5read(Filename,dinfo.Name,start,count);
    else
      val = h5read(Filename,dinfo.Name);
    end
  end
  
 otherwise
  if any(start)
    val = h5read(Filename,dinfo.Name,start,count);
  else
    val = h5read(Filename,dinfo.Name);
  end
end


if any(count)
  if iscell(val) && numel(val) == 1,  val = val{1};  end
end
switch lower(matclass)
 case {'char'}
  val = char(val);
 otherwise
end

status = 1;

return
