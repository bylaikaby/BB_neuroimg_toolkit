function SIG = mvoxlogical(SIG_A,LOGOP,SIG_B,varargin)
%MVOXLOGICAL - does logical operation of SIG_A and SIG_B.
%  SIG = MVOXLOGICAL(SIG_A,LOGOP,SIG_B) does logical operation (LOGOP) of 
%  SIG_A and SIG_B.  .dat/.coords/.stat/.resp will be updated, other data
%  structure will remain the same as in SIG_A.
%
%  Supported logical operations are :
%    'and'  : SIG_A and SIG_B
%    'or'   : SIG_A or  SIG_B
%    'xor'  : SIG_A xor SIG_B
%    'diff' : SIG_A and ~SIG_B,  or SIG_A - SIG_B
%
%  EXAMPLE :
%    >> sig1 = mvoxselect('e04ds1','visesmix','all','glm[2]',[],0.01);
%    >> sig2 = mvoxselect('e04ds1','visescomb','all','glm[1]',[],0.01);
%    >> sig12 = mvoxlogical(sig1,'and',sig2)
%    >> figure;  plot([mean(sig1.dat,2), mean(sig12.dat,2)]);
%
%  NOTE :
%    Time length size(SIG_A.dat,1) and size(SIG_B.dat,1) should be the same,
%    otherwise, set the property, 'coords_only' as 1 to get coordinates only.
%    .stat and .resp also selected but .stat may not be useful if two source 
%    signals are selected by different way.
%
%  VERSION :
%    0.90 23.08.07 YM  pre-release
%    0.91 13.11.07 YM  supports SIG_B as ROI names.
%    0.92 17.06.09 YM  bug fix when SIG.resp/stat is empty.
%    0.92 01.02.12 YM  take care of .stat.beta.
%
%  See also MVOXSELECT INTERSECT SETDIFF SETXOR

if nargin < 3,  eval(sprintf('help %s;',mfilename)); return;  end


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


if sub_is_roiname(SIG_B),
  % just select by ROI name(s),
  SIG_B = subDoROI(SIG_A,SIG_B);
end



if ~all(size(SIG_A.ana) == size(SIG_A.ana)),
  SIG = SIG_A;
  fprintf('\n WARNING %s: differnt imaging size, no logical operation has made...',mfilename);
  return
end

COORDS_ONLY = 0;
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case { 'coords_only','coordsonly' }
    COORDS_ONLY = varargin{N+1};
  end
end


switch lower(LOGOP)
 case { 'and', 'intersect', '&', '&&' ,'*'}
  SIG = subDoAND(SIG_A,SIG_B);
 case { 'or', '|', '||','+' ,'cat'}
  SIG = subDoOR(SIG_A,SIG_B, COORDS_ONLY);
 case { 'xor' }
  SIG = subDoXOR(SIG_A,SIG_B, COORDS_ONLY);
 case { 'dif', 'diff', 'subtract', 'minus', '-', '!', '~'}
  SIG = subDoDiff(SIG_A,SIG_B);
 otherwise
  error('\n ERROR %s: logic ''%s'' not supported yet.\n',mfilename,LOGOP);
  SIG = [];
end


return


function isroi = sub_is_roiname(A)

isroi = 0;
if ischar(A),
  isroi = 1;
elseif iscell(A),
  if ischar(A{1}),  isroi = 1;  end
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to select by ROI names
%   later process needs only SIG.ana/coords.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG2 = subDoROI(SIG1,RoiName)

if any(strcmpi(RoiName,'all')),
  SIG2.ana    = SIG1.ana;
  SIG2.coords = SIG1.coords;
  return
end

ROI = roiload(SIG1.session,SIG1.grpname,'',[],RoiName);
coords = [];
for N = 1:length(ROI.roi),
  [x y] = find(ROI.roi{N}.mask);
  z = zeros(size(x));  z(:) = ROI.roi{N}.slice;
  coords = cat(1,coords,[x(:),y(:),z(:)]);
end

SIG2.ana = SIG1.ana;
SIG2.coords = coords;

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to do logical AND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG = subDoAND(SIG1,SIG2)

% select by logical AND
A = [];  B = [];
if ~isempty(SIG1.coords),
  A = sub2ind(size(SIG1.ana),SIG1.coords(:,1),SIG1.coords(:,2),SIG1.coords(:,3));
end
if ~isempty(SIG2.coords),
  B = sub2ind(size(SIG1.ana),SIG2.coords(:,1),SIG2.coords(:,2),SIG2.coords(:,3));
end
[C sel] = intersect(A,B);

% now select voxels
SIG        = SIG1;
SIG.dat    = SIG.dat(:,sel);
SIG.coords = SIG.coords(sel,:);
if isfield(SIG,'stat') && ~isempty(SIG.stat),
  SIG.stat.p   = SIG.stat.p(sel);
  SIG.stat.dat = SIG.stat.dat(sel);
  if isfield(SIG.stat,'beta') && ~isempty(SIG.stat.beta),
    SIG.stat.beta = SIG.stat.beta(sel);
  end
end
if isfield(SIG,'resp') && ~isempty(SIG.resp),
  SIG.resp.base = SIG.resp.base(sel);
  SIG.resp.mean = SIG.resp.mean(sel);
  SIG.resp.max  = SIG.resp.max(sel);
  SIG.resp.min  = SIG.resp.min(sel);
