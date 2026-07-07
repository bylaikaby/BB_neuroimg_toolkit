function ts = sigspatfilt(roiTs,sfilter)
%SIGSPATFILT - Convert roiTs to tcImg, filter and then back to roiTs
% NKL 15.08.09
  
if nargin < 2,
  fprintf('This function must be called with all arguments: sigspatfilt(roiTs, sfilter)\n');
  keyboard;
end;
  
ARGS.ISUBSTITUDE             = 0;           % Get rid of magnetization-transients
ARGS.IFILTER                 = 1;           % Filter w/ a small kernel
ARGS.IFILTER_KSIZE           = sfilter(1);  % Filter size
ARGS.IFILTER_SD              = sfilter(2);  % Filter SD (if half about 90% of flt in kernel)
ARGS.IDETREND                = 0;           % Remove linear treneds
ARGS.ITMPFILTER              = 0;   		% Temporal filtering
ARGS.ITMPFLT_LOW             = 0;       	% Remove high frequency noise
ARGS.ITMPFLT_HIGH            = 0;           % Remove slow oscillations
ARGS.ITOSDU                  = 0;           % Convert to SD Units
ARGS.VERBOSE                 = 0;

if ~isstruct(roiTs),
  fprintf('SIGSPATFILT expects a roiTs structure; no cell arrays\n');
  keyboard;
end;
fprintf('SIGSPATFILT (%s): Spatial Filtering (%g,%g)...',roiTs.name,sfilter);
tcImg = roiTs2tcImg(roiTs);
tcImg = mimgpro(tcImg,ARGS);
ts = tcImg2roiTs(tcImg);
fprintf(' Done!\n');

