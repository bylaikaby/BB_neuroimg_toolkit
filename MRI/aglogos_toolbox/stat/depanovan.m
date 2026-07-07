function varargout = depanovan(SigName,Method)
%DEPANOVA - N-way ANOVA for dependency analysis
% DEPANOVAN(SIGNAME,METHOD) applys N-way ANOVA to SIGNAME/METHOD
%   Session/Groups for this analysis is described internally.
%   Please edit session/group list in this script as your demand.
%
% EXAMPLE :
%   depanova('cfMua','kc')
%
% VERSION : 0.90 22.07.04 YM  pre-release
%
% See also DEPSTAT, CATSIG, XMOVPHYS

if nargin < 2,  help depanovan;  return;  end


% Sessoin/Group list for N-way ANOVA.
if 1,
  % for physiology
  SessGrps = {
      { 'C98NM1', {'movie1','movie2','movie3','movie4','spont1'} },
      { 'G97NM1', {'movie1','movie2','movie3','spont1'} },
      { 'R97NM1', {'movie1','movie2','spont1'} },
%      { 'C98NM2', {'movie1','movie2','movie3','movie4','movie5','movie6','spont1'} },
%      { 'G02NM1', {'movie1','movie2','movie3','spont'} },
      { '', {} } };
else
  % for imaging
  SessGrps = {
      { 'M02LX1', {'movie1','movie2','movie3','movie4','movie5','movie6','movie7','movie8','movie9','movie10','movie11','movie12','movie13','movie14','movie15','baseline'} },
      { 'G02MN1', {'movie1','movie2','movie3','polar','spont1'} },
      { 'N02M21', {'movie1','movie2','movie3','movie4','movie5','movie6','movie7','movie8','movie9','polar1','spont1'} },
      { 'G02LV1', {'movie1','movie2','movie3','movie4','movie5','spontact'} },
      { 'F01M91', {'movie1','movie2','movie3','movie4','polar1','spont1'} },
      { '', {} } };
end


% ANOVA parameters
ANOVA_DISPLAY = 'off';
ANOVA_ALPHA   = 0.05;  % default 0.05 for 95% confidence
ANOVA_MODEL   = 'linear';  % linear|interaction|full


XBINS = [0 2 4 6];  % bins for distance, 0-2,2-4,6-inf.

datAnov = cell(1,length(XBINS));
datDist = cell(1,length(XBINS));
facSess = cell(1,length(XBINS));
facSubj = cell(1,length(XBINS));
facArea = cell(1,length(XBINS));
facStim = cell(1,length(XBINS));

fprintf('%s: depanovan %s/%s...\n',gettimestring,SigName,Method);
% load data and label them.
for iSes = 1:length(SessGrps);
  if isempty(SessGrps{iSes}),    continue;  end
  if isempty(SessGrps{iSes}{1}), continue;  end
  Ses = goto(SessGrps{iSes}{1});
  % get session and subject(animal) name.
  sess = lower(Ses.name);
  subj = lower(Ses.name(1:3));
  fprintf('  %s:',sess);
  for iGrp = 1:length(SessGrps{iSes}{2}),
    grp = getgrp(Ses,SessGrps{iSes}{2}{iGrp});
    Sig = sigload(Ses,grp.name,SigName);
    fprintf(' %s',grp.name);
    if isstruct(Sig), Sig = { Sig };  end
    for iSig = 1:length(Sig),
      % get area name of the signal.
      area = subGetAreaName(Sig{iSig});
      if isempty(area), continue;  end
      % get stimulus type.
      stim = subGetStimName(Sig{iSig});
      if isempty(stim), continue;  end
      % gruop data by distnace.
      [tmpdat,tmpx] = subBinData(Sig{iSig},XBINS, Method);
      for iDist = 1:length(tmpdat),
        if isempty(tmpdat{iDist}),  continue;  end
        len = length(tmpdat{iDist});
        datAnov{iDist} = cat(1,datAnov{iDist},tmpdat{iDist});
        datDist{iDist} = cat(1,datDist{iDist},tmpx{iDist});
        facSess{iDist} = [facSess{iDist}, repmat({sess},1,len)];
        facSubj{iDist} = [facSubj{iDist}, repmat({subj},1,len)];
        facArea{iDist} = [facArea{iDist}, repmat({area},1,len)];
        facStim{iDist} = [facStim{iDist}, repmat({stim},1,len)];
      end
    end
  end
  fprintf('\n');
