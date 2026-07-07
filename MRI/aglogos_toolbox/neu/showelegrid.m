function showelegrid(SESSION,GrpName)
%SHOWELEGRID - shows the grid of electrodes or voxels
% SHOWELEGRID shows the grid and the distance we used to compute
% coherence and vector-independence

if ~nargin,
  SESSION ='c98nm1';
  GrpName = 'movie1';
end;

getelepos(SESSION,GrpName);
