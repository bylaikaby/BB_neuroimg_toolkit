function showavgresp(fname,varargin)
%SHOWAVGRESP - Shows all roiTs/avgTs from project-files (e.g. visesmix_lgn)
%
% >> showavgresp('visesmix_lgn','fmt','paper2');
% >> showavgresp('visesmix_otpul','fmt','paper1');
% >> showavgresp('visesmix_otpul','fmt','paper1','barplot',1);

% See also XAVERAGE SHOWAVGRESP XFIT
% NKL 25.02.07

if nargin < 1,
  fname = 'visesmix_lgn';
end;
fname = strcat(fname,'.mat');
tmp = findstr(fname,'_');
exptype = lower(fname(1:tmp-1));
essite = fname(tmp+1:end);
tmp = findstr(essite,'.');
essite = lower(essite(1:tmp-1));

FMTTYPE     = 'default';    % Default is paper
ROITSTYPE   = 'avgTs';
FIGFLAG     = 1;
MASK        = 1;            % select MASK to display (e.g. fVal, PVS, NVS)
STDERROR    = 0;            % If set uses errorbar otherwise CI
BSTRP       = 1000;         % low and high confidence interval
CIVAL       = [1 99];       % low and high confidence interval
STMLINES    = 0;            % If set draws rectangles and lines; otherwise no lines
YLIM        = [-1 2];       % common scale
COL_LINE    = [];           % Line color for CI plots
COL_FACE    = [];           % shading color for CI plots
ABSFREQ     = 1;            % If set, (pes & nes)/sum(pes&nes); otherwise as % of MASK
BARPLOT     = 0;            % bar plot with voxfrequencies
LGND        = 0;            % if set, display voxfreq as legend
SDUNITS     = 0;
SELECT      = [];

% ---------------------------------------------------
% PARSE INPUT
% ---------------------------------------------------
for N=1:2:length(varargin),
  switch lower(varargin{N}),
   case {'select'}
    SELECT = varargin{N+1};
   case {'sdunits'}
    SDUNITS = varargin{N+1};
   case {'roits'}
    ROITSTYPE = varargin{N+1};
   case {'fmt'}
    FMTTYPE = varargin{N+1};
   case {'figure'}
    FIGFLAG = varargin{N+1};
   case {'stderror'}
    STDERROR = varargin{N+1};
   case {'cival'}
    CIVAL = varargin{N+1};
   case {'linecolor'}
    COL_LINE = varargin{N+1};
   case {'facecolor'}
    COL_FACE = varargin{N+1};
   case {'ylim'}
    YLIM = varargin{N+1};
   case {'mask'}
    MASK = varargin{N+1};
   case {'stmlines'}
    STMLINES = varargin{N+1};
   case {'absfreq'}
    ABSFREQ = varargin{N+1};
   case {'barplot'}
    BARPLOT = varargin{N+1};
   case {'bstrp'}
    BSTRP = varargin{N+1};
   case {'ylabel'}
    YLABEL = varargin{N+1};
   otherwise,
    fprintf('Unknown option!\n');
    return;
  end
end

DEF_varargin = {'sdunits',SDUNITS,'roits',ROITSTYPE,'fmt',FMTTYPE,'figure',FIGFLAG,'stderr',STDERROR,...
                'cival',CIVAL,'linecolor',COL_LINE,'facecolor',COL_FACE,'ylim',YLIM,'mask',MASK,...
                'stimlines',STMLINES,'absfreq',ABSFREQ,'barplot',BARPLOT,'bstrp',BSTRP,...
                'ylabel','Percent Signal Change'};

% ---------------------------------------------------
% info = 
%        SupGrpName: 'visesmix_lgn'
%         MaskNames: {'pvs'  'nvs'}
%          MdlNames: {'pes'  'nes'}
%          RoiNames: {'LGN'  'SC'  'Pul'  'V1'  'V2'  'MT'  'XC'  'Brain'}
%               SES: {1x16 cell}
%     NumOfSubjects: 7
%     NumOfSessions: 16
%       NumOfGroups: 16
%         NumOfExps: 275
%             MTneg: [1 2 3 4 5 6 7 8 9 10 11]
%             MTpos: [12 13 14 15 16]
%            colmap: {[1 0 0]  [0 0 1]  [0 0.5000 0]  [0 0 0]  [1 0 1]  [0 1 1]}

% [ses,info] = esgetses(exptype,essite);
es_goto;
load(fname);

if ~isempty(SELECT),
  if ischar(SELECT),
    switch(lower(SELECT)),
     case 'all',
      SELECT = [];
     case 'mtp',
      SELECT = info.MTpos;
     case 'mtn',
      SELECT = info.MTneg;
     case 'allneg',
      SELECT = info.Allneg;
     otherwise,
    end;
  end;
end;

if ~isempty(SELECT),
  for N=1:length(AvgResp),
    for K=1:length(AvgResp{N}.roiTs),
      AvgResp{N}.avgTs{K}.dat = AvgResp{N}.avgTs{K}.dat(:,SELECT);
    end;
  end;
end;

if SDUNITS,
  for N=1:length(AvgResp),
    for K=1:length(AvgResp{N}.roiTs),
      AvgResp{N}.avgTs{K} = xform(AvgResp{N}.avgTs{K},'tosdu');
    end;
  end;
end;  

keyboard
  
dspavgresp(AvgResp,info,DEF_varargin{:});

