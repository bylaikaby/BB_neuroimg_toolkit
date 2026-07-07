function [pxout,pyout] = mcluster(px,py,B,cutoff)
%MCLUSTER - Cluster analysis on "px,py" to discard single voxels of activation 
%
% [occords, idx] = MCLUSTER(coord,B,cutoff)
%
% px, py are indices of correlated voxels, i.e. [px,py] = find(corrmap>threshold) pxnewm pynew
% are indices of correlated voxels with at least "cutoff" voxels within +/i border size B.
% Old Defaults (cutoff =  8, B = 5);
% New Defaults (cutoff = 10, B = 5);
%
% NKL, 10.11.01

if nargin < 4,	cutoff = 10; end;
if nargin < 3,	B = 5;		end;

for i=1:length(px),
    t1=((px>(px(i)-B))&(px<(px(i)+B)));
    t2=((py>(py(i)-B))&(py<(py(i)+B)));
    N(i) = sum(t1&t2)-1;
end

pxout = px(find(N>cutoff));
pyout = py(find(N>cutoff));
