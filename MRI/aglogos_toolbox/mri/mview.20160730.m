function varargout = mview(varargin)
%MVIEW - Displays roiTs
%  MVIEW(SESSION,GRPNAME/EXPNO)
%  MVIEW(ROITS)  displays roiTs.
%
%  EXAMPLE :
%    mview('f01m91','polar1');
%    mview(roiTs);
%
%  NOTES :
%    This function assumes .ana as (x,y,z) as default.
%    Scaling of anatomy can be controlled by ANAP.mview.anascle in the description file.
%    ANAP.mview.anascale = [minv maxv gamma]
% 
%
%  VERSION :
%    0.90 26.10.05 YM   pre-release, modified from mnview().
%    0.91 29.10.05 YM   supports "light-box" mode.
%    0.92 31.10.05 YM   shows time course, bug fix
%    0.93 02.11.05 YM   supports "response" plot.
%    0.94 05.11.05 YM   supports "ALL" to plot all models.
%    0.95 28.11.05 YM   modified for GLM.
%    0.96 19.12.05 YM   supports .glmcontref of grp.refgrp as masking data.
%    0.97 21.12.05 YM   supports "hold on" to plot time courses.
%    0.98 03.01.06 YM   bug fix on grp.refgrp.
%    0.99 18.01.06 YM   supports Z-reverse
%    1.00 26.01.06 YM   supports troiTs if only a single trial.
%    1.01 28.01.06 YM   stops ploting "ALL" models to supports troiTs fully.
%    1.02 16.02.06 YM   supports ANAP.mview.anascale, shows time-couse even in lightbox.
%    1.03 23.02.06 YM   supports ANAP.mview.xxxxx as default parameters.
%    1.04 22.03.06 YM   supports "Negative Corr' check box, bug fix when image is a vector.
%    1.05 23.03.06 YM   supports drawing ROIs, bug fix on refgrp.reftrial of the same group.
%    1.06 26.03.06 YM   supports "base-align" for plotting time courses.
%    1.07 21.04.06 YM   keeps min-max values mofified by the user.
%    1.08 23.04.06 YM   validates group-name, if the groupname changed after creating ROITS.
%    1.09 08.07.06 YM   supports drawing ELEs.
%    1.10 21.02.07 YM   can select T(1) of time courses as zero or vol-TR.
%    1.11 16.03.07 YM   supports saving the current data as a mask.
%    1.12 28.03.07 YM   supports ANAP.mview.nrowncol_xxx.
%    1.13 22.05.07 NK   supports user-defined ROIs (PickArea)
%    1.14 04.12.07 YM   supports neg/pos selection for corr analysis.
%    1.15 01.04.08 YM   supports neg/pos time-course plot, improved 'PickArea'.
%    1.16 09.10.08 YM   supports 'Stim as 0'.
%    1.17 23.07.10 YM   mask.dat as int16 instead of int8.
%    1.18 24.09.10 YM   bug fix on 'Hold On'.
%    1.19 30.11.10 YM   supports tSNR masking, color-map, bug fix of twice-drawing.
%    1.20 06.12.10 YM   supports ANAP.mview.xslice/yslice/zslice for slice-selection.
%    1.21 07.12.10 YM   supports EPI-anatomy, improved drawing speed.
%    1.22 28.02.11 YM   supports mview(Ses,Grp,[SigName])
%    1.23 07.10.11 YM   supports ROITS{}.epiana.
%    1.24 01.02.12 YM   use sigfilename()/mroi_file().
%    1.25 01.02.12 YM   use glmload() if needed.
%    1.26 07.02.12 YM   supports .xform as a struct array.
%
%  See also ANALOAD ANAVIEW SETBACK SETFRONT MAREATS MROI GETSTIMINDICES MVOXSELECT

if nargin == 0,  help mview; return;  end

% execute callback function then return; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% DEFAULT CONTROL SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ANAP.mview.viewmode = 'lightbox-trans';
ANAP.mview.viewpage = 1;
ANAP.mview.xslice   = [];
ANAP.mview.yslice   = [];
ANAP.mview.zslice   = [];
ANAP.mview.roi      = 'all';
ANAP.mview.drawroi  = 0;
ANAP.mview.drawele  = 1;
ANAP.mview.anascale = [];
ANAP.mview.anascale_epi = [];
ANAP.mview.zreverse = 1;
ANAP.mview.colormap = 'AUTO';
ANAP.mview.tzero    = 0;  % starts time courses from time zero or not
ANAP.mview.errorbar = 0;  % show error-bar or not
ANAP.mview.nrowncol_cor   = []; % NRow and NCol for lightbox mode (coronal)
ANAP.mview.nrowncol_sag   = []; % NRow and NCol for lightbox mode (sagital)
ANAP.mview.nrowncol_trans = []; % NRow and NCol for lightbox mode (transverse)
% statistics
ANAP.mview.alpha      = 0.05;
ANAP.mview.statistics = 'glm';
ANAP.mview.datname   = 'response';
ANAP.mview.datname   = 'beta';
ANAP.mview.corana.model = 1;
ANAP.mview.corana.trial = 1;
ANAP.mview.glmana.model = 1;
ANAP.mview.glmana.trial = 1;
% color bar settings
ANAP.mview.corana.minmax   = [];
ANAP.mview.glmana.minmax   = [];
ANAP.mview.glmana.betaminmax = [];
ANAP.mview.response.minmax = [];
ANAP.mview.gamma    = 1.8;
% cluster settings
ANAP.mview.cluster  = 0;
ANAP.mview.clusterfunc = 'bwlabeln';
ANAP.mview.mcluster.B = 5;
ANAP.mview.mcluster.cutoff =  10;
ANAP.mview.mcluster3.B = 5;
ANAP.mview.mcluster3.cutoff =  round((2*(ANAP.mview.mcluster3.B-1)+1)^3*0.3);
ANAP.mview.spm_bwlabel.conn = 26;	% must be 6(surface), 18(edges) or 26(corners)
ANAP.mview.spm_bwlabel.minvoxels = ANAP.mview.spm_bwlabel.conn * 0.8;
ANAP.mview.bwlabeln.conn = 18;
ANAP.mview.bwlabeln.minvoxels = ANAP.mview.bwlabeln.conn * 0.8;
% misc
ANAP.mview.stimcolor = [0.88 0.92 0.88];  % color for stimulus period in TC plot.

ANAP.mview.colors = {[1 0 0], [0 1 0], [0 0 1], [1 0 1], [1 1 0],[0 1 1]} ;


% PREPARE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROITS = {};  ROI = {};

% called like mview(roiTs),
if isstruct(varargin{1}) && isfield(varargin{1},'session'),
  varargin{1} = { varargin{1} };
end
if isempty(ROITS) && iscell(varargin{1}),
  ROITS = varargin{1};
  if iscell(ROITS{1}),
    Ses = goto(ROITS{1}{1}.session);
    grp = getgrp(Ses,ROITS{1}{1}.ExpNo(1));
  else
    Ses = goto(ROITS{1}.session);
    grp = getgrp(Ses,ROITS{1}.ExpNo(1));
  end
  anap = getanap(Ses,grp);
  RoiFile = mroi_file(Ses,grp.grproi);
  if exist(RoiFile,'file'),
    ROI = load(RoiFile,grp.grproi);  ROI = ROI.(grp.grproi);
  end
end

% called like mview('demo')
if isempty(ROITS) && ischar(varargin{1}) && strcmpi(varargin{1},'demo'),
  varargout = mview('f01m91','polar1');
  return;
end

% called like mview(Ses,grp/expno,[SigName])
if isempty(ROITS),
  SigName = '';
  Ses = goto(varargin{1});
  if nargin < 2,
    fprintf('usage: %s(Ses,grp/expno,[SigName]), missing grpname or expno.\n',mfilename);
    return;
  end
  if nargin > 2,  SigName = varargin{3};  end
  grp = getgrp(Ses,varargin{2});
  anap = getanap(Ses,grp);
  if isempty(SigName),
    if isfield(anap,'gettrial') && anap.gettrial.status > 0,
      SigName = 'troiTs';
    else
      SigName = 'roiTs';
    end
  end
  ROITS = sigload(Ses,varargin{2},SigName);
  RoiFile = mroi_file(Ses,grp.grproi);
  if exist(RoiFile,'file'),
    ROI = load(RoiFile,grp.grproi);  ROI = ROI.(grp.grproi);
  end
else
  SigName = sub_signame(ROITS);
end

% OVERWRITE DEFAULT SETTING BY ANAP
if isfield(anap,'mview'),   ANAP.mview = sctmerge(ANAP.mview,anap.mview);  end


% To make compatible with troiTs, make roiTs as a cell array of cell array.
if ~iscell(ROITS{1}),
  for N = 1:length(ROITS),
    ROITS{N} = { ROITS{N} };
  end
end


% IF GROUPED DATA, THEN TAKE AVERAGES
for N = 1:length(ROITS),
  for T = 1:length(ROITS{N}),
    if ndims(ROITS{N}{T}.dat) == 3,
      ROITS{N}{T}.dat = mean(ROITS{N}{T}.dat,3);
    end
    if isfield(ROITS{N}{T},'r') && ~isempty(ROITS{N}{T}.r),
      for K = 1:length(ROITS{N}{T}.r),
        if ~isvector(ROITS{N}{T}.r{K}),
          ROITS{N}{T}.r{K} = mean(ROITS{N}{T}.r{K},2);
        end
        if ~isvector(ROITS{N}{T}.p{K}),
          ROITS{N}{T}.p{K} = mean(ROITS{N}{T}.p{K},2);
        end
      end
    end
  end
end


% MASKING BY "grp.refgrp"
refgrp = subGetRefGrp(grp);
if ~isempty(refgrp),
  ROITS = mroitsmask(ROITS);
end
clear refgrp;
if isfield(grp,'refgrp') && isfield(grp.refgrp,'reftrial') && ~isempty(grp.refgrp.reftrial) && grp.refgrp.reftrial > 0,
  reftrial = grp.refgrp.reftrial;
  for N = 1:length(ROITS),
    for T = 1:length(ROITS{N}),
      if T == reftrial,  continue;  end
      if isfield(ROITS{N}{reftrial},'r'),
        ROITS{N}{T}.r = ROITS{N}{reftrial}.r;
        ROITS{N}{T}.p = ROITS{N}{reftrial}.p;
      end
      if isfield(ROITS{N}{reftrial},'glmcont'),
        ROITS{N}{T}.glmcont = ROITS{N}{reftrial}.glmcont;
      end
    end
  end
  clear reftrial;
end



if isempty(ROITS),
  fprintf('\n%s ERROR: no way to get roiTs.\n',mfilename);
  return;
end



if isempty(ROITS{1}{1}.ana),
  tcImg = sigload(ROITS{1}{1}.session,ROITS{1}{1}.ExpNo(1),'tcImg');
  ROITS{1}{1}.ana = mean(tcImg.dat,4);
  clear tcImg;
end


EPIDIM = size(ROITS{1}{1}.ana);

% validate group-name, sometime the groupname changed after creating ROITS...
if ~any(strcmpi(getgrpnames(ROITS{1}{1}.session), ROITS{1}{1}.grpname)),
  tmpgrp = getgrp(ROITS{1}{1}.session,ROITS{1}{1}.ExpNo(1));
  for R = 1:length(ROITS),
    for T = 1:length(ROITS{R}),
      ROITS{R}{R}.grpname = tmpgrp.name;
    end
  end
  clear tmpgrp;
end


% prepare time series of all voxels
for T = 1:length(ROITS{1}),
  TCTRIAL{T}.session = ROITS{1}{T}.session;
  TCTRIAL{T}.grpname = ROITS{1}{T}.grpname;
  TCTRIAL{T}.ExpNo   = ROITS{1}{T}.ExpNo;
  TCTRIAL{T}.dat     = [];
  TCTRIAL{T}.dx      = ROITS{1}{T}.dx;
  TCTRIAL{T}.coords  = [];
  TCTRIAL{T}.stm     = ROITS{1}{T}.stm;
  TCTRIAL{T}.labels  = ROITS{1}{T}.stm.labels;
  TCTRIAL{T}.xlabel  = 'Time in seconds';
  TCTRIAL{T}.ylabel  = 'Arbitrary Units';
  if isfield(ROITS{1}{T},'xform') && isfield(ROITS{1}{T}.xform,'method'),
    switch lower(sub_find_xform(ROITS{1}{T}.xform)),
     case {'tosdu', 'sdu'}
      TCTRIAL{T}.ylabel = 'Amplitude in SDU';
     case {'percent'}
      TCTRIAL{T}.ylabel = 'Amplitude in % changes';
     case {'frac'}
      TCTRIAL{T}.ylabel = 'Amplitude in fraction';
     case {'zerobase'}
      TCTRIAL{T}.ylabel = 'Amplitude (zero-base)';
    end
  end
  if isfield(ROITS{1}{T},'mdl'),
    TCTRIAL{T}.mdl = ROITS{1}{T}.mdl;
  end
  for N = 1:length(ROITS),
    if N == 1,
      tmpdat    = ROITS{N}{T}.dat;
      tmpcoords = ROITS{N}{T}.coords;
    else
      tmpdat    = cat(2,tmpdat,ROITS{N}{T}.dat);
      tmpcoords = cat(1,tmpcoords,ROITS{N}{T}.coords);
    end
  end
  % avoid multiple data of the same voxel.
  tmpcoords = double(tmpcoords);
  idx = sub2ind(EPIDIM,tmpcoords(:,1),tmpcoords(:,2),tmpcoords(:,3));
  [uidx, m] = unique(idx);
  tmpdat = tmpdat(:,m);
  tmpcoords = tmpcoords(m,:);
  TCTRIAL{T}.dat = tmpdat;
  TCTRIAL{T}.coords = tmpcoords;
  TCTRIAL{T}.sub2ind = sub2ind(EPIDIM,tmpcoords(:,1),tmpcoords(:,2),tmpcoords(:,3));
end



% COMPUTE MEAN AMPLITUDE
HemoDelay = 2;  HemoTail = 5;
for T = 1:length(ROITS{1}),
  idx = getStimIndices(ROITS{1}{T},'noblank',HemoDelay,HemoTail,'verbose',0);
  if isempty(idx),  idx = 1:size(ROITS{1}{T}.dat,1);  end
  TCTRIAL{T}.amp    = mean(TCTRIAL{T}.dat(idx,:),1);
  TCTRIAL{T}.maxamp = max(TCTRIAL{T}.dat(idx,:),[],1);
  for N = 1:length(ROITS),
    ROITS{N}{T}.amp    = mean(ROITS{N}{T}.dat(idx,:),1);
    ROITS{N}{T}.maxamp = max(ROITS{N}{T}.dat(idx,:),[],1);
  end
end


% FIX .ds problem
if ndims(ROITS{1}{1}.ana) ~= length(ROITS{1}{1}.ds) || length(ROITS{1}{1}.ds) ~= 3,
  par = expgetpar(Ses,ROITS{1}{1}.ExpNo(1));
  if size(ROITS{1}{1}.ana,3) == 1,
    %dz = par.pvpar.acqp.IMND_slice_thick;
    dz = par.pvpar.slithk;
  else
    dz = par.pvpar.acqp.IMND_slice_sepn(1);
  end
  for N = 1:length(ROITS),
    for T = 1:length(ROITS{N}),
      ROITS{N}{T}.ds(3) = dz;
    end
  end
end


% converts ANA.dat into RGB
if isfield(ROITS{1}{1},'epiana') && any(ROITS{1}{1}.epiana),
  ANA.dat = ROITS{1}{1}.ana;
  ANA.ds  = ROITS{1}{1}.ds;
else
  %ANA = anaload(ROITS{1}{1}.session,ROITS{1}{1}.grpname);
  ANA = anaload(ROITS{1}{1}.session,ROITS{1}{1}.ExpNo(1));
end

if isempty(ANA),
  % likely memory problem, ImgDistort=1, huge roiTs...
  ANA.dat = ROITS{1}{1}.ana;
  ANA.ds  = ROITS{1}{1}.ds;
end
ANA.ds(3) = ROITS{1}{1}.ds(3);
tmpana   = double(ANA.dat);
anaminv  = 0;
anamaxv  = 0;
anagamma = 1.8;
if ~isempty(ANAP.mview.anascale),
  if length(ANAP.mview.anascale) == 1,
    anamaxv = ANAP.mview.anascale(1);
  else
    anaminv = ANAP.mview.anascale(1);
    anamaxv = ANAP.mview.anascale(2);
    if length(ANAP.mview.anascale) > 2,
      anagamma = ANAP.mview.anascale(3);
    end
  end
end
if anamaxv == 0,
  tmpv = nanmean(tmpana(:));
  if tmpv > 100,
    anamaxv = round(tmpv*3.5/100)*100;
  else
    anamaxv = tmpv;
  end
end
ANA.rgb = subScaleAnatomy(ANA.dat,anaminv,anamaxv,anagamma);
ANA.scale = [anaminv anamaxv anagamma];
ANA.episcale = size(ANA.dat)./size(ROITS{1}{1}.ana);
if length(ANA.episcale) < 3,  ANA.episcale(3) = 1;  end
clear tmpana anaminv anamaxv anagamma anacmap;


% Make EPI anatomy
EPIANA.dat = ROITS{1}{1}.ana;
EPIANA.ds  = ROITS{1}{1}.ds;
EPIANA.episcale = [1 1 1];
tmpana   = double(EPIANA.dat);
anaminv  = 0;
anamaxv  = 0;
anagamma = 1.8;
if ~isempty(ANAP.mview.anascale_epi),
  if length(ANAP.mview.anascale_epi) == 1,
    anamaxv = ANAP.mview.anascale_epi(1);
  else
    anaminv = ANAP.mview.anascale_epi(1);
    anamaxv = ANAP.mview.anascale_epi(2);
    if length(ANAP.mview.anascale_epi) > 2,
      anagamma = ANAP.mview.anascale_epi(3);
    end
  end
end
if anamaxv == 0,
  tmpv = nanmean(tmpana(:));
  if tmpv > 100,
    anamaxv = round(tmpv*3.5/100)*100;
  else
    anamaxv = tmpv;
  end
end
EPIANA.rgb = subScaleAnatomy(EPIANA.dat,anaminv,anamaxv,anagamma);
EPIANA.scale = [anaminv anamaxv anagamma];
clear tmpana anaminv anamaxv anagamma anacmap;




% ADD SOME INFO TO ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(ROI),
  ROI.roinames = Ses.roi.names;
  ROI.pxscale = 1/ANA.episcale(1);
  ROI.pyscale = 1/ANA.episcale(2);
end


% GET SCREEN SIZE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[scrW scrH] = subGetScreenSize('char');

% 288x60.3 char. for 1440x900 pixels.
%figW = 175; figH = 55;
figW = 185; figH = 57;
figX = 91;  figY = scrH-figH-15;
if isfield(ANAP.mview,'figdims'),
  figX = ANAP.mview.figdims(1); figY = ANAP.mview.figdims(2);
  figW = ANAP.mview.figdims(3); figH = ANAP.mview.figdims(4);
end;


%[figX figY figW figH]

tmptitle = sprintf('%s: SES=''%s'' GRP=''%s''',mfilename,ROITS{1}{1}.session,ROITS{1}{1}.grpname);
if length(ROITS{1}{1}.ExpNo) == 1,
  tmptitle = sprintf('%s ExpNo=%d',tmptitle,ROITS{1}{1}.ExpNo);
else
  tmptitle = sprintf('%s NumExps=%d',tmptitle,length(ROITS{1}{1}.ExpNo));
end
if ~isempty(SigName),
  tmptitle = sprintf('%s SIG=%s',tmptitle,SigName);
end



% CREATE A MAIN FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hMain = figure(...
    'Name',tmptitle,...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');



% WIDGETS TO SELECT ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 7; H = figH - 2.5;
RoiTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','ROI:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','RoiTxt',...
    'BackgroundColor',get(hMain,'Color'));
roinames = {};
for N = 1:length(ROITS),  roinames{N} = ROITS{N}{1}.name;  end
roinames = unique(roinames);
roinames = { 'ALL', roinames{:} };
idx = find(strcmpi(roinames,ANAP.mview.roi));
if isempty(idx),
  fprintf('WARNING %s: roi ''%s'' not found.\n',mfilename,ANAP.mview.roi);
  idx = 1;
end
RoiCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+8.5 H 22 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''select-stat'',guidata(gcbo))',...
    'String',roinames,'Value',idx(1),'Tag','RoiCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select ROI(s) to plot',...
    'FontWeight','Bold');
clear roinames idx;
% Pick Area Combo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PickAreaCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+32 H 22 1.5],...
    'Callback','mview(''ROI_Callback'',gcbo,''roi-action'',guidata(gcbo))',...
    'String',{'--- PickArea ---','Append','Replace','Delete','Coordinate'},'Value',1,...
    'Tag','PickAreaCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select PickArea action',...
    'FontWeight','Bold');


% CHECK BOX FOR "draw-roi" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DrawRoiCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+65 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''toggle-drawrois'',guidata(gcbo))',...
    'Tag','DrawRoiCheck','Value',ANAP.mview.drawroi,...
    'String','DrawROI','FontWeight','bold',...
    'TooltipString','draw ROIs','BackgroundColor',get(hMain,'Color'));
% CHECK BOX FOR "draw-ele" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DrawEleCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+80 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''toggle-draweles'',guidata(gcbo))',...
    'Tag','DrawEleCheck','Value',ANAP.mview.drawele,...
    'String','ELE','FontWeight','bold',...
    'TooltipString','draw ELEs','BackgroundColor',get(hMain,'Color'));
% Superimpose or not %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OverlayCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+103 H 20 1.5],...
    'Tag','OverlayCheck','Value',1,...
    'Callback','mview(''Main_Callback'',gcbo,''redraw-image'',guidata(gcbo))',...
    'String','Map Overlay','FontWeight','bold',...
    'TooltipString','map on/off','BackgroundColor',get(hMain,'Color'));

% MASING OF BLACK REGIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MaskBlackCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+130 H 20 1.5],...
    'Tag','MaskBlackCheck','Value',0,...
    'Callback','mview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String','Black-mask','FontWeight','bold',...
    'TooltipString','Mask black regrions','BackgroundColor',get(hMain,'Color'));

% Masking by tSNR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MaskBySnrCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+147 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'Tag','MaskBySnrCheck','Value',0,...
    'String','tSNR-mask','FontWeight','bold',...
    'TooltipString','mask by tSNR','BackgroundColor',get(hMain,'Color'));
MaskBySnrEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+164 H 8 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String','40','Tag','MaskBySnrEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','tSNR for masking',...
    'FontWeight','Bold');

if isfield(ROITS{1}{1},'snr') && ~isempty(ROITS{1}{1}.snr),
  set(MaskBySnrCheck,'Enable','on');
  set(MaskBySnrEdt,  'Enable','on');
else
  set(MaskBySnrCheck,'Enable','off');
  set(MaskBySnrEdt,  'Enable','off');
end




% P-value %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 7; H = figH - 4.5;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','STAT:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','PvalueTxt',...
    'BackgroundColor',get(hMain,'Color'));
AlphaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+8.5 H 22 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String',num2str(ANAP.mview.alpha),'Tag','AlphaEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','alpha for significance level',...
    'FontWeight','Bold');
% WIDGETS TO SELECT STATISTICS/MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 7; H = figH - 4.5;
stats = {'none'};
if isfield(ROITS{1}{1},'r') && ~isempty(ROITS{1}{1}.r),  stats{end+1} = 'corr';  end
if isfield(ROITS{1}{1},'glmcont') && ~isempty(ROITS{1}{1}.glmcont),  stats{end+1} = 'glm';  end
idx = find(strcmpi(stats,ANAP.mview.statistics));
if isempty(idx),
  fprintf('WARNING %s: statistics ''%s'' not found.\n',mfilename,ANAP.mview.statistics);
  idx = 1;
end
StatCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+32 H 22 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''init-stat'',guidata(gcbo))',...
    'String',stats,'Value',idx,'Tag','StatCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select statistics to plot',...
    'FontWeight','Bold');
ModelCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+56 H 31 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''select-stat'',guidata(gcbo))',...
    'String',{'1'},'Value',1,'Tag','ModelCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select Model to plot',...
    'FontWeight','Bold');
