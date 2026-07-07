function meleprofile(Session,ExpNo,RoiName,DistTick)
%MELEPROFILE - to be done!
%MELEPROFILE (Session,ExpNo,RoiName,DistTick)
%
%
%  VERSION :
%    0.90 13.03.06 YM  pre-release
%
%  See also MGETELEPOS MGETELEDIST
  
if nargin < 2,  eval(sprintf('help %s;',mfilename)); return;  end

if nargin < 3,  RoiName = 'v1';  end
if nargin < 4,  DistTick = 0:1:10;  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Session);
grp = getgrp(Ses,ExpNo);
anap = getanap(Ses,grp);

if isnumeric(ExpNo),
  % ExpNo as experiment number
  figtitle = sprintf('%s: %s(%s) ExpNo=%d ROI=%s',mfilename,Ses.name,grp.name,ExpNo,RoiName);
else
  % ExpNo as group-name (structure)
  figtitle = sprintf('%s: %s(%s) ROI=%s',mfilename,Ses.name,grp.name,RoiName);
end


% LOAD DATA AND PLOT
elepos = mgetelepos(Ses,grp);
if isempty(elepos),
  fprintf('ERROR %s: electrode(s) is not defined in ROI.\n',mfilename);
  return;
end


if isfield(anap,'gettrial') & anap.gettrial.status > 0,
  ROITS = sigload(Ses,ExpNo,'troiTs');
else
  ROITS = sigload(Ses,ExpNo,'roiTs');
  % to make compatible with troiTs
  for N = 1:length(ROITS),
    ROITS{N} = { ROITS{N} };
  end
end


% find roiTs
idx = zeros(1,length(ROITS));
for N = 1:length(ROITS),
  if strcmpi(ROITS{N}{1}.name,RoiName),  idx(N) = 1;  end
end
ROITS = ROITS(find(idx > 0));




% FIX .ds problem
if ndims(ROITS{1}{1}.ana) ~= length(ROITS{1}{1}.ds),
  par = expgetpar(Ses,ROITS{1}{1}.ExpNo(1));
  if size(ROITS{1}{1}.ana,3) == 1,
    dz = par.pvpar.acqp.IMND_slice_thick;
  else
    dz = par.pvpar.acqp.IMND_slice_sepn(1);
  end
  for N = 1:length(ROITS),
    for T = 1:length(ROITS{N}),
      ROITS{N}{T}.ds(3) = dz;
    end
  end
end

for N = 1:length(ROITS),
  for T = 1:length(ROITS{N}),
    for K = 1:size(elepos,1),
      tmptitle = sprintf('%s TRIAL=%d ELE=%d',figtitle,T,K);
      subPlotProfileTC(ROITS{N}{T},elepos(K,:),tmptitle,DistTick);
    end
  end
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subPlotProfileTC(ROITS,ELEPOS,FIGTITLE,DISTTICK)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name',FIGTITLE);
set(gcf,'DefaultAxesfontsize',	10);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName', 'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');



axes;

t = [0:size(ROITS.dat,1)-1]*ROITS.dx(1);
eledist = mgeteledist(ROITS.coords,ELEPOS,ROITS.ds);

TCRAW = cell(1,length(DISTTICK)-1);
for N = 1:length(DISTTICK)-1,
  idx = find(eledist >= DISTTICK(N) & eledist < DISTTICK(N+1));
  if isempty(idx),  continue;  end
  tmpdat = ROITS.dat(:,idx);
  TCRAW{N} = tmpdat;
  
  x = ones(1,size(tmpdat,1)) * (DISTTICK(N)+DISTTICK(N+1))/2;
  z = mean(tmpdat,2);
  plot3(x,t,z);
  hold on;
end
grid on;
set(gca,'xlim',[0 max(DISTTICK)]);

xlabel('Distance from the electrode (mm)');
ylabel('Time in seconds');
zlabel('BOLD Amplitude');

return;

