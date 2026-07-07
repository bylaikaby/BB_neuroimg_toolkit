function RES = find_saccade(XY,DT,varargin)
%FIND_SACCADE - Find saccadic eye movement.
%  RES = FIND_SACCADE(XY,DT,...) finds saccadic eye movement.
%  XY as (time,xy), DT as sampling time in seconds.
%
%  Supported options are :
%    'ResampleHz'  : resampling Hz
%    'Smooth'      : smoothing width in msec
%    'Vthr'        : velocity threshold, deg/sec for eye-stop
%    'Tthr'        : theta(angle) threshold in deg
%    'Rrange'      : [min max] of movement
%    'MinDurSec'   : minimum stopped(stable) duration in sec
%
%  EXAMPLE :
%    RES = find_saccade(peter55(:,3:4),1/60,'smooth',50,'resample',1000,'v',5)
%
%  NOTES :
%    Based on saccade-stop algorithm by 
%    Martinez-Conde,(2000). Nat. Neurosci. 3(3): 251-8.
%      "Microsaccadic eye movements and firing of single cells in the
%       striate cortex of macaque monkeys." 
%
%  VERSION :
%    0.90 27.05.11 YM  pre-release
%    0.91 28.05.11 YM  bug-fix, improved logic etc
%
%  See also interp1



ResampleHz = 1000;
SmoothWms  = 30;

V_THR      = 3.0;      % deg/sec

%V_THR      = 10.0;     % deg/sec

T_THR      = 15.0;
R_RANGE    = [3/60 2]; % degree

MinDurSec  = DT*2.0;

DO_PLOT    = 1;

for N = 1:2:length(varargin),
  switch lower(varargin{N})
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'smooth','smoothw','smoothwidth'}
    SmoothWms = varargin{N+1};
   case {'v','vthr','velocity'}
    V_THR = varargin{N+1};
   case {'t','tthr','theta'}
    T_THR = varargin{N+1};
   case {'r','rrange','range'}
    R_RANGE = varargin{N+1};
   case {'mindur','mindursec'}
    MinDurSec = varargin{N+1};
   case {'plot'}
    DO_PLOT = varargin{N+1};
  end
end


if any(ResampleHz),
  NEWDT = 1/ResampleHz;

  
  % nyqf = (1/DT)/2;
  % [b a] = butter(4,14/nyqf,'low');
  % %plot((0:size(XY,1)-1)*NEWDT,[XY(:,2) filtfilt(b,a,XY(:,2))]);
  % %keyboard
  % XY(:,1) = filtfilt(b,a,XY(:,1));
  % XY(:,2) = filtfilt(b,a,XY(:,2));
  
  
  if 1,
    fprintf(' interp1(%gHz)...',ResampleHz);
    % use interp1()
    x = 0:size(XY,1)-1;
    xi = 0:NEWDT/DT:size(XY,1)-1;
    for N = 1:size(XY,2),
      XYr(:,N) = interp1(x,XY(:,N),xi,'spline');
    end
    %plot((0:size(XY,1)-1)*DT,XY);  hold on;
    %plot((0:size(XYr,1)-1)*NEWDT,XYr);
    XY = XYr;
  else
    % use resample()
    fprintf(' resample(%gHz)...',ResampleHz);
    RAT_TOL = 0.0001;
    [p q] = rat(DT/NEWDT,RAT_TOL);
    for N = 1:size(XY,2),
      XYr(:,N) = resample(XY(:,N),p,q);
    end
    XY = XYr;
  end
  
  % need to remove juggy stuff in Y
  fprintf(' filter(lp)..');
  nyqf = (1/NEWDT)/2;
  %[b a] = butter(8,14/nyqf,'low');
  %plot((0:size(XY,1)-1)*NEWDT,[XY(:,2) filtfilt(b,a,XY(:,2))]);

  %[b a]   = iirnotch(30/nyqf,5/nyqf);
  %[b2 a2] = iirnotch(15/nyqf,2/nyqf);
  %plot((0:size(XY,1)-1)*NEWDT,[XY(:,2) filtfilt(b2,a2,filtfilt(b,a,XY(:,2)))]);
  
  if 0,
    [b a] = butter(8,30/nyqf,'low');
    XY(:,1) = filtfilt(b,a,XY(:,1));

    [b a] = butter(8,14/nyqf,'low');
    %[b a] = iirnotch(15/nyqf,15/nyqf);
    XY(:,2) = filtfilt(b,a,XY(:,2));

    %[b a] = iirnotch(30/nyqf,4/nyqf);
    %XY(:,2) = filtfilt(b,a,XY(:,2));
    
    %[b a] = iirnotch(15/nyqf,3/nyqf);
    %XY(:,2) = filtfilt(b,a,XY(:,2));
  else
    [b a] = butter(8,14/nyqf,'low');
    %[b a] = iirnotch(15/nyqf,15/nyqf);
    XY(:,2) = filtfilt(b,a,XY(:,2));
  end  
  
  DT = NEWDT;
end


