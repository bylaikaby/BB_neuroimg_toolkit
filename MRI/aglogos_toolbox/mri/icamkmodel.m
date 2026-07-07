function icamkmodel(Arg1, Arg2)
%ICAMKMODEL - Make models from the IC defined in anap.ic2mdl
% ICAMKMODEL(Arg1, Arg2)
%   Arg1 - SesName or ICA
%   Arg2 - GrpName or nothing
%
% ----------------------------------------------------------------------------------------------------
% The ICA Structure in the ESGETPARS or individual description file
% ----------------------------------------------------------------------------------------------------
% FOR CLNSPC
% GRPP.anap.ica.ClnSpc.evar_keep  = 20;
% GRPP.anap.ica.ClnSpc.dim        = 'spatial';
% GRPP.anap.ica.ClnSpc.type       = 'bell';
% GRPP.anap.ica.ClnSpc.normalize  = 'none';
%
% FOR ROITS ETC.
% GRPP.anap.ica.roinames          = {'SC','LGN','V1','V2'};
% GRPP.anap.ica.evar_keep         = 20;           % Numbers of PCs to keep
% GRPP.anap.ica.dim               = 'spatial';    % Temporal does not really work...
% GRPP.anap.ica.type              = 'bell';       % The Tony Bell algorithm
% GRPP.anap.ica.normalize         = 'none';       % No normalization (e.g. to SD etc.)
% GRPP.anap.ica.period            = 'all';        % blank, stim, all...
% GRPP.anap.ica.icomp             = [1:6];
% GRPP.anap.ica.ic2mdl            = [];           % Use the following ICs as models for GLM
% GRPP.anap.ica.DISP_THRESHOLD    = 2;            % For SHOWICA only 
%
% The following variables are used when we select IC components by estimating their
% correlation with a given model, e.g. mixica. This is not used very much, because in the
% microstimulation experiments the "model" is quite unpredictable (see for example
% H05Tm1/visesmix).
% ============================================================
% I think the best selection is LOOKING AT THE DATA!!!
% ============================================================
% GRPP.anap.ica.MdlName           = 'mixica';       % 'combica' for VISESCOMB groups
% GRPP.anap.ica.pVal              = 0.05;           % pVal for corr(mixica,IComponent)
% GRPP.anap.ica.rVal              = 0.6;            % rVal-thr for corr(mixica,IComponent)
% GRPP.anap.ica.NoComponents      = 10;             % How many ICs were selected...
% ----------------------------------------------------------------------------------------------------
%
% EXAMPLE :
%   showica('h03fi1','visesmix')
%   showica('h05tm1','visesmix')    - Excellent example of IC  !!
%
% ICA structure:
%         ana: [72x72x12 double]
%          ds: [0.7500 0.7500 2]
%      slices: [4 5 6 7 8 9]
%         map: [20x2575 double]
%      colors: {1x34 cell}
%     anapica: [1x1 struct]
%       mview: [1x1 struct]
%         raw: [1x1 struct]
%          ic: [1x1 struct]
% ICA.raw
%     session: 'h05tm1'  grpname: 'visesmix'   ExpNo: [1x40 double]
%      coords: [2575x3 double]
%         dat: [120x20 double]
%         err: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
% ICA.ic
%     session: 'h05tm1'  grpname: 'visesmix'   ExpNo: [1x40 double]
%         dat: [120x20 double]
%          dx: 2
%         stm: [1x1 struct]
%  
% NKL 11.06.09

if ischar(Arg1),
  SesName = Arg1;
  if nargin < 2,
    help icamkmodel;
    return;
  end;
  GrpName = Arg2;
  tcICA =  icaload(SesName, GrpName);
else
  tcICA = Arg1;
end;

raw = tcICA.raw;
raw = xform(raw,'tosdu','prestim');

anap = getanap(raw.session, raw.grpname);

model.session     = raw.session;
model.grpname     = raw.grpname;
model.ExpNo       = raw.ExpNo;
model.type        = 'IC-Based Model';
model.dir.dname   = 'icamdl';
model.dsp.func    = 'dspmodel';
model.dsp.label   = {'Power in SDU'  'Time in sec'};
model.stm         = raw.stm;

model.name        = anap.ica.mdlname;
for N=1:length(anap.ica.ic2mdl),
  for K=1:length(anap.ica.ic2mdl{N}),
    if anap.ica.ic2mdl{N}(K) < 0,
      raw.dat(:,abs(anap.ica.ic2mdl{N}(K))) = -1 * raw.dat(:,abs(anap.ica.ic2mdl{N}(K)));
    end;
  end;
end;
for N=1:length(anap.ica.ic2mdl),
  model.dat(:,N) = hnanmean(raw.dat(:,abs(anap.ica.ic2mdl{N})),2);
end;
model.dx = raw.dx;
matfile = sprintf('ICAMDL_%s.mat', model.grpname);
save(matfile,'model');
fprintf('ICAMKMODEL: Structure "model" saved in %s/%s\n', pwd, matfile);

return;
