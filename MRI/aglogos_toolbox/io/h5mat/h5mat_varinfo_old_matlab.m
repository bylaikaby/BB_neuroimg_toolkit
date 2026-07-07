function hinfo = h5mat_varinfo_old_matlab(filename,VarName)
%H5MAT_VARINFO - Get information about the given MATLAB var. in the hdf5file.
%  INFO = H5MAT_VARINFO(FILENAME,VarName) gets information about the given MATLAB var. in 
%  the hdf5file.
%
%  EXAMPLE :
%    info = h5mat_varinfo_old_matlab(hdf5file,'myvar');
%
%  VERSION :
%    0.90 04.06.13 YM   modified from MATLAB-2011's h5info().
%    0.91 04.07.19 YM   renamed as h5mat_varinfo_old_matlab.m.
%
%  See also h5mat_derefinfo h5mat_sig1info is_hdf5file h5info h5read


hinfo = [];


location = VarName;
if location(1) ~= '/',  location = ['/' location];  end

global h5_object_map;        % list of objects with reference counts > 1
h5_object_map = containers.Map('KeyType','double','ValueType','any');

try  
  hinfo = get_info(filename, location);
  clear global h5_object_map;
  %hinfo = rmfield(hinfo,{'Groups' 'Datasets' 'Links'});
  
catch me
  clear global h5_object_map;
  rethrow(me);
end


hinfo.class = 'unknown';
hinfo.size  = [];
n = numel(fieldnames(hinfo));
hinfo = orderfields(hinfo, [1 2 n-1 n 3:n-2]);


if isfield(hinfo,'Attributes'),
  for N = 1:length(hinfo.Attributes)
    if strcmpi(hinfo.Attributes(N).Name,'MATLAB_class')
      hinfo.class = hinfo.Attributes(N).Value;
      break;
    end
  end
  if isfield(hinfo,'Dataspace') && ~isempty(hinfo.Dataspace)
    hinfo.size = hinfo.Dataspace.Size;
  elseif isfield(hinfo,'Datasets') && ~isempty(hinfo.Datasets)
    % likely "VarName" as 'struct'
    for N = 1:length(hinfo.Datasets)
      switch(hinfo.Datasets(N).Datatype.Class)
       case 'H5T_ENUM'
        continue;
       case 'H5T_STRING'
        continue;
       case 'H5T_OPAQUE'
        continue;
       case 'H5T_REFERENCE'
        %hinfo.size = hinfo.Datasets(1).Dataspace.Size;
        % should be N==1...
        hinfo.size = hinfo.Datasets(N).Dataspace.Size;
        break;
       otherwise
        hinfo.size = [1 1];
        break;
      end
    end
    if isempty(hinfo.size)
      fprintf(' WARNING %s: cannot find size of %s...\n',mfilename,VarName);
    end
  end
end




return





%--------------------------------------------------------------------------
function hinfo = get_info(filename,location)

% This routine is executed just once.
    
fid = fopen(filename,'r');
if ( fid == -1 )
    error(message('MATLAB:imagesci:h5info:fileOpen', filename));
end
fullhfile = fopen(fid);  % get full pathname
fclose(fid);

if ~H5F.is_hdf5(fullhfile)
    error(message('MATLAB:imagesci:h5read:notHDF5', filename));
end

fid = H5F.open(fullhfile,'H5F_ACC_RDONLY','H5P_DEFAULT');
    

if location == '/'
    
   % Get metadata starting from the root group.
   root_gid = H5G.open(fid,'/','H5P_DEFAULT');
   hinfo = get_group_info(root_gid,'/'); 
   H5G.close(root_gid);
   
else
    
    % Check if we were given a soft, external, or user-defined link.
    link_info = H5L.get_info(fid,location,'H5P_DEFAULT');
    switch(link_info.type)
        case -1
            error(message('MATLAB:imagesci:h5info:topLevelLinkError', location));
             
        case H5ML.get_constant_value('H5L_TYPE_HARD')
            % This is the case we normally expect.
            hinfo = get_toplevel_hardlink_info(fid,location);
                   
        case H5ML.get_constant_value('H5L_TYPE_SOFT')
            hinfo = get_link_info(fid,location,link_info.type);
            
        case H5ML.get_constant_value('H5L_TYPE_EXTERNAL')
            hinfo = get_link_info(fid,location,link_info.type);
            
        otherwise
            hinfo = get_link_info(fid,location,link_info.type);
    end
            