trials = {};
if iscell(ROITS{1}),
  for N = 1:length(ROITS{1}),
    if isfield(ROITS{1}{N}.stm,'labels') && ~isempty(ROITS{1}{N}.stm.labels),
      trials{end+1} = sprintf('%d: %s',N,ROITS{1}{N}.stm.labels{1});
    else
      trials{end+1} = sprintf('%d',N);
    end
  end
  if length(ROITS{1}) > 1,  trials{end+1} = 'ALL';  end
else
  trials = {'1'};
end
if strcmpi(stats{idx},'corr'),
  tmptrial = ANAP.mview.corana.trial;
else
  tmptrial = ANAP.mview.glmana.trial;
end
if tmptrial < 1 || tmptrial > length(trials),
  fprintf('WARNING %s: trial is out of range ''%d''.\n',mfilename,tmptrial);
  tmptrial = 1;
end
TrialCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+89.2 H 31 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''redraw'',guidata(gcbo))',...
    'String',trials,'Value',tmptrial,'Tag','TrialCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select Trial to plot',...
    'FontWeight','Bold');
clear stats;
clear trials tmptrial;

% CLUSTER DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clusterfuncs = {'mcluster','mcluster3','spm_bwlabel','bwlabeln','unknown'};
idx = find(strcmpi(clusterfuncs,ANAP.mview.clusterfunc));
if isempty(idx),
  fprintf('WARNING %s: unknown cluster function ''%s''.\n',mfilename,ANAP.mview.clusterfunc);
  idx = 1;
end
ClusterCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+130 H 20 1.5],...
    'Tag','ClusterCheck','Value',ANAP.mview.cluster,...
    'Callback','mview(''Main_Callback'',gcbo,''edit-alpha'',guidata(gcbo))',...
    'String','Cluster','FontWeight','bold',...
    'TooltipString','Cluster detection','BackgroundColor',get(hMain,'Color'));
ClusterCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+147 H 25 1.5],...
    'String',clusterfuncs,'Tag','ClusterCmb','Value',idx,...
    'Callback','mview(''Main_Callback'',gcbo,''select-cluster'',guidata(gcbo))',...
    'TooltipString','Select a function for clustering',...
    'FontWeight','bold');
clear clusterfuncs idx;




% VIEW MODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
XDSP = 7; H = figH - 6.5;
ViewModeTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H-0.3 30 1.5],...
    'String','View:','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','PvalueTxt',...
    'BackgroundColor',get(hMain,'Color'));
ViewModeCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+8.5 H 22 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''view-mode'',guidata(gcbo))',...
    'String',{'orthogonal','lightbox-cor','lightbox-sag','lightbox-trans'},...
    'Tag','ViewModeCmb','Value',1,...
    'TooltipString','Select the view mode',...
    'FontWeight','bold','Background','white');
ViewPageCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+32 H 22 1.5],...
    'String',{'page1','page2','page3','page4'},...
    'Callback','mview(''Main_Callback'',gcbo,''view-page'',guidata(gcbo))',...
    'HorizontalAlignment','left',...
    'Tag','ViewPageCmb','Value',1,...
    'TooltipString','Select a page for lightbox',...
    'FontWeight','bold','Background','white');


% Slice selection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpidx = ANAP.mview.xslice > 0 & ANAP.mview.xslice <= size(ROITS{1}{1}.ana,1);
ANAP.mview.xslice = ANAP.mview.xslice(tmpidx);
if isempty(ANAP.mview.xslice),  ANAP.mview.xslice = 1:size(ROITS{1}{1}.ana,1);  end
if all(diff(ANAP.mview.xslice) == 1),
  tmpstr = sprintf('%d:%d',ANAP.mview.xslice(1),ANAP.mview.xslice(end));
else
  tmpstr = deblank(sprintf('%d ',ANAP.mview.xslice));
end
SliceXEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+56 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''edit-slicex'',guidata(gcbo))',...
    'String',tmpstr,'Tag','SliceXEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','slice(X) selection',...
    'FontWeight','Bold','Enable','off','Visible','off');
tmpidx = ANAP.mview.yslice > 0 & ANAP.mview.yslice <= size(ROITS{1}{1}.ana,2);
ANAP.mview.yslice = ANAP.mview.yslice(tmpidx);
if isempty(ANAP.mview.yslice),  ANAP.mview.yslice = 1:size(ROITS{1}{1}.ana,2);  end
if all(diff(ANAP.mview.yslice) == 1),
  tmpstr = sprintf('%d:%d',ANAP.mview.yslice(1),ANAP.mview.yslice(end));
else
  tmpstr = deblank(sprintf('%d ',ANAP.mview.yslice));
end
SliceYEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+56 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''edit-slicey'',guidata(gcbo))',...
    'String',tmpstr,'Tag','SliceYEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','slice(Y) selection',...
    'FontWeight','Bold','Enable','off','Visible','off');
tmpidx = ANAP.mview.zslice > 0 & ANAP.mview.zslice <= size(ROITS{1}{1}.ana,3);
ANAP.mview.zslice = ANAP.mview.zslice(tmpidx);
if isempty(ANAP.mview.zslice),  ANAP.mview.zslice = 1:size(ROITS{1}{1}.ana,3);  end
if all(diff(ANAP.mview.zslice) == 1),
  tmpstr = sprintf('%d:%d',ANAP.mview.zslice(1),ANAP.mview.zslice(end));
else
  tmpstr = deblank(sprintf('%d ',ANAP.mview.zslice));
end
SliceZEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+56 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''edit-slicez'',guidata(gcbo))',...
    'String',tmpstr,'Tag','SliceZEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','slice(Z) selection',...
    'FontWeight','Bold','Enable','off','Visible','off');


% Reverse Z axes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ZReverseCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+78 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''dir-reverse'',guidata(gcbo))',...
    'Tag','ZReverseCheck','Value',ANAP.mview.zreverse,...
    'String','Z-Reverse','FontWeight','bold',...
    'TooltipString','Zdir reverse','BackgroundColor',get(hMain,'Color'));

% ANATOMY SCALING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if round(ANA.scale(1)) == ANA.scale(1),
  anascale = sprintf('%d',ANA.scale(1));
else
  anascale = sprintf('%g',ANA.scale(1));
end
if round(ANA.scale(2)) == ANA.scale(2),
  anascale = sprintf('%s  %d',anascale,ANA.scale(2));
else
  anascale = sprintf('%s  %g',anascale,ANA.scale(2));
end
anascale = sprintf('%s  %.1f',anascale,ANA.scale(3));
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+95 H-0.3 50 1.5],...
    'String','AnaScale: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
AnaScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+107 H 20.2 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''update-anascale'',guidata(gcbo))',...
    'String',anascale,'Tag','AnaScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set anatomy scaling, [min max gamma]',...
    'FontWeight','bold');
if round(EPIANA.scale(1)) == EPIANA.scale(1),
  anascale = sprintf('%d',EPIANA.scale(1));
else
  anascale = sprintf('%g',EPIANA.scale(1));
end
if round(EPIANA.scale(2)) == EPIANA.scale(2),
  anascale = sprintf('%s  %d',anascale,EPIANA.scale(2));
else
  anascale = sprintf('%s  %g',anascale,EPIANA.scale(2));
end
anascale = sprintf('%s  %.1f',anascale,EPIANA.scale(3));
AnaScaleEpiEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+107 H 20.2 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''update-anascale'',guidata(gcbo))',...
    'String',anascale,'Tag','AnaScaleEpiEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set anatomy scaling, [min max gamma]',...
    'FontWeight','bold','visible','off');
clear anascale;



EpiAnaCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+130 H 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''epi-anatomy'',guidata(gcbo))',...
    'Tag','EpiAnaCheck','Value',0,...
    'String','EPI-ana','FontWeight','bold',...
    'TooltipString','use mean EPI as anatomy','BackgroundColor',get(hMain,'Color'));


% SCALE BAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ScaleBarCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+147 H 25 1.5],...
    'String',{'--- Scale Bar ---','2mm','4mm','5mm','10mm'},'Tag','ScaleBarCmb','Value',1,...
    'Callback','mview(''Main_Callback'',gcbo,''update-scalebar'',guidata(gcbo))',...
    'TooltipString','Select a scalebar length',...
    'FontWeight','bold');

% SAVE MASK BUTTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SaveMaskBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+130 H-2 42 1.5],...
    'String','Save as Mask','Tag','SaveMaskBtn',...
    'Callback','mview(''Main_Callback'',gcbo,''save-as-mask'',guidata(gcbo))',...
    'TooltipString','Save the current data as mask',...
    'FontWeight','bold');



% AXES for plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AXES FOR LIGHT BOX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 3; XSZ = 55; YSZ = 20;
XDSP = 7;
LightiboxAxs = axes(...
    'Parent',hMain,'Tag','LightboxAxs',...
    'Units','char','Position',[XDSP H XSZ*2+10 YSZ*2+6.5],...
    'Box','off','color','black','Visible','off');




% AXES FOR ORTHOGONL VIEW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 27.5; XSZ = 55; YSZ = 20;
XDSP = 7;
CoronalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 20 1.5],...
    'String','Coronal (X-Z)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','CoronalTxt',...
    'BackgroundColor',get(hMain,'Color'));
CoronalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+22 H+YSZ+0.2 8 1.5],...
    'Callback','mview(''OrthoView_Callback'',gcbo,''edit-coronal'',guidata(gcbo))',...
    'String','','Tag','CoronalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set coronal slice',...
    'FontWeight','Bold');
CoronalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','mview(''Main_Callback'',gcbo,''update-hold'',guidata(gcbo))',...
    'Tag','CoronalSldr','SliderStep',[1 4],...
    'TooltipString','coronal slice');
CoronalAxs = axes(...
    'Parent',hMain,'Tag','CoronalAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');
SagitalTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ H+YSZ 20 1.5],...
    'String','Sagital (Y-Z)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','SagitalTxt',...
    'BackgroundColor',get(hMain,'Color'));
SagitalEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+22 H+YSZ+0.2 8 1.5],...
    'Callback','mview(''OrthoView_Callback'',gcbo,''edit-sagital'',guidata(gcbo))',...
    'String','','Tag','SagitalEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set sagital slice',...
    'FontWeight','Bold');
SagitalSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+10+XSZ*1.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','mview(''Main_Callback'',gcbo,''update-hold'',guidata(gcbo))',...
    'Tag','SagitalSldr','SliderStep',[1 4],...
    'TooltipString','sagital slice');
SagitalAxs = axes(...
    'Parent',hMain,'Tag','SagitalAxs',...
    'Units','char','Position',[XDSP+10+XSZ H XSZ YSZ],...
    'Box','off','Color','black');

% CHECK BOX FOR "cross-hair" %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CrosshairCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+XSZ-15 H-3 20 1.5],...
    'Callback','mview(''OrthoView_Callback'',gcbo,''crosshair'',guidata(gcbo))',...
    'Tag','CrosshairCheck','Value',1,...
    'String','Crosshair','FontWeight','bold',...
    'TooltipString','show a crosshair','BackgroundColor',get(hMain,'Color'));


H = 3;
TransverseTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP H+YSZ 20 1.5],...
    'String','Transverse (X-Y)','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','TransverseTxt',...
    'BackgroundColor',get(hMain,'Color'));
TransverseEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+22 H+YSZ+0.2 8 1.5],...
    'Callback','mview(''OrthoView_Callback'',gcbo,''edit-transverse'',guidata(gcbo))',...
    'String','','Tag','TransverseEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set transverse slice',...
    'FontWeight','Bold');
TransverseSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[XDSP+XSZ*0.6 H+YSZ+0.2 XSZ*0.4 1.2],...
    'Callback','mview(''Main_Callback'',gcbo,''update-hold'',guidata(gcbo))',...
    'Tag','TransverseSldr','SliderStep',[1 4],...
    'TooltipString','transverse slice');
TransverseAxs = axes(...
    'Parent',hMain,'Tag','TransverseAxs',...
    'Units','char','Position',[XDSP H XSZ YSZ],...
    'Box','off','Color','black');


TCXSZ = XSZ + 52;
% TimeCourseTxt = uicontrol(...
%     'Parent',hMain,'Style','Text',...
%     'Units','char','Position',[XDSP+10+XSZ H+YSZ 20 1.5],...
%     'String','Voxel Time Course','FontWeight','bold',...
%     'HorizontalAlignment','left',...
%     'Tag','TimeCourseTxt',...
%     'BackgroundColor',get(hMain,'Color'));
TimeCourseCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10+XSZ H+YSZ+0.2 30 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''redraw-timecourse'',guidata(gcbo))',...
    'String',{'Voxel Time Course','Distribution (mean)','Distribution (max)'},...
    'Value',1,'Tag','TimeCourseCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select statistics to plot',...
    'FontWeight','Bold');
TimeCourseAxs = axes(...
    'Parent',hMain,'Tag','TimeCourseAxs',...
    'Units','char','Position',[XDSP+10+XSZ H TCXSZ YSZ],...
    'Box','off','color','white');
TCHoldCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+TCXSZ-12 H+YSZ 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''update-hold'',guidata(gcbo))',...
    'Tag','TCHoldCheck','Value',0,...
    'String','Hold On','FontWeight','bold',...
    'TooltipString','hold on/off','BackgroundColor',get(hMain,'Color'));
BaseAlignCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+TCXSZ-32 H+YSZ 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''redraw-timecourse'',guidata(gcbo))',...
    'Tag','BaseAlignCheck','Value',0,...
    'String','base-align','FontWeight','bold',...
    'TooltipString','align baseline','BackgroundColor',get(hMain,'Color'));
ErrorbarCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+TCXSZ-32 H+YSZ+1.5 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''redraw-timecourse'',guidata(gcbo))',...
    'Tag','ErrorbarCheck','Value',ANAP.mview.errorbar,...
    'String','Errorbar','FontWeight','bold',...
    'TooltipString','show error-bar','BackgroundColor',get(hMain,'Color'));
TZeroCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+TCXSZ-12 H+YSZ+1.5 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''redraw-timecourse'',guidata(gcbo))',...
    'Tag','TZeroCheck','Value',ANAP.mview.tzero,...
    'String','T(1) as 0','FontWeight','bold',...
    'TooltipString','t(1) as 0','BackgroundColor',get(hMain,'Color'));
TStimCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+10+XSZ+TCXSZ-12 H+YSZ+3.0 20 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''redraw-timecourse'',guidata(gcbo))',...
    'Tag','TStimCheck','Value',ANAP.mview.tzero,...
    'String','Stim as 0','FontWeight','bold',...
    'TooltipString','stim as 0','BackgroundColor',get(hMain,'Color'));




% AXES FOR COLORBAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 27.5;
XDSP=XDSP+XSZ+7;
ColorbarAxs = axes(...
    'Parent',hMain,'Tag','ColorbarAxs',...
    'units','char','Position',[XDSP+10+XSZ+2 H XSZ*0.1 YSZ],...
    'FontSize',8,...
    'Box','off','YAxisLocation','left','XTickLabel',{},'XTick',[]);

% DATA FOR COLOR BAR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DataCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ-1.5 30 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''select-stat'',guidata(gcbo))',...
    'String',{'Response'},...
    'Tag','DataCmb','Value',1,...
    'TooltipString','Select data to plot',...
    'FontWeight','bold');

SelectValueCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10+XSZ+15 H+YSZ-3.5 30 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''select-stat'',guidata(gcbo))',...
    'String',{'positive','negative','pos+neg'},...
    'Tag','SelectValueCmb','Value',1,...
    'TooltipString','Select value to plot',...
    'FontWeight','bold');



% COLORBAR MIN-MAX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ColorbarMinMaxTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ-5.5 20 1.25],...
    'String','min-max: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
ColorbarMinMaxEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+27, H+YSZ-5.5 18 1.5],...
    'Callback','mview(''Plot_Callback'',gcbo,[],[])',...
    'String','','Tag','ColorbarMinMaxEdt',...
    'Callback','mview(''Main_Callback'',gcbo,''update-cmap-redraw'',guidata(gcbo))',...
    'HorizontalAlignment','center',...
    'TooltipString','set colorbar min max',...
    'FontWeight','Bold');

% COLORBAR GAMAMA SETTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ-7.5 20 1.25],...
    'String','gamma: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
GammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+10+XSZ+27, H+YSZ-7.5 18 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''update-cmap-redraw'',guidata(gcbo))',...
    'String',num2str(ANAP.mview.gamma),'Tag','GammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set a gamma value for color bar',...
    'FontWeight','bold');

% COLOR-MAP SETTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cmaps = {'AUTO','mri','autumn','winter','spring','summer','hot','cool','jet','hsv','bone','copper','pink','red256','green256','blue256','yellow256','cyan256','magenta256'};
idx = find(strcmpi(cmaps,ANAP.mview.colormap));
if isempty(idx),
  idx = 1;
end
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+10+XSZ+15, H+YSZ-9.5 20 1.25],...
    'String','colormap: ','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'BackgroundColor',get(hMain,'color'));
ColormapCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+10+XSZ+27 H+YSZ-9.5 18 1.5],...
    'Callback','mview(''Main_Callback'',gcbo,''update-cmap-redraw'',guidata(gcbo))',...
    'String',cmaps,'Value',idx,'Tag','ColormapCmb',...
    'TooltipString','Select colormap',...
    'FontWeight','bold');
clear cmaps idx;




% INFORMATION TEXT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
H = 27.5;
InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[XDSP+10+XSZ+15 H 30 8],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','InfoTxt','Background','white');



% get widgets handles at this moment
HANDLES = findobj(hMain);

% set colors
MAPCOLOR = ANAP.mview.colors ;
if isfield(ANAP.mview,'mapcolor'),
  MAPCOLOR = ANAP.mview.mapcolor ;
end
if ischar(MAPCOLOR),
  tmpcol = {} ;
  for N = 1:numel(MAPCOLOR),
    tmpcol{N} = MAPCOLOR(N) ;
  end
  MAPCOLOR = tmpcol ;
  clear tmpcol ;
end
if iscell(MAPCOLOR),
  for N = 1:numel(MAPCOLOR),
    if ischar(MAPCOLOR{N}),
      switch lower(MAPCOLOR{N}),
      case {'r','red'}
        MAPCOLOR{N} = [1 0 0] ;
      case {'g','green'}
        MAPCOLOR{N} = [0 1 0] ;
      case {'b','blue'}
        MAPCOLOR{N} = [0 0 1] ;
      case {'c','cyan'}
        MAPCOLOR{N} = [0 1 1] ;
      case {'m','magenta'}
        MAPCOLOR{N} = [1 0 1] ;
      case {'y','yellow'}
        MAPCOLOR{N} = [1 1 0] ;
      case {'k','black','w','white'}
        MAPCOLOR{N} = [1 1 1] ;
      otherwise
        error('%s: The character %s is not supported as a color identifier.',mfilename,MAPCOLOR{N}) ;
      end
    end
  end
end

% INITIALIZE THE APPLICATION
setappdata(hMain,'ROITS',ROITS);
setappdata(hMain,'TCTRIAL',TCTRIAL);
setappdata(hMain,'STATMAP',[]);
setappdata(hMain,'ANA',ANA);
setappdata(hMain,'EPIANA',EPIANA);
setappdata(hMain,'ANAP',ANAP);
setappdata(hMain,'MASKTHRESHOLD',nanmean(ROITS{1}{1}.ana(:))*0.7);
setappdata(hMain,'ROI',ROI);
setappdata(hMain,'PICKAREA',[]);
setappdata(hMain,'COLORS','rgbcmy');
setappdata(hMain,'MAPCOLOR',MAPCOLOR);
setappdata(hMain,'SIGNAME',SigName);
Main_Callback(SagitalAxs,'init');
set(hMain,'visible','on');



% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');

% CHANGE THE VIEW MODE IF NEEDED
if ~strcmpi(ANAP.mview.viewmode,'orthogonal'),
  ViewMode = get(ViewModeCmb,'String');
  idx = find(strcmpi(ViewMode,ANAP.mview.viewmode));
  if isempty(idx),
    fprintf('WARNING %s: unknown view-mode, ''%s''.\n',mfilename,ANAP.mview.viewmode);
  else
    set(ViewModeCmb,'Value',idx);
    if ~isempty(ANAP.mview.viewpage),
      ViewPages = get(ViewPageCmb,'String');
      if ANAP.mview.viewpage < 1 || ANAP.mview.viewpage > length(ViewPages),
        fprintf('WARNING %s: view-page out of range, ''%d''.\n',mfilename,ANAP.mview.viewpage);
      elseif ANAP.mview.viewpage > 1,
        set(ViewPageCmb,'Value',ANAP.mview.viewpage);
      end
    end
    Main_Callback(ViewModeCmb,'view-mode',[]);
  end
