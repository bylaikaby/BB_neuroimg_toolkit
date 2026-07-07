function mroireset(SesName)
%MROIRESET - Delete all activation-related ROIs in Roi.mat
% MROIRESET (SesName, xcor) reads the Roi.mat file and delete any
% of the entries created by the MROIUPDATE function.
%
% The Roi.roi structure
%      name: 'brain'
%      slice: 1
%       mask: [52x40 logical]
%         px: [54x1 double]
%         py: [54x1 double]
%    anamask: [208x160 logical]	%%% OBSOLETE
%     coords: [1033x3 double]	%%% OBSOLETE
%
% NKL 19.04.04
  
Ses = goto(SesName);
grproinames = getgrproi(Ses);
load('roi.mat',grproinames{:});
save('roi.mat',grproinames{:});