if any(SmoothWms),
  span = round(SmoothWms/1000/DT);
  if mod(span,2) == 0,  span = span + 1;  end
  fprintf(' smooth(w=%d,%gms)...',span,SmoothWms);
  for N = 1:size(XY,2),
    XY(:,N) = smooth(XY(:,N),span,'moving');
    %XY(:,N) = smooth(XY(:,N),span,'rloess');
  end
end



DXYi = complex(diff(XY(:,1)),diff(XY(:,2)));
DXYi(end+1) = 0;

InstRT = [abs(DXYi) unwrap(angle(DXYi))/pi*180];

InstRT(:,1) = InstRT(:,1)/DT;  % deg/sec

fprintf(' detecting(v=%g,t=%g,r=[%s])...',V_THR,T_THR,deblank(sprintf('%g ',R_RANGE)));
EYESTOP = sub_find_eyestop(DT, MinDurSec, InstRT(:,1), InstRT(:,2),...
                           V_THR, T_THR, R_RANGE);



% limit within +-20 degree...
tmpR = abs(complex(XY(:,1)-nanmedian(XY(:,1)),XY(:,2)-nanmedian(XY(:,2))));
EYESTOP(tmpR > 20) = 0;



RES.dt  = DT;
RES.xy  = XY;
RES.irt = InstRT;
RES.eyestop = EYESTOP;
RES.options.ResampleHz = ResampleHz;
RES.options.SmoothWms  = SmoothWms;
RES.options.V_THR      = V_THR;
RES.options.T_THR      = T_THR;
RES.options.R_RANGE    = R_RANGE;




if DO_PLOT,
  sub_plot(RES);
  sub_plot2(RES);
end



return


% =====================================================================
function EYESTOP = sub_find_eyestop(DT, MinDurSec, R, Theta, Vthr, Tthr, R_RANGE)
% =====================================================================

tmpstop = R < Vthr;
if any(Tthr),
  tmpstop = tmpstop | abs(diff([Theta(1); Theta])) > Tthr;
end

% make sure 1 as nothing
tmpstop(1) = 0;

if any(R_RANGE),
  dxy = complex(R.*cos(Theta/180*pi),R.*sin(Theta/180*pi))*DT;
  tmpin = find(diff(tmpstop) ==  1) + 1;
  tmpin(end+1) = length(R);
  for N = 1:length(tmpin)-1,
    ie = tmpin(N)-1;
    if N == 1,
      is = 1;
    else
      is = tmpin(N-1);
    end
    tmpr = abs(sum(dxy(is:ie)));
    if tmpr < R_RANGE(1) || tmpr > R_RANGE(2),
      tmpstop(tmpin(N):tmpin(N+1)-1) = 0;
    end
  end
end

if any(MinDurSec),
  sstart = find(diff(tmpstop) ==  1) + 1;
  send   = find(diff(tmpstop) == -1);
  if length(sstart) > length(send),
    send(end+1) = length(tmpstop);
  end
  minpts = round(MinDurSec/DT);
  for N = 1:length(sstart),
    if send(N)-sstart(N) < minpts,
      tmpstop(sstart(N):send(N)) = 0;
    end
  end
end


EYESTOP = double(tmpstop);



return


% =====================================================================
function EYESTOP = sub_find_eyestopOLD(DT, MinDurSec, R, Theta, Vthr, Tthr, R_RANGE)
% =====================================================================

tmpstop = R < Vthr;  tmpstop(1) = 0;
EYESTOP = zeros(size(tmpstop));

N = 0;
while N < length(tmpstop),
  N = N + 1;
  if tmpstop(N) == 0,  continue;  end
  is = N;  ie = NaN;
  for K = is:length(tmpstop),
    if tmpstop(K) == 0,
      ie = K-1;
      break;
    end
  end
  if isnan(ie),  continue;  end
  if ie == is,   continue;  end
  N = ie;
  minv = min(Theta(is:ie));
  maxv = max(Theta(is:ie));
  if any(Tthr) && maxv - minv > Tthr,
    continue;
  end
  % ok, it looks a stable stop period
  EYESTOP(is:ie) = 1;
  
end

  
%figure; subplot(2,1,1); plot(EYESTOP);

if any(MinDurSec),
  sstart = find(diff(EYESTOP) ==  1) + 1;
  send   = find(diff(EYESTOP) == -1);
  if length(sstart) > length(send),
    send(end+1) = length(EYESTOP);
  end
  minpts = round(MinDurSec/DT);
  for N = 1:length(sstart),
    if send(N)-sstart(N) < minpts,
      EYESTOP(sstart(N):send(N)) = 0;
    end
  end
end


if isempty(R_RANGE),  return;  end


sstart = find(diff(EYESTOP) ==  1) + 1;
send   = find(diff(EYESTOP) == -1);

if length(sstart) > length(send),
  send(end+1) = length(EYESTOP);
end


for N = 1:length(sstart),
  ie = sstart(N)-1;
  if N == 1,
    is = 1;
  else
    is = send(N-1)+1;
  end
  tmpr = sum(R(is:ie))*DT;
  % reject if out of range...
  if tmpr < R_RANGE(1) || tmpr > R_RANGE(2),
    EYESTOP(sstart(N):send(N)) = 0;
  end