end


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get "refgrp" structure of the group
function refgrp = subGetRefGrp(grp,ROITS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refgrp = {};
if isfield(grp,'refgrp') && ~isempty(grp.refgrp),
  if isfield(grp.refgrp,'grpexp') && ~isempty(grp.refgrp.grpexp) && ~strcmpi(grp.refgrp.grpexp,grp.name),
    refgrp = grp.refgrp;
  end
end
if ~isempty(refgrp),
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SigName = sub_signame(ROITS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(ROITS),
  SigName = sub_signame(ROITS{1});
  return;
end

SigName = '';
if isfield(ROITS,'dir') && isfield(ROITS.dir,'dname'),
  SigName = ROITS.dir.dname;
end

return





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(hObject);

switch lower(eventdata),
 case {'init'}
  ANA  = getappdata(wgts.main,'ANA');
  ROITS = getappdata(wgts.main,'ROITS');
  MINV = -1;  MAXV = 1;
  % set min/max value for scaling
  set(wgts.ColorbarMinMaxEdt,'string',sprintf('%g  %g',MINV,MAXV));
  
  % set information text
  INFTXT = {};
  INFTXT{end+1} = sprintf('%s',ROITS{1}{1}.session);
  INFTXT{end+1} = sprintf('%s',ROITS{1}{1}.grpname);
  if isfield(ANA,'ExpNo') && length(ROITS{1}{1}.ExpNo) == 1,
    INFTXT{end+1} = sprintf('ExpNo=%d',ROITS{1}{1}.ExpNo);
  end
  szdat = size(ROITS{1}{1}.ana);
  INFTXT{end+1} = sprintf('[%d%s]',szdat(1),sprintf(' %d',szdat(2:end)));
  if isfield(ROITS{1}{1},'ds'),
    INFTXT{end+1} = sprintf('[%g%s]',ROITS{1}{1}.ds(1),sprintf(' %g',ROITS{1}{1}.ds(2:end)));
  end
  set(wgts.InfoTxt,'String',INFTXT);

  % initialize the statistical map
  Main_Callback(hObject,'init-stat',[]);
  
  % initialize view
  if nargin < 3,
    OrthoView_Callback(hObject(1),'init');
  else
    OrthoView_Callback(hObject(1),'init',handles);
  end
  if nargin < 3,
    LightboxView_Callback(hObject(1),'init');
  else
    LightboxView_Callback(hObject(1),'init',handles);
  end
  Main_Callback(hObject,'redraw',[]);
  
 case {'init-stat'}
  % INITIALIZE WIDGETS FOR THE SELECTED STATISTICS
  StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
  ROITS = getappdata(wgts.main,'ROITS');
  ANAP  = getappdata(wgts.main,'ANAP');
  DATNAME_IDX = 1;
  if isfield(ANAP.mview,'datname'),
    switch ANAP.mview.datname,
     case 'StatV',      DATNAME_IDX = 1;
     case 'beta',       DATNAME_IDX = 2;
     case 'Response',   DATNAME_IDX = 3;
     case 'tSNR',       DATNAME_IDX = 4;
    end;
  end;

  %grp = getgrp(ROITS{1}{1}.session,ROITS{1}{1}.grpname);
  grp = getgrp(ROITS{1}{1}.session,ROITS{1}{1}.ExpNo(1));
  switch lower(StatName),
   case {'corr'}
    models = {};
    for N = 1:length(ROITS{1}{1}.r),
      if isfield(grp,'corana') && length(grp.corana) == length(ROITS{1}{1}.r),
        models{end+1} = sprintf('%d: %s',N,grp.corana{N}.mdlsct);
      else
        models{end+1} = sprintf('%d',N);
      end
    end
    if ANAP.mview.corana.model > length(models),
      ANAP.mview.corana.model = 1;
    end
    set(wgts.ModelCmb,'String',models,'Value',ANAP.mview.corana.model);
    if isfield(ROITS{1}{1},'snr') && ~isempty(ROITS{1}{1}.snr),
      set(wgts.DataCmb,'String',{'R_value','Response','tSNR'},'Value',1);
    else
      set(wgts.DataCmb,'String',{'R_value','Response'},'Value',1);
    end
   case {'glm'}
    models = {};
    for N = 1:length(ROITS{1}{1}.glmcont),
      models{end+1} = sprintf('%d: %s',N,ROITS{1}{1}.glmcont(N).cont.name);
    end
    if ANAP.mview.glmana.model > length(models),
      ANAP.mview.glmana.model = 1;
    end
    set(wgts.ModelCmb,'String',models,'Value',ANAP.mview.glmana.model);
    if isfield(ROITS{1}{1},'snr') && ~isempty(ROITS{1}{1}.snr),
      set(wgts.DataCmb,'String',{'StatV','beta','Response','tSNR'},'Value',DATNAME_IDX);
    else
      set(wgts.DataCmb,'String',{'StatV','beta','Response'},'Value',DATNAME_IDX);
    end
   otherwise
    set(wgts.ModelCmb,'String',{'1'},'Value',1);
    if isfield(ROITS{1}{1},'snr') && ~isempty(ROITS{1}{1}.snr),
      set(wgts.DataCmb,'String',{'Response','tSNR'},'Value',1);
    else
      set(wgts.DataCmb,'String',{'Response'},'Value',1);
    end
  end
  Main_Callback(hObject,'select-stat',[]);  % redraw image only
  %Main_Callback(hObject,'redraw-timecourse',[]); % this is called already in Main_Callback(hObject,'select-stat',[])
  
 case {'init-statmap'}
  
  % PREPARE STATISTICAL MAP STRUCTURE
  ROITS = getappdata(wgts.main,'ROITS');
  alpha = str2double(get(wgts.AlphaEdt,'String'));
  RoiName = get(wgts.RoiCmb,'String');  RoiName = RoiName{get(wgts.RoiCmb,'Value')};
  StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
  ModelNo = get(wgts.ModelCmb,'String');  ModelNo = ModelNo{get(wgts.ModelCmb,'Value')};
  ModelNo = sscanf(ModelNo,'%d:');  ModelNo = ModelNo(1);
  
  if ~isempty(alpha),
    switch lower(StatName),
     case {'corr'}
      STATMAP = subGetStatCorr(ROITS,wgts,alpha,RoiName,ModelNo);
     case {'glm'}
      STATMAP = subGetStatGLM(ROITS,wgts,alpha,RoiName,ModelNo);
     otherwise
      STATMAP = subGetStatNull(ROITS,wgts,alpha,RoiName);
    end
    setappdata(wgts.main,'STATMAP',STATMAP);
  end
  
 case {'select-stat'}
  RoiName = get(wgts.RoiCmb,'String');  RoiName = RoiName{get(wgts.RoiCmb,'Value')};
  
  DATNAME = get(wgts.DataCmb,'String');
  DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
  ANAP = getappdata(wgts.main,'ANAP');
  switch lower(DATNAME),
   case {'statv','stat'}
    MINV = 0;   MAXV = 30;
    StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
    if strcmpi(StatName,'glm') && length(ANAP.mview.glmana.minmax) == 2,
      MINV = ANAP.mview.glmana.minmax(1);  MAXV = ANAP.mview.glmana.minmax(2);
    end
   case {'r_value','r-value','r'}
    MINV = -1;  MAXV = 1;
    if length(ANAP.mview.corana.minmax) == 2,
      MINV = ANAP.mview.corana.minmax(1);  MAXV = ANAP.mview.corana.minmax(2);
    end
   case {'amplitude','response'}
    MINV = -3;  MAXV = 3;
    if length(ANAP.mview.response.minmax) == 2,
      MINV = ANAP.mview.response.minmax(1);  MAXV = ANAP.mview.response.minmax(2);
    end
   case {'beta'}
    MINV = -3;  MAXV = 3;
    if length(ANAP.mview.glmana.betaminmax) == 2,
      MINV = ANAP.mview.glmana.betaminmax(1);  MAXV = ANAP.mview.glmana.betaminmax(2);
    end
   case {'tsnr','snr'}
    MINV = 0;  MAXV = 100;
   otherwise
    MINV = -3;  MAXV = 3;
  end
  MINMAX = getappdata(wgts.main,'MINMAX');
  if isfield(MINMAX,DATNAME),
    MINV = MINMAX.(DATNAME)(1);  MAXV = MINMAX.(DATNAME)(2);
  else
    MINMAX.(DATNAME) = [MINV MAXV];
    setappdata(wgts.main,'MINMAX',MINMAX);
  end
  
  % set min/max value for scaling
  set(wgts.ColorbarMinMaxEdt,'string',sprintf('%g  %g',MINV,MAXV));
  
  Main_Callback(hObject,'init-statmap',[]);
  Main_Callback(hObject,'update-cmap',[]);
  Main_Callback(hObject,'redraw-image',[]);
  Main_Callback(hObject,'redraw-timecourse',[]);
 
  
  
 case {'update-cmap'}
  tmpv = str2num(get(wgts.ColorbarMinMaxEdt,'String'));
  MINMAX = getappdata(wgts.main,'MINMAX');
  DATNAME = get(wgts.DataCmb,'String');
  DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
  if length(tmpv) ~= 2,
    MINV = MINMAX.(DATNAME)(1);
    MAXV = MINMAX.(DATNAME)(2);
    set(wgts.ColorbarMinMaxEdt,'String',sprintf('%g  %g',MINV,MAXV));
  else
    MINV = tmpv(1);  MAXV = tmpv(2);
    MINMAX.(DATNAME) = [MINV MAXV];
    setappdata(wgts.main,'MINMAX',MINMAX);
  end
  
  cmap = subGetColorMap(wgts);
  setappdata(wgts.main,'CMAP',cmap);
  % update tick for colorbar
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    ydat = (0:255)/255 * (MAXV - MINV) + MINV;
    set(wgts.main,'CurrentAxes',wgts.ColorbarAxs);
    colormap(cmap);
    set(GRAHANDLE.colorbar,'ydata',ydat);
    set(wgts.ColorbarAxs,'ylim',[MINV MAXV]);
  end

 case {'update-cmap-redraw'}
  Main_Callback(hObject,'update-cmap',[]);
  Main_Callback(hObject,'redraw-image',[]);
  
 case {'epi-anatomy'}
  if get(wgts.EpiAnaCheck,'value'),
    set(wgts.AnaScaleEdt,   'visible','off');
    set(wgts.AnaScaleEpiEdt,'visible','on');
  else
    set(wgts.AnaScaleEdt,   'visible','on');
    set(wgts.AnaScaleEpiEdt,'visible','off');
  end
  Main_Callback(hObject,'redraw-image',[]);
  
 case {'update-anascale'}
  if get(wgts.EpiAnaCheck,'value'),
    anascale = str2num(get(wgts.AnaScaleEpiEdt,'String'));
    if length(anascale) ~= 3,  return;  end
    ANA = getappdata(wgts.main,'EPIANA');
    if isempty(ANA),  return;  end
    ANA.rgb = subScaleAnatomy(ANA.dat,anascale(1),anascale(2),anascale(3));
    setappdata(wgts.main,'EPIANA',ANA);  clear ANA anascale;
  else
    anascale = str2num(get(wgts.AnaScaleEdt,'String'));
    if length(anascale) ~= 3,  return;  end
    ANA = getappdata(wgts.main,'ANA');
    if isempty(ANA),  return;  end
    ANA.rgb = subScaleAnatomy(ANA.dat,anascale(1),anascale(2),anascale(3));
    setappdata(wgts.main,'ANA',ANA);  clear ANA anascale;
  end
  Main_Callback(hObject,'redraw-image',[]);
  
 case {'edit-alpha'}
  alpha = str2double(get(wgts.AlphaEdt,'String'));
  if ~isempty(alpha),
    Main_Callback(hObject,'update-cmap',[]);
    Main_Callback(hObject,'init-statmap',[]);
    Main_Callback(hObject,'redraw',[]);
    %Main_Callback(hObject,'update-hold',[])
  end
  
 case {'select-cluster'}
  if get(wgts.ClusterCheck,'Value') > 0,
    Main_Callback(hObject,'edit-alpha',[]);
  end

 case {'clear-hold'}
  set(wgts.LightboxAxs,'UserData',[]) ; 
  delete(findobj(wgts.LightboxAxs,'Type','image'));
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  orient = {'sagital','coronal','transverse'} ;
  for N = 1:numel(orient),
    set(GRAHANDLE.(orient{N}),'UserData',[]) ;
  end
  set(wgts.TimeCourseAxs,'UserData',[]);
  if get(wgts.TCHoldCheck,'Value') > 0
    %delete(findobj(wgts.TimeCourseAxs,'Type','line'));
    delete(findobj(wgts.TimeCourseAxs,'Tag','tcdat'));
  else
    POS = get(wgts.TimeCourseAxs,'pos');
    delete(allchild(wgts.TimeCourseAxs));
    set(wgts.TimeCourseAxs,'pos',POS);
  end
    
 case {'update-hold'}
  Main_Callback(hObject,'clear-hold',[]);
  Main_Callback(hObject,'update-cmap',[]);
  Main_Callback(hObject,'redraw-image',[]);
  Main_Callback(hObject,'redraw-timecourse',[]);

  
 case {'redraw'}
  % UPDATES BOTH IMAGES AND TIME-COURSE PLOT
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'orthogonal'),
    OrthoView_Callback(hObject,'redraw',[]);
  else
    LightboxView_Callback(hObject,'redraw',[]);
  end
  % update time couse plot
  Main_Callback(hObject,'redraw-timecourse',[]);

 case {'toggle-drawrois'}
   if get(wgts.DrawRoiCheck,'Value'),
     onoff = 'on' ;
   else
     onoff = 'off' ;
   end
   hrois = findobj(wgts.main,'tag','ROI') ;
   for N = 1:numel(hrois),
     set(hrois(N),'Visible',onoff) ;
   end

 case {'toggle-draweles'}
   if get(wgts.DrawEleCheck,'Value'),
     onoff = 'on' ;
   else
     onoff = 'off' ;
   end
   hrois = findobj(wgts.main,'tag','ELE') ;
   for N = 1:numel(hrois),
     set(hrois(N),'Visible',onoff) ;
   end

 case {'redraw-image'}
  % UPDATES IMAGES ONLY
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'orthogonal'),
    OrthoView_Callback(hObject,'redraw',[]);
  else
    LightboxView_Callback(hObject,'redraw',[]);
  end

 case {'redraw-timecourse'}
  % update time couse plot
  PlotMode = get(wgts.TimeCourseCmb,'String');
  PlotMode = PlotMode{get(wgts.TimeCourseCmb,'Value')};
  switch lower(PlotMode),
   case {'voxel time course'}
    subPlotTimeCourse(wgts);
   case {'distribution (mean)'}
    subPlotDistribution(wgts,'amp');
   case {'distribution (max)'}
    subPlotDistribution(wgts,'maxamp');
   otherwise
    error(' ERROR %s: unsupported plotting mode, %s',mfilename,PlotMode);
  end
  
 case {'update-scalebar'}
  % UPDATES SCALEBAR
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if strcmpi(ViewMode,'orthogonal'),
    OrthoView_Callback(hObject,'update-scalebar',[]);
  else
    LightboxView_Callback(hObject,'update-scalebar',[]);
  end

 case {'view-mode'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  hL = [wgts.LightboxAxs wgts.ViewPageCmb wgts.SliceXEdt wgts.SliceYEdt wgts.SliceZEdt];
  hO = [wgts.CoronalTxt, wgts.CoronalEdt, wgts.CoronalSldr, wgts.CoronalAxs,...
        wgts.SagitalTxt, wgts.SagitalEdt, wgts.SagitalSldr, wgts.SagitalAxs,...
        wgts.TransverseTxt, wgts.TransverseEdt, wgts.TransverseSldr, wgts.TransverseAxs,...
        wgts.CrosshairCheck ];
  
  tmppos = get(wgts.TransverseAxs,'pos');
  tcy = tmppos(2);  tch = tmppos(4);
  
  if strcmpi(ViewMode,'orthogonal'),
    set(hL,'visible','off');
    set(findobj(hL),'visible','off');
    set(findobj(hL,'tag','ROI'),'visible','off');
    set(hO,'visible','on');
    h = findobj([wgts.CoronalAxs, wgts.SagitalAxs, wgts.TransverseAxs]);
    set(h,'visible','on');
    % change the size of TimeCourseAxs
    tmppos = get(wgts.SagitalAxs,'pos');
    tcx = tmppos(1);
    tmppos = get(wgts.TimeCourseAxs,'pos');
    tcw = tmppos(1)+tmppos(3)-tcx;
    set(wgts.TimeCourseAxs,'pos',[tcx tcy tcw tch]);
    %tmppos = get(wgts.TimeCourseTxt,'pos');
    %set(wgts.TimeCourseTxt,'pos',[tcx tmppos(2:4)]);
    tmppos = get(wgts.TimeCourseCmb,'pos');
    set(wgts.TimeCourseCmb,'pos',[tcx tmppos(2:4)]);

    hRoiPoly = findobj(wgts.TransverseAxs,'tag','ROI');
    if get(wgts.DrawRoiCheck,'value') > 0 && isempty(hRoiPoly),
      OrthoView_Callback(hObject,'redraw',[]);
    elseif get(wgts.DrawRoiCheck,'value') == 0 && ~isempty(hRoiPoly),
      delete(hRoiPoly);
    end
  else
    set(hL,'visible','on');
    set(findobj(hL),'visible','on');
    set(findobj(hL,'tag','ROI'),'visible','on');
    set(hO,'visible','off');
    h = findobj([wgts.CoronalAxs, wgts.SagitalAxs, wgts.TransverseAxs]);
    set(h,'visible','off');
    % change the size of TimeCourseAxs
    tmppos = get(wgts.ColorbarAxs,'pos');
    tcx = tmppos(1);
    tmppos = get(wgts.TimeCourseAxs,'pos');
    tcw = tmppos(1)+tmppos(3)-tcx;
    set(wgts.TimeCourseAxs,'pos',[tcx tcy tcw tch]);
    %tmppos = get(wgts.TimeCourseTxt,'pos');
    %set(wgts.TimeCourseTxt,'pos',[tcx tmppos(2:4)]);
    tmppos = get(wgts.TimeCourseCmb,'pos');
    set(wgts.TimeCourseCmb,'pos',[tcx tmppos(2:4)]);
    LightboxView_Callback(hObject,'init',[]);
  end
  Main_Callback(hObject,'update-hold',[]) ;

 case {'view-page'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if ~isempty(strfind(ViewMode,'lightbox')),
    LightboxView_Callback(hObject,'redraw',[]);
  end

 case {'edit-slicex'}
  ROITS = getappdata(wgts.main, 'ROITS');
  ANAP  = getappdata(wgts.main,'ANAP');
  if strcmpi(get(wgts.SliceXEdt,'String'),'all'),
    tmpsli = 1:size(ROITS{1}{1}.ana,1);
  else
    tmpsli = str2num(get(wgts.SliceXEdt,'String'));
    if isempty(tmpsli),
      tmpsli = 1:size(ROITS{1}{1}.ana,1);
      set(wgts.SliceXEdt,'String',sprintf('1:%d',size(ROITS{1}{1}.ana,1)));
    end
    if any(tmpsli < 1) || any(tmpsli > size(ROITS{1}{1}.ana,1)),
      tmpsli = tmpsli(tmpsli >= 1 & tmpsli <= size(ROITS{1}{1}.ana,1));
      if all(diff(tmpsli) == 1),
        tmpstr = sprintf('%d:%d',tmpsli(1),tmpsli(end));
      else
        tmpstr = deblank(sprintf('%d ',tmpsli));
      end
      set(wgts.SliceXEdt,'String',tmpstr);
    end
  end
  ANAP.mview.xslice = tmpsli;
  setappdata(wgts.main,'ANAP',ANAP);
  LightboxView_Callback(hObject,'init',[]);
 case {'edit-slicey'}
  ROITS = getappdata(wgts.main, 'ROITS');
  ANAP  = getappdata(wgts.main,'ANAP');
  if strcmpi(get(wgts.SliceYEdt,'String'),'all'),
    tmpsli = 1:size(ROITS{1}{1}.ana,2);
  else
    tmpsli = str2num(get(wgts.SliceYEdt,'String'));
    if isempty(tmpsli),
      tmpsli = 1:size(ROITS{1}{1}.ana,2);
      set(wgts.SliceZEdt,'String',sprintf('1:%d',size(ROITS{1}{1}.ana,2)));
    end
    if any(tmpsli < 1) || any(tmpsli > size(ROITS{1}{1}.ana,2)),
      tmpsli = tmpsli(tmpsli >= 1 & tmpsli <= size(ROITS{1}{1}.ana,2));
      if all(diff(tmpsli) == 1),
        tmpstr = sprintf('%d:%d',tmpsli(1),tmpsli(end));
      else
        tmpstr = deblank(sprintf('%d ',tmpsli));
      end
      set(wgts.SliceYEdt,'String',tmpstr);
    end
  end
  ANAP.mview.yslice = tmpsli;
  setappdata(wgts.main,'ANAP',ANAP);
  LightboxView_Callback(hObject,'init',[]);
 case {'edit-slicez'}
  ROITS = getappdata(wgts.main,'ROITS');
  ANAP  = getappdata(wgts.main,'ANAP');
  if strcmpi(get(wgts.SliceZEdt,'String'),'all'),
    tmpsli = 1:size(ROITS{1}{1}.ana,3);
  else
    tmpsli = str2num(get(wgts.SliceZEdt,'String'));
    if isempty(tmpsli),
      tmpsli = 1:size(ROITS{1}{1}.ana,3);
      set(wgts.SliceZEdt,'String',sprintf('1:%d',size(ROITS{1}{1}.ana,3)));
    end
    if any(tmpsli < 1) || any(tmpsli > size(ROITS{1}{1}.ana,3)),
      tmpsli = tmpsli(tmpsli >= 1 & tmpsli <= size(ROITS{1}{1}.ana,3));
      if all(diff(tmpsli) == 1),
        tmpstr = sprintf('%d:%d',tmpsli(1),tmpsli(end));
      else
        tmpstr = deblank(sprintf('%d ',tmpsli));
      end
      set(wgts.SliceZEdt,'String',tmpstr);
    end
  end
  ANAP.mview.zslice = tmpsli;
  setappdata(wgts.main,'ANAP',ANAP);
  LightboxView_Callback(hObject,'init',[]);
  
 case {'dir-reverse'}
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  if ~isempty(strfind(ViewMode,'lightbox')),
    LightboxView_Callback(hObject,'redraw',[]);
  else
    OrthoView_Callback(hObject,'dir-reverse',[]);
  end
  
 case {'save-as-mask'}
  % PREPARE STATISTICAL MAP STRUCTURE
  TCTRIAL = getappdata(wgts.main, 'TCTRIAL');
  STATMAP = getappdata(wgts.main, 'STATMAP');
  if isempty(STATMAP), return;  end
  RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};
  StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
  ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};
  ModelNo = sscanf(ModelNo,'%d:');  ModelNo = ModelNo(1);
  TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
  if strcmpi(TrialNo,'all'),
    TrialNo = 1:length(TCTRIAL);
    fprintf('%s ERROR: select a single trial.\n',mfilename);
    return
  else
    TrialNo = sscanf(TrialNo,'%d:');
    % NKL to YM: CHECK THIS OUT (in different positions)
    % sscan does not work for labels like "1Hz Flicker"
    if length(TrialNo)>1, TrialNo=TrialNo(1); end;
  end
  BaseAlign = get(wgts.BaseAlignCheck,'value');
  T = TrialNo(1);
  idx = find(STATMAP{T}.mask.dat(:) > 0);
  if isempty(idx),
    fprintf('%s ERROR: no voxels, empty mask.\n',mfilename);
    return
  end
  [idx found] = intersect(TCTRIAL{T}.sub2ind,idx);
  tcdat = TCTRIAL{T}.dat(:,found);
  [x y z] = ind2sub(size(STATMAP{T}.dat),TCTRIAL{T}.sub2ind(found));
  if get(wgts.BaseAlignCheck,'value') > 0,
    baseidx = subGetPreStim(TCTRIAL{T},[-0.3 +0.3]);
    if ~isempty(baseidx),
      tmpm = mean(tcdat(baseidx,:),1);
      for V = 1:size(tcdat,2),  tcdat(:,V) = tcdat(:,V) - tmpm(V);  end
    end
  end
  MASK = rmfield(TCTRIAL{T},{'sub2ind','amp','maxamp'});
  MASK.dat    = tcdat;
  MASK.coords = [x(:),y(:),z(:)];
  MASK.name   = RoiName;
  MASK.slice  = -1;
  MASK.trial  = T;
  MASK.model  = sprintf('%s[%d]',StatName,ModelNo);
  %MASK

  matfile = sprintf('mask_%s_%s_%s.mat',MASK.session,MASK.grpname,MASK.model);
  if exist(matfile,'file'),
    [fname,fp] = uiputfile({'*.mat','MAT-files (*.mat)';'*.*','All Files (*.*)'},...
                           'Save Data As');
    if isequal(fname,0) || isequal(fp,0),  return;  end
    matfile = fullfile(fp,fname);
  end
  save(matfile,'MASK');
  
 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle orthogonal view
function ROI_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
ViewMode = get(wgts.ViewModeCmb,'String');
ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};

if get(wgts.PickAreaCmb,'Value') == 1,  return;  end
if ~strcmpi(ViewMode,'lightbox-trans') || ~strcmpi(eventdata,'roi-action'), 
  % set to 'no action'
  set(wgts.PickAreaCmb,'Value',1);
  return;
end

PICKAREA = getappdata(wgts.main,'PICKAREA');

RoiAction = get(wgts.PickAreaCmb,'String');
RoiAction = RoiAction{get(wgts.PickAreaCmb,'Value')};

