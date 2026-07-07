function varargout = mncheck_vital(SESSION,GRPNAME,RoiName,USE_PCA)
%MNCHECK_VITAL - plots vital signs and roiTs.
%  [VITAL,ROITS] = MNCHECK_VITAL(SESSION,GRPNAME,ROINAME,[USE_PCA=0]) plots 
%  vital signs and ROITS of given ROINAME.
%  If USE_PCA==1, then use tcImg.pca_denoised as time course data.
%
%  VERSION :
%    0.90 10.06.05 YM  pre-release
%    0.91 15.06.05 YM  supports USE_PCA.
%    0.92 27.06.05 YM  supports 'd03se1', that only Puls/SpO2/Temp/CO2
%    0.93 06.02.12 YM  use mroi_file().
%
%  See also MNCHECK_ROITS, MNCHECK_PROJOUT, MN_ROITS_GET, MN_ROITS_CAT

if nargin < 2,  help mncheck_vital; return;  end
if nargin < 3,  RoiName = {};  end
if nargin < 4,  USE_PCA = 0;   end




% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


% LOAD TIME COURSE FOR EACH ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('%s %s: reading... ',datestr(now,'HH:MM:SS'),mfilename);
ROI = load(mroi_file(Ses,grp.grproi));
ROI = ROI.(grp.grproi);
ROI.roinames = union(ROI.roinames,Ses.roi.names);
roiTs = {};
if isempty(RoiName), RoiName = Ses.roi.names;  end
if ischar(RoiName),  RoiName = { RoiName };    end
for iRoi = 1:length(RoiName),
  if ~any(strcmpi(Ses.roi.names,RoiName{iRoi})),
    fprintf('%s ERROR: ROI ''%s'' not found.\n',mfilename,RoiName{iRoi});
    return;
  end
end

for iRoi = 1:length(RoiName),
  fprintf('%s.',RoiName{iRoi});
  tmpts = mn_roits_get(ROI,GRPNAME,RoiName{iRoi},[],USE_PCA);
  if isempty(tmpts), continue; end
  tmpts = mn_roits_cat(tmpts);
  if ~isempty(tmpts.dat),
    roiTs{end+1} = tmpts;
  end
end
fprintf(' done.\n');


% GET VITAL INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VITAL.Pulse  = zeros(1,length(grp.exps));
VITAL.SpO2   = zeros(1,length(grp.exps));
VITAL.T      = zeros(1,length(grp.exps));
VITAL.ExCO2  = zeros(1,length(grp.exps));
VITAL.InO2   = zeros(1,length(grp.exps));
VITAL.ExO2   = zeros(1,length(grp.exps));
VITAL.InIsofluran = zeros(1,length(grp.exps));
VITAL.ExIsofluran = zeros(1,length(grp.exps));
VITAL.VT     = zeros(1,length(grp.exps));
VITAL.Resp   = zeros(1,length(grp.exps));
VITAL.MinVol = zeros(1,length(grp.exps));
VITAL.Peep   = zeros(1,length(grp.exps));
VITAL.ABPs  = zeros(1,length(grp.exps));
VITAL.ABPd  = zeros(1,length(grp.exps));
VITAL.ABPm  = zeros(1,length(grp.exps));

for iExp = 1:length(grp.exps),
  ExpNo = grp.exps(iExp);
  tmpvit = Ses.expp(ExpNo).vit;
  VITAL.Pulse(iExp)  = tmpvit.Pulse;
  VITAL.SpO2(iExp)   = tmpvit.SpO2;
  VITAL.T(iExp)      = tmpvit.T;
  VITAL.ExCO2(iExp)  = tmpvit.ExCO2;
  VITAL.InO2(iExp)   = tmpvit.InO2;
  VITAL.ExO2(iExp)   = tmpvit.ExO2;
  VITAL.InIsofluran(iExp) = tmpvit.InIsofluran;
  VITAL.ExIsofluran(iExp) = tmpvit.ExIsofluran;
  VITAL.VT(iExp)     = tmpvit.VT;
  VITAL.Resp(iExp)   = tmpvit.Resp;
  VITAL.MinVol(iExp) = tmpvit.MinVol;
  VITAL.Peep(iExp)   = tmpvit.Peep;
  VITAL.ABPs(iExp)   = tmpvit.ABPs;
  VITAL.ABPd(iExp)   = tmpvit.ABPd;
  VITAL.ABPm(iExp)   = tmpvit.ABPm;