end

hinfo.Filename = fullhfile;

% Reorder the fields such that Filename is on top.
n = numel(fieldnames(hinfo));
hinfo = orderfields(hinfo, [n 1:n-1]);


H5F.close(fid);


%--------------------------------------------------------------------------
function hinfo = get_toplevel_hardlink_info(fid,location)

% OK, the object has a normal hard link.  Proceed as usual.
% Get metadata starting at the specified location.
obj_id = H5O.open(fid,location,'H5P_DEFAULT');
obj_info = H5O.get_info(obj_id);

obj_name = H5I.get_name(obj_id);

switch(obj_info.type)

    case H5ML.get_constant_value('H5O_TYPE_GROUP')
        sep = strfind(obj_name,'/');
        parent_group_name = obj_name(1:sep(end)-1);

        % If '/' was specified, then the parent group is still the root
        % group.
        if isempty(parent_group_name)
            parent_group_name = '/';
        end

        % Parse out the name of the leaf group.
        child_group_name = obj_name(sep(end)+1:end);
        if isempty(child_group_name)
            child_group_name = '/';
        end

        parent_group_id = H5G.open(fid,parent_group_name);
        hinfo = get_group_info(parent_group_id,child_group_name);
        H5G.close(parent_group_id);

    case H5ML.get_constant_value('H5O_TYPE_DATASET')
        hinfo = get_dataset_info(obj_id);

    case H5ML.get_constant_value('H5O_TYPE_NAMED_DATATYPE')
        hinfo = get_datatype_info(obj_id);
end

H5O.close(obj_id);
    
%--------------------------------------------------------------------------
function info = get_group_info(parent_group_id,child_group_name)
% Get information about a specific group whose full name is given by 
%
% '/parent_group_name/child_group_name'
%
% where parent_group_name can consist of many groups.

% list of objects with reference counts > 1
% persistent h5_object_map;
% if isempty(h5_object_map)
%     h5_object_map = containers.Map('KeyType','double','ValueType','any');
% end

global h5_object_map;

parent_group_name = H5I.get_name(parent_group_id);

info = get_struct_template('group');

% Assign the full path of the group name.
if (child_group_name == '/')
    % This happens when get_group_info is called for a file as a whole.
	info.Name = '/';
elseif parent_group_name == '/'
    % This case arises when get_group_info is called on top-level groups.
    info.Name = sprintf('/%s', child_group_name);
else
	info.Name = sprintf('%s/%s', parent_group_name, child_group_name);
end

group_count = 0;
dataset_count = 0;
datatype_count = 0;
link_count = 0;

link_type_hard = H5ML.get_constant_value('H5L_TYPE_HARD');
link_type_soft = H5ML.get_constant_value('H5L_TYPE_SOFT');
link_type_external = H5ML.get_constant_value('H5L_TYPE_EXTERNAL');
link_type_error = -1;