end


fprintf(' anaovan: ...');
% Do N-way ANOVA
STAT = {};
STAT.alpha   = ANOVA_ALPHA;
STAT.model   = ANOVA_MODEL;
STAT.distbin = XBINS;
STAT.ndata   = zeros(1,length(XBINS));
STAT.p       = cell(1,length(XBINS));
STAT.factor  = cell(1,length(XBINS));
STAT.table   = cell(1,length(XBINS));
STAT.stats   = cell(1,length(XBINS));
for iDist = 1:length(XBINS),
  tmpData = datAnov{iDist};
  tmpSess = facSess{iDist};
  tmpSubj = facSubj{iDist};
  tmpArea = facArea{iDist};
  tmpStim = facStim{iDist};
  if isempty(tmpData),  continue;  end
  
  %tmpfac = {tmpSess,tmpSubj};
  %facstr = {'session','subject'};
  tmpfac = {tmpSess};
  facstr = {'session'};
  %tmpfac = {tmpSubj};
  %facstr = {'subject'};
  if length(unique(tmpArea)) > 1,
    tmpfac = cat(2,tmpfac,{tmpArea});
    facstr = cat(2,facstr,{'area'});
  end
  if length(unique(tmpStim)) > 1,
    tmpfac = cat(2,tmpfac,{tmpStim});
    facstr = cat(2,facstr,{'stim'});
  end
  vnames = {};
  for N = 1:length(facstr),
    vnames{N} = sprintf('X%s',facstr{N});
  end
  
  %!!!!!!!!!!!!
  % 23.07.04 YM,
  % session is a subgoup of subject, so it doen't give all combination for
  % ANOVA, resulting 0 degree of freedom.....
  % so we may need to do one by one.
  [p,table,stats] = anovan(tmpData,tmpfac,...
                           'varnames',vnames,'display',ANOVA_DISPLAY,...
                           'alpha',ANOVA_ALPHA,'model',ANOVA_MODEL);

  STAT.ndata(iDist) = length(tmpData);
  STAT.p{iDist} = p;
  STAT.factor   = facstr;  % should always be the same.
  STAT.table{iDist} = table;
  STAT.stats{iDist} = stats;
end
fprintf(' done.\n');


DATA = {};
DATA.distbin = XBINS;
DATA.dat = datAnov;
DATA.dist = datDist;
DATA.factor = facstr;
DATA.fac.session = facSess;
DATA.fac.subject = facSubj;
DATA.fac.area    = facArea;
DATA.fac.stim    = facStim;


if nargout,
  varargout{1} = DATA;
  if nargout > 1,
    varargout{2} = STAT;
  end
  return;
end


% just prints/plots out result
col = 'brgymbrgmb';
tmptitle = sprintf('depanovan RESULTS for "%s" "%s"\n',SigName,Method);
figure('Name',tmptitle,'pos',[0 0 750 300]);
fprintf('depanovan RESULTS for "%s" "%s"\n',SigName,Method);
for iDist = 1:length(XBINS),
  fprintf(' ==========================================\n');
  if iDist == length(XBINS),
    fprintf(' Dist = %.2f-Inf.mm',XBINS(iDist));
  else
    fprintf(' Dist = %.2f-%.2fmm',XBINS(iDist),XBINS(iDist+1));
  end
  fprintf(',  Ndata = %d\n',STAT.ndata(iDist));
  if STAT.ndata(iDist) == 0,  continue;  end
  for iFac = 1:length(STAT.factor),
    fprintf(' X%s\tP=%.4f\n',STAT.factor{iFac},STAT.p{iDist}(iFac));
  end

  for iFac = 1:length(DATA.factor),
    subplot(1,length(DATA.factor),iFac);
    pars = DATA.fac.(DATA.factor{iFac}){iDist};
    upar = unique(pars);
    for iPar = 1:length(upar),
      idx = find(strcmp(pars,upar{iPar}));
      tmpx = DATA.dist{iDist}(idx);
      tmpy = DATA.dat{iDist}(idx);
      plot(tmpx,tmpy,'linestyle','none',...
           'marker','.','markersize',12,'color',col(iPar));
      hold on;
      tmptxt = sprintf('P=%.4f',STAT.p{iDist}(iFac));
      text(0,1.0-0.05*iDist,tmptxt,'units','normalized',...
           'FontSize',8,'FontName','Comic Sans MS');
    end
    if iDist == 1,
      hLegend(iFac) = legend(upar,'location','NorthEast');
      legend('boxoff');
    end
  end
