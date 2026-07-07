function Cln = clndespike(Cln, Spkt,varargin)
%clndespike - Remove spikes from Cln signal.
%  Cln = clndespike(Cln,Spkt,...) removes spikes from Cln signal.
%
%  Supported options are :
%   spkwin_ms : spike window in msec
%   edge_ms   : period for edge-averaging
%   spkdt_sec : time resolution of "Spkt"
%
%  NOTE :
%    Simple interpolation causes artificial oscillation in some LFP bands.
%    Here I use averaged values of both edges for interpolation.
%
%  EXAMPLE :
%    sigload('e10ha1',6,'Cln','Spkt')
%    Cln2 = clndespike(Cln,Spkt.times,'spkdt',Spkt.dt);
%    rip  = sigfiltfilt(Cln, [80 160], 'band');
%    rip2 = sigfiltfilt(Cln2,[80 160], 'band');
%    figure; plot([Cln.dat(1:80000,1) Cln2.dat(1:80000,1)]);
%    figure; plot([rip.dat(1:80000,1) rip2.dat(1:80000,1)]);
%
%  VERSION :
%    0.90 10.02.13 YM  pre-release
%    0.91 28.10.13 YM  bug fix on 'spkdt' option
%
%  See also interp1 siggetblp siggetspk spkselect

if nargin < 2,  eval(['help ' mfilename]); return;  end

VERBOSE   = 1;

SPKWIN_MS       = [-1 +2];    % spike window in msec
EDGE_AVERAGE_MS = 0.8;        % 0.8ms average at edges
SPKTDT_SEC      = Cln.dx;     % spike time resolution
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'spkwin' 'win' 'spkwin_ms'}
    SPKWIN_MS = varargin{N+1};
   case {'edge' 'edge_ms' 'edgeaverage' 'edgeaveragems' 'edgeaverage_ms'}
    EDGE_AVERAGE_MS = varargin{N+1};
   case {'spkdt' 'spktdt' 'spkdt_sec' 'spkdtsec'}
    SPKTDT_SEC = varargin{N+1};
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

% sampling rate correction
if SPKTDT_SEC ~= Cln.dx,
  for iCh = 1:length(Spkt),
    Spkt{iCh} = round(Spkt{iCh}*SPKTDT_SEC/Cln.dx);
  end
end


is = round(SPKWIN_MS(1)/1000/Cln.dx);
ie = round(SPKWIN_MS(2)/1000/Cln.dx);
xi = is-1:ie+1;

if any(VERBOSE),
  fprintf(' %s: spkwin=[%g %g]ms nch=%d: ',...
          mfilename,SPKWIN_MS(1),SPKWIN_MS(2),size(Cln.dat,2));
end

EDGE_AVERAGE_PTS = round(EDGE_AVERAGE_MS /1000.0/Cln.dx);
if any(VERBOSE),
  fprintf(' edge_avr=%d(%gms) ',EDGE_AVERAGE_PTS,EDGE_AVERAGE_MS);
end


clnsz = size(Cln.dat);
Cln.dat = reshape(Cln.dat,[clnsz(1) prod(clnsz(2:end))]);


for iCh = 1:size(Cln.dat,2),
  if any(VERBOSE),
    if mod(iCh,10) == 0,
      fprintf('%d',iCh);
    else
      fprintf('.');
    end
  end
  
  tmpdat = Cln.dat(:,iCh);
  
  spktimes = Spkt{iCh};
  % ignore spikes out of the window
  spktimes = spktimes(spktimes+xi(1)-EDGE_AVERAGE_PTS > 0 & ...
                      spktimes+xi(end)+EDGE_AVERAGE_PTS <= size(Cln.dat,1));
  

  % interpolate periods where it should be with taking into account of overlaps.
  % fast and clearner.
  
  % mark periods to interpolate
  tmpspk = zeros(size(tmpdat));
  for iSpk = 1:length(spktimes),
    tmpspk(xi + spktimes(iSpk)) = 1;
  end
  % detect periods
  is = find(diff(tmpspk) > 0) + 1;
  ie = find(diff(tmpspk) < 0);
  lens = ie - is;
  ulens = sort(unique(lens));
  for L = 1:length(ulens),
    tmpidx = find(lens == ulens(L));
    tmpis  = is(tmpidx);
    tmpie  = ie(tmpidx);
    if EDGE_AVERAGE_PTS > 1,
      % use mean values at the edges 
      isdat  = zeros(EDGE_AVERAGE_PTS,length(tmpidx),class(tmpdat));
      iedat  = zeros(EDGE_AVERAGE_PTS,length(tmpidx),class(tmpdat));
      iswin  = -(EDGE_AVERAGE_PTS-2):1;
      iewin  = -1:(EDGE_AVERAGE_PTS-2);
      for iSpk = 1:length(tmpidx),
        isdat(:,iSpk) = tmpdat(iswin + tmpis(iSpk));
        iedat(:,iSpk) = tmpdat(iewin + tmpie(iSpk));
      end
      ydat = zeros(2,length(tmpidx),class(tmpdat));
      ydat(1,:) = nanmean(isdat,1);
      ydat(2,:) = nanmean(iedat,1);
      tmpxi = 0:ulens(L)-1;
      tmpx  = [nanmean(iswin+tmpxi(1)), nanmean(iewin+tmpxi(end))];
      %tmpx  = tmpxi([1 end]);
      yidat = interp1(tmpx,ydat,tmpxi,'linear','extrap');
    else
      % this may cause artificial oscillation in some LFP bands...
      ydat = zeros(2,length(tmpidx),class(tmpdat));
      for iSpk = 1:length(tmpidx),
        ydat(:,iSpk) = tmpdat([tmpis(iSpk), tmpie(iSpk)]);
      end
      tmpxi = 0:ulens(L)-1;
      tmpx  = tmpxi([1 end]);
      yidat = interp1(tmpx,ydat,tmpxi,'linear');
    end

    for iSpk = 1:length(tmpidx),
      tmpdat(tmpxi + tmpis(iSpk)) = yidat(:,iSpk);
    end
  end

  % --------------------------------------------------------------------
  % following methods introduce more ripples (artificial).
  % --------------------------------------------------------------------
  
  % % this is much-much faster, but overlap of spikes causes jaggy shapes.
  % tmpx = xi([1,end]);
  % ydat = zeros(2, length(spktimes),class(tmpdat));
  % for iSpk = 1:length(spktimes)
  %   ydat(:,iSpk) = tmpdat(tmpx + spktimes(iSpk));
  % end
  % yidat = interp1(tmpx,ydat,xi,'linear');
  % for iSpk = 1:length(spktimes),
  %   tmpdat(xi + spktimes(iSpk)) = yidat(:,iSpk);
  % end
  
  % interpolate 1 by 1, slowest
  % for iSpk = 1:length(spktimes)
  %   tmpsel = xi + spktimes(iSpk);
  %   y  = tmpdat(tmpsel);
  %   yi = interp1(xi([1,end]), y([1,end]),xi,'linear');
  %   tmpdat(tmpsel) = yi;
  % end

  % --------------------------------------------------------------------
  
  Cln.dat(:,iCh) = tmpdat;
end

Cln.dat = reshape(Cln.dat,clnsz);

if any(VERBOSE),  fprintf(' done.\n');  end

Cln.(mfilename).spkwin_ms = SPKWIN_MS;
Cln.(mfilename).edg_ms    = EDGE_AVERAGE_MS;

return
