function mnareats(SESSION,GRPNAME,NORM,USE_PCA)
%MNAREATS - creates roiTs structure
%  MNAREATS(SESSION)
%  MNAREATS(SESSION,GRPNAME) creats roiTs.
%  MNAREATS(SESSINO,GRPNAME,NORM) creats roiTs with normalization of NORM.
%
%  VERSION :
%    0.90 18.01.06 YM  pre-release
%
%  See also MN_ROITS_CAT MN_ROITS_GET MNNORMALIZE

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if nargin < 2,  GRPNAME = {};  end
if nargin < 3,  NORM = 'global'; end
if nargin < 4,  USE_PCA = [];  end

if isempty(GRPNAME),
  GRPNAME = getgrpnames(SESSION);
end
if ischar(GRPNAME),  GRPNAME = { GRPNAME };  end
if isempty(USE_PCA),  USE_PCA = 0;  end
if ischar(NORM) & ~isempty(NORM),  NORM = { NORM };  end


for N = 1:length(GRPNAME),
  subDoAreats(SESSION,GRPNAME{N},NORM,USE_PCA);
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subDoAreats(SESSION,GRPNAME,NORM,USE_PCA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
anap = getanap(SESSION,GRPNAME);


fprintf('%s %s: NORM=%s, USE_PCA=%d\n',...
        datestr(now,'HH:MM:SS'),mfilename,NORM{1},USE_PCA);
ROI = load('Roi.mat',grp.grproi);
ROI = ROI.(grp.grproi);
ROI.roinames = union(ROI.roinames,Ses.roi.names);


% GET A TIME COURSE FOR NORMALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(NORM) && ~isempty(NORM),  NORM = { NORM; };  end
if ~isempty(NORM) && ~any(strcmpi(NORM,'none')),
  NORM = mn_roits_cat(mn_roits_get(ROI,grp,NORM,[],USE_PCA));
  if isempty(strfind(NORM.name,'regress')),
    NORM.dat = mean(NORM.dat,2);
  end
else
  NORM = {};
end





% GET TIME COURSES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROINAME = Ses.roi.names;
if isfield(anap,'mareats') & ~isempty(anap.mareats.IEXCLUDE),
  tmpflag = zeros(size(ROINAME));
  for N = 1:length(anap.mareats.IEXCLUDE),
    tmpflag = tmpflag | strcmpi(ROINAME,anap.mareats.IEXCLUDE{N});
  end
  ROINAME = ROINAME(find(~tmpflag));
end

fprintf(' loding roiTs...');
roiTs = {};
for N = 1:length(ROINAME),
  fprintf('%s.',ROINAME{N});
  tmpts = mn_roits_cat(mn_roits_get(ROI,grp.name,ROINAME{N},[],USE_PCA));
  if ~isempty(tmpts),
    tmpts.dat = double(tmpts.dat);
    if ~isempty(NORM),
      tmpts = mnnormalize(tmpts,NORM);
      %for K = 1:size(tmpts.dat,2),
      %  tmpts.dat(:,K) = tmpts.dat(:,K) ./ NORM.dat;
      %end
    end
    tmpts.slice = -1;
    roiTs{end+1} = tmpts;
  end
end

fprintf(' done.\n');

sigsave(Ses,grp.name,'roiTs',roiTs);


return;

