function IS_HDF5 = is_hdf5file(Filename)
%IS_HDF5File - Determine if file is HDF5.
%  value = IS_HDF5FILE(name) returns a positive number if the file
%  specified by name is in the HDF5 format, and zero if it is not. A
%  negative return value indicates failure.
%
%  EXAMPLE :
%    is_hdf5 = is_hdf5file(Filename)
%
%  VERSION :
%    0.90 05.06.13 YM  pre-release
%
%  See also H5F.is_hdf5 H5F h5info h5read mat2h5mat

if nargin < 1,  eval(['help ' mfilename]); return;  end

if ~exist(Filename,'file')
  error('\n ERROR %s: ''%s'' not found.\n',mfilename,Filename);
end


fid = fopen(Filename,'r');
fullfilename = fopen(fid);
fclose(fid);

IS_HDF5 = H5F.is_hdf5(fullfilename);


return
