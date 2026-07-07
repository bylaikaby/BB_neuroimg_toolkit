function ZD = zapts(SesName, ESSITE)
%ZAPTS - Get the time course of a ROI for each selected session
% ZD = ZAPTS(SesName,GrpName) will plot the time course of a ROI for each
% analyzed sessions. ZD are the sorted zap-data.
%  

ESSITE = 'lgn';
pVal = 0.001;
ROINAMES = {'V1','V2','MT','XC'};
MdlName = 'fVal';
ROICOL = {[1 .7 .7],[.8 .8 .85],[1 0 0],[0 1 0],[0 0 1]};

Ses = goto(SesName);

grps = getgroups(Ses);

GRP = {};
for N=1:length(grps),
  if strncmp(grps{N}.name,'zapp',4),
    GRP{end+1} = grps{N};
  end;
end;

if isempty(GRP),
  fprintf('Session %s has no ZAPPn Groups\n');
  return;
end;

for N=1:length(GRP),
  ZD{N} = subGetZapp(Ses,GRP{N}.name,ESSITE,ROINAMES,MdlName,pVal);
end;

if nargout,
  return;
end;

% ELSE PLOT...
NPLOTS = length(GRP);
if NPLOTS <= 4,
  NROW = 2;
  NCOL = 2;
  COLWIDTH = 580;
elseif NPLOTS > 4 & NPLOTS <= 6,
  NROW = 2;
  NCOL = 3;
  COLWIDTH = 420;
else
  fprintf('too many subplots... change DIMS in ZAPTS\n');
  return;
end;
YSIZE = 800;
XSIZE = COLWIDTH * NCOL;
mfigure([100 100 XSIZE YSIZE]);
LEGTXT = {ESSITE,ROINAMES{:}};
    
for N=1:length(ZD),
  subplot(NROW,NCOL,N);
  h = area(ZD{N}.freq,[ZD{N}.roiTs{1}.dat ZD{N}.roiTs{2}.dat]);
  set(h(1),'facecolor',ROICOL{1},'edgecolor','r');
  set(h(2),'facecolor',ROICOL{2},'edgecolor','none');
  hold on;
  for K=3:length(ZD{N}.roiTs),
    h(K) = plot(ZD{N}.freq,ZD{N}.roiTs{K}.dat,'marker','s','markerfacecolor',ROICOL{K},...
              'markeredgecolor','y', 'markersize',5);
  end;
  set(gca,'layer','top')
  set(gca,'xlim',ZD{N}.frange);
  set(gca,'xtick',[ZD{N}.frange(1):10:ZD{N}.frange(2)]);
  xlabel('Frequency in Hz');
  ylabel('BOLD Response in SD Units');
  grid on;
  [lh, lh1] = legend(h,LEGTXT,'Location','northwest');
  set(lh,'FontWeight','normal','FontSize',8,'color',[.9 .9 .9]);
  set(lh,'xcolor','k','ycolor','k');
  title(sprintf('Group: %s/%s Model: %s', ZD{N}.session, ZD{N}.grpname, ZD{N}.mdlname));
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ZD = subGetZapp(Ses,GrpName,ESSITE,ROINAMES,MdlName,pVal);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rois = {ESSITE,ROINAMES{:}};
anap = getanap(Ses,GrpName);
grp = getgrpbyname(Ses, GrpName);
glm = grp.glmconts;
glmidx = [];

glmidx = NaN;
for N=1:length(glm),
  if strcmp(lower(glm{N}.name),lower(MdlName)),
    glmidx = N;
  end;
end;

if isnan(glmidx),
  fprintf('ZAPTS: Wrong model definition\n');
  keyboard
end;

mdl = sprintf('glm[%d]',glmidx);

for N=1:length(rois),
  roiTs{N} = mvoxselect(Ses,GrpName,rois{N},mdl,[],pVal);
  roiTs{N} = xform(roiTs{N},'tosdu');
  roiTs{N}.dat = hnanmean(roiTs{N}.dat,2);
  [freq frange] = subGetFreq(roiTs{N}.stm,size(roiTs{N}.dat,1),anap.HemoDelay);
  roiTs{N}.dat = flipud(roiTs{N}.dat);
  idx = find(freq);
  freq = freq(idx);
  roiTs{N}.dat = roiTs{N}.dat(idx);
  if frange(1) > frange(2),
    frange = flipud(frange);
  end;
end;
ZD.session = Ses.name;
ZD.grpname = GrpName;
ZD.mdlname = MdlName;
ZD.mdl = mdl;
ZD.pVal = pVal;
ZD.freq = freq;
ZD.frange = frange;
ZD.roiTs = roiTs;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [F frange] = subGetFreq(STM,NPOINTS,HemoDelay)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% assuming blnak-microstim-blank
wavfile = STM.stmpars.stmobj{2}.niwavfile;
if isempty(wavfile),
  error('%s: stm.stmpars.stmobj{2}.niwavfile is empty.',mfilename);
end
%wavfile = 'sweep_100-010.txt';
wavfile = wavfile(1:end-4);  % remove .txt
wavfile = wavfile(min(strfind(wavfile,'_'))+1:end);
frange  = sscanf(wavfile,'%d');
frange  = abs(frange(1:2));
F = zeros(NPOINTS,1);
stmdur = STM.dt{1}(2);
tsel = [1:stmdur] + STM.dt{1}(1) + round(HemoDelay/STM.voldt);
tmpt = [0:stmdur-1]*STM.voldt;
F(tsel) = (frange(2)-frange(1))/(stmdur-1)*tmpt + frange(1);
return;