child_group_id = H5G.open(parent_group_id,child_group_name,'H5P_DEFAULT');
child_group_info = H5G.get_info(child_group_id);
for j = 1:child_group_info.nlinks
    
    name{j} = H5L.get_name_by_idx(parent_group_id,child_group_name, ...
        'H5_INDEX_NAME', 'H5_ITER_INC', j-1, 'H5P_DEFAULT'); %#ok<AGROW>
    
    link_info = H5L.get_info(parent_group_id, ...
        [child_group_name '/' name{j}], ...
        'H5P_DEFAULT');

    
    % Soft, external, and user-defined links can be handled first.
    switch (link_info.type)
        case link_type_error
            error(message('MATLAB:imagesci:h5info:linkInfoError', parent_group_name, child_group_name, name{ j }));
            
        case link_type_hard
            % Do nothing just yet.  Hard links will be resolved later.
            
        case link_type_soft
            % Do not follow soft links, as this can result in infinite
            % loops.
            link_count = link_count + 1;
            l_info = get_link_info(child_group_id,name{j},link_info.type);
            if link_count == 1
                info.Links = l_info;
            else
                info.Links(link_count,1) = l_info;
            end
            continue
            
        case link_type_external
            % Do not follow external links.
            link_count = link_count + 1;
            l_info = get_link_info(child_group_id,name{j},link_info.type);
            if link_count == 1
                info.Links = l_info;
            else
                info.Links(link_count,1) = l_info;
            end
            continue
            
        otherwise
            
            % It must be a user-defined link.
            % Do not follow user defined links.  Terminate here.
            link_count = link_count + 1;
            l_info = get_link_info(child_group_id,name{j},link_info.type);
            if link_count == 1
                info.Links = l_info;
            else
                info.Links(link_count,1) = l_info;
            end

            
            continue           
            
    end
    
    % If not a soft, external, or user-defined link, then the object must
    % be a hard link. Get object information.  We use the object's 
    % reference count and in-file address to avoid infinite circular link 
    % cycles.
    obj_id = H5O.open(child_group_id,name{j},'H5P_DEFAULT');
	obj_info = H5O.get_info(obj_id);

    if obj_info.rc > 1
        
         % We have encountered an object that is hardlinked from a location
         % other than the parent group.  Have we already encountered this
         % object?
         if isKey(h5_object_map,obj_info.addr)
             % Ok we already encountered this object.  Classify it as a hard
             % link and decrement our private reference count of it.  Then
             % we are done with this object, so go onto the next.
             o = h5_object_map(obj_info.addr);
             o.obj_info.rc = o.obj_info.rc-1;
             h5_object_map(obj_info.addr) = o;
             link_count = link_count + 1;
             
             l_info = get_link_info(child_group_id,name{j},link_info.type);
             l_info.Value = {o.value};
             
             if link_count == 1
                 info.Links = l_info;
             else
                 info.Links(link_count,1) = l_info;
             end
             continue
         else
             % No such object has as of yet been encountered and there
             % are multiple references to it.  We will continue to treat
             % it as a valid hard link, but we also will keep track of
             % so that we don't follow this link when we encounter it
             % again.
             obj_info.rc = obj_info.rc-1;
             o.obj_info = obj_info;
             o.value = H5I.get_name(obj_id);
             h5_object_map(obj_info.addr) = o;
         end
     end
    
    % What we have below are "proper" children of the parent group.  These
    % are hard links that are not linked to from anywhere else.  This is
    % the lion's share of objects.
	switch(obj_info.type)
		case H5ML.get_constant_value('H5O_TYPE_GROUP')
			group_count = group_count + 1;
            ginfo = get_group_info(child_group_id,name{j});
            if ( group_count == 1 )
                info.Groups = ginfo;
            else
                info.Groups(group_count,1) = ginfo;
            end
            
		case H5ML.get_constant_value('H5O_TYPE_DATASET')
            dataset_count = dataset_count + 1;
            dinfo = get_dataset_info(obj_id);
            if (dataset_count == 1)
                info.Datasets = dinfo;
            else
                info.Datasets(dataset_count,1) = dinfo;
            end
            
		case H5ML.get_constant_value('H5O_TYPE_NAMED_DATATYPE')
			datatype_count = datatype_count + 1;
            dtinfo = get_datatype_info(obj_id);
            if ( datatype_count == 1 )
                info.Datatypes = dtinfo;
            else
                info.Datatypes(datatype_count,1) =  dtinfo;
            end
            
        otherwise
            warning(message('MATLAB:imagesci:h5info:unrecognizedObjectType', parent_group_name, child_group_name, name{ j }));
	end

	H5O.close(obj_id);
	
end


info.Attributes = get_attributes(child_group_id);


H5G.close(child_group_id);

return


%--------------------------------------------------------------------------
function info = get_link_info(group_id,link_name,link_type)
% Retrieve information about links.  Hard 

info = get_struct_template('link');

info.Name = link_name;