switch lower(RoiAction),
 case {'coordinate'}
  set(wgts.PickAreaCmb,'Enable','off');
  tmpxy = ginput(1);
  set(wgts.PickAreaCmb,'Enable','on');
  [tmp epix epiy epiz] = subGetROI(wgts,[],tmpxy(1),tmpxy(2));
  if ~isempty(epix),
    fprintf('  XYZ=[%d %d %d]\n',epix,epiy,epiz);
  end
 
 case {'append','replace'}
  if strcmpi(RoiAction,'replace'),
    PICKAREA = [];
    setappdata(wgts.main,'PICKAREA',[]);
    delete(findobj(wgts.LightboxAxs,'tag','PickArea'));  drawnow;
  end
  % add ROIs now
  %LightboxView_Callback(hObject,'redraw',[]);
  %subPickArea(wgts);
  while 1,
    %set(wgts.main,'CurrentAxes',wgts.LightboxAxs);
    axes(wgts.LightboxAxs);
    [anamask,anax,anay] = roipoly_71;  % use Matlab 7.1's roipoly()
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'extend'),
      %fprintf('here');
      break;
    elseif strcmp(click,'alt'),
      %fprintf('here2');
      break;
    end;
    if length(anax) > 2,
      anamask = logical(anamask'); % transpose "mask"
      K = length(PICKAREA)+1;
      PICKAREA{K} = subGetROI(wgts,anamask,anax,anay);
      % draw the polygon
      hold on;
      set(wgts.main,'CurrentAxes',wgts.LightboxAxs);
      plot(anax,anay,'color',[0 1 0],'tag','PickArea');
      % put some text
      if K == 1
        text(max(get(gca,'xlim')),0,'PickArea:ON','tag','PickArea',...
             'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
             'HorizontalAlignment','right',...
             'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
      end
    end
  end
  setappdata(wgts.main,'PICKAREA',PICKAREA);
 
 case {'delete','clear'}
  setappdata(wgts.main,'PICKAREA',[]);
  delete(findobj(wgts.LightboxAxs,'tag','PickArea'));  drawnow;

 otherwise
  fprintf('WARNING %s: ROI_Callback() ''%s'' not supported yet.\n',mfilename,RoiAction);
end

% set to 'no action'
set(wgts.PickAreaCmb,'Value',1);

% update time courses
if ~strcmpi(RoiAction,'coordinate'),
  Main_Callback(hObject,'redraw-timecourse',[]);
end
  
return


       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle orthogonal view
function OrthoView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
if get(wgts.EpiAnaCheck,'value')
  ANA  = getappdata(wgts.main,'EPIANA');
else
  ANA  = getappdata(wgts.main,'ANA');
end
ROITS   = getappdata(wgts.main, 'ROITS');
TCTRIAL = getappdata(wgts.main, 'TCTRIAL');
STATMAP = getappdata(wgts.main, 'STATMAP');
MINMAX  = getappdata(wgts.main, 'MINMAX');
DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
MINV = MINMAX.(DATNAME)(1);  MAXV = MINMAX.(DATNAME)(2);
ALPHA   = str2double(get(wgts.AlphaEdt,'String'));
CMAP    = getappdata(wgts.main,'CMAP');
COLORS  = getappdata(wgts.main,'COLORS');
MAPCOLOR  = getappdata(wgts.main,'MAPCOLOR');
RoiName = get(wgts.RoiCmb,'String'); RoiName = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
TrialNo = get(wgts.TrialCmb,'String');  TrialNo = TrialNo{get(wgts.TrialCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};

switch lower(eventdata),
 case {'init'}
  iX = 1;  iY = 1;  iZ = 1;
  nX = size(ROITS{1}{1}.ana,1);  nY = size(ROITS{1}{1}.ana,2);  nZ = size(ROITS{1}{1}.ana,3);
  % set slider edit value
  set(wgts.SagitalEdt,   'String', sprintf('%d',iX));
  set(wgts.CoronalEdt,   'String', sprintf('%d',iY));
  set(wgts.TransverseEdt,'String', sprintf('%d',iZ));
  % set slider, add +0.01 to prevent error.
  set(wgts.SagitalSldr,   'Min',1,'Max',nX+0.01,'Value',iX);
  set(wgts.CoronalSldr,   'Min',1,'Max',nY+0.01,'Value',iY);
  set(wgts.TransverseSldr,'Min',1,'Max',nZ+0.01,'Value',iZ);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.SagitalSldr,   'SliderStep',[1, 2]/max(1,nX));
  set(wgts.CoronalSldr,   'SliderStep',[1, 2]/max(1,nY));
  set(wgts.TransverseSldr,'SliderStep',[1, 2]/max(1,nZ));
  

 
  cmap = subGetColorMap(wgts);
  setappdata(wgts.main,'CMAP',cmap);
  
  AXISCOLOR = [0.8 0.2 0.8];
  episcale = ANA.episcale;
  tmpx = (1:size(ANA.rgb,1))/episcale(1);
  tmpy = (1:size(ANA.rgb,2))/episcale(2);
  tmpz = (1:size(ANA.rgb,3))/episcale(3);

  % now draw images
  set(wgts.main,'CurrentAxes',wgts.SagitalAxs);
  tmpimg = squeeze(ANA.rgb(round(iX*episcale(1)),:,:,:));
  hSag = image(tmpy,tmpz,permute(tmpimg,[2 1 3]));
  set(hSag,...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  set(wgts.SagitalAxs,'tag','SagitalAxs');	% set this again, some will reset.
  %daspect([5 5 1]);
  set(wgts.main,'CurrentAxes',wgts.CoronalAxs);
  tmpimg = squeeze(ANA.rgb(:,round(iY*episcale(2)),:,:));
  hCor = image(tmpx,tmpz,permute(tmpimg,[2 1 3]));
  set(hCor,...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  set(wgts.CoronalAxs,'tag','CoronalAxs');  % set this again, some will reset.
  %daspect([5 5 1]);
  set(wgts.main,'CurrentAxes',wgts.TransverseAxs);
  tmpimg = squeeze(ANA.rgb(:,:,round(iZ*episcale(3)),:));
  hTra = image(tmpx,tmpy,permute(tmpimg,[2 1 3]));
  set(hTra,...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  set(wgts.TransverseAxs,'tag','TransverseAxs');	% set this again, some will reset.
  %daspect([5 5 1]);
  
  % now draw a color bar
  set(wgts.main,'CurrentAxes',wgts.ColorbarAxs);
  ydat = (0:255)/255 * (MAXV - MINV) + MINV;
  hColorbar = imagesc(1,ydat,(0:255)'); colormap(cmap);
  set(wgts.ColorbarAxs,'Tag','ColorbarAxs');  % set this again, some will reset.
  set(wgts.ColorbarAxs,'ylim',[MINV MAXV],...
                    'YAxisLocation','left','XTickLabel',{},'XTick',[],'Ydir','normal');
  
  haxs = [wgts.SagitalAxs, wgts.CoronalAxs, wgts.TransverseAxs];
  set(haxs,'fontsize',8,'xcolor',AXISCOLOR,'ycolor',AXISCOLOR);
  GRAHANDLE.sagital    = hSag;
  GRAHANDLE.coronal    = hCor;
  GRAHANDLE.transverse = hTra;
  GRAHANDLE.colorbar   = hColorbar;
  
  % draw crosshair(s)
  set(wgts.main,'CurrentAxes',wgts.SagitalAxs);
  hSagV = line([iY iY],[ 1-0.5 nZ+0.5],'color','y','tag','crosshair');
  hSagH = line([ 1-0.5 nY+0.5],[iZ iZ],'color','y','tag','crosshair');
  set([hSagV hSagH],...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
  set(wgts.main,'CurrentAxes',wgts.CoronalAxs);
  hCorV = line([iX iX],[ 1-0.5 nZ+0.5],'color','y','tag','crosshair');
  hCorH = line([ 1-0.5 nX+0.5],[iZ iZ],'color','y','tag','crosshair');
  set([hCorV hCorH],...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
  set(wgts.main,'CurrentAxes',wgts.TransverseAxs);
  hTraV = line([iX iX],[ 1-0.5 nY+0.5],'color','y','tag','crosshair');
  hTraH = line([ 1-0.5 nX+0.5],[iY iY],'color','y','tag','crosshair');
  set([hTraV hTraH],...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
  if get(wgts.CrosshairCheck,'Value') == 0,
    set([hSagV hSagH hCorV hCorH hTraV hTraH],'visible','off');
  end
  
  GRAHANDLE.sagitalV    = hSagV;
  GRAHANDLE.sagitalH    = hSagH;
  GRAHANDLE.coronalV    = hCorV;
  GRAHANDLE.coronalH    = hCorH;
  GRAHANDLE.transverseV = hTraV;
  GRAHANDLE.transverseH = hTraH;
  
  % time course
  set(wgts.main,'CurrentAxes',wgts.TimeCourseAxs);
  %tmpm = mean(TCTRIAL{1}.dat,2);
  %tmps = std(TCTRIAL{1}.dat,[],2)/sqrt(size(TCTRIAL{1}.dat,2));
  
  if get(wgts.TZeroCheck,'Value') > 0,
    tmpt = (0:size(TCTRIAL{1}.dat,1)-1)*TCTRIAL{1}.dx(1);
  else
    tmpt = (1:size(TCTRIAL{1}.dat,1))*TCTRIAL{1}.dx(1);
  end
  if get(wgts.TStimCheck,'Value') > 0 && isfield(TCTRIAL{1},'stm') && ~isempty(TCTRIAL{1}.stm),
    stimv = TCTRIAL{1}.stm.v{1};
    stimt = TCTRIAL{1}.stm.time{1};
    for K = 1:length(stimv),
      if any(strcmpi(TCTRIAL{1}.stm.stmpars.StimTypes{stimv(K)+1},{'blank','none','nostim'})),
        continue;
      else
        tmpt = tmpt - stimt(K);
        break;
      end
    end
  end
  
  %errorbar(tmpt,tmpm,tmps);
  set(gca,'Tag','TimeCourseAxs');
  set(gca,'fontsize',8,'xlim',[min([0 tmpt(1)]), tmpt(end)]);
  grid on;
  xlabel('Time (s)'); ylabel('Amplitude');
  set(gca,...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-timecourse'',guidata(gcbo))');
  

  setappdata(wgts.main,'GRAHANDLE',GRAHANDLE);
  OrthoView_Callback(hObject,'dir-reverse',[]);

 case {'redraw'}
  % update images
  OrthoView_Callback(hObject,'slider-sagital',[]);
  OrthoView_Callback(hObject,'slider-coronal',[]);
  OrthoView_Callback(hObject,'slider-transverse',[]);
  
 case {'slider-sagital'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if isempty(GRAHANDLE),  return;  end
  if isempty(STATMAP),    return;  end
  iX = round(get(wgts.SagitalSldr,'Value'));
  aX = round(iX/size(STATMAP{1}.dat,1)*size(ANA.dat,1));
  tmpimg = squeeze(ANA.rgb(aX,:,:,:));
  if get(wgts.OverlayCheck,'Value'),
    TrialNo = get(wgts.TrialCmb,'String');  TrialNo = TrialNo{get(wgts.TrialCmb,'Value')};
    delete(findobj(wgts.SagitalAxs,'tag','signif.voxel'));
    if strcmpi(TrialNo,'all'),
      for T = 1:length(STATMAP),
        tmps = squeeze(STATMAP{T}.dat(iX,:,:));
        tmpp = squeeze(STATMAP{T}.p(iX,:,:));
        tmpm = squeeze(STATMAP{T}.mask.dat(iX,:,:));
        idx = find(tmpm(:) == 0);
        tmps(idx) = 0;
        tmpp(idx) = 1;
        idx = find(tmpp(:) < ALPHA);
        if ~isempty(idx),
          set(wgts.main,'CurrentAxes',wgts.SagitalAxs);
          hold on;
          [tmpx tmpy] = ind2sub(size(tmpp),idx);

          tmpcol = MAPCOLOR(mod(M-1,length(MAPCOLOR))+1);
          if iscell(tmpcol),
            tmpcol = tmpcol{1} ;
          end
          tmph = plot(tmpx-(M-1)/4,tmpy-(M-1)/4,'marker','s','markersize',3,...
                      'markerfacecolor',tmpcol,'markeredgecolor',tmpcol,...
                      'linestyle','none','tag','signif.voxel');
          set(tmph,...
              'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-sagital'',guidata(gcbo))');
        end
      end
    else
      T = sscanf(TrialNo,'%d:');
      if length(T)>1, T=T(1); end;
      tmps = squeeze(STATMAP{T}.dat(iX,:,:));
      tmpp = squeeze(STATMAP{T}.p(iX,:,:));
      tmpm = squeeze(STATMAP{T}.mask.dat(iX,:,:));
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      tmpimg = subRoimerge('sagital',tmps,tmpp,MINV,MAXV,ALPHA,wgts,GRAHANDLE,tmpimg,ROITS,RoiName,StatName,ModelNo,TrialNo) ;
    end
  end
  set(GRAHANDLE.sagital,'cdata',permute(tmpimg,[2 1 3]));
  set(GRAHANDLE.coronalV,   'xdata',[iX iX]);
  set(GRAHANDLE.transverseV,'xdata',[iX iX]);
  set(wgts.SagitalEdt,'String',sprintf('%d',iX));
  
 case {'slider-coronal'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if isempty(GRAHANDLE),  return;  end
  if isempty(STATMAP),    return;  end
  iY = round(get(wgts.CoronalSldr,'Value'));
  aY = round(iY/size(STATMAP{1}.dat,2)*size(ANA.dat,2));
  tmpimg = squeeze(ANA.rgb(:,aY,:,:));
  if get(wgts.OverlayCheck,'Value'),
    TrialNo = get(wgts.TrialCmb,'String');  TrialNo = TrialNo{get(wgts.TrialCmb,'Value')};
    delete(findobj(wgts.CoronalAxs,'tag','signif.voxel'));
    if strcmpi(TrialNo,'all'),
      for T = 1:length(STATMAP),
        tmps = squeeze(STATMAP{T}.dat(:,iY,:));
        tmpp = squeeze(STATMAP{T}.p(:,iY,:));
        tmpm = squeeze(STATMAP{T}.mask.dat(:,iY,:));
        idx = find(tmpm(:) == 0);
        tmps(idx) = 0;
        tmpp(idx) = 1;
        idx = find(tmpp(:) < ALPHA);
        if ~isempty(idx),
          set(wgts.main,'CurrentAxes',wgts.CoronalAxs);
          hold on;
          [tmpx tmpy] = ind2sub(size(tmpp),idx);
          tmpcol = MAPCOLOR(mod(M-1,length(MAPCOLOR))+1);
          if iscell(tmpcol),
            tmpcol = tmpcol{1} ;
          end
          tmph = plot(tmpx-(M-1)/4,tmpy-(M-1)/4,'marker','s','markersize',3,...
                      'markerfacecolor',tmpcol,'markeredgecolor',tmpcol,...
                      'linestyle','none','tag','signif.voxel');
          set(tmph,...
              'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-coronal'',guidata(gcbo))');
        end
      end
    else
      T = sscanf(TrialNo,'%d:');
      if length(T)>1, T=T(1); end;
      tmps = squeeze(STATMAP{T}.dat(:,iY,:));
      tmpp = squeeze(STATMAP{T}.p(:,iY,:));
      tmpm = squeeze(STATMAP{T}.mask.dat(:,iY,:));
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      tmpimg = subRoimerge('coronal',tmps,tmpp,MINV,MAXV,ALPHA,wgts,GRAHANDLE,tmpimg,ROITS,RoiName,StatName,ModelNo,TrialNo) ;
    end
  end
  set(GRAHANDLE.coronal,'cdata',permute(tmpimg,[2 1 3]));
  set(GRAHANDLE.sagitalV,   'xdata',[iY iY]);
  set(GRAHANDLE.transverseH,'ydata',[iY iY]);
  set(wgts.CoronalEdt,'String',sprintf('%d',iY));
  
 case {'slider-transverse'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if isempty(GRAHANDLE),  return;  end
  if isempty(STATMAP),    return;  end
  iZ = round(get(wgts.TransverseSldr,'Value'));
  aZ = round(iZ/size(STATMAP{1}.dat,3)*size(ANA.dat,3));
  tmpimg = squeeze(ANA.rgb(:,:,aZ,:));
  if get(wgts.OverlayCheck,'Value'),
    TrialNo = get(wgts.TrialCmb,'String');  TrialNo = TrialNo{get(wgts.TrialCmb,'Value')};
    delete(findobj(wgts.TransverseAxs,'tag','signif.voxel'));
    if strcmpi(TrialNo,'all'),
      for T = 1:length(STATMAP),
        tmps = squeeze(STATMAP{T}.dat(:,:,iZ));
        tmpp = squeeze(STATMAP{T}.p(:,:,iZ));
        tmpm = squeeze(STATMAP{T}.mask.dat(:,:,iZ));
        idx = find(tmpm(:) == 0);
        tmps(idx) = 0;
        tmpp(idx) = 1;
        idx = find(tmpp(:) < ALPHA);
        if ~isempty(idx),
          set(wgts.main,'CurrentAxes',wgts.TransverseAxs);
          hold on;
          [tmpx tmpy] = ind2sub(size(tmpp),idx);
          tmpcol = MAPCOLOR(mod(T-1,length(MAPCOLOR))+1);
          tmph = plot(tmpx-(T-1)/4,tmpy-(T-1)/4,'marker','s','markersize',3,...
                      'markerfacecolor',tmpcol,'markeredgecolor',tmpcol,...
                      'linestyle','none','tag','signif.voxel');
          set(tmph,...
              'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-transverse'',guidata(gcbo))');
        end
      end
    else
      T = sscanf(TrialNo,'%d:');
      if length(T)>1, T=T(1); end;
      tmps = squeeze(STATMAP{T}.dat(:,:,iZ));
      tmpp = squeeze(STATMAP{T}.p(:,:,iZ));
      tmpm = squeeze(STATMAP{T}.mask.dat(:,:,iZ));
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      tmpimg = subRoimerge('transverse',tmps,tmpp,MINV,MAXV,ALPHA,wgts,GRAHANDLE,tmpimg,ROITS,RoiName,StatName,ModelNo,TrialNo) ;
    end
  end
  %delete(findobj(wgts.TransverseAxs,'tag','ROI'));
  delete(findobj(wgts.main,'tag','ROI'));
  if 1 || get(wgts.DrawRoiCheck,'value') == 1,
    ROI = getappdata(wgts.main,'ROI');
    haxs = wgts.TransverseAxs;
    RoiName = get(wgts.RoiCmb,'String');  RoiName = RoiName{get(wgts.RoiCmb,'Value')};
    OffsX = 0;  OffsY = 0;
    subDrawROIs(haxs,ROI,iZ,RoiName,COLORS,OffsX,OffsY,0,get(wgts.DrawRoiCheck,'Value'));
  end
  delete(findobj(wgts.main,'tag','ELE'));
  if 1 || get(wgts.DrawEleCheck,'value') == 1,
    ROI = getappdata(wgts.main,'ROI');
    haxs = wgts.TransverseAxs;
    RoiName = get(wgts.RoiCmb,'String');  RoiName = RoiName{get(wgts.RoiCmb,'Value')};
    OffsX = 0;  OffsY = 0;
    subDrawELEs(haxs,ROI,iZ,RoiName,COLORS,OffsX,OffsY,0,get(wgts.DrawEleCheck,'Value'));
  end
  
  
  set(GRAHANDLE.transverse,'cdata',permute(tmpimg,[2 1 3]));
  set(GRAHANDLE.sagitalH,   'ydata',[iZ iZ]);
  set(GRAHANDLE.coronalH,   'ydata',[iZ iZ]);
  set(wgts.TransverseEdt,'String',sprintf('%d',iZ));

 case {'update-scalebar'}
  % update scalebar
  haxs = [wgts.SagitalAxs wgts.CoronalAxs wgts.TransverseAxs];
  ScaleBar = get(wgts.ScaleBarCmb,'String');
  ScaleBar = ScaleBar{get(wgts.ScaleBarCmb,'Value')};
  ScaleBar = sscanf(ScaleBar,'%dmm');
  
  for N = 1:length(haxs),
    set(wgts.main,'CurrentAxes',haxs(N));
    delete(findobj(gca,'tag','ScaleBar'));
    delete(findobj(gca,'tag','ScaleBarTxt'));
    if ~isempty(ScaleBar) && ScaleBar > 0,
      MARGIN = 1;
      if N == 1,
        % Sagital
        DXmm = ANA.ds(2) * ANA.episcale(2);
        DYmm = ANA.ds(3) * ANA.episcale(3);
      elseif N == 2,
        % Coronal
        DXmm = ANA.ds(1) * ANA.episcale(1);
        DYmm = ANA.ds(3) * ANA.episcale(3);
      else
        % Transverse
        DXmm = ANA.ds(1) * ANA.episcale(1);
        DYmm = ANA.ds(2) * ANA.episcale(2);
      end
      tmpx = max(get(gca,'xlim'))-MARGIN;      tmpy = MARGIN;
      tmpw = ScaleBar/DXmm;  tmph = ScaleBar*0.15/DYmm;
      rectangle('Position',[tmpx-tmpw tmpy tmpw tmph],...
                'facecolor',[1.0 1.0 1.0],'linestyle','none','Tag','ScaleBar');
      text(tmpx-tmpw, tmpy, sprintf('%dmm ',ScaleBar),'tag','ScaleBarTxt',...
           'color',[0.9 0.9 0.5],'HorizontalAlignment','right',...
           'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
      tmpw = ScaleBar*0.15/DXmm;  tmph = ScaleBar/DYmm;
      rectangle('Position',[tmpx-tmpw tmpy tmpw tmph],...
                'facecolor',[1.0 1.0 1.0],'linestyle','none','Tag','ScaleBar');
    end
  end  
  
 case {'edit-sagital'}
  iX = str2double(get(wgts.SagitalEdt,'String'));
  if isempty(iX),
    iX = round(get(wgts.SagitalSldr,'Value'));
    set(wgts.SagitalEdt,'String',sprintf('%d',iX));
  else
    if iX < 0,
      iX = 1; 
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    elseif iX > size(STATMAP{1}.dat,1),
      iX = size(STATMAP{1}.dat,1);
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
    end
    set(wgts.SagitalSldr,'Value',iX);
    if ~get(wgts.TCHoldCheck,'Value'),
      OrthoView_Callback(hObject,'slider-sagital',[]);
    else
      Main_Callback(hObject,'update-hold',[]);
    end
  end
  
 case {'edit-coronal'}
  iY = str2double(get(wgts.CoronalEdt,'String'));
  if isempty(iY),
    iY = round(get(wgts.CoronalSldr,'Value'));
    set(wgts.CoronalEdt,'String',sprintf('%d',iY));
  else
    if iY < 0,
      iY = 1; 
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    elseif iY > size(STATMAP{1}.dat,1),
      iY = size(STATMAP{1}.dat,1);
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
    end
    set(wgts.CoronalSldr,'Value',iY);
    %OrthoView_Callback(hObject,'slider-coronal',[]);
    Main_Callback(hObject,'update-hold',[]);
  end
 
 case {'edit-transverse'}
  iZ = str2double(get(wgts.TransverseEdt,'String'));
  if isempty(iZ),
    iZ = round(get(wgts.TransverseSldr,'Value'));
    set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
  else
    if iZ < 0,
      iZ = 1; 
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    elseif iZ > size(STATMAP{1}.dat,1),
      iZ = size(STATMAP{1}.dat,1);
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
    end
    set(wgts.TransverseSldr,'Value',iZ);
    %OrthoView_Callback(hObject,'slider-transverse',[]);
    Main_Callback(hObject,'update-hold',[]);
  end

 case {'dir-reverse'}
  % note that image(),imagesc() reverse Y axies
  %Xrev = get(wgts.XReverseCheck,'Value');
  %Yrev = get(wgts.YReverseCheck,'Value');
  Zrev = get(wgts.ZReverseCheck,'Value');
  %if Xrev == 0,
  %  corX = 'normal';   traX = 'normal';
  %else
  %  corX = 'reverse';  traX = 'reverse';
  %end
  %if Yrev == 0,
  %  sagX = 'normal';   traY = 'reverse';
  %else
  %  sagX = 'reverse';  traY = 'normal';
  %end
  sagX = 'normal';  corX = 'normal';
  if Zrev == 0,
    sagY = 'reverse';  corY = 'reverse';
  else
    sagY = 'normal';   corY = 'normal';
  end
  set(wgts.SagitalAxs,   'xdir',sagX,'ydir',sagY);
  set(wgts.CoronalAxs,   'xdir',corX,'ydir',corY);
  %set(wgts.TransverseAxs,'xdir',traX,'ydir',traY);
 
 case {'crosshair'}
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  if ~isempty(GRAHANDLE),
    if get(wgts.CrosshairCheck,'value') == 0,
      set(GRAHANDLE.sagitalV,   'visible','off');
      set(GRAHANDLE.sagitalH,   'visible','off');
      set(GRAHANDLE.coronalV,   'visible','off');
      set(GRAHANDLE.coronalH,   'visible','off');
      set(GRAHANDLE.transverseV,'visible','off');
      set(GRAHANDLE.transverseH,'visible','off');
    else
      set(GRAHANDLE.sagitalV,   'visible','on');
      set(GRAHANDLE.sagitalH,   'visible','on');
      set(GRAHANDLE.coronalV,   'visible','on');
      set(GRAHANDLE.coronalH,   'visible','on');
      set(GRAHANDLE.transverseV,'visible','on');
      set(GRAHANDLE.transverseH,'visible','on');
    end
  end
  
 case {'button-sagital'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') && get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.SagitalAxs,'CurrentPoint'));
    iY = pt(1,1);  iZ = pt(1,2);
    if iY > 0 && iY <= size(ANA.dat,2),
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
      set(wgts.CoronalSldr,'Value',iY);
      %OrthoView_Callback(hObject,'slider-coronal',[]);
      Main_Callback(hObject,'update-hold',[]) ;
    end
    if iZ > 0 && iZ <= size(ANA.dat,3),
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
      set(wgts.TransverseSldr,'Value',iZ);
      %OrthoView_Callback(hObject,'slider-transverse',[]);
      Main_Callback(hObject,'update-hold',[]) ;
    end
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('sagital',wgts,ROITS);
  end
  
 case {'button-coronal'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') && get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.CoronalAxs,'CurrentPoint'));
    iX = pt(1,1);  iZ = pt(1,2);
    if iX > 0 && iX <= size(ANA.dat,1),
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
      set(wgts.SagitalSldr,'Value',iX);
      %OrthoView_Callback(hObject,'slider-sagital',[]);
      Main_Callback(hObject,'update-hold',[]) ;
    end
    if iZ > 0 && iZ <= size(ANA.dat,3),
      set(wgts.TransverseEdt,'String',sprintf('%d',iZ));
      set(wgts.TransverseSldr,'Value',iZ);
      %OrthoView_Callback(hObject,'slider-transverse',[]);
      Main_Callback(hObject,'update-hold',[]) ;
    end
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('coronal',wgts,ROITS);
  end

 case {'button-transverse'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'alt') && get(wgts.CrosshairCheck,'Value') == 1,
    pt = round(get(wgts.TransverseAxs,'CurrentPoint'));
    iX = pt(1,1);  iY = pt(1,2);
    if iX > 0 && iX <= size(ANA.dat,1),
      set(wgts.SagitalEdt,'String',sprintf('%d',iX));
      set(wgts.SagitalSldr,'Value',iX);
      %OrthoView_Callback(hObject,'slider-sagital',[]);
      Main_Callback(hObject,'update-hold',[]) ;
    end
    if iY > 0 && iY <= size(ANA.dat,2),
      set(wgts.CoronalEdt,'String',sprintf('%d',iY));
      set(wgts.CoronalSldr,'Value',iY);
      %OrthoView_Callback(hObject,'slider-coronal',[]);
      Main_Callback(hObject,'update-hold',[]) ;
    end
  elseif strcmpi(click,'open'),
    % double click
    subZoomIn('transverse',wgts,ROITS);
  end
  
 case {'button-timecourse'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    subZoomInTC(wgts,ROITS);
  end
  
 otherwise
  fprintf('WARNING %s: OrthoView_Callback() ''%s'' not supported yet.\n',...
          mfilename,eventdata);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to handle lightbox view
function LightboxView_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wgts = guihandles(get(hObject,'Parent'));
if get(wgts.EpiAnaCheck,'value')
  ANA  = getappdata(wgts.main,'EPIANA');
else
  ANA  = getappdata(wgts.main,'ANA');
end
ROITS   = getappdata(wgts.main, 'ROITS');
STATMAP = getappdata(wgts.main, 'STATMAP');
MINMAX  = getappdata(wgts.main, 'MINMAX');
DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
ALPHA   = str2double(get(wgts.AlphaEdt,'String'));
CMAP    = getappdata(wgts.main,'CMAP');
COLORS  = getappdata(wgts.main,'COLORS');
MAPCOLOR = getappdata(wgts.main,'MAPCOLOR');
RoiName  = get(wgts.RoiCmb,'String');   RoiName = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String'); StatName = StatName{get(wgts.StatCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String'); ModelNo = ModelNo{get(wgts.ModelCmb,'Value')};
ViewMode = get(wgts.ViewModeCmb,'String');
ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
switch lower(ViewMode),
 case {'lightbox-cor'}
  iDimension = 2;
  if strcmpi(get(wgts.SliceYEdt,'String'),'all'),
    SLICES = 1:size(ROITS{1}{1}.ana,2);
  else
    SLICES = str2num(get(wgts.SliceYEdt,'String'));
  end
 case {'lightbox-sag'}
  iDimension = 1;
  if strcmpi(get(wgts.SliceXEdt,'String'),'all'),
    SLICES = 1:size(ROITS{1}{1}.ana,1);
  else
    SLICES = str2num(get(wgts.SliceXEdt,'String'));
  end
 case {'lightbox-trans'}
  iDimension = 3;
  if strcmpi(get(wgts.SliceZEdt,'String'),'all'),
    SLICES = 1:size(ROITS{1}{1}.ana,3);
  else
    SLICES = str2num(get(wgts.SliceZEdt,'String'));
  end
 otherwise
  iDimension = 3;
  if strcmpi(get(wgts.SliceZEdt,'String'),'all'),
    SLICES = 1:size(ROITS{1}{1}.ana,3);
  else
    SLICES = str2num(get(wgts.SliceZEdt,'String'));
  end
end
%nmaximages = size(ROITS{1}{1}.ana,iDimension);
nmaximages  = length(SLICES);
[NRow NCol] = subGetNRowNCol(size(ROITS{1}{1}.ana),ROITS{1}{1}.ds,iDimension,SLICES,wgts);
NROWCOL.NRow = NRow;
NROWCOL.NCol = NCol;
setappdata(wgts.main,'NROWCOL',NROWCOL);
    
switch lower(eventdata),
 case {'init'}
  NPages = floor((nmaximages-1)/NRow/NCol)+1;
  tmptxt = {};
  for iPage = 1:NPages,
    tmp1 = (iPage-1)*NRow*NCol+1;
    tmp2 = min([nmaximages,iPage*NRow*NCol]);
    tmptxt{iPage} = sprintf('Page%d: %d-%d',iPage,SLICES(tmp1),SLICES(tmp2));
  end
  set(wgts.ViewPageCmb,'String',tmptxt,'Value',1);
  ViewMode = get(wgts.ViewModeCmb,'String');
  ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};
  switch lower(ViewMode),
   case {'lightbox-cor'}
    set(wgts.SliceXEdt,'Enable','off','Visible','off');
    set(wgts.SliceYEdt,'Enable','on', 'Visible','on');
    set(wgts.SliceZEdt,'Enable','off','Visible','off');
   case {'lightbox-sag'}
    set(wgts.SliceXEdt,'Enable','on', 'Visible','on');
    set(wgts.SliceYEdt,'Enable','off','Visible','off');
    set(wgts.SliceZEdt,'Enable','off','Visible','off');
   case {'lightbox-trans'}
    set(wgts.SliceXEdt,'Enable','off','Visible','off');
    set(wgts.SliceYEdt,'Enable','off','Visible','off');
    set(wgts.SliceZEdt,'Enable','on', 'Visible','on');
   otherwise
  end
  %setappdata(wgts.main,'PICKAREA',[]);
  if strncmpi(ViewMode,'lightbox',8),
    LightboxView_Callback(hObject,'redraw');
  end
  
 case {'redraw'}
  pagestr = get(wgts.ViewPageCmb,'String');
  pagestr = pagestr{get(wgts.ViewPageCmb,'Value')};
  ipage = sscanf(pagestr,'Page%d:');
  tmp1 = (ipage-1)*NRow*NCol+1;
  tmp2 = min([nmaximages,ipage*NRow*NCol]);
  SLICES = SLICES(tmp1:tmp2);
  ROI = getappdata(wgts.main,'ROI');
  if iDimension == 1,
    Xdim = 2;  Ydim = 3;
    INFSTR = 'Sag';
    Yrev = get(wgts.ZReverseCheck,'Value');
  elseif iDimension == 2,
    Xdim = 1;  Ydim = 3;
    INFSTR = 'Cor';
    Yrev = get(wgts.ZReverseCheck,'Value');
  else
    Xdim = 1;  Ydim = 2;
    INFSTR = 'Trans';
    Yrev = 0;
  end
  nX = size(STATMAP{1}.dat,Xdim);  nY = size(STATMAP{1}.dat,Ydim);
  X = (0:size(ANA.dat,Xdim)-1)/ANA.episcale(Xdim);
  Y = (0:size(ANA.dat,Ydim)-1)/ANA.episcale(Ydim);
  
  Y = fliplr(Y);
  if Yrev > 0,  Y = fliplr(Y);  end
  
  TrialNo = get(wgts.TrialCmb,'String');  TrialNo = TrialNo{get(wgts.TrialCmb,'Value')};
  oldimages = get(wgts.LightboxAxs,'UserData') ; 
  if ~get(wgts.TCHoldCheck,'Value'),
    oldimages = {} ;
  else
    if ~isempty(oldimages) && oldimages{1}(1).iDimension ~= iDimension,
      oldimages = {} ;
    end
  end
  set(wgts.main,'CurrentAxes',wgts.LightboxAxs);
  cla;
  delete(findobj(wgts.main,'tag','ROI'));
  delete(findobj(wgts.main,'tag','ELE'));
  %delete(findobj(wgts.LightboxAxs,'tag','ROI'));
  for N = 1:length(SLICES),
    iSlice = SLICES(N);
    if iDimension == 1,
      aSlice = round(iSlice*ANA.episcale(1));
      tmpimg = squeeze(ANA.rgb(aSlice,:,:,:));
    elseif iDimension == 2,
      aSlice = round(iSlice*ANA.episcale(2));
      tmpimg = squeeze(ANA.rgb(:,aSlice,:,:));
    else
      aSlice = round(iSlice*ANA.episcale(3));
      tmpimg = squeeze(ANA.rgb(:,:,aSlice,:));
    end
    
    if ~isempty(STATMAP) && get(wgts.OverlayCheck,'Value') && ~strcmpi(TrialNo,'all'),
      T = sscanf(TrialNo,'%d:');
      if length(T)>1, T=T(1); end;
      if iDimension == 1,
        tmps = squeeze(STATMAP{T}.dat(iSlice,:,:));
        tmpp = squeeze(STATMAP{T}.p(iSlice,:,:));
        tmpm = squeeze(STATMAP{T}.mask.dat(iSlice,:,:));
      elseif iDimension == 2,
        tmps = squeeze(STATMAP{T}.dat(:,iSlice,:));
        tmpp = squeeze(STATMAP{T}.p(:,iSlice,:));
        tmpm = squeeze(STATMAP{T}.mask.dat(:,iSlice,:));
      else
        tmps = squeeze(STATMAP{T}.dat(:,:,iSlice));
        tmpp = squeeze(STATMAP{T}.p(:,:,iSlice)); 
        tmpm = squeeze(STATMAP{T}.mask.dat(:,:,iSlice));
      end
      idx = find(tmpm(:) == 0);
      tmps(idx) = 0;
      tmpp(idx) = 1;
      MINV = MINMAX.(DATNAME)(1);  MAXV = MINMAX.(DATNAME)(2);
      tmpstr1 = sprintf('%s %s',ROITS{1}{1}.session,ROITS{1}{1}.grpname);
      if length(ROITS{1}{1}.ExpNo) > 1,
        tmpstr2 = sprintf('NumExps=%d',length(ROITS{1}{1}.ExpNo));
      else
        tmpstr2 = sprintf('ExpNo=%d',ROITS{1}{1}.ExpNo);
      end
      tmpstr2 = sprintf('%s P<%s ROI=%s Model=%s/%s',tmpstr2,get(wgts.AlphaEdt,'String'),...
                       RoiName,StatName,ModelNo);
      if length(get(wgts.TrialCmb,'String')) > 1,
        tmpstr2 = sprintf('%s Trial=%s',tmpstr2,TrialNo);
      end

      newimage(N) = struct('tmps',tmps,'tmpp',tmpp,'MINV',MINV,'MAXV',MAXV,...
                           'ALPHA',ALPHA,'CMAP',subGetColorMap(wgts), ...
                           'iDimension',iDimension,'titlestr',tmpstr1,'legendstr',tmpstr2);
      for M = 1:length(oldimages),
        tmpimg = subFuseImage(tmpimg,oldimages{M}(N).tmps,oldimages{M}(N).MINV,...
            oldimages{M}(N).MAXV,oldimages{M}(N).tmpp,oldimages{M}(N).ALPHA,oldimages{M}(N).CMAP) ;
      end
      tmpimg = subFuseImage(tmpimg,tmps,MINV,MAXV,tmpp,ALPHA,subGetColorMap(wgts));
    end
    iCol = floor((N-1)/NCol)+1;
    iRow = mod((N-1),NCol)+1;
    offsX = nX*(iRow-1);
    offsY = nY*NRow - iCol*nY;
    tmpimg = permute(tmpimg,[2 1 3]);
    tmpx = X + offsX;  tmpy = Y + offsY;
    image(tmpx,tmpy,tmpimg);  hold on;
    if N == 1, 
      xlim([0 nX*NCol]); ylim([0 nY*NRow]);
    end
     
    
    if ~isempty(STATMAP) && get(wgts.OverlayCheck,'Value') && strcmpi(TrialNo,'all'),
      for T = 1:length(STATMAP)
        if iDimension == 1,
          tmpp = squeeze(STATMAP{T}.p(iSlice,:,:));
          tmpm = squeeze(STATMAP{T}.mask.dat(iSlice,:,:));
        elseif iDimension == 2,
          tmpp = squeeze(STATMAP{T}.p(:,iSlice,:));
          tmpm = squeeze(STATMAP{T}.mask.dat(:,iSlice,:));
        else
          tmpp = squeeze(STATMAP{T}.p(:,:,iSlice)); 
          tmpm = squeeze(STATMAP{T}.mask.dat(:,:,iSlice));
        end
        tmpp(tmpm(:) == 0) = 1;
        idx = find(tmpp(:) < ALPHA);
        if ~isempty(idx),
          if gca ~= wgts.LightboxAxs,
            set(wgts.main,'CurrentAxes',wgts.LightboxAxs);
          end
          hold on;
          [tmpx2 tmpy2] = ind2sub(size(tmpp),idx);
          tmpx2 = tmpx2 + offsX;  tmpy2 =  max(Y)-tmpy2 + offsY;
          tmpcol = MAPCOLOR(mod(T-1,length(MAPCOLOR))+1);
          if iscell(tmpcol),
            tmpcol = tmpcol{1} ;
          end
          plot(tmpx2-(T-1)/4,tmpy2-(T-1)/4,'marker','s','markersize',1.5,...
               'markerfacecolor',tmpcol,'markeredgecolor',tmpcol,...
               'linestyle','none','tag','signif.voxel');
        end
      end
    end
    text(min(tmpx)+1,max(tmpy),sprintf('%s=%d',INFSTR,iSlice),...
         'color',[0.9 0.9 0.5],'VerticalAlignment','top',...
         'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');

    tmpoffsX = offsX - 1/ANA.episcale(Xdim);
    tmpoffsY = max(tmpy) + 1/ANA.episcale(Ydim);
    if iDimension == 3,
      %set(gca,'drawmode','fast');
      if 1 || get(wgts.DrawRoiCheck,'value') > 0,
        subDrawROIs(wgts.LightboxAxs,ROI,iSlice,RoiName,COLORS,tmpoffsX,...
                    tmpoffsY,1,get(wgts.DrawRoiCheck,'Value'))
      end
      if 1 || get(wgts.DrawEleCheck,'value') > 0,
        subDrawELEs(wgts.LightboxAxs,ROI,iSlice,RoiName,COLORS,tmpoffsX,...
                    tmpoffsY,1,get(wgts.DrawEleCheck,'Value')) ;
      end
    end
  end % for N = 1:length(SLICES)
  
  PICKAREA = getappdata(wgts.main,'PICKAREA');
  for K = 1:length(PICKAREA),
    if PICKAREA{K}.ipage == ipage,
      plot(PICKAREA{K}.anapx,PICKAREA{K}.anapy,'color',[0 1.0 0],'tag','PickArea');
    end
    if K == 1,
      text(nX*NCol,0,'PickArea:ON','tag','PickArea',...
           'color',[0.9 0.9 0.5],'VerticalAlignment','bottom',...
           'HorizontalAlignment','right',...
           'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
    end
  end
  
  
  if get(wgts.TCHoldCheck,'Value'),
    if exist('newimage','var'),
      if ~isempty(oldimages),
        oldimages{end+1} = newimage ;
      else
        oldimages = {} ;
        oldimages{1} = newimage ;
      end
    end
    set(wgts.LightboxAxs,'UserData',oldimages) ;
  else
    set(wgts.LightboxAxs,'UserData',{}) ;
  end
  haxs = wgts.LightboxAxs;
  set(haxs,'Tag','LightboxAxs','color','black');
  set(haxs,'XTickLabel',{},'YTickLabel',{},'XTick',[],'YTick',[]);
  set(haxs,'xlim',[0 nX*NCol],'ylim',[0 nY*NRow]);
  set(haxs,'YDir','normal');
  set(get(haxs,'Children'),...
      'ButtonDownFcn','mview(''LightboxView_Callback'',gcbo,''button-lightbox'',guidata(gcbo))');
  set(haxs,...
      'ButtonDownFcn','mview(''LightboxView_Callback'',gcbo,''button-lightbox'',guidata(gcbo))');
  
  LightboxView_Callback(hObject,'update-scalebar',[]);
 
 case {'update-scalebar'}
  % update scalebar
  delete(findobj(wgts.LightboxAxs,'tag','ScaleBar'));
  delete(findobj(wgts.LightboxAxs,'tag','ScaleBarTxt'));
  if iDimension == 1,
    Xdim = 2;  Ydim = 3;
  elseif iDimension == 2,
    Xdim = 1;  Ydim = 3;
  else
    Xdim = 1;  Ydim = 2;
  end
  DXmm = ANA.ds(Xdim) * ANA.episcale(Xdim);
  DYmm = ANA.ds(Ydim) * ANA.episcale(Ydim);
  
  ScaleBar = get(wgts.ScaleBarCmb,'String');
  ScaleBar = ScaleBar{get(wgts.ScaleBarCmb,'Value')};
  ScaleBar = sscanf(ScaleBar,'%dmm');
  if ~isempty(ScaleBar) && ScaleBar > 0,
    MARGIN = 1;
    set(wgts.main,'CurrentAxes',wgts.LightboxAxs);
    xlm = get(gca,'xlim');
    tmpx = round(max(xlm))-MARGIN;      tmpy = MARGIN;
    tmpw = ScaleBar/DXmm;  tmph = ScaleBar*0.15/DYmm;
    rectangle('Position',[tmpx-tmpw tmpy tmpw tmph],...
              'facecolor',[1.0 1.0 1.0],'linestyle','none','Tag','ScaleBar');
    text(tmpx-tmpw, tmpy-tmph, sprintf('%dmm ',ScaleBar),'tag','ScaleBarTxt',...
         'color',[0.9 0.9 0.5],'HorizontalAlignment','right','VerticalAlignment','bottom',...
         'FontName','Comic Sans MS','FontSize',8,'Fontweight','bold');
    tmpw = ScaleBar*0.15/DXmm;  tmph = ScaleBar/DYmm;
    rectangle('Position',[tmpx-tmpw tmpy tmpw tmph],...
              'facecolor',[1.0 1.0 1.0],'linestyle','none','Tag','ScaleBar');
  end
 
 case {'button-lightbox'}
  click = get(wgts.main,'SelectionType');
  if strcmpi(click,'open'),
    % double click
    subZoomInLightBox(wgts,ROITS);
  end
  
 otherwise
  fprintf('WARNING %s: LightboxView_Callback() ''%s'' not supported yet.\n',...
          mfilename,eventdata);
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to scale anatomy image
function ANARGB = subScaleAnatomy(ANA,MINV,MAXV,GAMMA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstruct(ANA),
  tmpana = double(ANA.dat);
else
  tmpana = double(ANA);
end
clear ANA;
tmpana = (tmpana - MINV) / (MAXV - MINV);
tmpana = round(tmpana*255) + 1; % +1 for matlab indexing
tmpana(tmpana(:) <   0) =   1;
tmpana(tmpana(:) > 256) = 256;
anacmap = gray(256).^(1/GAMMA);
ANARGB = zeros(size(tmpana,1),size(tmpana,2),3,size(tmpana,3));
for N = size(tmpana,3):-1:1,
  ANARGB(:,:,:,N) = ind2rgb(tmpana(:,:,N),anacmap);
end

ANARGB = permute(ANARGB,[1 2 4 3]);  % [x,y,rgb,z] --> [x,y,z,rgb]

  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fuse anatomy and functional images
function IMG = subFuseImage(ANARGB,STATV,MINV,MAXV,PVAL,ALPHA,CMAP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ndims(ANARGB) == 2,
  % image is just a vector, squeezed, so make it 2D image with RGB
  ANARGB = permute(ANARGB,[1 3 2]);
end

IMG = ANARGB;
if isempty(STATV) || isempty(PVAL) || isempty(ALPHA),  return;  end

PVAL(isnan(PVAL(:))) = 1;  % to avoid error;

imsz = [size(ANARGB,1) size(ANARGB,2)];
if any(imsz ~= size(STATV)),
  if datenum(version('-date')) >= datenum('January 29, 2007'),
    STATV = imresize_old(STATV,imsz,'nearest',0);
    PVAL  = imresize_old(PVAL, imsz,'nearest',0);
    %STATV = imresize_old(STATV,imsz,'bilinear',0);
    %PVAL  = imresize_old(PVAL, imsz,'bilinear',0);
  else
    STATV = imresize(STATV,imsz,'nearest',0);
    PVAL  = imresize(PVAL, imsz,'nearest',0);
    %STATV = imresize(STATV,imsz,'bilinear',0);
    %PVAL  = imresize(PVAL, imsz,'bilinear',0);
  end
end


tmpdat = repmat(PVAL,[1 1 3]);   % for rgb
idx = find(tmpdat(:) < ALPHA);
if ~isempty(idx),
  % scale STATV from MINV to MAXV as 0 to 1
  STATV = (STATV - MINV)/(MAXV - MINV);
  STATV = round(STATV*255) + 1;  % +1 for matlab indexing
  STATV(STATV(:) <   0) =   1;
  STATV(STATV(:) > 256) = 256;
  % map 0-256 as RGB
  STATV = ind2rgb(STATV,CMAP);
  % replace pixels
  %fprintf('\nsize(IMG)=  '); fprintf('%d ',size(IMG));
  %fprintf('\nsize(STATV)='); fprintf('%d ',size(STATV));
  IMG(idx) = STATV(idx);
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot ROIs
function subDrawROIs(haxs,ROI,Slice,RoiName,COLORS,OffsX,OffsY,DO_FLIP,Visible)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(ROI),  return;  end  

DRAW_ALL = strcmpi(RoiName,'all');
if any(Visible),
  vstr = 'on';
else
  vstr = 'off';
end

% focusing by axes() takes a longer time, do only when necessary
if ~isequal(get(gcf,'CurrentAxes'),haxs),  axes(haxs);  end
hold on;
for N = 1:length(ROI.roi),
  roiroi = ROI.roi{N};
  if roiroi.slice ~= Slice,  continue;  end
  if DRAW_ALL || strcmpi(roiroi.name,RoiName),
    hold on;
    cidx = find(strcmpi(ROI.roinames, roiroi.name));
    if isempty(cidx),  cidx = 1;  end
    cidx = mod(cidx(1),length(COLORS)) + 1;
    tmpcol = COLORS(cidx) ;
    if iscell(tmpcol),
      tmpcol = tmpcol{1} ;
    end
    %anax = roiroi.px / ROI.pxscale + OffsX;
    %anay = roiroi.py / ROI.pyscale + OffsY;
    if DO_FLIP > 0,
      anax =  roiroi.px + OffsX;
      anay = -roiroi.py + OffsY;
    else
      anax =  roiroi.px + OffsX;
      anay =  roiroi.py + OffsY;
    end
    hDR = plot(anax,anay,'color',tmpcol,'tag','ROI','Visible',vstr);
    %hDR = line(anax,anay,'color',tmpcol,'tag','ROI','Visible',vstr);
    set(get(get(hDR,'Annotation'),'LegendInformation'),'IconDisplayStyle','off') ;
  end
end

% if isfield(ROI,'ele'),
%   for N = 1:length(ROI.ele),
%     ele = ROI.ele{N};
%     if ele.slice ~= Slice,  continue;  end
%     hold on;
%     if DO_FLIP > 0,
%       anax = ele.x + OffsX;
%       anay = -ele.y + OffsY;
%     else
%       anax = ele.x + OffsX;
%       anay = ele.y + OffsY;
%     end
%     hELE = plot(anax,anay,'y+','markersize',12,'linewidth',2,'tag','ELE');
%     if Visible,
%       set(hELE,'Visible','on');
%     else
%       set(hELE,'Visible','off');
%     end
%     set(get(get(hELE,'Annotation'),'LegendInformation'),'IconDisplayStyle','off') ;
%   end
% end



return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot ELEs
function subDrawELEs(haxs,ROI,Slice,RoiName,COLORS,OffsX,OffsY,DO_FLIP,Visible)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(ROI),  return;  end  
if ~isfield(ROI,'ele'),  return;  end

if any(Visible),
  vstr = 'on';
else
  vstr = 'off';
end

% focusing by axes() takes a longer time, do only when necessary
if ~isequal(get(gcf,'CurrentAxes'),haxs),  axes(haxs);  end
hold on;
for N = 1:length(ROI.ele),
  ele = ROI.ele{N};
  if ele.slice ~= Slice,  continue;  end
  if DO_FLIP > 0,
    anax =  ele.x + OffsX;
    anay = -ele.y + OffsY;
  else
    anax =  ele.x + OffsX;
    anay =  ele.y + OffsY;
  end
  hELE = plot(anax,anay,'y+','markersize',12,'linewidth',2,...
              'visible',vstr,'tag','ELE');
  set(get(get(hELE,'Annotation'),'LegendInformation'),'IconDisplayStyle','off') ;
end



return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get a color map
function CMAP = subGetColorMap(wgts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if get(wgts.TCHoldCheck,'Value') && get(wgts.ColormapCmb,'Value') == 1,
  MAPCOLOR = getappdata(wgts.main,'MAPCOLOR') ;
  %COLORNO = mod(get(wgts.RoiCmb,'Value')-1,length(MAPCOLOR)) + 1 ;
  if get(wgts.TCHoldCheck,'Value'),
    COLORNO = length(get(wgts.TimeCourseAxs,'UserData')) ;
    COLORNO = mod([COLORNO COLORNO+1],length(MAPCOLOR)) +1 ;
  else
    COLORNO = [1 2] ;
  end
  NCOLOR = MAPCOLOR{COLORNO(1)} ;
  MAPCOLOR = MAPCOLOR{COLORNO(2)} ;
  SelectValue = get(wgts.SelectValueCmb,'String') ;
  SelectValue = SelectValue(get(wgts.SelectValueCmb,'Value')) ;
  StatName = get(wgts.StatCmb,'String') ;
  StatName = StatName(get(wgts.StatCmb,'Value')) ;
  if ~(strcmpi(SelectValue,'pos+neg') && strcmpi(StatName,'corr')),
    MAPCOLOR = NCOLOR ;
  end

  tmpcolormap = zeros(256,3) ;
  MINV = str2num(get(wgts.ColorbarMinMaxEdt,'String')) ;
  MAXV = MINV(2) ;
  MINV = MINV(1) ;
  if(MINV >= 0),
    for N = 1:length(MAPCOLOR),
      if MAPCOLOR(N),
        tmpcolormap(:,N) = MAPCOLOR(N)*(0:255)/255 ;
      end
    end
  else
    upart = round(255*abs(MAXV/double(MAXV-MINV))) ;
    lpart = 256 - upart ;
    for N = 1:length(MAPCOLOR),
      if MAPCOLOR(N),
        tmpcolormap(1:lpart,N) = MAPCOLOR(N)*(-lpart:-1)/lpart ;
      end
    end
    for N = 1:length(NCOLOR),
      if NCOLOR(N),
        tmpcolormap((1:upart)+lpart,N) = NCOLOR(N)*(1:upart)/upart ;
      end
    end
  end
  CMAP = abs(tmpcolormap) ;
else

  CMAPSTR = get(wgts.ColormapCmb,'String');
  CMAPSTR = CMAPSTR{get(wgts.ColormapCmb,'Value')};

  switch lower(CMAPSTR),
   case {'mri'}
    posmap = hot(128);
    negmap = jet(256);
    negmap = flipud(negmap(1:96,:));
    negmap(97:128,:) = 0;
    negmap(97:128,3) = (31:-1:0)/64;
    CMAP = [negmap; posmap];
   case {'autumn','winter','spring','summer','hot','cool','jet','hsv','bone','copper','pink'}
    CMAP = eval(sprintf('%s(256)',CMAPSTR));
   case {'red'}
    CMAP = zeros(256,3);  CMAP(:,1) = 1;
   case {'green'}
    CMAP = zeros(256,3);  CMAP(:,2) = 1;
   case {'blue'}
    CMAP = zeros(256,3);  CMAP(:,3) = 1;
   case {'yellow'}
    CMAP = zeros(256,3);  CMAP(:,1) = 1;  CMAP(:,2) = 1;
   case {'cyan'}
    CMAP = zeros(256,3);  CMAP(:,2) = 1;  CMAP(:,3) = 1;
   case {'magenta'}
    CMAP = zeros(256,3);  CMAP(:,1) = 1;  CMAP(:,3) = 1;
   case {'red256'}
    CMAP = zeros(256,3);  CMAP(:,1) = (0:255)'/255;
   case {'green256'}
    CMAP = zeros(256,3);  CMAP(:,2) = (0:255)'/255;
   case {'blue256'}
    CMAP = zeros(256,3);  CMAP(:,3) = (0:255)'/255;
   case {'yellow256'}
    CMAP = zeros(256,3);  CMAP(:,1) = (0:255)'/255;  CMAP(:,2) = (0:255)'/255;
   case {'cyan256'}
    CMAP = zeros(256,3);  CMAP(:,2) = (0:255)'/255;  CMAP(:,3) = (0:255)'/255;
   case {'magenta256'}
    CMAP = zeros(256,3);  CMAP(:,1) = (0:255)'/255;  CMAP(:,3) = (0:255)'/255;
   otherwise
    DATNAME = get(wgts.DataCmb,'String');
    DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
    switch lower(DATNAME),
     case {'stat','statv'}
      CMAP = hot(256);
     case {'tsnr', 'snr'}
      CMAP = jet(256);
     otherwise
      MINV = str2num(get(wgts.ColorbarMinMaxEdt,'String'));
      MINV = MINV(1);
      if MINV >= 0,
        CMAP = hot(256);
      else
        posmap = hot(128);
        if 1,
          negmap = jet(256);
          negmap = flipud(negmap(1:96,:));
          negmap(97:128,:) = 0;
          negmap(97:128,3) = (31:-1:0)/64;
        else
          negmap = zeros(128,3);
          negmap(:,3) = (1:128)'/128;
          %negmap(:,2) = flipud(brighten(negmap(:,3),-0.5));
          negmap(:,3) = brighten(negmap(:,3),0.5);
          negmap = flipud(negmap);
        end
        CMAP = [negmap; posmap];
      end
    end
  end
end

%cmap = cool(256);
%cmap = autumn(256);
gammav = str2double(get(wgts.GammaEdt,'String'));
if ~isempty(gammav),
  CMAP = CMAP.^(1/gammav);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to do cluster analysis
function STATMAP = subDoClusterAnalysis(STATMAP,fname,anap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isfield(anap,'mview'),
  anap = anap.mview;
else
  anap = [];
end

if strcmpi(fname,'mcluster3'),
  B = 5;  cutoff = round((2*(B-1)+1)^3*0.3);
  % overwrite settings with anap.mcluster3
  if isfield(anap,'mcluster3'),
    if isfield(anap.mcluster3,'B') && ~isempty(anap.mcluster3.B),
      B = anap.mcluster3.B;
    end
    if isfield(anap.mcluster3,'cutoff') && ~isempty(anap.mcluster3.cutoff),
      cutoff = anap.mcluster3.cutoff;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.mcluster3_B = B;
  STATMAP.mask.mcluster3_cutoff = cutoff;
  idx = find(STATMAP.mask.dat(:) > 0);
  [ix,iy,iz] = ind2sub(size(STATMAP.p),idx);
  coords = zeros(length(ix),3);
  coords(:,1) = ix(:);  coords(:,2) = iy(:); coords(:,3) = iz(:);
  fprintf('%s.mcluster3(n=%d,B=%d,cutoff=%d): %s-',...
          mfilename,size(coords,1),B,cutoff,datestr(now,'HH:MM:SS'));
  coords = mcluster3(coords, STATMAP.mask.mcluster3_B, STATMAP.mask.mcluster3_cutoff);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
  STATMAP.mask.dat(:)   = 0;
  if ~isempty(coords),
    idx = sub2ind(size(STATMAP.p),coords(:,1),coords(:,2),coords(:,3));
    STATMAP.mask.dat(idx) = 1;
  end
elseif strcmpi(fname,'mcluster'),
  B = 5;  cutoff = 10;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'mcluster'),
    if isfield(anap.mcluster,'B') && ~isempty(anap.mcluster.B),
      B = anap.mcluster.B;
    end
    if isfield(anap.mcluster,'cutoff') && ~isempty(anap.mcluster.cutoff),
      cutoff = anap.mcluster.cutoff;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.mcluster_B = B;
  STATMAP.mask.mcluster_cutoff = cutoff;
  idx = find(STATMAP.mask.dat(:) > 0);
  [ix,iy,iz] = ind2sub(size(STATMAP.p),idx);
  fprintf('%s.mcluster(n=%d,B=%d,cutoff=%d): %s-',...
          mfilename,length(ix),B,cutoff,datestr(now,'HH:MM:SS'));
  slices = sort(unique(iz));
  coords = [];
  for N = 1:length(slices),
    idx = find(iz == slices(N));
    [tmpx tmpy] = mcluster(ix(idx),iy(idx),B,cutoff);
    if isempty(tmpx),  continue;  end
    coords = cat(1,coords, [tmpx(:), tmpy(:), ones(length(tmpx),1)*slices(N)]);
  end
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
  STATMAP.mask.dat(:)   = 0;
  if ~isempty(coords),
    idx = sub2ind(size(STATMAP.p),coords(:,1),coords(:,2),coords(:,3));
    STATMAP.mask.dat(idx) = 1;
  end
elseif strcmpi(fname,'spm_bwlabel'),
  CONN = 26;	% must be 6(surface), 18(edges) or 26(corners)
  MINVOXELS = CONN*0.8;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'spm_bwlabel'),
    if isfield(anap.spm_bwlabel,'conn') && ~isempty(anap.spm_bwlabel.conn),
      CONN = anap.spm_bwlabel.conn;
    end
    if isfield(anap.spm_bwlabel,'minvoxels') && ~isempty(anap.spm_bwlabel.minvoxels),
      MINVOXELS = anap.spm_bwlabel.minvoxels;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.spm_bwlabel_conn = CONN;
  STATMAP.mask.minvoxels = MINVOXELS;
  fprintf('%s.spm_bwlabel(CONN=%d,min=%g): %s-',...
          mfilename,CONN,MINVOXELS,datestr(now,'HH:MM:SS'));
  tmpdat = double(STATMAP.mask.dat);
  [tmpdat tmpn] = spm_bwlabel(tmpdat, CONN);
  hn = histc(tmpdat(:), 1:tmpn);
  ci = find(hn >= MINVOXELS);
  STATMAP.mask.dat(:) = 0;
  for iCluster = 1:length(ci),
    %tmpi = find(tmpdat(:) == ci(iCluster));
    %STATMAP.mask.dat(tmpi) = iCluster;
    STATMAP.mask.dat(tmpdat(:) == ci(iCluster)) = iCluster;
  end
  STATMAP.mask.nclusters = length(hn);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
elseif strcmpi(fname,'bwlabeln'),
  CONN = 18;	% must be 6(surface), 18(edges) or 26(corners)
  MINVOXELS = CONN*0.8;
  % overwrite settings with anap.mcluster3
  if isfield(anap,'bwlabeln'),
    if isfield(anap.bwlabeln,'conn') && ~isempty(anap.bwlabeln.conn),
      CONN = anap.bwlabeln.conn;
    end
    if isfield(anap.bwlabeln,'minvoxels') && ~isempty(anap.bwlabeln.minvoxels),
      MINVOXELS = anap.bwlabeln.minvoxels;
    end
  end
  STATMAP.mask.func = fname;
  STATMAP.mask.bwlabeln_conn = CONN;
  STATMAP.mask.minvoxels = MINVOXELS;
  fprintf('%s.bwlabeln(CONN=%d,min=%g): %s-',...
          mfilename,CONN,MINVOXELS,datestr(now,'HH:MM:SS'));
  tmpdat = double(STATMAP.mask.dat);
  [tmpdat tmpn] = bwlabeln(tmpdat, CONN);
  hn = histc(tmpdat(:),1:tmpn);
  ci = find(hn >= MINVOXELS);
  STATMAP.mask.dat(:) = 0;
  for iCluster = 1:length(ci),
    %tmpi = find(tmpdat(:) == ci(iCluster));
    %STATMAP.mask.dat(tmpi) = iCluster;
    STATMAP.mask.dat(tmpdat(:) == ci(iCluster)) = iCluster;
  end
  STATMAP.mask.nclusters = length(hn);
  fprintf('%s\n',datestr(now,'HH:MM:SS'));
else
  SATAMAP.mask.func = 'unknown';
end


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to generate statistical data for 'none'
function STATMAP = subGetStatNull(ROITS,wgts,alpha,RoiName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATMAP = {};
EPIDIM = size(ROITS{1}{1}.ana);
SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};
if get(wgts.MaskBlackCheck,'Value') > 0,
  MASKTHR = getappdata(wgts.main,'MASKTHRESHOLD');
  idx_black = find(ROITS{1}{1}.ana(:) < MASKTHR);
end
if get(wgts.MaskBySnrCheck,'Value') > 0
  idx_snr = 0;
  if isfield(ROITS{1}{1},'snr') && ~isempty(ROITS{1}{1}.snr),
    tmpsnr = num2double(get(wgts.MaskBySnrEdt,'String'));
    if any(tmpsnr),  idx_snr = find(ROITS{1}{1}.snr(:) < tmpsnr);  end
  end
end


for T = 1:length(ROITS{1}),
  tmpmap.session = ROITS{1}{T}.session;
  tmpmap.grpname = ROITS{1}{T}.grpname;
  tmpmap.ExpNo   = ROITS{1}{T}.ExpNo;
  tmpmap.dat     = zeros(EPIDIM);
  tmpmap.p       = ones(EPIDIM);
  tmpmap.coords  = [];
  tmpmap.datname = 'none';
  tmpmap.roiname = RoiName;

  for N = 1:length(ROITS),
    if ~strcmpi(RoiName,'all') && ~strcmpi(ROITS{N}{T}.name,RoiName),  continue;  end
    xyz = double(ROITS{N}{T}.coords);
    tmpV = ROITS{N}{T}.amp;
    idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
    if length(idx) ~= length(tmpV),
      % some version of grouping cause this problem....
      idx = idx(1:length(tmpV));
    end
    try
      tmpmap.dat(idx) = tmpV(:);
      tmpmap.p(idx)   = 0;
    catch
      keyboard
    end
  end
  switch lower(SelectValue),
   case {'positive','pos','pos value','pos corr'}
    idx = find(tmpmap.dat < 0);
    tmpmap.dat(idx) = 0;
    tmpmap.p(idx)   = 1;
   case {'negative','neg','neg value','neg corr'}
    idx = find(tmpmap.dat > 0);
    tmpmap.dat(idx) = 0;
    tmpmap.p(idx)   = 1;
  end

  tmpmap.mask.alpha   = alpha;
  tmpmap.mask.mask_black = get(wgts.MaskBlackCheck,'Value');
  if get(wgts.MaskBySnrCheck,'Value') > 0,
    tmpmap.mask.mask_snr   = str2double(get(wgts.MaskBySnrEdt,'String'));
  else
    tmpmap.mask.mask_snr   = 0;
  end
  tmpmap.mask.cluster = get(wgts.ClusterCheck,'Value');
  tmpmap.mask.dat     = zeros(EPIDIM,'int16');

  tmpmap.mask.dat(tmpmap.p(:) < alpha) = 1;
  tmpmap.mask.cluster  = 0;

  if tmpmap.mask.mask_black > 0,
    tmpmap.mask.dat(idx_black) = 0;
  end
  if any(tmpmap.mask.mask_snr),
    tmpmap.mask.dat(idx_snr)   = 0;
  end
  %if tmpmap.mask.cluster > 0,
  %  fname = get(wgts.ClusterCmb,'String');
  %  fname = fname{get(wgts.ClusterCmb,'Value')};
  %  tmpmap = subDoClusterAnalysis(tmpmap,fname,anap);
  %end
  
  STATMAP{T} = tmpmap;
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to generate statistical data correlation analysis
function STATMAP = subGetStatCorr(ROITS,wgts,alpha,RoiName,ModelNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATMAP = {};
EPIDIM = size(ROITS{1}{1}.ana);
DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
anap = getanap(ROITS{1}{1}.session,ROITS{1}{1}.grpname);
SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};
if get(wgts.MaskBlackCheck,'Value') > 0,
  MASKTHR = getappdata(wgts.main,'MASKTHRESHOLD');
  idx_black = find(ROITS{1}{1}.ana(:) < MASKTHR);
end
if get(wgts.MaskBySnrCheck,'Value') > 0
  idx_snr = 0;
  if isfield(ROITS{1}{1},'snr') && ~isempty(ROITS{1}{1}.snr),
    tmpsnr = str2double(get(wgts.MaskBySnrEdt,'String'));
    if any(tmpsnr),  idx_snr = find(ROITS{1}{1}.snr(:) < tmpsnr);  end
  end
end

for T = 1:length(ROITS{1}),
  tmpmap.session = ROITS{1}{T}.session;
  tmpmap.grpname = ROITS{1}{T}.grpname;
  tmpmap.ExpNo   = ROITS{1}{T}.ExpNo;
  tmpmap.dat     = zeros(EPIDIM);
  tmpmap.p       = ones(EPIDIM);
  tmpmap.coords  = [];
  tmpmap.datname = DATNAME;
  tmpmap.roiname = RoiName;

  for N = 1:length(ROITS),
    if ~strcmpi(RoiName,'all') && ~strcmpi(ROITS{N}{T}.name,RoiName),  continue;  end
    xyz = double(ROITS{N}{T}.coords);
    tmpR = ROITS{N}{T}.r{ModelNo};
    switch lower(DATNAME),
     case {'r','rvalue','r_value','r-value'}
      tmpmap.datname = 'r-value';
      tmpV = tmpR;
     otherwise
      tmpV = ROITS{N}{T}.amp;
    end
    tmpP = ROITS{N}{T}.p{ModelNo};
    switch lower(SelectValue),
     case {'pos corr','pos','positive'}
      % select only pos set V/P of neg as nonsense
      idx = find(tmpR(:) < 0);
      tmpV(idx) = 0;
      tmpP(idx) = 1;
     case {'neg corr','neg','negative'}
      % select only neg, set V/P of pos as nonsense
      idx = find(tmpR(:) > 0);
      tmpV(idx) = 0;
      tmpP(idx) = 1;
     case {'tsnr','snr'}
      if isfield(ROITS{N}{T},'snr') && ~isempty(ROITS{N}{T}.snr)
        idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
        tmpV = ROITS{N}{T}.snr(idx);
      end
     otherwise
      % select both pos/neg
    end
    %if IncludeNegative == 0,
    %  idx = find(tmpR(:) < 0);
    %  tmpV(idx) = 0;
    %  tmpP(idx) = 1;
    %end
    idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
    if length(idx) ~= length(tmpV),
      % some version of grouping cause this problem....
      idx = idx(1:length(tmpV));
    end
    try
      tmpmap.dat(idx) = tmpV(:);
      tmpmap.p(idx)   = tmpP(:);
    catch
      keyboard
    end
  end
  
  tmpmap.mask.alpha   = alpha;
  tmpmap.mask.mask_black = get(wgts.MaskBlackCheck,'Value');
  if get(wgts.MaskBySnrCheck,'Value') > 0,
    tmpmap.mask.mask_snr   = str2double(get(wgts.MaskBySnrEdt,'String'));
  else
    tmpmap.mask.mask_snr   = 0;
  end
  tmpmap.mask.cluster = get(wgts.ClusterCheck,'Value');
  tmpmap.mask.dat     = zeros(EPIDIM,'int16');
  tmpmap.mask.dat(tmpmap.p(:) < alpha) = 1;

  if tmpmap.mask.mask_black > 0,
    tmpmap.mask.dat(idx_black) = 0;
  end
  if any(tmpmap.mask.mask_snr),
    tmpmap.mask.dat(idx_snr)   = 0;
  end
  if tmpmap.mask.cluster > 0,
    fname = get(wgts.ClusterCmb,'String');
    fname = fname{get(wgts.ClusterCmb,'Value')};
    tmpmap = subDoClusterAnalysis(tmpmap,fname,anap);
  end
  STATMAP{T} = tmpmap;
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to generate statistical data correlation analysis
function STATMAP = subGetStatGLM(ROITS,wgts,alpha,RoiName,ModelNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
STATMAP = {};
EPIDIM = size(ROITS{1}{1}.ana);
DATNAME = get(wgts.DataCmb,'String');
DATNAME = DATNAME{get(wgts.DataCmb,'Value')};
ANAP = getappdata(wgts.main,'ANAP');
SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};
if get(wgts.MaskBlackCheck,'Value') > 0,
  MASKTHR = getappdata(wgts.main,'MASKTHRESHOLD');
  idx_black = find(ROITS{1}{1}.ana(:) < MASKTHR);
end
if get(wgts.MaskBySnrCheck,'Value') > 0
  idx_snr = 0;
  if isfield(ROITS{1}{1},'snr') && ~isempty(ROITS{1}{1}.snr),
    tmpsnr = str2double(get(wgts.MaskBySnrEdt,'String'));
    if any(tmpsnr),  idx_snr = find(ROITS{1}{1}.snr(:) < tmpsnr);  end
  end
end

for T = 1:length(ROITS{1}),
  tmpmap.session = ROITS{1}{T}.session;
  tmpmap.grpname = ROITS{1}{T}.grpname;
  tmpmap.ExpNo   = ROITS{1}{T}.ExpNo;
  tmpmap.dat     = zeros(EPIDIM);
  tmpmap.p       = ones(EPIDIM);
  tmpmap.coords  = [];
  tmpmap.datname = DATNAME;
  tmpmap.roiname = RoiName;

  for N = 1:length(ROITS),
    if ~strcmpi(RoiName,'all') && ~strcmpi(ROITS{N}{T}.name,RoiName),  continue;  end
    xyz = double(ROITS{N}{T}.coords(ROITS{N}{T}.glmcont(ModelNo).selvoxels,:));
    if isempty(xyz), continue;  end
    switch lower(DATNAME),
     case {'statv','stat'}
      if isfield(ROITS{N}{T}.glmcont(ModelNo),'cont') && isfield(ROITS{N}{T}.glmcont(ModelNo).cont,'type'),
        tmpmap.datname = ROITS{N}{T}.glmcont(ModelNo).cont.type;
      end
      tmpV = ROITS{N}{T}.glmcont(ModelNo).statv;
     case {'beta'}
      if isfield(ROITS{N}{T}.glmcont(ModelNo),'BetaMag') && ~isempty(ROITS{N}{T}.glmcont(ModelNo).BetaMag),
        tmpV = ROITS{N}{T}.glmcont(ModelNo).BetaMag;
      else
        if N == 1 && T == 1,
          fprintf(' WARNING %s: no .glmcont().BetaMag for glm(%s)...\n',mfilename,ROITS{N}{T}.glmcont(ModelNo).cont.name);
        end
        % no way...
        tmpV = zeros(1,length(ROITS{N}{T}.glmcont(ModelNo).statv));
      end
     case {'tsnr','snr'}
      if isfield(ROITS{N}{T},'snr') && ~isempty(ROITS{N}{T}.snr)
        idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
        tmpV = ROITS{N}{T}.snr(idx);
      else
        fprintf(' WARNING %s: no .snr...\n',mfilename);
        tmpV = zeros(1,length(ROITS{N}{T}.glmcont(ModelNo).statv));
      end
     otherwise
      tmpV = ROITS{N}{T}.amp(ROITS{N}{T}.glmcont(ModelNo).selvoxels);
    end
    tmpP = ROITS{N}{T}.glmcont(ModelNo).pvalues;
    idx = sub2ind(EPIDIM,xyz(:,1),xyz(:,2),xyz(:,3));
    if length(idx) ~= length(tmpV),
      % some version of grouping cause this problem....
      idx = idx(1:length(tmpV));
    end
    try
      tmpmap.dat(idx) = tmpV(:);
      tmpmap.p(idx)   = tmpP(:);
    catch
      keyboard
    end
    % if alpha = 1.0, need to show everything of roi.
    if alpha >= 1.0,
      tmpmap.p(idx) = 0.99;
    end
  end
  
  %switch lower(SelectValue),
  % case {'positive','pos','pos value','pos corr'}
  %  idx = find(tmpmap.dat < 0);
  %  tmpmap.dat(idx) = 0;
  %  tmpmap.p(idx)   = 1;
  % case {'negative','neg','neg value','neg corr'}
  %  idx = find(tmpmap.dat > 0);
  %  tmpmap.dat(idx) = 0;
  %  tmpmap.p(idx)   = 1;
  %end

  tmpmap.mask.alpha   = alpha;
  tmpmap.mask.mask_black = get(wgts.MaskBlackCheck,'Value');
  if get(wgts.MaskBySnrCheck,'Value') > 0,
    tmpmap.mask.mask_snr   = str2double(get(wgts.MaskBySnrEdt,'String'));
  else
    tmpmap.mask.mask_snr   = 0;
  end
  tmpmap.mask.cluster = get(wgts.ClusterCheck,'Value');
  tmpmap.mask.dat     = zeros(EPIDIM,'int16');
  tmpmap.mask.dat(tmpmap.p(:) < alpha) = 1;

  if tmpmap.mask.mask_black > 0,
    tmpmap.mask.dat(idx_black) = 0;
  end
  if any(tmpmap.mask.mask_snr),
    tmpmap.mask.dat(idx_snr)   = 0;
  end
  if tmpmap.mask.cluster > 0,
    fname = get(wgts.ClusterCmb,'String');
    fname = fname{get(wgts.ClusterCmb,'Value')};
    tmpmap = subDoClusterAnalysis(tmpmap,fname,ANAP);
  end
  STATMAP{T} = tmpmap;
end

  
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot time course
function subPlotTimeCourse(wgts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TCTRIAL = getappdata(wgts.main, 'TCTRIAL');
STATMAP = getappdata(wgts.main, 'STATMAP');
COLORS  = getappdata(wgts.main,'COLORS');
if get(wgts.TCHoldCheck,'Value'),
  MAPCOLOR  = getappdata(wgts.main,'MAPCOLOR');
else
  MAPCOLOR = {'r','g'} ;
end
PICKAREA = getappdata(wgts.main,'PICKAREA');
ANAP     = getappdata(wgts.main,'ANAP');

if isempty(STATMAP),  return;  end
RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};
TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
if strcmpi(TrialNo,'all'),
  TrialNo = 1:length(TCTRIAL);
else
  TrialNo = sscanf(TrialNo,'%d:');
  % NKL to YM: CHECK THIS OUT (in different positions)
  % sscan does not work for labels like "1Hz Flicker"
  if length(TrialNo)>1, TrialNo=TrialNo(1); end;
end
BaseAlign = get(wgts.BaseAlignCheck,'value');


set(wgts.main,'CurrentAxes',wgts.TimeCourseAxs);
haxs = wgts.TimeCourseAxs;
%hold(haxs,'off') ;
%delete(findobj(get(haxs,'Children'),'tag','tcdat')) ;
%delete(get(haxs,'Children')) ;

POS = get(haxs,'pos');
if get(wgts.TCHoldCheck,'Value') == 0,
  % cla;
  delete(allchild(wgts.TimeCourseAxs));
  set(haxs,'UserData',[]);
end

SelectValue = get(wgts.SelectValueCmb,'String');
SelectValue = SelectValue{get(wgts.SelectValueCmb,'Value')};
if ~isempty(PICKAREA),  RoiName = 'PickArea';   end


hDATA = get(haxs,'UserData');
for iTrial = 1:length(TrialNo),
  T = TrialNo(iTrial);
  if get(wgts.TZeroCheck,'Value') > 0,
    tmpt = (0:size(TCTRIAL{T}.dat,1)-1) * TCTRIAL{T}.dx(1);
  else
    tmpt = (1:size(TCTRIAL{T}.dat,1)) * TCTRIAL{T}.dx(1);
  end
  if get(wgts.TStimCheck,'Value') > 0 && isfield(TCTRIAL{T},'stm') && ~isempty(TCTRIAL{T}.stm),
    stimv = TCTRIAL{T}.stm.v{1};
    stimt = TCTRIAL{T}.stm.time{1};
    for K = 1:length(stimv),
      if any(strcmpi(TCTRIAL{T}.stm.stmpars.StimTypes{stimv(K)+1},{'blank','none','nostim'})),
        continue;
      else
        tmpt = tmpt - stimt(K);
        break;
      end
    end
  end
  
  tmptxt = {};
  tmpsel = {};
  
  if ~isempty(PICKAREA),
    idx = [];
    for K = 1:length(PICKAREA),
      idx = cat(2,idx,PICKAREA{K}.epiidx(:)');
    end
    idx = unique(idx);
    [idx found] = intersect(TCTRIAL{T}.sub2ind,idx);
    tmpsel{1} = found;
    tmptxt{1} = sprintf('%s(%s:%s) Trial=%s N=%d',RoiName,StatName,ModelNo,...
                        TCTRIAL{T}.labels{1},length(idx));
  else
    if strcmpi(StatName,'corr'),
      switch lower(SelectValue),
       case {'pos','positive','neg','negative'}
        idx = find(STATMAP{T}.mask.dat(:) > 0);
        [idx found] = intersect(TCTRIAL{T}.sub2ind,idx);
        tmpsel{1} = found;
        tmptxt{1} = sprintf('%s(%s:%s:%s) Trial=%s N=%d',RoiName,StatName,ModelNo,...
                            SelectValue,TCTRIAL{T}.labels{1},length(idx));
       otherwise
        idx = find(STATMAP{T}.mask.dat(:) > 0 & STATMAP{T}.dat(:) > 0);
        [idx found] = intersect(TCTRIAL{T}.sub2ind,idx);
        tmpsel{1} = found;
        tmptxt{1} = sprintf('%s(%s:%s:pos) Trial=%s N=%d',RoiName,StatName,ModelNo,...
                            TCTRIAL{T}.labels{1},length(idx));
        idx = find(STATMAP{T}.mask.dat(:) > 0 & STATMAP{T}.dat(:) < 0);
        [idx found] = intersect(TCTRIAL{T}.sub2ind,idx);
        tmpsel{2} = found;
        tmptxt{2} = sprintf('%s(%s:%s:neg) Trial=%s N=%d',RoiName,StatName,ModelNo,...
                            TCTRIAL{T}.labels{1},length(idx));
      end
    else
      idx = find(STATMAP{T}.mask.dat(:) > 0);
      [idx found] = intersect(TCTRIAL{T}.sub2ind,idx);
      tmpsel{1} = found;
      tmptxt{1} = sprintf('%s(%s:%s) Trial=%s N=%d',RoiName,StatName,ModelNo,...
                          TCTRIAL{T}.labels{1},length(idx));
    end
  end

  for K = 1:length(tmpsel),
    if ischar(MAPCOLOR),
      tmpcol = MAPCOLOR(mod(length(hDATA),length(MAPCOLOR))+1);
    elseif iscell(MAPCOLOR),
      tmpcol = MAPCOLOR{mod(length(hDATA),length(MAPCOLOR))+1};
    else
      tmpcol = MAPCOLOR(mod(length(hDATA),length(MAPCOLOR))+1,:);
    end
    if isempty(tmpsel{K}),
      tcdat = [];
      hDATA(end+1) = plot(tmpt,zeros(size(tmpt)),'color',tmpcol,...
                          'tag','tcdat','UserData',tmptxt{K});
    else
      tcdat = TCTRIAL{T}.dat(:,tmpsel{K});
      tmpm = mean(tcdat,2);
      tmps = std(tcdat,[],2) / sqrt(size(tcdat,2));
      if get(wgts.BaseAlignCheck,'value') > 0,
        baseidx = subGetPreStim(TCTRIAL{T},[-0.3 +0.3]);
        if ~isempty(baseidx),
          tmpm = tmpm - mean(tmpm(baseidx));
        end
      end

      if get(wgts.ErrorbarCheck,'value') > 0 && length(tmpsel{K}) > 1,
        hDATA(end+1) = errorbar(tmpt,tmpm,tmps,'color',tmpcol,'tag','tcdat','UserData',tmptxt{K});
      else
        hDATA(end+1) = plot(tmpt,tmpm,'color',tmpcol,'tag','tcdat','UserData',tmptxt{K});
      end
      if get(wgts.TCHoldCheck,'Value') == 0,
        set(get(get(hDATA(end),'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); 
      end
    end
    hold on;
  end
end
set(haxs,'UserData',hDATA);
grid on;
  
if get(wgts.TCHoldCheck,'Value') == 0,
  set(haxs,'xlim',[min([0 tmpt(1)]),tmpt(end)],'Tag','TimeCourseAxs');
  xlabel(TCTRIAL{1}.xlabel);  ylabel(TCTRIAL{1}.ylabel);
  if length(tmpsel) == 1,
    tmpstr = sprintf('Nvox=%d P<%s ROI=%s Model=%s/%s',...
                     size(tcdat,2),get(wgts.AlphaEdt,'String'),...
                     RoiName,StatName,ModelNo);
  else
    tmpstr = sprintf('Nvox=%d/%d P<%s ROI=%s Model=%s/%s',...
                     length(tmpsel{1}),length(tmpsel{2}),...
                     get(wgts.AlphaEdt,'String'),...
                     RoiName,StatName,ModelNo);
  end
  text(0.01,0.99,strrep(tmpstr,'_','\_'),'units','normalized',...
       'FontName','Comic Sans MS','tag','Nvox',...
       'HorizontalAlignment','left','VerticalAlignment','top');
  text(0.99,0.01,'mean+-sem','units','normalized',...
       'FontName','Comic Sans MS','tag','Info',...
       'HorizontalAlignment','right','VerticalAlignment','bottom');
  set(haxs,'layer','top');
  set(haxs,...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-timecourse'',guidata(gcbo))');
  subDrawStimIndicators(haxs,TCTRIAL,TrialNo,1,ANAP.mview.stimcolor, get(wgts.TStimCheck,'Value'));
else
  delete(findobj(haxs,'type','text','tag','Nvox'));
  %delete(findobj(haxs,'type','text'));
  legtxt = {};
  for N = 1:length(hDATA),
    legtxt{N} = strrep(get(hDATA(N),'UserData'),'_','\_');
  end
  legend(haxs,legtxt);
  subDrawStimIndicators(haxs,TCTRIAL,TrialNo,0,ANAP.mview.stimcolor, get(wgts.TStimCheck,'Value'));
end
  
set(allchild(haxs),...
    'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-timecourse'',guidata(gcbo))');
set(haxs,'pos',POS);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to plot response distribution
function subPlotDistribution(wgts,which_stat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TCTRIAL = getappdata(wgts.main, 'TCTRIAL');
STATMAP = getappdata(wgts.main, 'STATMAP');
COLORS  = getappdata(wgts.main,'COLORS');
if get(wgts.TCHoldCheck,'Value'),
  MAPCOLOR  = getappdata(wgts.main,'MAPCOLOR');
else
  MAPCOLOR = {'r','g'} ;
end
PICKAREA = getappdata(wgts.main,'PICKAREA');

if isempty(STATMAP),  return;  end
RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};
TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
if strcmpi(TrialNo,'all'),
  TrialNo = 1:length(TCTRIAL);
else
  TrialNo = sscanf(TrialNo,'%d:');
  % NKL to YM: CHECK THIS OUT (in different positions)
  % sscan does not work for labels like "1Hz Flicker"
  if length(TrialNo)>1, TrialNo=TrialNo(1); end;
end

set(wgts.main,'CurrentAxes',wgts.TimeCourseAxs);
haxs = wgts.TimeCourseAxs;
  
POS = get(haxs,'pos');
if get(wgts.TCHoldCheck,'Value') == 0,
  % cla;
  delete(allchild(wgts.TimeCourseAxs));
  set(haxs,'UserData',[]);
end

if ~isempty(PICKAREA),  RoiName = 'PickArea';  end

BIN_W = 0.05;

hDATA = get(haxs,'UserData');
for iTrial = 1:length(TrialNo),
  T = TrialNo(iTrial);
  
  tmpcol = MAPCOLOR(mod(length(hDATA),length(MAPCOLOR))+1);
  if iscell(tmpcol),
    tmpcol = tmpcol{1} ;
  end
  if ~isempty(PICKAREA),
    idx = [];
    for K = 1:length(PICKAREA),
      idx = cat(2,idx,PICKAREA{K}.epiidx(:)');
    end
    idx = unique(idx);
  else
    idx = find(STATMAP{T}.mask.dat(:) > 0);
  end
  [idx found] = intersect(TCTRIAL{T}.sub2ind,idx);
  tmptxt = sprintf('%s(%s:%s) Trial=%s N=%d',RoiName,StatName,ModelNo,...
                   TCTRIAL{T}.labels{1},length(idx));
  
  if isempty(found),
    tmpdat = [];
    tmpx = -0.5:BIN_W:0.5;
    hDATA(end+1) = plot(tmpx,zeros(size(tmpx)),'color',tmpcol,...
                        'tag','tcdat','UserData',tmptxt);
  else
    tmpdat = TCTRIAL{T}.(which_stat);
    tmpdat = tmpdat(found);
    if get(wgts.BaseAlignCheck,'value') > 0,
      baseidx = subGetPreStim(TCTRIAL{T},[-0.3 +0.3]);
      if ~isempty(baseidx),
        tmpbas = mean(TCTRIAL{T}.dat(baseidx,found),1);
        tmpdat(:) = tmpdat(:) - tmpbas(:);
      end
    end
    tmpx = -ceil(abs(min(tmpdat))/BIN_W+1)*BIN_W:BIN_W:ceil(max(tmpdat)/BIN_W+1)*BIN_W;
    edges = tmpx - BIN_W/2;
    edges(end+1) = tmpx(end) + BIN_W/2;
    [hc,bin] = histc(tmpdat,edges);
    hc = hc / sum(hc);
    hDATA(end+1) = plot(tmpx,hc(1:length(tmpx)),'linewidth',2,...
                        'color',tmpcol,'tag','tcdat','UserData',tmptxt);
    if get(wgts.TCHoldCheck,'Value') == 0,
      set(get(get(hDATA(end),'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); 
    end
  end
  hold on;
end
set(haxs,'UserData',hDATA);
grid on;
  
if get(wgts.TCHoldCheck,'Value') == 0,
  set(haxs,'xlim',[-1 2],'Tag','TimeCourseAxs');
  xlabel('Response Amplitude');  ylabel('Normalized Frequency');
  tmpstr = sprintf('Nvox=%d P<%s ROI=%s Model=%s/%s',...
                   length(tmpdat),get(wgts.AlphaEdt,'String'),...
                   RoiName,StatName,ModelNo);
  text(0.01,0.99,strrep(tmpstr,'_','\_'),'units','normalized',...
       'FontName','Comic Sans MS','tag','Nvox',...
       'HorizontalAlignment','left','VerticalAlignment','top');
  set(haxs,'layer','top');
  set(haxs,...
      'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-timecourse'',guidata(gcbo))');
else
  delete(findobj(haxs,'type','text','tag','Nvox'));
  %delete(findobj(haxs,'type','text'));
  legtxt = {};
  for N = 1:length(hDATA),
    legtxt{N} = strrep(get(hDATA(N),'UserData'),'_','\_');
  end
  legend(haxs,legtxt);
end
  
set(allchild(haxs),...
    'ButtonDownFcn','mview(''OrthoView_Callback'',gcbo,''button-timecourse'',guidata(gcbo))');
set(haxs,'pos',POS);

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw stimulus indicators
function subDrawStimIndicators(haxs,TCTRIAL,TrialNo,DRAW_OBJ,STIMCOLOR,STIM1_ZERO)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 5,
  STIMCOLOR = [0.88 0.88 0.88];
  STIMCOLOR = [0.88 0.92 0.88];
end

if DRAW_OBJ > 0,
  % draw stimulus indicators
  ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
  drawL = [];  drawR = [];
  for iTrial = 1:length(TrialNo),
    T = TrialNo(iTrial);
    if isfield(TCTRIAL{T},'stm') && ~isempty(TCTRIAL{T}.stm),
      stimv = TCTRIAL{T}.stm.v{1};
      stimt = TCTRIAL{T}.stm.time{1};  stimt(end+1) = sum(TCTRIAL{T}.stm.dt{1});
      stimdt = TCTRIAL{T}.stm.dt{1};
      if STIM1_ZERO > 0,
        for K = 1:length(stimv),
          if any(strcmpi(TCTRIAL{T}.stm.stmpars.StimTypes{stimv(K)+1},{'blank','none','nostim'})),
            continue;
          else
            stimt = stimt - stimt(K);
            break;
          end
        end
      end
      for N = 1:length(stimv),
        if any(strcmpi(TCTRIAL{T}.stm.stmpars.StimTypes{stimv(N)+1},{'blank','none','nostim'})),
          continue;
        end
        if stimt(N) == stimt(N+1) || length(stimv) == 1,
          tmpw = stimdt(N);
        elseif stimt(N)+stimdt(N) < stimt(N+1),
          tmpw = stimdt(N);
        else
          tmpw = stimt(N+1) - stimt(N);
          if tmpw <= 0,  tmpw = stimdt(N);  end
        end
        if ~any(drawL == stimt(N)),
          line([stimt(N), stimt(N)],ylm,'color','k','tag','stim-line');
          drawL(end+1) = stimt(N);
        end
        if isempty(drawR) || ~any(drawR(:,1) == stimt(N) & drawR(:,2) == tmpw),
          rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
                    'facecolor',STIMCOLOR,'linestyle','none',...
                    'tag','stim-rect');
          drawR(end+1,1) = stimt(N);
          drawR(end  ,2) = tmpw;
        end
        if ~any(drawL == stimt(N)+tmpw),
          line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line');
          drawL(end+1) = stimt(N)+tmpw;
        end
      end
    end
  end
else
  set(allchild(haxs),'HandleVisibility','on');
  ylm   = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
  for iTrial = 1:length(TrialNo),
    T = TrialNo(iTrial);
    if isfield(TCTRIAL{T},'stm') && ~isempty(TCTRIAL{T}.stm),
      stimv = TCTRIAL{T}.stm.v{1};
      stimt = TCTRIAL{T}.stm.time{1};  stimt(end+1) = sum(TCTRIAL{T}.stm.dt{1});
      stimdt = TCTRIAL{T}.stm.dt{1};
      if STIM1_ZERO > 0,
        for K = 1:length(stimv),
          if any(strcmpi(TCTRIAL{T}.stm.stmpars.StimTypes{stimv(K)+1},{'blank','none','nostim'})),
            continue;
          else
            stimt = stimt - stimt(K);
            break;
          end
        end
      end
      for N = 1:length(stimv),
        if any(strcmpi(TCTRIAL{T}.stm.stmtypes{stimv(N)+1},{'blank','none','nostim'})),
        %if any(strcmpi(TCTRIAL{T}.stm.stmpars.StimTypes{stimv(N)+1},{'blank','none','nostim'})),
          continue;
        end
        if stimt(N) == stimt(N+1) || length(stimv) == 1,
          tmpw = stimdt(N);
        elseif stimt(N)+stimdt(N) < stimt(N+1),
          tmpw = stimdt(N);
        else
          tmpw = stimt(N+1) - stimt(N);
          if tmpw <= 0,  tmpw = stimdt(N);  end
        end
        % elongate rectangle
        hrect = findobj(gca,'tag','stim-rect');
        h = [];
        for K = 1:length(hrect),
          pos = get(hrect(K),'pos');
          if pos(1) == stimt(N) && pos(3) <= tmpw,
            h = hrect(K);  break;
          end
        end
        if isempty(h),
          rectangle('Position',[stimt(N) ylm(1) tmpw tmph],...
                    'facecolor',STIMCOLOR,'linestyle','none',...
                    'tag','stim-rect');
        else
          pos = get(h,'pos');
          pos(3) = tmpw;
          set(h,'pos',pos);
        end
        % draw a line if needed.
        hline = findobj(gca,'tag','stim-line');
        h1 = []; h2 = [];
        for K = 1:length(hline),
          %pos = get(hline(K),'pos');
          pos = get(hline(K),'xdata');
          if pos(1) == stimt(N),
            h1 = hline(K);  continue;
          end
          if pos(1) == stimt(N)+tmpw,
            h2 = hline(K);  continue;
          end
          if any(h1) && any(h2),  break;  end
        end
        if isempty(h1),
          line([stimt(N),stimt(N)],ylm,'color','k','tag','stim-line');
        end
        if isempty(h2),
          line([stimt(N),stimt(N)]+tmpw,ylm,'color','k','tag','stim-line');
        end
      end
    end
  end
end

% adjust stimulus indicator size
set(allchild(haxs),'HandleVisibility','on');
ylm = get(haxs,'ylim');  tmph = ylm(2)-ylm(1);
h = findobj(haxs,'tag','stim-line');
set(h,'ydata',ylm);
h = findobj(haxs,'tag','stim-rect');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(2) = ylm(1);  tmppos(4) = tmph;
  set(h(N),'pos',tmppos);
end

setfront(findobj(haxs,'tag','stim-line'));
setback(findobj(haxs,'tag','stim-rect'));
% set indicators' handles invisible to use legend() funciton.
set(findobj(haxs,'tag','stim-line'),'handlevisibility','off');
set(findobj(haxs,'tag','stim-rect'),'handlevisibility','off');

  

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to align base line
function IDX = subGetPreStim(SIG,TWIN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IDX = [];
if ~isfield(SIG,'stm') || isempty(SIG.stm),  return;  end
stype = SIG.stm.stmtypes;
stimv = SIG.stm.v{1};
stimt = SIG.stm.time{1};
if isempty(stimv) || isempty(stimt),  return;  end

%TIDX = [0:size(SIG.dat,1)-1]*SIG.dx;
TIDX = (1:size(SIG.dat,1))*SIG.dx;

% look for the first stimulus
for N = 1:length(stimv),
  if stimt(N) > 0 && ~any(strcmpi(stype{abs(stimv(N))+1},{'blank','none','nostim'})),
    IDX = find(TIDX >= TWIN(1)+stimt(N) & TIDX < TWIN(2)+stimt(N));
    break;
  end
end

  
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomIn(planestr,wgts,ROITS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};
TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
DatName  = get(wgts.DataCmb,'String');   DatName  = DatName{get(wgts.DataCmb,'Value')};
  
if 0 && get(wgts.CrosshairCheck,'Value'),
  set(wgts.CrosshairCheck,'Value',0) ;
  OrthoView_Callback(gcbo,'crosshair',guidata(gcbo));
end

switch lower(planestr)
 case {'coronal'}
  hfig = wgts.main + 1001;
  hsrc = wgts.CoronalAxs;
  DX = ROITS{1}{1}.ds(1);  DY = ROITS{1}{1}.ds(3);
  N = str2double(get(wgts.CoronalEdt,'String'));
  tmpstr = sprintf('CORONAL %03d:\n%s %s',N, ROITS{1}{1}.session,ROITS{1}{1}.grpname);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'sagital'}
  hfig = wgts.main + 1002;
  hsrc = wgts.SagitalAxs;
  DX = ROITS{1}{1}.ds(2);  DY = ROITS{1}{1}.ds(3);
  N = str2double(get(wgts.SagitalEdt,'String'));
  tmpstr = sprintf('SAGITAL %03d:\n%s %s',N,ROITS{1}{1}.session,ROITS{1}{1}.grpname);
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'transverse'}
  hfig = wgts.main + 1003;
  hsrc = wgts.TransverseAxs;
  DX = ROITS{1}{1}.ds(1);  DY = ROITS{1}{1}.ds(2);
  N = str2double(get(wgts.TransverseEdt,'String'));
  tmpstr = sprintf('TRANSVERSE %03d:\n%s %s',N,ROITS{1}{1}.session,ROITS{1}{1}.grpname);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end
sliceNo = N ;
if length(ROITS{1}{1}.ExpNo) > 1,
  tmpstr = sprintf('%s NumExps=%d',tmpstr,length(ROITS{1}{1}.ExpNo));
else
  tmpstr = sprintf('%s ExpNo=%d',tmpstr,ROITS{1}{1}.ExpNo);
end
SigName = getappdata(wgts.main,'SIGNAME');
if ~isempty(SigName),
  tmpstr = sprintf('%s Sig=%s',tmpstr,SigName);
end

tmpstr = sprintf('%s P<%s ROI=%s Model=%s/%s',tmpstr,get(wgts.AlphaEdt,'String'),...
                 RoiName,StatName,ModelNo);
if length(get(wgts.TrialCmb,'String')) > 1,
  tmpstr = sprintf('%s Trial=%s',tmpstr,TrialNo);
end

figure(hfig);  clf;
set(hfig,'PaperPositionMode',	'auto');
set(hfig,'PaperOrientation', 'landscape');
set(hfig,'PaperType',			'A4');
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) || pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 || pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmpstr,'pos',pos);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function
set(h,'xdata',get(h,'xdata')*DX,'ydata',get(h,'ydata')*DY);
nx = length(get(h,'xdata'));  ny = length(get(h,'ydata'));

set(haxs,'Position',[0.08 0.1 0.75 0.75],'units','normalized');
h = findobj(haxs,'type','line');
for N =1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end
set(haxs,'xlim',get(haxs,'xlim')*DX,'ylim',get(haxs,'ylim')*DY);

if ~any(findobj(haxs,'tag','ScaleBar')),
  set(haxs,'xtick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
  set(haxs,'ytick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
end

h = findobj(haxs,'tag','ScaleBar');
if ~isempty(h),
  %if length(h) > 1,
  %  delete(h(1:end-1));
  %end
  %h = h(end);
  for N = 1:length(h),
    tmppos = get(h(N),'pos');
    tmppos([1 3]) = tmppos([1 3])*DX;
    tmppos([2 4]) = tmppos([2 4])*DY;
    set(h(N),'pos',tmppos);
  end
  htxt = findobj(haxs,'tag','ScaleBarTxt');
  tmppos = get(htxt(1),'pos');
  tmppos(1) = tmppos(1)*DX;  tmppos(2) = tmppos(2)*DY;
  set(htxt(1),'pos',tmppos);
end

xlabel(tmpxlabel);  ylabel(tmpylabel);


%hLines = findobj(haxs,'type','line');
hLines = findobj(gca,'tag','ELE');
for N = 1:numel(hLines),
  set(get(get(hLines(N),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
hLines = findobj(gca,'tag','crosshair');
for N = 1:numel(hLines),
  set(get(get(hLines(N),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
hLines = findobj(gca,'tag','ROI');
for N = 1:numel(hLines),
  set(get(get(hLines(N),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
if get(wgts.TCHoldCheck,'Value'),
  GRAHANDLE = getappdata(wgts.main,'GRAHANDLE');
  %GRAHANDLE.sagital,'cdata',permute(tmpimg,[2 1 3]));
  oldimages = get(GRAHANDLE.(planestr),'UserData');
  tmpstr = sprintf('%s %03d: %s',upper(planestr),sliceNo,oldimages(1).titlestr) ;
  legendstr = {} ;
  for N = 1:numel(oldimages),
    legendstr{N} = oldimages(N).legendstr ;
    line([0 1],[0 1],[0
    1],'color',oldimages(N).CMAP(1,:),'Visible','off','tag','legendhelpline')
  end
  hLeg = legend(haxs,legendstr,'color','white','FontSize',8,'Location','South') ;
end

title(haxs,strrep(tmpstr,'_','\_'));
daspect(haxs,[1 1 1]);

if ~get(wgts.TCHoldCheck,'Value'),
  pos = get(haxs,'pos');
  hbar = copyobj(wgts.ColorbarAxs,hfig);
  set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)],'YAxisLocation','right');
  ylabel(hbar,strrep(DatName,'_',' '));

  %clear callbacks
  set(haxs,'ButtonDownFcn','');
  set(allchild(haxs),'ButtonDownFcn','');

  % make font size bigger
  set(haxs,'FontSize',10);
  set(get(haxs,'title'),'FontSize',10);
  set(get(haxs,'xlabel'),'FontSize',10);
  set(get(haxs,'ylabel'),'FontSize',10);
  set(hbar,'FontSize',10);
  set(get(hbar,'ylabel'),'FontSize',10);
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot (TIME COURSE)
function subZoomInTC(wgts,ROITS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};
TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
DatName  = get(wgts.DataCmb,'String');   DatName  = DatName{get(wgts.DataCmb,'Value')};

hfig = wgts.main + 1004;
hsrc = wgts.TimeCourseAxs;

PlotMode = get(wgts.TimeCourseCmb,'String');
PlotMode = PlotMode{get(wgts.TimeCourseCmb,'Value')};
switch lower(PlotMode),
 case {'voxel time course'}
  tmpstr = sprintf('BOLD Time Course\n%s %s',ROITS{1}{1}.session,ROITS{1}{1}.grpname);
 case {'distribution (mean)'}
  tmpstr = sprintf('Distribution (mean)\n%s %s',ROITS{1}{1}.session,ROITS{1}{1}.grpname);
 case {'distribution (max)'}
  tmpstr = sprintf('Distribution (max)\n%s %s',ROITS{1}{1}.session,ROITS{1}{1}.grpname);
 otherwise
  error(' ERROR %s: unsupported plotting mode, %s',mfilename,PlotMode);
end


if length(ROITS{1}{1}.ExpNo) > 1,
  tmpstr = sprintf('%s NumExps=%d',tmpstr,length(ROITS{1}{1}.ExpNo));
else
  tmpstr = sprintf('%s ExpNo=%d',tmpstr,ROITS{1}{1}.ExpNo);
end
SigName = getappdata(wgts.main,'SIGNAME');
if ~isempty(SigName),
  tmpstr = sprintf('%s %s',tmpstr,SigName);
end


if length(get(hsrc,'UserData')) > 1,
  % multiple plot with "hold-on"
  tmpstr = sprintf('%s P<%s Model=%s/%s',tmpstr,get(wgts.AlphaEdt,'String'),...
                   StatName,ModelNo);
else
  tmpstr = sprintf('%s P<%s ROI=%s Model=%s:%s',tmpstr,get(wgts.AlphaEdt,'String'),...
                   RoiName,StatName,ModelNo);
end
if length(get(wgts.TrialCmb,'String')) > 1,
  set(hfig,'Name',tmpstr,'pos',[100 200 1100 750]);
  tmpstr = sprintf('%s Trial=%s',tmpstr,TrialNo);
end

figure(hfig);  clf;
set(hfig,'PaperPositionMode',	'auto');
set(hfig,'PaperOrientation', 'landscape');
set(hfig,'PaperType',			'A4');
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) || pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 || pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end

%-% 12 AUG 2007: NIKOS -- I changed this temporarily to start at different zoom
%-% OLD: set(hfig,'Name',tmpstr,'pos',pos);
%-% NEW:
set(hfig,'Name',tmpstr,'pos',[100 200 1100 750]);


if 0,
  haxs = axes;
  subCompCopy(hsrc,haxs);
else
  haxs = copyobj(hsrc,hfig);
  set(haxs,'pos',[0.1300    0.1100    0.7750    0.8150]);
  title(strrep(tmpstr,'_','\_'));
  % FU__ING MATLAB(R14), copyobj() makes lines in legend all black. ----------
  erb = findobj(haxs,'tag','tcdat');
  for N = 1:length(erb),
    tmph = findobj(erb(N),'type','line');
    if ~isempty(tmph),
      set(erb(N),'color',get(tmph(1),'color'));
    else 
      %dbstack ; keyboard
    end
  end
  % FU__ING MATLAB(R2007b), copyobj() makes lines's IconDisplayStyle as 'off'. 
  for N = 1:length(erb),
    try
      hAnnotation = get(erb(N),'Annotation');
      hLegendEntry = get(hAnnotation','LegendInformation');
      if ishandle(hLegendEntry) && strcmpi(get(hLegendEntry,'IconDisplayStyle'),'off'),
        set(hLegendEntry,'IconDisplayStyle','on');
      end
    catch
      break;
    end
  end
  %---------------------------------------------------------------------------
end

% if "hold-on" then put the legend
hDATA = get(hsrc,'UserData');
legtxt = {};
if length(hDATA) > 1,
  for N = 1:length(hDATA),
    legtxt{N} = strrep(get(hDATA(N),'UserData'),'_','\_');
  end
  legend(haxs,legtxt);
end

%clear callbacks
set(haxs,'ButtonDownFcn','');  % clear callback function
%set(get(haxs,'Children'),'ButtonDownFcn','');
set(allchild(haxs),'ButtonDownFcn','');

% make font size bigger
set(haxs,'FontSize',10);
set(get(haxs,'title'),'FontSize',10);
set(get(haxs,'xlabel'),'FontSize',10);
set(get(haxs,'ylabel'),'FontSize',10);


return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to zoom-in plot
function subZoomInLightBox(wgts,ROITS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RoiName  = get(wgts.RoiCmb,'String');    RoiName  = RoiName{get(wgts.RoiCmb,'Value')};
StatName = get(wgts.StatCmb,'String');   StatName = StatName{get(wgts.StatCmb,'Value')};
ModelNo  = get(wgts.ModelCmb,'String');  ModelNo  = ModelNo{get(wgts.ModelCmb,'Value')};
TrialNo  = get(wgts.TrialCmb,'String');  TrialNo  = TrialNo{get(wgts.TrialCmb,'Value')};
DatName  = get(wgts.DataCmb,'String');   DatName  = DatName{get(wgts.DataCmb,'Value')};

ViewMode = get(wgts.ViewModeCmb,'String');
ViewMode = ViewMode{get(wgts.ViewModeCmb,'Value')};

switch lower(ViewMode),
 case {'lightbox-cor'}
  DX = ROITS{1}{1}.ds(1);  DY = ROITS{1}{1}.ds(3);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Z (mm)';
 case {'lightbox-sag'}
  DX = ROITS{1}{1}.ds(2);  DY = ROITS{1}{1}.ds(3);
  tmpxlabel = 'Y (mm)';  tmpylabel = 'Z (mm)';
 case {'lightbox-trans'}
  DX = ROITS{1}{1}.ds(1);  DY = ROITS{1}{1}.ds(2);
  tmpxlabel = 'X (mm)';  tmpylabel = 'Y (mm)';
end

hfig = wgts.main + 1005;
hsrc = wgts.LightboxAxs;

tmpstr = sprintf('%s %s',ROITS{1}{1}.session,ROITS{1}{1}.grpname);
if length(ROITS{1}{1}.ExpNo) > 1,
  tmpstr = sprintf('%s NumExps=%d',tmpstr,length(ROITS{1}{1}.ExpNo));
else
  tmpstr = sprintf('%s ExpNo=%d',tmpstr,ROITS{1}{1}.ExpNo);
end
SigName = getappdata(wgts.main,'SIGNAME');
if ~isempty(SigName),
  tmpstr = sprintf('%s %s',tmpstr,SigName);
end

tmpstr = sprintf('%s P<%s ROI=%s Model=%s/%s',tmpstr,get(wgts.AlphaEdt,'String'),...
                 RoiName,StatName,ModelNo);
if length(get(wgts.TrialCmb,'String')) > 1,
  tmpstr = sprintf('%s Trial=%s',tmpstr,TrialNo);
end

figure(hfig);  clf;
pos = get(hfig,'pos');
pos = [pos(1)-(680-pos(3)) pos(2)-(500-pos(4)) 680 500];
% sometime, wiondow is outside the screen....why this happens??
[scrW scrH] = subGetScreenSize('pixels');
if pos(1) < -pos(3) || pos(1) > scrW,  pos(1) = 1;  end
if pos(2)+pos(4) < 0 || pos(2)+pos(4)+70 > scrH,  pos(2) = scrH-pos(4)-70;  end
set(hfig,'Name',tmpstr,'pos',pos);
haxs = copyobj(hsrc,hfig);
set(haxs,'ButtonDownFcn','');  % clear callback function
set(hfig,'Colormap',get(wgts.main,'Colormap'));
h = findobj(haxs,'type','image');
set(h,'ButtonDownFcn','');  % clear callback function
for N = 1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
  nx = length(get(h(N),'xdata'));  ny = length(get(h(N),'ydata'));
end
h = findobj(haxs,'type','text');
for N = 1:length(h),
  tmppos = get(h(N),'pos');
  tmppos(1) = tmppos(1)*DX;  tmppos(2) = tmppos(2)*DY;
  set(h(N),'pos',tmppos);
end
set(haxs,'Position',[0.08 0.1 0.75 0.75],'units','normalized');
h = findobj(haxs,'type','line');
for N =1:length(h),
  set(h(N),'xdata',get(h(N),'xdata')*DX,'ydata',get(h(N),'ydata')*DY);
end

h = findobj(haxs,'tag','ScaleBar');
if ~isempty(h),
  %if length(h) > 1,
  %  delete(h(1:end-1));
  %end
  %h = h(end);
  for N = 1:length(h),
    tmppos = get(h(N),'pos');
    tmppos([1 3]) = tmppos([1 3])*DX;
    tmppos([2 4]) = tmppos([2 4])*DY;
    set(h(N),'pos',tmppos);
  end
end

%hLines = findobj(haxs,'type','line');
hLines = findobj(haxs,'tag','ELE');
for N = 1:numel(hLines),
  set(get(get(hLines(N),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
hLines = findobj(haxs,'tag','ROI');
for N = 1:numel(hLines),
  set(get(get(hLines(N),'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end


set(haxs,'xlim',get(haxs,'xlim')*DX,'ylim',get(haxs,'ylim')*DY);
if ~any(findobj(haxs,'tag','ScaleBar')),
  set(haxs,'xtick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
  set(haxs,'ytick',[0 10 20 30 40 50 60 70 80 90 100 110 120]);
end
xlabel(tmpxlabel);  ylabel(tmpylabel);
if get(wgts.TCHoldCheck,'Value'),
  oldimages = get(haxs,'UserData');
  tmpstr = oldimages{1}(1).titlestr ;
  legendstr = {} ;
  for N = 1:numel(oldimages),
    legendstr{N} = oldimages{N}(1).legendstr ;
    line([0 1],[0 1],[0 1],'color',oldimages{N}(1).CMAP(1,:),'Visible','off')
  end
  hLeg = legend(haxs,legendstr,'color','white','FontSize',8,'Location','South') ;
end
title(haxs,strrep(tmpstr,'_','\_'));
daspect(haxs,[1 1 1]);


if ~get(wgts.TCHoldCheck,'Value'),
  pos = get(haxs,'pos');
  hbar = copyobj(wgts.ColorbarAxs,hfig);
  set(hbar,'pos',[0.85 pos(2) 0.045 pos(4)],'YAxisLocation','right');

  if strcmpi(DatName,'Response'),
    if isfield(ROITS{1}{1},'xform') && isfield(ROITS{1}{1}.xform,'method'),
      switch lower(sub_find_xform(ROITS{1}{1}.xform)),
       case {'tosdu', 'sdu'}
        DatName = 'Amplitude in SDU';
       case {'percent'}
        DatName = 'Amplitude in % changes';
       case {'frac'}
        DatName = 'Amplitude in fraction';
       case {'zerobase'}
        DatName = 'Amplitude (zero-base)';
      end
    end
  end
  ylabel(hbar,strrep(DatName,'_',' '));
    

  %clear callbacks
  set(haxs,'ButtonDownFcn','');
  set(allchild(haxs),'ButtonDownFcn','');


  % make font size bigger
  set(haxs,'FontSize',10);
  set(get(haxs,'title'),'FontSize',10);
  set(get(haxs,'xlabel'),'FontSize',10);
  set(get(haxs,'ylabel'),'FontSize',10);
  set(hbar,'FontSize',10);
  set(get(hbar,'ylabel'),'FontSize',10);
end


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get NRow/NCol for Lightbox mode
function [NRow NCol] = subGetNRowNCol(IMGDIM,PIXDIM,iDimension,SLICES,wgts)

if length(IMGDIM) < 3 || length(SLICES) < 2,
  NRow = 1;  NCol = 1;  return;
end

  

ANAP = getappdata(wgts.main,'ANAP');
if isfield(ANAP,'mview'),
  if iDimension == 1,
    % sagital, YZ
    if ~isempty(ANAP.mview.nrowncol_sag),
      NRow = ANAP.mview.nrowncol_sag(1);
      NCol = ANAP.mview.nrowncol_sag(2);
      return
    end
  elseif iDimension == 2,
    % coronal, XZ
    if ~isempty(ANAP.mview.nrowncol_cor),
      NRow = ANAP.mview.nrowncol_cor(1);
      NCol = ANAP.mview.nrowncol_cor(2);
      return
    end
  else
    % transverse, XY
    if ~isempty(ANAP.mview.nrowncol_trans),
      NRow = ANAP.mview.nrowncol_trans(1);
      NCol = ANAP.mview.nrowncol_trans(2);
      return
    end
  end
end

if 1,
  if iDimension == 1,
    % sagital, YZ
    xfov = IMGDIM(2)*PIXDIM(2);
    yfov = IMGDIM(3)*PIXDIM(3);
  elseif iDimension == 2,
    % coronal, XZ
    xfov = IMGDIM(1)*PIXDIM(1);
    yfov = IMGDIM(3)*PIXDIM(3);
  else
    % transverse, XY
    xfov = IMGDIM(1)*PIXDIM(1);
    yfov = IMGDIM(2)*PIXDIM(2);
  end
  %nslices = min([25 IMGDIM(iDimension)]);
  nslices = min([25 length(SLICES)]);
  
  NRow = ceil(sqrt(nslices*xfov/yfov));
  NCol = round(nslices/NRow);

  if NCol*NRow < nslices-1,
    if xfov > yfov,
      NRow = NRow + 1;
    else
      NCol = NCol + 1;
    end
  end
  
  %fprintf('nsli=%d,xfov=%g,yfov=%g,NRow=%d,NCol=%d\n',nslices,xfov,yfov,NRow,NCol);
else
  minsize    = min(IMGDIM);
  if minsize <= 2,
    NRow = 2;  NCol = 1;  %  2 images in a page
  elseif minsize <= 4,
    NRow = 2;  NCol = 2;  %  4 images in a page
  elseif minsize <= 9
    NRow = 3;  NCol = 3;  %  9 images in a page
  elseif minsize <= 12
    NRow = 4;  NCol = 3;  % 12 images in a page
  elseif minsize <= 16
    NRow = 4;  NCol = 4;  % 16 images in a page
  else
    NRow = 5;  NCol = 4;  % 20 images in a page
  end
end

NROWCOL.NRow = NRow;
NROWCOL.NCol = NCol;
setappdata(wgts.main,'NROWCOL',NROWCOL);

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to get screen size
function [scrW scrH] = subGetScreenSize(Units)
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subCompCopy(op, np)
%COMPCOPY copies a figure object represented by "op" and its
% descendants to another figure "np" preserving the same hierarchy.

ch = get(op, 'children');
if ~isempty(ch)
  nh = copyobj(ch,np);
  for k = 1:length(ch)
    subCompCopy(ch(k),nh(k));
  end
end;

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get ROI info
function [ROI epix epiy epiz] = subGetROI(wgts,anamask,anapx,anapy)

NROWCOL = getappdata(wgts.main, 'NROWCOL');
ROITS = getappdata(wgts.main,'ROITS');
EPIDIM = size(ROITS{1}{1}.ana);
if length(EPIDIM) < 3,
  EPIDIM(end+1:3) = 1;
end
%ANADIM = size(ANA.dat);
ANADIM = EPIDIM;
pagestr = get(wgts.ViewPageCmb,'String');
pagestr = pagestr{get(wgts.ViewPageCmb,'Value')};
ipage = sscanf(pagestr,'Page%d:');


if strcmpi(get(wgts.SliceZEdt,'String'),'all'),
  SLICES = 1:size(ROITS{1}{1}.ana,3);
else
  SLICES = str2num(get(wgts.SliceZEdt,'String'));
end



NRow = NROWCOL.NRow;
NCol = NROWCOL.NCol;

nx = ANADIM(1); ny = ANADIM(2);

% stupid bug of matlab...
if NCol*nx ~= size(anamask,1) || NRow*ny ~= size(anamask,2),
  anamask = roipoly_71(ones(NCol*nx,NRow*ny)',anapx,anapy);
  anamask = logical(anamask'); % transpose "mask"
  if length(anapx) < 3,
    anamask(round(anapx),round(anapy)) = 1;
  end
end


[anaX anaY] = find(anamask > 0);
epix = zeros(1,length(anaX));
epiy = zeros(1,length(anaX));
epiz = zeros(1,length(anaX));
for N=1:length(anaX),
  %ny*NRow-anaY(N)/nx
  %[floor((ny*NRow-anaY(N))/ny)*NCol floor(anaX(N)/nx)+1]
  tmpi = floor((ny*NRow-anaY(N))/ny)*NCol + floor(anaX(N)/nx)+1  + NRow*NCol*(ipage-1);
  tmpx = mod(anaX(N),nx);
  tmpy = mod(ny*NRow-anaY(N),ny);
  
  epix(N) = round(tmpx/nx*EPIDIM(1));
  epiy(N) = round(tmpy/ny*EPIDIM(2));
  epiz(N) = SLICES(tmpi);
end

%[epix(:) epiy(:) epiz(:)]

tmpidx = find(epix >= 1 & epix <= nx & epiy >= 1 & epiy <= ny & epiz >= 1 & epiz <= EPIDIM(3));
epix = epix(tmpidx);
epiy = epiy(tmpidx);
epiz = epiz(tmpidx);

ROI.name = 'PickArea';
ROI.epiidx = sub2ind(EPIDIM,epix,epiy,epiz); % epix as y of original data
ROI.anapx  = anapx;
ROI.anapy  = anapy;
ROI.ipage  = ipage;

if 0,
  % for debug
  tmpdat = zeros(EPIDIM);
  if ~isempty(ROI.epiidx),
    tmpdat(ROI.epiidx) = 1;
    figure(10);
    imagesc(squeeze(tmpdat(:,:,epiz(1)))');
  end
  [epix(:) epiy(:) epiz(:)]
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get and store multiple images of rois 
function tmpimg = subRoimerge(orient,tmps,tmpp,MINV,MAXV,ALPHA,wgts,GRAHANDLE,tmpimg,ROITS,RoiName,StatName,ModelNo,TrialNo)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      tmpstr1 = sprintf('%s %s',ROITS{1}{1}.session,ROITS{1}{1}.grpname);
      if length(ROITS{1}{1}.ExpNo) > 1,
        tmpstr2 = sprintf('NumExps=%d',length(ROITS{1}{1}.ExpNo));
      else
        tmpstr2 = sprintf('ExpNo=%d',ROITS{1}{1}.ExpNo);
      end
      tmpstr2 = sprintf('%s P<%s ROI=%s Model=%s/%s',tmpstr2,get(wgts.AlphaEdt,'String'),...
                       RoiName,StatName,ModelNo);
      if length(get(wgts.TrialCmb,'String')) > 1,
        tmpstr2 = sprintf('%s Trial=%s',tmpstr2,TrialNo);
      end

newimage.tmps = tmps ;
newimage.tmpp = tmpp ;
newimage.MINV = MINV ;
newimage.MAXV = MAXV ;
newimage.ALPHA = ALPHA ;
newimage.titlestr = tmpstr1 ;
newimage.legendstr = tmpstr2 ;
newimage.position = [round(get(wgts.CoronalSldr,'Value')) ...
                     round(get(wgts.SagitalSldr,'Value')) ...
                     round(get(wgts.TransverseSldr,'Value'))];
newimage.CMAP = subGetColorMap(wgts) ;

oldimages = get(GRAHANDLE.(orient),'UserData') ;
if ~isempty(oldimages) && ~isequal(oldimages(1).position, ...
                                  [round(get(wgts.CoronalSldr,'Value')) ...
                                   round(get(wgts.SagitalSldr,'Value')) ...
                                   round(get(wgts.TransverseSldr,'Value'))]),
  oldimages = [] ;
  tmpnames = {'sagital','coronal','transverse'} ;
  for N = 1:length(tmpnames),
    set(GRAHANDLE.(tmpnames{N}),'UserData',[]) ;
    if ~isequal(tmpnames{N},orient),
      OrthoView_Callback(gcbo,sprintf('slider-%s',tmpnames{N}),wgts) ;
    end
  end
end

if ~get(wgts.TCHoldCheck,'Value'),
  oldimages = [] ;
end

if isempty(oldimages),
  oldimages = newimage ;
else
  oldimages(end+1) = newimage ;
end

if get(wgts.TCHoldCheck,'Value'),
  set(GRAHANDLE.(orient),'UserData',oldimages) ;
else
  set(GRAHANDLE.(orient),'UserData',[]);
end

for N = 1:length(oldimages),
  tmpimg = subFuseImage(tmpimg,oldimages(N).tmps,oldimages(N).MINV,oldimages(N).MAXV, ...
                        oldimages(N).tmpp,oldimages(N).ALPHA,oldimages(N).CMAP);
end

return ;


% ================================================================
function method = sub_find_xform(XFORM)
% ================================================================
method = XFORM(end).method;
for N = length(XFORM):-1:1,
  if ~strcmpi(XFORM(N).method,'zerobase'),
    method = XFORM(N).method;
    break;
  end
end

return
