function csize = h5mat_info_size(info)
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