switch(link_type)
    case H5ML.get_constant_value('H5L_TYPE_HARD')
        info.Type = 'hard link';
        % Don't bother with the value.  We will fill that in when we
        % return.
        
    case H5ML.get_constant_value('H5L_TYPE_SOFT')
        info.Type = 'soft link';
        info.Value = H5L.get_val(group_id,link_name,'H5P_DEFAULT');
        
    case H5ML.get_constant_value('H5L_TYPE_EXTERNAL')
        info.Type = 'external link';
        info.Value = H5L.get_val(group_id,link_name,'H5P_DEFAULT');   
        
    otherwise
        info.Type = 'user-defined link'; % no other possibility
        info.Value = {''};
end






%--------------------------------------------------------------------------
function info = get_dataset_info(dsid)
% Return information about the dataset.

dtype    = H5D.get_type(dsid); 
dcpl     = H5D.get_create_plist(dsid);
space_id = H5D.get_space(dsid);  

info = get_struct_template('dataset');
name = H5I.get_name(dsid);

% % Remove the leading group path from the name.
% sep = strfind(name,'/');
% info.Name = name(sep(end)+1:end);
info.Name = name;


info.Datatype = get_datatype_info(dtype);

% Get the size information from the dataspace.  If the dataspace is scalar,
% then the dims will be [].
info.Dataspace = get_dataspace_info(space_id);



% Get the layout and chunking
layout = H5P.get_layout(dcpl);
if layout == H5ML.get_constant_value('H5D_CHUNKED')
    [~,dims] = H5P.get_chunk(dcpl);
    info.ChunkSize = fliplr(dims);
end

info.Filters = get_filters(dcpl);
info.Attributes = get_attributes(dsid);
info.FillValue = get_fill_value(dsid,dtype,space_id,dcpl);

H5P.close(dcpl);
H5S.close(space_id);
H5T.close(dtype);

% Don't close the dataset id, that's handled elsewhere.

return;

%--------------------------------------------------------------------------
function info = get_dataspace_info(space_id)

[~,dims,maxdims] = H5S.get_simple_extent_dims(space_id);
info.Size = fliplr(dims);
maxdims(maxdims == -1) = Inf;
info.MaxSize = fliplr(maxdims);

stype = H5S.get_simple_extent_type(space_id);
switch(stype)
    case H5ML.get_constant_value('H5S_SIMPLE');
        info.Type = 'simple';
    case H5ML.get_constant_value('H5S_NULL');
        info.Type = 'null';
    case H5ML.get_constant_value('H5S_SCALAR');
        info.Type = 'scalar';
    otherwise
        error(message('MATLAB:imagesci:h5info:unknownDataspaceType', stype));
end

                     

%--------------------------------------------------------------------------
function Filter = get_filters(dcpl)

% Get the filters, i.e. compression.
nfilt = H5P.get_nfilters(dcpl);
if nfilt == 0
	Filter = [];
else
    x = struct('Name','','Data',[]);
	Filter = repmat(x,nfilt,1);
    for j = 1:nfilt
        % The filter name and associated data is the most useful
        % information.  The filter flag is difficult to interpret without
        % dropping down entirely to the low-level interface.
        [~, ~, Filter(j).Data, Filter(j).Name] = H5P.get_filter(dcpl,j-1);
    end
end

%--------------------------------------------------------------------------
function fill_value = get_fill_value(~,dtype,space_id,dcpl)

% Set a default value.
fill_value = [];


fvd = H5P.fill_value_defined(dcpl);
fill_time = H5P.get_fill_time(dcpl);
if ( (fill_time ~= H5ML.get_constant_value('H5D_FILL_TIME_IFSET')) ...
        || (fvd == H5ML.get_constant_value('H5D_FILL_VALUE_UNDEFINED')) )
    return
end
    

% The fill value is defined, so go ahead and try to retrieve it.
fill_value = H5P.get_fill_value(dcpl,dtype);

% Do we need to do any post processing?
class_id = H5T.get_class(dtype);
switch ( class_id )
    case { H5ML.get_constant_value('H5T_FLOAT'), ...
            H5ML.get_constant_value('H5T_INTEGER'), ...
            H5ML.get_constant_value('H5T_BITFIELD'), ...
            H5ML.get_constant_value('H5T_OPAQUE'), ...
            H5ML.get_constant_value('H5T_REFERENCE'), ...
            H5ML.get_constant_value('H5T_STRING'), ...
            H5ML.get_constant_value('H5T_VLEN'), ...
            H5ML.get_constant_value('H5T_COMPOUND'), ...
            H5ML.get_constant_value('H5T_ARRAY') }
        % No need to post process.
    case H5ML.get_constant_value('H5T_ENUM')
        data = h5postprocessenums(dtype,space_id,fill_value);
        fill_value = data{1};
