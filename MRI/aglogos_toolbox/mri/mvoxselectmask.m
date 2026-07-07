function SIG = mvoxselectmask(SIG1,SIG2)
%MVOXSELECTMASK - masks (logical AND) SIG1 with SIG2.
%  SIG = MVOXSELECTMASK(SIG1,SIG2) masks (logical AND) SIG1 with SIG2.
%    Time courses of returned SIG is compatible with SIG1, NOT with SIG2.
%
%  EXAMPLE :
%    >> sig1 = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> sig2 = mvoxselect('e04ds1','visescomb','all','glm[1]',[],0.01);
%    >> sig12 = mvoxselectmask(sig1,sig2)
%    >> figure;  plot([mean(sig1.dat,2), mean(sig12.dat,2)]);
%
%  VERSION :
%    0.90 22.02.07 YM  pre-release
%    0.91 14.03.07 YM  use intersect() for AND, a bit faster.
%
%  See also MVOXSELECT MVOXLOGICAL INTERSECT

if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end


SIG = mvoxlogical(SIG1,'and',SIG2);


return



% SIG1 = 
%     session: 'e04ds1'
%     grpname: 'visesmix'
%       ExpNo: [1 2 3 4 5 11 12 13 14 15 21 22 23]
%         ana: [44x90x12 double]
%          ds: [0.7500 0.7500 2]
%          dx: 2
%         dat: [30x2052 double]
%        name: 'all'
%      coords: [2052x3 double]
%         stm: [1x1 struct]
%        stat: [1x1 struct]
%        resp: [1x1 struct]
% SIG1.stat = 
%       model: 'glm[2]'
%       trial: 1
%       alpha: 0.0100
%     cluster: 1
%     datname: 'statv'
%           p: [2052x1 double]
%         dat: [2052x1 double]
% SIG1.resp = 
%     iresp: [7 23]
%     ibase: [1 5]
%      base: [1x2052 double]
%      mean: [1x2052 double]
%       max: [1x2052 double]
%       min: [1x2052 double]


SIG = SIG1;

if ~all(size(SIG1.ana) == size(SIG2.ana)),
  fprintf('\n WARNING %s: differnt imaging size, no masking made...',mfilename);
  return
end


% select by logical AND
idx1 = sub2ind(size(SIG1.ana),SIG1.coords(:,1),SIG1.coords(:,2),SIG1.coords(:,3));
idx2 = sub2ind(size(SIG1.ana),SIG2.coords(:,1),SIG2.coords(:,2),SIG2.coords(:,3));

%tmpflag = zeros(size(idx1));
%for N = 1:length(idx1),
%  if any(idx2 == idx1(N)),
%    tmpflag(N) = 1;
%  end
%end
%sel = find(tmpflag);
[idx1 sel] = intersect(idx1,idx2);

% now select voxels
SIG.dat    = SIG.dat(:,sel);
SIG.coords = SIG.coords(sel,:);
if isfield(SIG,'stat'),
  SIG.stat.p   = SIG.stat.p(sel);
  SIG.stat.dat = SIG.stat.dat(sel);
end
if isfield(SIG,'resp'),
  SIG.resp.base = SIG.resp.base(sel);
  SIG.resp.mean = SIG.resp.mean(sel);
  SIG.resp.max  = SIG.resp.max(sel);
  SIG.resp.min  = SIG.resp.min(sel);
end


return
