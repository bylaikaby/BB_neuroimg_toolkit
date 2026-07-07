function GRPP = rpgetpars_awake(SesName,GRPP)
%RPGETPARS_AWAKE - Rpgetpars for Awake Monkey Experiments
% realign ================================================================================
%GRPP.anap.exprealign.spm_realign.PW = 'b04bw1_spont_realign_mask_brain.img';
GRPP.anap.exprealign.spm_realign.PW = sprintf('%s_spont_realign_mask_brain.img',lower(SesName));


% % roiTs ==================================================================================
% GRPP.anap.mareats.ITOSDU        = {'sdu','blank'};
% GRPP.anap.mareats.USE_REALIGNED = 1;
% GRPP.anap.mareats.IFILTER_KSIZE = 3;        % Kernel size
% GRPP.anap.mareats.IFILTER_SD    = 1.5;        % Kernel SD (90% of flt in kernel)
% GRPP.anap.mareats.IROIFILTER    = 0;        % spatial filter with ROI masking
% GRPP.anap.mareats.SMART_UPDATE  = 0;        % smart update checks parameters



% % rproiTs, rpblp =========================================================================
% GRPP.anap.gettrial.PreT         = -20;              % Beginning of trial window w/ respect to event 
% GRPP.anap.gettrial.PostT        = +20;              % End of trial window w/ respect to event
% GRPP.anap.gettrial.PreT_no_motion  = -3;
% GRPP.anap.gettrial.PostT_no_motion = +3;
% GRPP.anap.gettrial.IBRAINMEAN   = 0;            % for rpgettrial()

% if strcmpi(GRPP.anap.mareats.ITOSDU{1},'none'),
%   GRPP.anap.gettrial.roiTs.Xmethod  = 'sdu';
% else
%   GRPP.anap.gettrial.roiTs.Xmethod  = 'none';
% end
% GRPP.anap.gettrial.froiTs = GRPP.anap.gettrial.roiTs;




% % GLM ====================================================================================

% GRPP.groupglm   = 'before glm';
% GRPP.glmana     = [];
% GRPP.glmconts   = {};

% GRPP.glmana{1}.mdlsct = {'mdlawake.mat[1]' 'mdlawake.mat[2]' 'mdlawake.mat[4]'};

% DNO = 1;
% GRPP.glmconts{end+1} = setglmconts('f','fVal', [],   'pVal', 0.1, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','PBR',  [ 1  1 -1  0], 'pVal', 1.0, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','NBR',  [-1 -1  1  0], 'pVal', 1.0, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','pbr',  [ 1  1  1  0], 'pVal', 1.0, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','nbr',  [-1 -1 -1  0], 'pVal', 1.0, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','PBR1', [ 1  0  0  0], 'pVal', 1.0, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','PBR2', [ 0  1  0  0], 'pVal', 1.0, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','NBR1', [-1  0  0  0], 'pVal', 1.0, 'WhichDesign',DNO);
% GRPP.glmconts{end+1} = setglmconts('t','NBR2', [ 0 -1  0  0], 'pVal', 1.0, 'WhichDesign',DNO);
