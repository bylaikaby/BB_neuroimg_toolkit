function showtimes(SesName, GrpName, varargin)
%DSPSPKT - Display Spike data as raster
% showtimes(SesName, GrpName, varargin) - show the times-field of the Spkt or esSpkt structure
%
% EXAMPLE:
%   showtimes(SesName, GrpName); histogram of esSpkt.times
%   showtimes(SesName, GrpName); histogram of Spkt.times

if nargin < 2,
  help showtimes;
  return;
end;

Ses = goto(SesName);

[hst, t, Spkt] = getspkhist(SesName,GrpName,varargin{:});

INFO = Ses.anap.recinfo;

if isfield(Ses.anap,'recinfo'),
  idx = [];
  name = {};
  for N=1:length(INFO.vsarea),
    idx = cat(2, idx, INFO.vsarea{N}{2});
    for M=1:length(INFO.vsarea{N}{2}),
      name{end+1} = INFO.vsarea{N}{1};
    end;
  end;
  Spkt.dat = Spkt.dat(:,idx,:,:);
  hst = hst(:,idx);
end;


if 0,
  dsptimes(Spkt);
end;

mfigure([100 50 1000 1000]);
mhst = max(hst(:));
for iCh=1:size(hst,2),
  subplot(size(hst,2),1,iCh);
  hd = bar(t*1000, hst(:,iCh));
  set(hd,'edgecolor','none','facecolor','k');
  set(gca,'xlim',Spkt.sesesmean.twin*1000,'ylim',[0 mhst]);
  title(sprintf('Visual Area %s(Ch=%d)', name{iCh},iCh));
end;

dat = [];
for N=1:length(INFO.vsarea),
  tmpdat = hnanmean(hst(:,[1:length(INFO.vsarea{N}{2})]),2);
  dat = cat(2,dat,tmpdat);
end;
hst = dat;

mfigure([100 200 600 600]);
for iCh=1:size(hst,2),
  subplot(size(hst,2),1,iCh);
  hd = bar(t*1000, hst(:,iCh));
  xlabel('Time in msec');
  set(hd,'edgecolor','none','facecolor','k');
  set(gca,'xlim',1000*Spkt.sesesmean.twin,'ylim',[0 mhst]);
  title(sprintf('Visual Area %s', INFO.vsarea{iCh}{1}));
end;
