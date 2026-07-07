function hinfo = h5mat_varinfo(filename,VarName)
%H5MAT_VARINFO - Get information about the given MATLAB var. in the hdf5file.
%  INFO = H5MAT_VARINFO(FILENAME,VarName) gets information about the given MATLAB var. in 
%  the hdf5file.
%
%  EXAMPLE :
%    info = h5mat_varinfo(hdf5file,'myvar');
%
%  VERSION :
%    0.90 04.06.13 YM   modified from MATLAB's h5info().
%    0.91 04.07.19 YM   no code from h5info(), just use it.
%
%  See also h5mat_derefinfo h5mat_sig1info is_hdf5file h5info h5read


hinfo = [];


location = VarName;
if location(1) ~= '/',  location = ['/' location];  end

hinfo = h5info(filename,location);

% MATLAB bug???
if hinfo.Name(1) ~= '/',  hinfo.Name = ['/' hinfo.Name];  end



% additional info for me ----------------------------

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
