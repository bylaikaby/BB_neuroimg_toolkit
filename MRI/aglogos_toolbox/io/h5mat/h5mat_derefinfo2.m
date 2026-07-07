function dinfo = h5mat_derefinfo2(HINFO,Dataset,varargin)
%H5MAT_DEREFINFO2 - Return de-referenced information about HDF5 file.
%  INFO = h5info(FILENAME,LOCATION) returns de-referenced information about the group,
%  dataset, or named datatype specified by location in the HDF5 file 
%  FILENAME.
%
%  See H5INFO for detail.
%
%  EXAMPLE :
%    hinfo = h5info(Filename)
%    dinfo = h5mat_derefinfo(hinfo,'/Cln')
%
%  VERSION :
%    0.90 06.07.19 YM  uses HINFO without reading the file.
%
%  See also h5info h5read h5mat_varinfo h5mat_sig1info is_hdf5file

if nargin < 2
  Dataset = '/';
end


p = inputParser;
p.addRequired('HINFO',@(x) isfield(x,'Name') && isfield(x,'Groups'));
p.addRequired('Dataset',@ischar);
p.addOptional('start',[], @(x) isa(x,'double') && isrow(x) && ~any(x<=0));
p.addOptional('count',[], @(x) isa(x,'double') && isrow(x) && ~any(x<=0));
p.addOptional('stride',[],@(x) isa(x,'double') && isrow(x) && ~any(x<=0));
p.parse(Filename,Dataset,varargin{:});
