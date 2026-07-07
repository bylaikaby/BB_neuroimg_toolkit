function varargout = mn_roits_ttest(roiTs,TBASE,TWIN,TAIL)
%MN_ROITS_TTEST - applys 1sample T-test to given roiTs
%  ROITS = MN_ROITS_TTEST(ROITS,TBASE,TWIN) applys 1 sample T-test,
%  sbtracting mean of TBASE from TWIN, and adds field ".ttest".
%
%  VERSION :
%    0.90 09.06.05 YM  pre-release
%    0.91 13.07.05 YM  supports o02wu1/wx1
%
%  See also MN_ROITS_GET, MN_ROITS_CAT, MNTTEST


if nargin == 0,  help mn_roits_ttest; return;  end

if nargin < 2,  TBASE = [];  end
if nargin < 3,  TWIN  = [];  end
if nargin < 4,  TAIL = 'right';  end

if iscell(roiTs),
  sesname = roiTs{1}.session;
  grpname = roiTs{1}.grpname;
else
  sesname = roiTs.session;
  grpname = roiTs.grpname;
end
Ses = goto(sesname);
grp = getgrp(Ses,grpname);


switch lower(Ses.name),
 otherwise
  if isfield(Ses.anap,'mnttest') & isfield(Ses.anap.mnttest,'tbase'),
    TBASE = Ses.anap.mnttest.tbase;
    TWIN  = Ses.anap.mnttest.twin;
  else
    fprintf('%s ERROR: unknown session, please add ANAP.mnttest.tbase/twin in %s.m\n',...
            mfilename,Ses.name);
    return;
  end
end


if iscell(roiTs),
  for N = 1:length(roiTs),
    roiTs{N}.ttest = subDoTTest(roiTs{N},TBASE,TWIN,TAIL);
  end
else
  roiTs.ttest = subDoTTest(roiTs,TBASE,TWIN,TAIL);
end

if nargout,
  varargout{1} = roiTs;
end


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to apply T-test for roiTs
function TTEST = subDoTTest(roiTs,TBASE,TWIN,TAIL)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%tbase = [TBASE(1):TBASE(2)];
%tsel  = [TWIN(1):TWIN(2)];
tbase = TBASE;
tsel  = TWIN;
  
m = mean(double(roiTs.dat(tbase,:)),1);
x = double(roiTs.dat(tsel,:));

for N=1:size(x,2),
  x(:,N) = x(:,N) - m(N);
end


% to avoid error of zero division
idx = find(var(x) ~= 0);
nvoxels = size(roiTs.dat,2);
P = ones(1,nvoxels);
T = zeros(1,nvoxels);
if ~isempty(idx),
  [h, signif, ci, stat] = ttest(x(:,idx), 0, 0.01, TAIL);
  P(idx) = signif(:);
  T(idx) = stat.tstat(:);
end


%TTEST.dat   = datname;
TTEST.tbase = int16(tbase);
TTEST.tsel  = int16(tsel);
TTEST.tail  = TAIL;
TTEST.df    = stat.df(1);
TTEST.p     = P;
TTEST.tstat = T;



return;