end


return



% =====================================================================
function sub_plot(RES)
% =====================================================================

figure;
tmpt = (0:size(RES.xy,1)-1)*RES.dt;

subplot(2,1,1);
tmpeye = RES.xy;
tmpidx = round(0.25*size(tmpeye,1)):round(0.75*size(tmpeye,1));
tmpeye(:,1) = tmpeye(:,1) - nanmean(tmpeye(tmpidx,1));
tmpeye(:,2) = tmpeye(:,2) - nanmean(tmpeye(tmpidx,2));
plot(tmpt,tmpeye(:,1),'r');  hold on;
plot(tmpt,tmpeye(:,2),'g');

xlabel('Time in sec');
ylabel('Eye movement in deg');
grid on;
set(gca,'xlim',[tmpt(1) tmpt(end)],'ylim',[-8 8]);

ylm = get(gca,'ylim');
tmpy = ylm(1); tmph = ylm(2)-ylm(1);
EYESTOP = RES.eyestop;
sstart = find(diff(EYESTOP) ==  1) + 1;
send   = find(diff(EYESTOP) == -1);
if length(sstart) > length(send),
  send(end+1) = length(EYESTOP);
end
H = [];
for N = 1:length(sstart),
  ts = tmpt(sstart(N));
  te = tmpt(send(N));
  tmpw = max(te-ts,RES.dt);
  fprintf('%5d: %g/%gs %gms\n',N,ts,te,tmpw*1000);
  H(end+1) = rectangle('position',[ts tmpy tmpw tmph],...
                       'linestyle','none','facecolor',[0.7 0.7 0.9]);
end
sub_back(H);
set(gca,'layer','top');


subplot(4,1,3);
plot(tmpt,RES.irt(:,1),'color','k');
set(gca,'xlim',[tmpt(1) tmpt(end)],'ylim',[0 20]);
ylabel('Eye movement (R) in deg');

subplot(4,1,4);
plot(tmpt,RES.irt(:,2),'color','k');
set(gca,'xlim',[tmpt(1) tmpt(end)]);
ylabel('Eye movement (Theta) in deg');


return




% =====================================================================
function sub_plot2(RES)
% =====================================================================

EYESTOP = RES.eyestop;
sstart = find(diff(EYESTOP) ==  1) + 1;
send   = find(diff(EYESTOP) == -1);




%W_PRE_SAC  = round();
%W_SACCADE  = round();

PosPre  = NaN(length(sstart),2);
VelSacc = NaN(1,length(sstart));
PosPost = NaN(length(sstart),2);
for N = 1:length(sstart),
  is = sstart(N);
  ie = send(N);
  PosPost(N,:) = nanmean(RES.xy(is:ie,:),1);
  if N == 1,
    tmpidx = (-round(48/1000/RES.dt):0) + (is-1);
  else
    %tmpidx = max([send(N-1)+1 is-round(0.2/RES.dt)]):is-1;
    tmpidx = send(N-1)+1:is-1;
  end
  VelSacc(N) = max(RES.irt(tmpidx,1));
  %VelSacc(N) = nanmean(RES.irt(tmpidx,1));
  %VelSacc(N) = nanmedian(RES.irt(tmpidx,1));
end
PosPre(2:end) = PosPost(1:end-1);

AmpSacc = sqrt(sum((PosPost-PosPre).^2,2));


tmpidx = find(VelSacc < 100);
AmpSacc = AmpSacc(tmpidx);
VelSacc = VelSacc(tmpidx);


figure;
plot(AmpSacc, VelSacc, 'marker','.','markerfacecolor','b','linestyle','none');
grid on;
xlabel('Saccade Magnitude (deg)');
ylabel('Saccade Velocity (deg/sec)');

text(0.01,0.95,sprintf('Amp: median/sd=%g/%g',nanmedian(AmpSacc),nanstd(AmpSacc)),'unit','normalized');
text(0.01,0.90,sprintf('Vel: median/sd=%g/%g',nanmedian(VelSacc),nanstd(VelSacc)),'unit','normalized');


%set(gca,'xlim',[0 4],'ylim',[0 50]);
set(gca,'xscale','log','yscale','log')
set(gca,'xlim',[0.01 4],'ylim',[1 50])

return






% =====================================================================
function sub_back(handles)
% =====================================================================

handles = handles(find(ishandle(handles)));
if isempty(handles),  return;  end


% get the current order of handles
hParent = get(handles(1),'Parent');
hChildren = get(hParent,'Children');

% change the order
for N = length(handles):-1:1,
  tmpflags = hChildren == handles(N);
  idx  = find(tmpflags);
  if ~isempty(idx),
    idx2 = find(~tmpflags);
    hChildren = hChildren([idx2(:)' idx]);
  end
end

% set the new order of handles
set(hParent,'Children',hChildren);
drawnow;	% update to draw


return;