end

%--------------------------------------------------------------------------
function info = get_attributes(obj_id)
% We could be getting attributes for a group, a dataset, or a named
% datatype.

total_attrs = H5A.get_num_attrs(obj_id);

% return early if there are no attributes.
if total_attrs == 0
    info = [];
    return;
end

info = get_struct_template('attribute');
info = repmat(info,total_attrs,1);

for j = 1:total_attrs
    attr_id = H5A.open_idx(obj_id,j-1);
    atype = H5A.get_type(attr_id);
    aspace = H5A.get_space(attr_id);
    info(j).Datatype = get_datatype_info(atype);
    info(j).Name = H5A.get_name(attr_id);
   
    info(j).Dataspace = get_dataspace_info(aspace);
    
    raw_value = H5A.read(attr_id,'H5ML_DEFAULT');
    switch(info(j).Datatype.Class)
        case 'H5T_ENUM'
            info(j).Value = h5postprocessenums(atype,aspace,raw_value);
        case 'H5T_STRING'
            info(j).Value = h5postprocessstrings(atype,aspace,raw_value);
        case 'H5T_OPAQUE'
            info(j).Value = h5postprocessopaques(atype,aspace,raw_value);
        case 'H5T_REFERENCE'
            info(j).Value = raw_value;
        otherwise
            info(j).Value = raw_value;
    end
    
    H5S.close(aspace);
    H5T.close(atype);
    H5A.close(attr_id);
end
return

%--------------------------------------------------------------------------
function info = get_datatype_info(dtype)

info = get_struct_template('datatype');

