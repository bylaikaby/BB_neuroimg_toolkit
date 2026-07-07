function atshowcf(SESSION, GrpName)
%ATSHOWCF - Group all contrast of a group by calling catconfunc
% ATSHOWCF invokes catconfunc(SESSION, GrpName, SigName) and
% concatanates all computed contrast functions.
%
% CF-Related variables
% ses.confunc.sigs		= {'LfpL', 'LfpM', 'LfpH', 'Mua', 'Sdf'};
% ses.confunc.algs		= {'kc'};
% ses.confunc.maxchan	= 16;
% ses.confunc.idist		= 1;	% 1mm
% ses.confunc.eleconfig	= [ 01 02 03 04; ...
% 							05 06 07 08; ...
% 						    09 10 11 12; ...
% 							13 14 15 16];
%
if ~nargin,
  SESSION='d98at2';
end;

NORMALIZE=1;
ANATYPE = 1;

Ses = goto(SESSION);

if nargin < 2,
  GrpName = strcat('sg',Ses.name,'.mat');
else
  GrpName = strcat(GrpName,'.mat');
end;
  
load(GrpName);


return;