end

% COMPUTE CORR.COEF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iRoi = 1:length(roiTs),
  roiTs{iRoi}.mdat = mean(roiTs{iRoi}.dat,2);
end
fields = fieldnames(VITAL);
fprintf('            Name : ');
for iRoi = 1:length(roiTs),
  fprintf(' %12s    ',roiTs{iRoi}.name);
end
fprintf('\n');
for N = 1:length(fields),
  if strcmpi(fields{N},'Peep'), continue;  end
  fprintf(' %15s : ',fields{N});
  tmpvital = VITAL.(fields{N});
  for iRoi = 1:length(roiTs),
    [r,p] = corr(tmpvital(:), roiTs{iRoi}.mdat(:));
    fprintf('  % .3f(%.5f)',r,p);
  end
  fprintf('\n');
end



% PLOT DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
h = subPlotData(VITAL,roiTs);
figfile = sprintf('%s_%s_%s.fig',Ses.name,grp.name,mfilename);
saveas(h,figfile);




% SET OUTPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout,
  varargout{1} = VITAL;
  if nargout > 1,
    varargout{2} = roiTs;
  end
end


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot data
function hWin = subPlotData(VITAL,roiTs)
tmptitle = sprintf('%s: %s %s',mfilename,roiTs{1}.session,roiTs{1}.grpname);
hWin = figure('Name',tmptitle);
set(gcf,'DefaultAxesfontweight','bold');
set(gcf,'DefaultAxesFontName',  'Comic Sans MS');
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');


%T = [1:size(roiTs{1}.dat,1)];
T = mn_exptime(roiTs{1}.session,roiTs{1}.grpname);


% plot normalized vital signs
% remove "Peep"
fields = fieldnames(rmfield(VITAL,{'T','Peep','VT','Resp','MinVol'}));
COL = jet(length(fields));
legtxt = {};
AX1 = subplot(2,1,1);
for N = 1:length(fields),
  tmpdat = VITAL.(fields{N});
  if any(find(tmpdat ~= 0)),
    tmpdat = tmpdat - mean(tmpdat(:));
    tmpdat = tmpdat / sqrt(sum(tmpdat(:).*tmpdat(:)));
    plot(T,tmpdat,'color',COL(N,:),'linewidth',2);  grid on;  hold on;
    legtxt = fields{N};
  end
end
xlabel('Experiment Number');
ylabel('Normalized Value');
title('Normalized Vital Signs');
legend(legtxt,'fontsize',6);
legend('location','eastoutside');
set(gca,'xlim',[0 max(T)]);


% plot normalized roiTs
COL = jet(length(roiTs));
AX2 = subplot(2,1,2);  legtxt = {};
for N = 1:length(roiTs),
  legtxt{N} = sprintf('%s N=%d', roiTs{N}.name, size(roiTs{N}.dat,2));
  tmpdat = roiTs{N}.mdat;
  tmpdat = tmpdat - mean(tmpdat(:));
  tmpdat = tmpdat / sqrt(sum(tmpdat(:).*tmpdat(:)));
  plot(T,tmpdat,'color',COL(N,:),'linewidth',2);  grid on; hold on;
end
xlabel('Experiment Number');
ylabel('Normalized Value');
title('Normalized Time Course of roiTs');
legend(legtxt,'fontsize',6);
legend('location','eastoutside');
set(gca,'xlim',[0 max(T)]);


%pos1 = get(AX1,'position');
%pos2 = get(AX2,'position');

%set(AX1,'position',[pos1(1) pos1(2) pos2(3) pos1(4)]);

return;