class_id = H5T.get_class(dtype);
switch ( class_id )
    case H5ML.get_constant_value('H5T_BITFIELD')
        info.Class = 'H5T_BITFIELD';
        if H5T.equal(dtype,'H5T_STD_B8BE')
            dtypeStr = 'H5T_STD_B8BE';
        elseif H5T.equal(dtype,'H5T_STD_B8LE')
            dtypeStr = 'H5T_STD_B8LE';
        elseif H5T.equal(dtype,'H5T_STD_B16LE')
            dtypeStr = 'H5T_STD_B16LE';
        elseif H5T.equal(dtype,'H5T_STD_B16BE')
            dtypeStr = 'H5T_STD_B16BE';
        elseif H5T.equal(dtype,'H5T_STD_B32LE')
            dtypeStr = 'H5T_STD_B32LE';
        elseif H5T.equal(dtype,'H5T_STD_B32BE')
            dtypeStr = 'H5T_STD_B32BE';
        elseif H5T.equal(dtype,'H5T_STD_B64LE')
            dtypeStr = 'H5T_STD_B64LE';
        elseif H5T.equal(dtype,'H5T_STD_B64BE')
            dtypeStr = 'H5T_STD_B64BE';
        else
            dtypeStr = sprintf('Unrecognized bitfield' );
        end
        info.Type = dtypeStr;
        
    case H5ML.get_constant_value('H5T_INTEGER')
        info.Class = 'H5T_INTEGER';
        if H5T.equal(dtype,'H5T_STD_I8BE')
            dtypeStr = 'H5T_STD_I8BE';
        elseif H5T.equal(dtype,'H5T_STD_I8LE')
            dtypeStr = 'H5T_STD_I8LE';
        elseif H5T.equal(dtype,'H5T_STD_U8BE')
            dtypeStr = 'H5T_STD_U8BE';
        elseif H5T.equal(dtype,'H5T_STD_U8LE')
            dtypeStr = 'H5T_STD_U8LE';
        elseif H5T.equal(dtype,'H5T_STD_I16BE')
            dtypeStr = 'H5T_STD_I16BE';
        elseif H5T.equal(dtype,'H5T_STD_I16LE')
            dtypeStr = 'H5T_STD_I16LE';
        elseif H5T.equal(dtype,'H5T_STD_U16BE')
            dtypeStr = 'H5T_STD_U16BE';
        elseif H5T.equal(dtype,'H5T_STD_U16LE')
            dtypeStr = 'H5T_STD_U16LE';
        elseif H5T.equal(dtype,'H5T_STD_I32BE')
            dtypeStr = 'H5T_STD_I32BE';
        elseif H5T.equal(dtype,'H5T_STD_I32LE')
            dtypeStr = 'H5T_STD_I32LE';
        elseif H5T.equal(dtype,'H5T_STD_U32BE')
            dtypeStr = 'H5T_STD_U32BE';
        elseif H5T.equal(dtype,'H5T_STD_U32LE')
            dtypeStr = 'H5T_STD_U32LE';
        elseif H5T.equal(dtype,'H5T_STD_I64BE')
            dtypeStr = 'H5T_STD_I64BE';
        elseif H5T.equal(dtype,'H5T_STD_I64LE')
            dtypeStr = 'H5T_STD_I64LE';
        elseif H5T.equal(dtype,'H5T_STD_U64BE')
            dtypeStr = 'H5T_STD_U64BE';
        elseif H5T.equal(dtype,'H5T_STD_U64LE')
            dtypeStr = 'H5T_STD_U64LE';
        else
            sgn = H5T.get_sign(dtype);
            if sgn == H5ML.get_constant_value('H5T_SGN_NONE')
                signed = 'unsigned';
            else
                signed = 'signed';
            end
            dtypeStr = sprintf('%d-bit %s integer', ...
                H5T.get_size(dtype)*8, signed );
        end
        info.Type = dtypeStr;


    case H5ML.get_constant_value('H5T_FLOAT')
        info.Class = 'H5T_FLOAT';
        if H5T.equal(dtype,'H5T_IEEE_F32BE')
            dtypeStr = 'H5T_IEEE_F32BE';
        elseif H5T.equal(dtype,'H5T_IEEE_F32LE')
            dtypeStr = 'H5T_IEEE_F32LE';
        elseif H5T.equal(dtype,'H5T_IEEE_F64BE')
            dtypeStr = 'H5T_IEEE_F64BE';
        elseif H5T.equal(dtype,'H5T_IEEE_F64LE')
            dtypeStr = 'H5T_IEEE_F64LE';
        else
            dtypeStr = sprintf('%d-bit floating point type', H5T.get_size(dtype)*8);
        end
        info.Type = dtypeStr;


    case H5ML.get_constant_value('H5T_OPAQUE')
        info.Class = 'H5T_OPAQUE';
        info.Type.Length = H5T.get_size(dtype);
        info.Type.Tag = H5T.get_tag(dtype);

    case H5ML.get_constant_value('H5T_REFERENCE')
        info.Class = 'H5T_REFERENCE';
        if H5T.equal(dtype,'H5T_STD_REF_OBJ')
            info.Type = 'H5R_OBJECT';
        else
            info.Type = 'H5R_DATASET_REGION';
        end


    case H5ML.get_constant_value('H5T_COMPOUND')
        info.Class = 'H5T_COMPOUND';
        info.Type = interrogate_compound_type(dtype);


    case H5ML.get_constant_value('H5T_ENUM')
        info = interrogate_enum_type(dtype);


    case H5ML.get_constant_value('H5T_ARRAY')
        info.Class = 'H5T_ARRAY';
        dims = H5T.get_array_dims(dtype);
        info.Dims = fliplr(dims);
        superType = H5T.get_super(dtype);
        info.Type = get_datatype_info(superType);


    case H5ML.get_constant_value('H5T_VLEN')
        info.Class = 'H5T_VLEN';
        superType = H5T.get_super(dtype);
        info.Type = get_datatype_info(superType);

    case H5ML.get_constant_value('H5T_STRING')
        info.Class = 'H5T_STRING';
        info.Type = interrogate_string_datatype(dtype);

    otherwise
        error(message('MATLAB:imagesci:h5info:unrecognizedClass', class_id));
end

info.Size = H5T.get_size(dtype);

info.Name = H5I.get_name(dtype);

