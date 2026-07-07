% CURRENT MONKEY SESSIONS (10.01.2012)
MATL2ROI = {};
MATL2ROI{end+1} = {'e10971',  'epi',     'nmi',          10,         1}; % 1 poor (epi/ana)...
  MATL2ROI{end+1} = {'e108e2',  'epi',     'ecc',          10,         1}; % 2 ok(epi)...
  MATL2ROI{end+1} = {'g10991',  'epi',     'ecc',          10,         1}; % 3 maybe ok(epi), but skewed epi
  MATL2ROI{end+1} = {'e109l1',  'ana',     'ecc',          10,         1}; % 4 bad (epi/ana)
  MATL2ROI{end+1} = {'g109r1',  'epi',     'ecc',          10,         1}; % 5 maybe ok(epi)
  MATL2ROI{end+1} = {'i02a11',  'epi',     'ecc',          10,         1}; % 6 ok(epi)
  MATL2ROI{end+1} = {'e10a31',  'epi',     'ecc',          10,         1}; % 7 maybe ok(epi)
  MATL2ROI{end+1} = {'g10a21',  'epi',     'ecc',          10,         1}; % 8 good

  MATL2ROI{end+1} = {'i11av1',  'ana',     'ecc',          10,         1}; % 9
  MATL2ROI{end+1} = {'e10aw1',  'ana',     'ecc',          10,         1}; %10
  MATL2ROI{end+1} = {'g10ax1',  'ana',     'ecc',          10,         1}; %11
  MATL2ROI{end+1} = {'i11bb1',  'ana',     'ecc',          10,         1}; %12
  MATL2ROI{end+1} = {'g10bg1',  'ana',     'ecc',          10,         1}; %13
  MATL2ROI{end+1} = {'e10bf1',  'ana',     'ecc',          10,         1}; %14
  MATL2ROI{end+1} = {'e10bv1',  'ana',     'ecc',          10,         1}; %15
  MATL2ROI{end+1} = {'i11bu1',  'ana',     'ecc',          10,         1}; %16

for N = 1:length(MATL2ROI)
  ses = MATL2ROI{N}{1};
  mrhesusatlas2ana(ses,'spont','export',1,'coregister',0,'makeroi',0,...
                   'epi',0,'dir','atlas_photoshop');
  mrhesusatlas2ana(ses,'spont','export',1,'coregister',0,'makeroi',0,...
                   'epi',1,'dir','atlas_photoshop');
end

return



















%   G10aX1               - - 10 Nov 11: fMRI+Neurophys in 4.7T
%   E10aW1               - - 09 Nov 11: fMRI+Neurophys in 4.7T
%   I11aV1               - - 08 Nov 11: fMRI+Neurophys in 4.7T



%   E10ai1               - - 30 Sep 11: fMRI+Neurophys in 7T



%   E108E2               - - 20 Jun 11: fMRI+Neurophys in 4.7T
%   E109l1               - - 02 Aug 11: fMRI+Neurophys in 7T
%   E109O1               - - 31 Aug 11: fMRI+Neurophys in 4.7T
%   E10971               - - 19 Jun 11: fMRI+Neurophys in 7T
%   E10a31               - - 15 Sep 11: fMRI+Neurophys in 4.7T

%   G109N1               - - 30 Aug 11: fMRI+Neurophys in 4.7T
%   G109r1               - - 08 Aug 11: fMRI+Neurophys in 7T
%   G10991               - - 21 Jun 11: fMRI+Neurophys in 7T
%   G10a21               - - 14 Sep 11: fMRI+Neurophys in 4.7T

%   I02a11               - - 13 Sep 11: fMRI+Neurophys in 4.7T


% LATEST SESSIONS
%   I11bb1               - - 24 Nov 11: fMRI+Neurophys in 4.7T
%   E10bf1               - - 28 Nov 11: fMRI+Neurophys in 4.7T
%   G10bg1               - - 29 Nov 11: fMRI+Neurophys in 4,7T
%   I11bu1               - - 13 Dec 11: fMRI+Neurophys in 4,7T
%   E10bv1               - - 14 Dec 11: fMRI+Neurophys in 4,7T


%   B04bi1               - - 01. Dez 11: Neurophys in 7T awake Monkey
%   B04bn1               - - 05. Dez 11: Neurophys in 7T awake Monkey
%
%   B04bo1               - - 07. Dez 11: Neurophys in 7T awake Monkey
%   B04bp1               - - 08. Dez 11: Neurophys in 7T awake Monkey
%   B04bw1               - - 15. Dez 11: Neurophys in 7T awake Monkey
%   B04bx1               - - 16. Dez 11: Neurophys in 7T awake Monkey