end


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to do logical OR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG = subDoOR(SIG1,SIG2,COORDS_ONLY)

% select by logical OR
A = [];  B = [];
if ~isempty(SIG1.coords),
  B = sub2ind(size(SIG1.ana),SIG1.coords(:,1),SIG1.coords(:,2),SIG1.coords(:,3));
end
if ~isempty(SIG2.coords),
  A = sub2ind(size(SIG1.ana),SIG2.coords(:,1),SIG2.coords(:,2),SIG2.coords(:,3));
end
[C sel] = setdiff(A,B);   % returns the values in A that are not in B

% now select voxels
SIG        = SIG1;
if COORDS_ONLY && size(SIG1.dat,1) ~= size(SIG2.dat,2)
SIG.dat    = [];
else
SIG.dat    = cat(2,SIG.dat,    SIG2.dat(:,sel));
end
SIG.coords = cat(1,SIG.coords, SIG2.coords(sel,:));
if isfield(SIG,'stat') && ~isempty(SIG.stat),
  SIG.stat.p   = cat(1,SIG.stat.p,   SIG2.stat.p(sel));
  SIG.stat.dat = cat(1,SIG.stat.dat, SIG2.stat.dat(sel));
  if isfield(SIG.stat,'beta') && ~isempty(SIG.stat.beta),
    SIG.stat.beta = cat(1,SIG.stat.beta,   SIG2.stat.beta(sel));
  end
end
if isfield(SIG,'resp') && ~isempty(SIG.resp),
  SIG.resp.base = cat(2,SIG.resp.base, SIG2.resp.base(sel));
  SIG.resp.mean = cat(2,SIG.resp.mean, SIG2.resp.mean(sel));
  SIG.resp.max  = cat(2,SIG.resp.max,  SIG2.resp.max(sel));
  SIG.resp.min  = cat(2,SIG.resp.min,  SIG2.resp.min(sel));
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to do logical XOR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG = subDoXOR(SIG1,SIG2,COORDS_ONLY)

% select by logical XOR
A = [];  B = [];
if ~isempty(SIG1.coords),
  A = sub2ind(size(SIG1.ana),SIG1.coords(:,1),SIG1.coords(:,2),SIG1.coords(:,3));
end
if ~isempty(SIG2.coords),
  B = sub2ind(size(SIG1.ana),SIG2.coords(:,1),SIG2.coords(:,2),SIG2.coords(:,3));
end
[C ia ib] = setxor(A,B);

% now select voxels
SIG        = SIG1;
if COORDS_ONLY && size(SIG1.dat,1) ~= size(SIG2.dat,2)
SIG.dat    = [];
else
SIG.dat    = cat(2,SIG.dat(:,ia),    SIG2.dat(:,ib));
end
SIG.coords = cat(1,SIG.coords(ia,:), SIG2.coords(ib,:));
if isfield(SIG,'stat') && ~isempty(SIG.stat),
  SIG.stat.p   = cat(1,SIG.stat.p(ia),   SIG2.stat.p(ib));
  SIG.stat.dat = cat(1,SIG.stat.dat(ia), SIG2.stat.dat(ib));
  if isfield(SIG.stat,'beta') && ~isempty(SIG.stat.beta),
    SIG.stat.beta = cat(1,SIG.stat.beta(ia), SIG2.stat.beta(ib));
  end
end
if isfield(SIG,'resp') && ~isempty(SIG.resp),
  SIG.resp.base = cat(2,SIG.resp.base(ia), SIG2.resp.base(ib));
  SIG.resp.mean = cat(2,SIG.resp.mean(ia), SIG2.resp.mean(ib));
  SIG.resp.max  = cat(2,SIG.resp.max(ia),  SIG2.resp.max(ib));
  SIG.resp.min  = cat(2,SIG.resp.min(ia),  SIG2.resp.min(ib));
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to do logical subtraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SIG = subDoDiff(SIG1,SIG2)

% select by logical subtraction
A = [];  B = [];
if ~isempty(SIG1.coords),
  A = sub2ind(size(SIG1.ana),SIG1.coords(:,1),SIG1.coords(:,2),SIG1.coords(:,3));
end
if ~isempty(SIG2.coords),
  B = sub2ind(size(SIG1.ana),SIG2.coords(:,1),SIG2.coords(:,2),SIG2.coords(:,3));
end
[C sel] = setdiff(A,B);   % returns the values in A that are not in B

% now select voxels
SIG        = SIG1;
SIG.dat    = SIG.dat(:,sel);
SIG.coords = SIG.coords(sel,:);
if isfield(SIG,'stat') && ~isempty(SIG.stat),
  SIG.stat.p   = SIG.stat.p(sel);
  SIG.stat.dat = SIG.stat.dat(sel);
  if isfield(SIG.stat,'beta') && ~isempty(SIG.stat.beta),
    SIG.stat.beta = SIG.stat.beta(sel);
  end
end
if isfield(SIG,'resp') && ~isempty(SIG.resp),
  SIG.resp.base = SIG.resp.base(sel);
  SIG.resp.mean = SIG.resp.mean(sel);
  SIG.resp.max  = SIG.resp.max(sel);
  SIG.resp.min  = SIG.resp.min(sel);
end

return
