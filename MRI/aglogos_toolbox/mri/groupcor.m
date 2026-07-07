function oSig = groupcor(varargin)
%GROUPCOR - Groups cor stuff, usually called from catsig().
%  oSig = groupcor(Ses,GrpName,[RoiNames])
%  oSig = groupcor(roiTs/troiTs,[RoiNames])
% 
%
%  VERSION :
%    0.90 12.01.06 YM  pre-release
%
%  See also CATSIG GRPMAKE

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end


RoiNames = {};
if issig(varargin{1}) > 0,
  % called like groupcor(roiTs,[RoiNames]);
  oSig = varargin{1};
  if nargin > 1,  RoiNames = varargin{2};  end
  [v info] = issig(oSig);
  Session = info.session;
  GrpName = info.grpname;
else
  % called like groupcor(Session,GrpNames,[RoiNames]);
  Session = varargin{1};
  GrpName = varargin{2};
  if nargin > 2,  RoiNames = varargin{3};  end
  oSig = {};
end

if isnumeric(GrpName),
  error('\nERROR %s: GrpName must be a group name.\n',mfilename);
end

% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses  = goto(Session);
grp  = getgrp(Ses,GrpName);
EXPS = grp.exps;
anap = getanap(Ses,grp);

if isfield(grp,'groupcor') & ~isempty(grp.groupcor),
  switch lower(grp.groupcor),
   case {'average after cor','averageaftercor',...
         'group after cor','groupaftercor', 'after cor', 'aftercor'}
    return;    % NO NEED TO DO...
   
   case {'average before cor','averagebeforecor',...
         'group before cor','groupbeforecor', 'before cor', 'beforecor'}
    
    if ~isfield(grp,'corana') | isempty(grp.corana),
      return;    % NO WAY TO GROUP...
    end
    if isfield(grp,'refgrp') & ~isempty(grp.refgrp),
      if ischar(grp.refgrp.grpexp) & ~strcmpi(grp.refgrp.grpexp,GrpName),
        % no need to run cor grouping.
        return;
      end
    end
   
   otherwise
    error('\n%s ERROR: unknown grouping method for COR (Ses=%s,grp=%s).\n',...
          mfilename,Ses.name,grp.name);
  end
else
  % NO NEED TO DO...
  return;
end

if isempty(oSig),
  if isfield(anap,'gettrial') & ~isempty(anap.gettrial) & anap.gettrial.status > 0,
    oSig = sigload(Ses,grp.name,'troiTs');
    if isempty(oSig),
      if isawake(grp),
        oSig = catsig_awake(Ses,EXPS,'troiTs',RoiNames);
      else
        oSig = catsig(Ses,EXPS,'troiTs',RoiNames);
      end
    end;
  else
    oSig = sigload(Ses,grp.name,'roiTs');
    if isempty(oSig),
      oSig = catsig(Ses,EXPS,'roiTs',RoiNames);
    end;
  end
end

DO_MCORANA = 1;
if isfield(anap,'gettrial') & ~isempty(anap.gettrial) & anap.gettrial.status > 0,
  % no need to do mcorana for roiTs
  if ~isfield(anap.gettrial,'trial2obsp'),
    anap.gettrial.trial2obsp = 0;
  end
  if anap.gettrial.trial2obsp == 0 & ~iscell(oSig{1}),  DO_MCORANA = 0;  end
else
  % no need to do mcorana for troiTs
  if iscell(oSig{1}),  DO_MCORANA = 0;  end
end
  
if DO_MCORANA,
  oSig = mcorana(oSig);
end

% % create mask data for refgrp, if needed.
[refEXPS, refGRPS] = subCheckRefGrp(Ses,grp.name);

if 0,
if ~isempty(refEXPS),
  sesgetmask(Ses,refEXPS);
end
if ~isempty(refGRPS),
  sesgetmask(Ses,refGRPS);
end
end;

if ~issig(varargin{1}) & nargout == 0,
  anap = getanap(Ses,grp.name); 
  if isfield(anap,'gettrial') & anap.gettrial.status > 0,
  %if iscell(oSig{1}),
    sigsave(Ses,grp.name,'troiTs',oSig);
  else
    sigsave(Ses,grp.name,'roiTs',oSig);
  end
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get groups and exps for masking
function [EXPS GRPS] = subCheckRefGrp(Ses,GrpName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
EXPS = [];
GRPS = {};

groups = getgroups(Ses);
for N = 1:length(groups),
  tmpgrp = groups{N};
  if ~isfield(tmpgrp,'refgrp') | ~isfield(tmpgrp.refgrp,'grpexp'),
    continue;
  end
  if ~isempty(tmpgrp.refgrp.grpexp),
    if ischar(tmpgrp.refgrp.grpexp),
      % group name
      GRPS{end+1} = tmpgrp.refgrp.grpexp;
    else
      % experiment number
      EXPS(end+1) = tmpgrp.refgrp.grpexp;
    end
  end
end

EXPS = unique(EXPS);
for N = 1:length(EXPS),
  if ~any(grp.exp == EXPS(N)),
    EXPS(N) = 0;
  end
end
EXPS = EXPS(find(EXPS ~= 0));


GRPS = unique(GRPS);
GRPS = GRPS(strcmpi(GRPS,grp.name));
return;