SES = {};

% SES{end+1} = 'E10ai1';  % phys-only DONE/COPIED




SES = {};
% SES{end+1} = 'E108E2';  % ROI  DONE/COPIED/MOVED
% SES{end+1} = 'E109l1';  % ROI  DONE/COPIED/MOVED
% SES{end+1} = 'E109O1';  % ROI, problem in sesgetevent(), ExpNo=3  DONE/COPIED/MOVED
% SES{end+1} = 'E10971';  % ROI  DONE/COPIED/MOVED...
% SES{end+1} = 'E10a31';  % ROI  DONE/COPIED
% SES{end+1} = 'E10aW1';  % ROI  DONE/COPIED


% % ==========================================
% SES = {};
% SES{end+1} = 'G109N1';  % ROI, bad coreg  DONE/COPIED/MOVED
% SES{end+1} = 'G109r1';  % ROI  DONE/COPIED/MOVED
% SES{end+1} = 'G10991';  % ROI  DONE/COPIED/MOVED
% SES{end+1} = 'G10a21';  % ROI, poor coreg  DONE/COPIED
% SES{end+1} = 'G10aX1';  % ROI  DONE/COPIED

% SES{end+1} = 'I02a11';  % ROI  DONE/COPIED
% SES{end+1} = 'I11aV1';  % ROI  DONE/COPIED


% % ==========================================
% SES = {};
% SES{end+1} = 'I11bb1';  % ROI  DONE/COPIED
% SES{end+1} = 'E10bf1';  % ROI  DONE/COPIED
% SES{end+1} = 'G10bg1';  % ROI  DONE/COPIED
% SES{end+1} = 'I11bu1';  % ROI  DONE/COPIED
% SES{end+1} = 'E10bv1';  % ROI  DONE/COPIED

% % ==========================================
% SES = {};
% SES{end+1} = 'B04bi1'; % NKL
% SES{end+1} = 'B04bn1'; % NKL
% SES{end+1} = 'B04bo1'; % NKL
%SES{end+1} = 'B04bp1'; % ???
% SES{end+1} = 'B04bw1';  % ROI  DONE/COPIED
SES{end+1} = 'B04bx1';  % ROI DONE/COPIED




for N = 1:length(SES)
  tmpses = SES{N};
  %sesdumppar(tmpses);
  
  sesimgload(tmpses);
  
  %sesclnadjevt(tmpses);
  sesgetcln(tmpses);
  
end

%return



for N = 1:length(SES)
  tmpses = SES{N};
  sesclnspc(tmpses);
  sesgetblp(tmpses);
  sesgetspk(tmpses);
end

% return



% % first mroi(), then do...
for N = 1:length(SES)
  tmpses = SES{N};
  
  sesareats(tmpses);
end



% for N = 1:length(SES)
%   tmpses = SES{N};
%   matlas2roi(tmpses,'spont');  % need to be run due to imgrop
%   paxrenameroi(tmpses,'roi_set','Atlas_spont')
% end


% for N = 1:length(SES),
%   gnames = getgrpnames(SES{N});
%   fprintf('%s:',SES{N});
%   for K = 1:length(gnames),
%     fprintf(' %s',gnames{K});
%   end
%   fprintf('\n');
% end




for N = 1:length(SES),
  tmpses = SES{N};
  gnames = getgrpnames(tmpses);
  for K = 1:length(gnames)
    tmpgrp = gnames{K};
    if strncmpi(tmpgrp,'spont',5),
      sesgetevent(tmpses, tmpgrp);
      % %rpspec(tmpses, tmpgrp, 'hip',1); % spectral-clustering of events
      rpsesgettrial(tmpses, tmpgrp, {'blp','roiTs'});
      sesgrpmake(tmpses, tmpgrp, {'rpblp','rproiTs'});
      rpmkmodel(tmpses,tmpgrp);
      sesgroupglm(tmpses,tmpgrp);
    end
    if strncmpi(tmpgrp,'flicker',7),
      sesgettrial(tmpses, tmpgrp,{'blp'});
      sesgrpmake(tmpses, tmpgrp,{'tblp','tClnSpc'});
    end
    % if strncmpi(tmpgrp,'microstim',9),
    %   sesgettrial(tmpses,tmpgrp,'roiTs');
    %   sesgrpmake(tmpses,tmpgrp,'troiTs');
    %   sesgroupglm(tmpses,tmpgrp);
    % end
  end
end