return

%--------------------------------------------------------------------------
function enumInfo = interrogate_enum_type(dtype)
% These must all be integer types.

enumInfo = get_struct_template('datatype');

enumInfo.Class = 'H5T_ENUM';

superType = H5T.get_super(dtype);

if H5T.equal(superType,'H5T_STD_I8BE')
    dtypeStr = 'H5T_STD_I8BE';
elseif H5T.equal(superType,'H5T_STD_I8LE')
    dtypeStr = 'H5T_STD_I8LE';
elseif H5T.equal(superType,'H5T_STD_U8BE')
    dtypeStr = 'H5T_STD_U8BE';
elseif H5T.equal(superType,'H5T_STD_U8LE')
    dtypeStr = 'H5T_STD_U8LE';
elseif H5T.equal(superType,'H5T_STD_I16BE')
    dtypeStr = 'H5T_STD_I16BE';
elseif H5T.equal(superType,'H5T_STD_I16LE')
    dtypeStr = 'H5T_STD_I16LE';
elseif H5T.equal(superType,'H5T_STD_U16BE')
    dtypeStr = 'H5T_STD_U16BE';
elseif H5T.equal(superType,'H5T_STD_U16LE')
    dtypeStr = 'H5T_STD_U16LE';
elseif H5T.equal(superType,'H5T_STD_I32BE')
    dtypeStr = 'H5T_STD_I32BE';
elseif H5T.equal(superType,'H5T_STD_I32LE')
    dtypeStr = 'H5T_STD_I32LE';
elseif H5T.equal(superType,'H5T_STD_U32BE')
    dtypeStr = 'H5T_STD_U32BE';
elseif H5T.equal(superType,'H5T_STD_U32LE')
    dtypeStr = 'H5T_STD_U32LE';
elseif H5T.equal(superType,'H5T_STD_I64BE')
    dtypeStr = 'H5T_STD_I64BE';
elseif H5T.equal(superType,'H5T_STD_I64LE')
    dtypeStr = 'H5T_STD_I64LE';
elseif H5T.equal(superType,'H5T_STD_U64BE')
    dtypeStr = 'H5T_STD_U64BE';
elseif H5T.equal(superType,'H5T_STD_U64LE')
    dtypeStr = 'H5T_STD_U64LE';
else
    dtypeStr = sprintf('%d-bit integer', H5T.get_size(dtype)*8 );
end
enumInfo.Type.Type = dtypeStr;

nmemb = H5T.get_nmembers(dtype);
elements = struct('Name','','Value',[]);
elements = repmat(elements,nmemb,1);
for j = 1:nmemb
    elements(j).Name = H5T.get_member_name(dtype,j-1);
    elements(j).Value = H5T.get_member_value(dtype,j-1);
end

enumInfo.Type.Member = elements;

%--------------------------------------------------------------------------
function stringInfo = interrogate_string_datatype(dtype)
% Return a structure that describes the string datatype.  
%
%     Length:  either the string length or a designation of variable
%     Padding:  null terminated, null padded, or space padded
%     CharacterSet:  either ASCII or UTF-8
%     CharacterType:  either C or fortran
%

if H5T.is_variable_str(dtype)
    stringInfo.Length = 'H5T_VARIABLE';
else
    stringInfo.Length = H5T.get_size(dtype);
end

padding = H5T.get_strpad(dtype);
switch(padding)
    case H5ML.get_constant_value('H5T_STR_NULLTERM')
        stringInfo.Padding = 'H5T_STR_NULLTERM';
     case H5ML.get_constant_value('H5T_STR_NULLPAD')
        stringInfo.Padding = 'H5T_STR_NULLPAD';
     case H5ML.get_constant_value('H5T_STR_SPACEPAD')
        stringInfo.Padding = 'H5T_STR_SPACEPAD';
    otherwise
        error(message('MATLAB:imagesci:h5info:invalidStringPadding', padding));
end

cset = H5T.get_cset(dtype);
switch(cset)
    case H5ML.get_constant_value('H5T_CSET_ASCII')
        stringInfo.CharacterSet = 'H5T_CSET_ASCII';
     case H5ML.get_constant_value('H5T_CSET_UTF8')
        stringInfo.CharacterSet = 'H5T_CSET_UTF8';
    otherwise
        error(message('MATLAB:imagesci:h5info:invalidCharacterSet', padding));
