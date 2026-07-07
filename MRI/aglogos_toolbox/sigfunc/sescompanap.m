function is_equal = sescompanap(SesName,GrpExp,SigName,varargin)
%SESCOMPANAP - Check whether analysis-parameters of 'SigName" is the same as the one in the description file.
%  is_equal = sescompanap(SesName,GrpName,SigName,...)
%  is_equal = sescompanap(SesName,ExpNo,  SigName,...) checks whether analysis parameters of
%  the given "SigName" is the same as the one in the description/session file.
%
%  'SigName:  blp, roiTs, froiTs
%
%  Supported options:
%    'allexps' : 0|1, check all exps in GrpName or check only the first exp
%
%  EXAMPLE :
%   is_equal = sescompanap(SesName,GrpName,'blp','allexps',1);   % checks all exps in GrpName
%   is_equal = sescompanap(SesName,GrpName,'blp','allexps',0);   % checks only the first exp
%   is_equal = sescompanap(SesName,ExpNo,  'blp')
%
%  VERSION :
%    0.90 03.07.2019 YM  pre-release
%
%  See also getanap

if nargin < 3, eval(['help ' mfilename]); return;  end

CHECK_ALL_EXPS_IN_GROUP = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'checkallexps' 'allexp' 'allexps'}
    CHECK_ALL_EXPS_IN_GROUP = varargin{N+1};
   case {'checksingleexp' 'singleexp'}
    CHECK_ALL_EXPS_IN_GROUP = ~any(varargin{N+1});
  end
end


Ses = getses(SesName);
if isnumeric(GrpExp)
  % GrpExp as exps
  EXPS = GrpExp;
else
  % GrpExp as GrpName
  GrpName = GrpExp;
  grp = getgrp(Ses,GrpName);
  EXPS = grp.exps;
  if ~any(CHECK_ALL_EXPS_IN_GROUP)
    EXPS = EXPS(1);
  end
end

is_equal = zeros(1,length(EXPS));
for N = 1:length(EXPS)
  ExpNo = EXPS(N);
  anap = getanap(SesName,ExpNo);

  switch lower(SigName)
   case {'blp'}
    tmpval =  sub_check_blp(SesName,ExpNo,anap);
   case {'roits'}
    tmpval = sub_check_roits(SesName,ExpNo,anap,'roiTs');
   case {'froits'}
    tmpval = sub_check_roits(SesName,ExpNo,anap,'froiTs');
   otherwise
    error('ERORR %s: SigName(%s) is not yet supported.\n',mfilename,SigName);
  end
  
  is_equal(N) = tmpval;
  
end

return




% ============================================================
function is_update = sub_check_blp(SesName,ExpNo,anap)
% ============================================================
is_update = 1;
sig = sigload(SesName,ExpNo,'blp');
infoA = anap.siggetblp;
infoS = sig.info;

fields = intersect(fieldnames(infoA),fieldnames(infoS));
for N = 1:length(fields)
  tmpf = fields{N};
  if ~isequal(infoA.(tmpf),infoS.(tmpf))
    is_update = 0;  break;
  end
end



% ============================================================
function is_update = sub_check_roits(SesName,ExpNo,anap,SigName)
% ============================================================
is_update = 1;
sig = sigload(SesName,ExpNo,SigName);  % roiTs, froiTs
infoA = anap.mareats;
if isfield(anap,SigName) && isfield(anap.(SigName),'mareats')
  % anap.roiTs.mareats or anap.froiTs.mareats
  infoA = sctmerge(infoA,anap.(SigName).mareats);
end
infoS = sig{1}.info;


fields = intersect(fieldnames(infoA),fieldnames(infoS));
for N = 1:length(fields)
  tmpf = fields{N};
  if ~isequal(infoA.(tmpf),infoS.(tmpf))
    is_update = 0;  break;
  end
end
