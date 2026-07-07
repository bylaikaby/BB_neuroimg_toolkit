function dsptimes(Spkt)
%DSPSPKT - Display Spike data as raster
% dsptimes(varargin) - show the times-field of the Spkt or esSpkt structure
%
% EXAMPLE:
%   dsptimes(Spkt);

if nargin < 1,
  help dsptimes;
  return;
end;

for iCh=1:size(Spkt.times,1),
  subplot(size(Spkt.times,1),1,iCh);
  for N=1:min(size(Spkt.times,2),40),
    spkt = Spkt.times{iCh,N}*Spkt.dt + Spkt.sesesmean.twin(1);
    tmpx = [spkt(:)';spkt(:)'];
    tmpy = repmat([N-0.5 N+0.5]',[1,length(spkt)]);
    line(tmpx,tmpy,'color','k','linewidth',1);
    hold on;
  end
  set(gca,'xlim',Spkt.sesesmean.twin);
end;
  



