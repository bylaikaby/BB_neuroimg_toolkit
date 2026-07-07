function Sig = xform(Sig,Method,Epoch,HemoDelay,HemoTail)
%XFORM - converts Sig's unit accoring to 'Method' and 'Epoch'
%   SIG = XFORM(SIG,METHOD,EPOCH) converts the signal's unit to
%   METHOD.  As METHOD, 'tosdu', 'percent', 'frac', 'detrend',
%   'collage' and 'zerobase' is supported.
%   XFORM use EPOCH variable as baseline period(s).
%   As EPOCH, '-1', 'blank', 'prestim', 'anystim' and stimulus type
%   in stm.stmtypes are available.  See GETSTIMINDICES for detail.
%   If EPOCH is 'prestim', of course, the experiment should start
%   with a 'blank' period.
%
%   To take in account of hemodynamic delay and tail for EPOCH, use
%   SIG = XFORM(SIG,METHOD,EPOCH,HEMODELAY,HEMOTAIL).
%   As default, HEMODELAY=2sec, HEMOTAIL=5sec if SIG.dir.dname is 
%   roiTs/troiTs/tcImg, otherwise HEMODELAY=0, HEMOTAIL=0.
%
%  SIG = XFORM(SIG,METHOD) converts the signal's units, setting
%  EPOCH as 'prestim'.
%
%
%
% EXAMPLE : tcImg = xform(tcImg,'percent','blank');
%         : tcImg = xform(tcImg,'tosdu','prestim');
%           tcImg = xform(tcImg,'collage');
% NOTES   :
% VERSION :
%   0.90 13.04.04 YM  first release
%   0.91 11.05.04 YM  supports 'collage'
%   0.92 21.07.04 YM  supports 'zerobase'
%   0.93 27.07.04 YM  supports HEMODELAY and HEMOTAIL
%   0.94 24.03.06 YM  supports a cell array, "allprestim".
%   0.95 26.03.07 YM  make sure 'prestim' compted by each vox/trial
%   0.96 28.03.07 YM  avoid zero division
%   0.97 27.11.13 YM  use bsxfun() for better performance.
%   0.98 09.07.19 YM  use renamed siggetbaseline(), not getbaseline().
%
% See also SIGGETBASELINE, GETSTIMINDICES, TOSDU, MTCIMG2COLLAGE

if nargin < 2,  eval(sprintf('help %s',mfilename));  return;  end

if any(strcmpi(Method,'collage'))
  % if 'collage' then use mtcimg2collage function
  if iscell(Sig)
    for N = 1:length(Sig),  Sig{N} = xform(Sig{N},'collage');  end
    return
  end
  Sig = mtcimg2collage(Sig);
  return;
end



if nargin < 3,  Epoch     = '';  end
if nargin < 4,  HemoDelay = [];  end
if nargin < 5,  HemoTail  = [];  end


[tmpv, infosig] = issig(Sig);

if isempty(Epoch),  Epoch = 'prestim';  end

if isempty(HemoDelay)
  % set default HemoDelay
  switch infosig.signame
   case { 'tcImg','Pts','xcor','xcortc','roiTs','troiTs','hroiTs','froiTs','mroiTs' }
    HemoDelay = 2;
   otherwise
    HemoDelay = 0;
  end
end
if isempty(HemoTail)
  % set default HemoTail
  switch infosig.signame
   case { 'tcImg','Pts','xcor','xcortc','roiTs','troiTs','hroiTs','froiTs','mroiTs' }
    HemoTail = 5;
   otherwise
    HemoTail = 0;
  end
end




if iscell(Sig) && iscell(Sig{1})
  % if its troiTs like structure, then process by ROI basis.
  for N = 1:length(Sig)
    Sig{N} = xform(Sig{N},Method,Epoch,HemoDelay,HemoTail);
  end
  return;
end

% compute mean/std.
stat = siggetbaseline(Sig,'dat',Epoch,[],HemoDelay,HemoTail);
% do conversion
Sig = sub_xform(Sig,stat,infosig,Method,Epoch,HemoDelay,HemoTail);


return;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to perform normalization/transformation of the signal
function Sig = sub_xform(Sig,stat,infosig,Method,Epoch,HemoDelay,HemoTail)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(Sig)
  % if a cell array then call this function recursively.
  for N = 1:length(Sig)
    Sig{N} = sub_xform(Sig{N},stat{N},infosig,Method,Epoch,HemoDelay,HemoTail);
  end
  return;