end


for iDist = 1:length(XBINS),
  for iFac = 1:length(DATA.factor),
    subplot(1,length(DATA.factor),iFac);
    set(gca,'FontName','Comic Sans MS');
    grid on;
    title(DATA.factor{iFac},'FontName','Comic Sans MS');
    ylim = get(gca,'ylim');
    line([XBINS(iDist),XBINS(iDist)],ylim,'color','k');
    xlabel('Distance in mm','FontName','Comic Sans MS');
    pars = DATA.fac.(DATA.factor{iFac}){iDist};
    %legend(unique(pars));
    set(hLegend(iFac),'FontName','Comic Sans MS','FontSize',8);
  end
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Dat,Dst] = subBinData(Sig,XBins,Method)

XBins(end+1) = 1000;  % add 1000mm to group far end.

dist = squeeze(Sig.dat(:,1,1));
XIdx = cell(1,length(XBins)-1);
Dat = cell(1,length(XBins)-1);
Dst = cell(1,length(XBins)-1);
iMethod = find(strcmpi(Sig.colnames,Method));
for N = 1:length(XBins)-1,
  tmpidx = find(dist >= XBins(N) & dist < XBins(N+1));
  if isempty(tmpidx),
    Dat{N} = [];
    Dst{N} = [];
  else
    % +1 for first-column as distance
    tmpdat = Sig.dat(tmpidx,iMethod+1,:);
    tmpdst = Sig.dat(tmpidx,1,:);
    % remove anoying NaN
    tmpidx = find(~isnan(tmpdat));
    tmpdat = tmpdat(:);
    tmpdat = tmpdat(tmpidx);
    tmpdst = tmpdst(:);
    tmpdst = tmpdst(tmpidx);
    if isempty(tmpdat),
      Dat{N} = [];
      Dst{N} = [];
    else
      Dat{N} = tmpdat;
      Dst{N} = tmpdst;
    end
    
  end
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% return area name of the signal
function area = subGetAreaName(Sig)
area = '';
if isfield(Sig,'name') && ~isempty(Sig.name),
  % imaging data.  use ROI name.
  switch upper(Sig.name),
   case { 'v1','V1' }
    area = 'V1';
   case { 'v2','V2' }
    area = 'V2';
   otherwise
    area = '';
  end
else
  % physiology data
  switch upper(Sig.session),
   case { 'C98NM3','G02NM1','G97NM1','C98NM1','R97NM1',...
          'C98NM2','A98NM1','S02NM1','B02NM2','E02NM1','J97NM1' }
    % xmovphys, V1
    area = 'V1';
   case { 'C01NM1','C01NM2' }
    % xmovphys, STS/IT
    area = 'STS/IT';
   otherwise
    fprintf(' depanovan.subGetAreaName error: unknown area for "%s".\n',...
            Sig.session);
    keyboard
  end
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% return stimulus name of the signal
function stim = subGetStimName(Sig)

stim = '';

if ~isempty(strfind(Sig.grpname,'mov')),
  stim = 'movie';
elseif ~isempty(strfind(Sig.grpname,'spo')),
  stim = 'spont';
elseif ~isempty(strfind(Sig.grpname,'base')),
  stim = 'spont';
elseif ~isempty(strfind(Sgi.grpname,'pol')),
  stim = 'periodic';
else
  fprintf(' depanovan.subGetStimName error: unknown stim for "%s.%s.\n',...
          Sig.session, Sig.grpname);
  keyboard
end

return;

