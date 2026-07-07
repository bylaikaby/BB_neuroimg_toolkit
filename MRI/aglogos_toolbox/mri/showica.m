function showica(SesName, GrpName, IComp, CompType, Norm)
%SHOWICA - Shows the IC clusters, and their IC or RAW signals of each cluster
% SHOWICA(SesName, GrpName, IComp, CompType, Norm) plots the results of IC Analysis usually run with
% GETICA.M. The following steps are performed by the GETICA and the SHOWICA:
%
% 0. Check the anap.ica in ESGETPARS or in your description file
% 1. Run GETICA for groups or SESICA for the entire sessions (all groups)
% 2. This will dump the results in a file of the type: ICA_visesmix_troiTs_spatial.mat or
%    ICA_visesmix_troiTs_temporal.mat.
% 3. Run SHOWICA(), which will
%       a. Load the data from the above file (ICALOAD) and normalize them (weights/TCs)
%       b. Plot the clusters of the selected ICs (ICAPLOTCLUSTERS)
%       c. Plot a 2D image with the time course of either all the RAW or all IC time series
%       d. Plot the time course of the selected IC
%
% EXAMPLE :
%   showica('h03fi1','visesmix')
%   showica('h05tm1','visesmix')    - Excellent example of IC  !!
%
% ICA structure:
%         ana: [72x72x12 double]
%          ds: [0.7500 0.7500 2]
%      slices: [4 5 6 7 8 9]
%         map: [20x2575 double]
%      colors: {1x34 cell}
%     anapica: [1x1 struct]
%       mview: [1x1 struct]
%         raw: [1x1 struct]
%          ic: [1x1 struct]
% ICA.raw
%     session: 'h05tm1'  grpname: 'visesmix'   ExpNo: [1x40 double]
%      coords: [2575x3 double]
%         dat: [120x20 double]
%         err: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
% ICA.ic
%     session: 'h05tm1'  grpname: 'visesmix'   ExpNo: [1x40 double]
%         dat: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
%  
% NKL 11.06.09
%
% See also ICALOAD ICAPLOTCLUSTERS ICAPLOTIC GETICA SHOWICARES SHOWICA

IMG_PLOT = 0;

if nargin < 5,  Norm = 'tosdu'; end;
if nargin < 4,  CompType = 'raw'; end;
if nargin < 2,  help showica;  return; end;

Ses     = goto(SesName);
grp     = getgrp(Ses,GrpName);
anap    = getanap(Ses,GrpName);

if nargin < 3 | isempty(IComp),
  IComp = anap.ica.icomp;
end;
if isempty(IComp),
  IComp = [1:10];       % Default shows the first 10 components
end;

tcICA =  icaload(SesName, GrpName);

mfigure([1 500 900 600]);
POS1 = [0.0500    0.1100    0.40    0.8150];
POS2 = [0.5303    0.1100    0.43    0.8150];

set(gcf,'color','w');

%tcICA.raw = xform(tcICA.raw,Norm,'prestim');
%tcICA.ic  = xform(tcICA.ic,Norm,'prestim');

subplot('position',POS1);
icaplotclusters(tcICA,IComp);

if IMG_PLOT,
  subplot('position',POS2);
  icaplotic2d(tcICA, [], CompType);
else
  for N=1:length(IComp)
    msubplot(length(IComp),2,2*N);
    icaplotts(tcICA, IComp(N), CompType, IMG_PLOT, IComp(N));
  end;
end;

if ~isempty(anap.ica.ic2mdl),
  icamkmodel(tcICA);
end;