end


% reshape data not to use repmat(), avoiding memory problem.
datdim = size(Sig.dat);
if strcmp(infosig.signame,'tcImg') && length(datdim) == 4
  % Sig.dat(X,Y,SLICE,T)  --> Sig.dat(N,T) --> Sig.dat(T,N)
  DIM_T = 2;
  Sig.dat = reshape(Sig.dat,[prod(datdim(1:3)) datdim(4)]);
  Sig.dat = permute(Sig.dat, [2 1]);
else
  % Sig.dat(T,CHAN,...) --> Sig.dat(T,N)
  DIM_T = 1;
  Sig.dat = reshape(Sig.dat,[datdim(1) prod(datdim(2:end))]);
end
statdim = size(stat.m);

stat.m = stat.m(:)';
stat.s = stat.s(:)';


% convert data units.
switch lower(Method)
 case { 'tosdu', 'sdu' }
  % COLUMN-BY-COLUMN
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = (Sig.dat(:,N) - stat.m(N)) / stat.s(N);
  % end

  % MATRIX CALC
  % tmpm = repmat(stat.m(:)',[size(Sig.dat,1) 1]);
  % tmps = repmat(stat.s(:)',[size(Sig.dat,1) 1]);
  % tmpi = (tmps < eps);  % prevent zero-div.
  % tmps(tmpi) = 1;
  % Sig.dat = (Sig.dat - tmpm) ./ tmps;
  % Sig.dat(:,tmpi) = 0;

  % BSXFUN
  tmpm = stat.m;
  tmps = stat.s;
  tmpi = (tmps <= eps);
  tmps(tmpi) = 1;  % prevent zero-div
  Sig.dat = bsxfun(@minus,   Sig.dat, tmpm);
  Sig.dat = bsxfun(@rdivide, Sig.dat, tmps);
  Sig.dat(:,tmpi) = 0;

 case { 'percent' 'percentage' }
  % avoid 'divide by zero'
  tmpm = stat.m;
  idx = find(tmpm == 0);
  if ~isempty(idx)
    tmpm(idx) = 1;
    Sig.dat(:,idx) = 1;  % should become zero by 1/1*100 -100
  end
  clear idx;
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = Sig.dat(:,N) / tmpm(N) * 100.0;
  % end
  % Sig.dat = Sig.dat - 100.0;

  % BSXFUN
  Sig.dat = bsxfun(@rdivide, Sig.dat, tmpm);
  Sig.dat = Sig.dat*100 - 100.0;
  
 case { 'frac' }
  % avoid 'divide by zero'
  tmpm = stat.m;
  idx = find(tmpm == 0);
  if ~isempty(idx)
    tmpm(idx) = 1;
    Sig.dat(:,idx) = 0;  % should become zero by 0/1
  end
  clear idx;
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = Sig.dat(:,N) / tmpm(N);
  % end
  % BSXFUN
  Sig.dat = bsxfun(@rdivide, Sig.dat, tmpm);
 
 case { 'detrend' }
  Sig.dat = detrend(Sig.dat);
  
 case { 'zerobase' }
  % for N = 1:size(Sig.dat,2),
  %   Sig.dat(:,N) = Sig.dat(:,N) - stat.m(N);
  % end
  % BSXFUN
  Sig.dat = bsxfun(@minus, Sig.dat, stat.m);

 otherwise
  fprintf(' %s ERROR:  ''%s'' not supported yet.\n',mfilename,Method);
  keyboard
end


% recover the original data dimension.
if DIM_T == 2
  Sig.dat = permute(Sig.dat,[2 1]);
end
Sig.dat = reshape(Sig.dat,datdim);

stat.m = reshape(stat.m,statdim);
stat.s = reshape(stat.s,statdim);

clear xinfo;
xinfo.method    = Method;
xinfo.epoch     = Epoch;
xinfo.HemoDelay = HemoDelay;
xinfo.HemoTail  = HemoTail;
xinfo.mean      = stat.m;
xinfo.std       = stat.s;

if isfield(Sig,mfilename)
  fnames = fieldnames(xinfo);
  for X = 1:length(fnames)
    if isfield(Sig.(mfilename),fnames{X}),  continue;  end
    Sig.(mfilename)(end).(fnames{X}) = [];
  end
  Sig.(mfilename)(end+1) = xinfo;
else
  Sig.(mfilename) = xinfo;
end



return;