end
     
stringInfo.CharacterType = determine_character_type(dtype,stringInfo);


%--------------------------------------------------------------------------
function chartype = determine_character_type(dtype,stringInfo)
% It's not straightforward to determine if it's a C or a FORTRAN string. 
% This is how h5dump does it.

% H5T_C_S1
% H5T_FORTRAN_S1

cset = H5T.get_cset(dtype);
padding = H5T.get_strpad(dtype);

% Create various candidates, see if there's a match.
strType = H5T.copy('H5T_C_S1');
if ischar(stringInfo.Length) && strcmp(stringInfo.Length,'H5T_VARIABLE')
    H5T.set_size(strType,'H5T_VARIABLE');
else
    H5T.set_size(strType,stringInfo.Length);
end

% Set the character set and padding
H5T.set_cset(strType,cset);
H5T.set_strpad(strType,padding);

% Is it a C variable length string?
if H5T.equal(dtype,strType)
    chartype = 'H5T_C_S1';
    return
end

% Change the endianness and see if they're equal.  
order = H5T.get_order(dtype);
if order == H5ML.get_constant_value('H5T_ORDER_LE')
    H5T.set_order(dtype,'H5T_ORDER_BE');
else
    H5T.set_order(dtype,'H5T_ORDER_LE');
end

if H5T.equal(dtype,strType)
    chartype = 'H5T_C_S1';
    return
end


% Ok, now check the fortran types
H5T.close(strType);
strType = H5T.copy('H5T_FORTRAN_S1');



% Set the character set and padding
H5T.set_cset(strType,cset);
H5T.set_strpad(strType,padding);    
H5T.set_size(strType,stringInfo.Length);

% Are they the same?
if H5T.equal(dtype,strType)
    chartype = 'H5T_FORTRAN_S1';
    return
end

% Change the endianness and see if they're equal.  
order = H5T.get_order(dtype);
if order == H5ML.get_constant_value('H5T_ORDER_LE')
    H5T.set_order(dtype,'H5T_ORDER_BE');
else
    H5T.set_order(dtype,'H5T_ORDER_LE');
end

% Are they the same?
if H5T.equal(dtype,strType)
    chartype = 'H5T_FORTRAN_S1';
else
    error(message('MATLAB:imagesci:h5info:unknownCharacterType'));
end

%--------------------------------------------------------------------------
function compoundInfo = interrogate_compound_type(dtype)
% Return a structure that describes the compound datatype.  There is just
% one top level field, 'Member', but each Member field as two fields 
% itself:
%
%     Name:  name of the compound field member
%     Datatype:  the datatype (possibly very complex) of the field member,
%         not that of the compound itself.

%%% check order of fields
%%% check Size name, possibly NumberOfBytes
n = H5T.get_nmembers(dtype);
template = struct('Name','','Datatype',[]);
memberInfo = repmat(template,n,1);
for j = 1:n
    memberInfo(j).Name = H5T.get_member_name(dtype,j-1);
    membType = H5T.get_member_type(dtype,j-1);
    memberInfo(j).Datatype = get_datatype_info(membType);
    H5T.close(membType);
end

compoundInfo.Member = memberInfo;

%--------------------------------------------------------------------------
function s = get_struct_template(type)
%%% May not be needed.
switch(type)  
    case 'group'
        s = struct('Name','','Groups',[],'Datasets',[],...
            'Datatypes',[],'Links',[],'Attributes',[]);
    case 'dataset'
        s = struct('Name','','Datatype',[],'Dataspace',[], ...
            'ChunkSize',[],'FillValue',[],'Filters',[],'Attributes',[]);
    case 'attribute'
        s = struct('Name','','Datatype',[],'Dataspace',[],'Value',[]);
    case 'datatype'
        s = struct('Name','','Class','','Type','','Size',[]);
    case 'link'
        s = struct('Name','','Type','','Value','');
    otherwise
        error(message('MATLAB:imagesci:h5info:unhandledTemplateType', type));
end