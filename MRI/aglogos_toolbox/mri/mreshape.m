function odata = mreshape(idata,dims,mode)
%MRESHAPE - convert a volume to a MxN matrix, with M time points, and
%	mreshape(idata,mode) - convert a volume to a MxN matrix, with M time points, and
%	N voxels
%	NKL, 24.02.01

if nargin < 1,
	error('usage: mreshape(idata,dims,mode);');
end;

if nargin < 2 | isempty(dims),
	dims = [size(idata,1) size(idata,2) size(idata,3)];
end;

if nargin < 3,
	mode = 'i2m';
	dims = [size(idata,1) size(idata,2) size(idata,3)];
end;

if strcmp(mode,'i2m'),	% Image to Matrix
	odata = reshape(idata, [dims(1)*dims(2) 1 dims(3)]);
	odata = squeeze(odata)';
else					% Matrix to Image
	odata = reshape(idata', dims);
end;



