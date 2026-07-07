function oSig = getmpxdata(Ses,ExpNo,adfofsSec,adflenSec)
%GETMPXDATA - Get multiplexed data
% PURPOSE : To get multi-plexed data in the adffile.
%
% USAGE :   oSig = getmpxdata(Ses,ExpNo,adfofsSec,adflenSec)
%
% NOTES : 
%   - adfofs,adflen (in sec) must be the same as neural data.
%   - GRP.(grpname).mpxdata field is used to get multi-plexed data info.
%     for example, GRP.(xxxx).mpxdata = { [10 11], {'contrL','contrR','oriL','oriR'} };
%     [10 11] is [multiplexed-CHAN clock-CHAN] in the adffile.
%     {'contrL',...} are data in multiplexed signal.
%
% SEEALSO : decmain.m
% VERSION :
%   0.90 06.10.05 YM  pre-release
%   0.91 25.10.05 YM  
%
% See also ADFREAD, DECMAIN

  
if nargin < 2,
  help getmpxdata;
  return;
end

if ~exist('adfofsSec','var'),  adfofsSec = 0;  end
if ~exist('adflenSec','var'),  adflenSec = [];  end


% CONTROL FLAGS/SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
NUM_MAX_MPXDATA = 8;



fprintf(' getmpxdata:');
oSig = {};

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
grp = getgrp(Ses,ExpNo);

if length(grp.mpxdata{1}) == 1,
  CH_MPX = grp.mpxdata{1};
  CH_CLK = CH_MPX + 1;
else
  CH_MPX = grp.mpxdata{1}(1);
  CH_CLK = grp.mpxdata{1}(2);;
end
NUM_MPXDATA = length(grp.mpxdata{2});


[MPXdata dx] = adfread(Ses,ExpNo,1,CH_MPX);
MPXdata = int16(MPXdata);
[CLKdata dx] = adfread(Ses,ExpNo,1,CH_CLK);
CLKdata = int16(CLKdata);

if isempty(adflenSec) | adflenSec == 0,
  adflenSec = length(MPXdata)*dx;
end

% get negative edges
% clean clock signal
highLv = max(CLKdata(:));
tmpidx = find(CLKdata >= highLv*0.7);
CLKdata(:) = 0;  CLKdata(tmpidx) = 1.0;
negEdges = find(diff(CLKdata) < 0);

dur = mean(diff(negEdges))/NUM_MAX_MPXDATA;

if negEdges(end) + dur*NUM_MAX_MPXDATA > length(MPXdata),
  negEdges = negEdges(1:end-1);
end


centers = round(([0:NUM_MPXDATA-1]+0.5)*dur);
MPXvalue = zeros(length(negEdges),NUM_MPXDATA);

try,
for N = 1:length(negEdges),
  ipts = negEdges(N);
  for K = 1:NUM_MPXDATA,
    MPXvalue(N,K) = mean(MPXdata([-4:4]+ipts+centers(K)));
  end
end
catch
  keyboard
end





oSig.name = 'mpxdata';
oSig.label = grp.mpxdata{2};
oSig.dx    = 0.001;  % 1 msec resolution
adfofsPts  = round(adfofsSec/oSig.dx);
adflenPts  = round(adflenSec/oSig.dx);


npts = round(length(CLKdata)*dx/oSig.dx);
DAT = zeros(npts,NUM_MPXDATA);

if nargout == 0,
  figure;
  plot([0:length(CLKdata)-1]*dx,CLKdata,'r');  hold on;
  plot([0:length(CLKdata)-1]*dx,MPXdata,'b');  grid on;
end

  
clear CLKdata MPXdata;

MPXtime  = round(negEdges * dx / oSig.dx) + 1;
MPXtime(end+1) = npts;
for N = 1:length(MPXtime)-1,
  idx = MPXtime(N):MPXtime(N+1);
  for K = 1:NUM_MPXDATA,
    DAT(idx,K) = MPXvalue(N,K);
  end
end


oSig.dat = DAT;


return;
