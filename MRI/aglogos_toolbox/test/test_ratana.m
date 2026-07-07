
RAT = {};                                                                         %   registration
RAT{end+1} = {'rat6e1',   'hp', 'fl5.5.22', 'spont', 'cc1', 'fl1', 'es0', 'rp0'}; %  1 o
RAT{end+1} = {'rat6k1',   'hp', 'fl5.5.22', 'spont', 'cc0', 'fl1', 'es0', 'rp0'}; %  2 o
RAT{end+1} = {'rat6q1',   'hp', 'fl5.5.22', 'spont', 'cc1', 'fl1', 'es0', 'rp1'}; %  3 x 
RAT{end+1} = {'rat6s1',   'hp', 'fl5.5.22', 'spont', 'cc1', 'fl1', 'es0', 'rp1'}; %  4 x
RAT{end+1} = {'rat6z1',   'hp', 'fl5.5.20', 'spont', 'cc1', 'fl1', 'es0', 'rp1'}; %  5 o
RAT{end+1} = {'rat7c1',   'hp', 'fl-none',  'spont', 'cc1', 'fl0', 'es0', 'rp1'}; %  6 o
RAT{end+1} = {'rat7e1',   'hp', 'fl5.5.20', 'spont', 'cc1', 'fl1', 'es0', 'rp1'}; %  7 o
RAT{end+1} = {'rat7j1',   'hp', 'fl5.5.20', 'spont', 'cc0', 'fl1', 'es0', 'rp1'}; %  8 o
RAT{end+1} = {'rat8s1',   'hp', 'fl5.5.20', 'spont', 'cc1', 'fl1', 'es0', 'rp1'}; %  9 x
RAT{end+1} = {'rat9v2',   'hp', 'fl4.6.10', 'spont', 'cc1', 'fl1', 'es0', 'rp0'}; % 10 o
RAT{end+1} = {'rat9g1',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp1'}; % 11 o
RAT{end+1} = {'rat9h1',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp1'}; % 12 o
RAT{end+1} = {'rat9x2',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp0'}; % 13 o
RAT{end+1} = {'rata71',   'hp', 'flicker',  'spont', 'cc0', 'fl1', 'es0', 'rp1'}; % 14 o
RAT{end+1} = {'rataa1',   'hp', 'flicker',  'spont', 'cc0', 'fl1', 'es0', 'rp0'}; % 15 o
RAT{end+1} = {'rataf1',   'hp', 'flicker',  'spont', 'cc0', 'fl1', 'es0', 'rp0'}; % 16 o 
RAT{end+1} = {'ratac2',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp0'}; % 17 o
RAT{end+1} = {'ratag2',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp1'}; % 18 o
RAT{end+1} = {'ratai2',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp1'}; % 19 x
RAT{end+1} = {'rataz1',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp1'}; % 20 o
RAT{end+1} = {'rat47an2', 'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp1'}; % 21 o
RAT{end+1} = {'ratau2',   'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp1'}; % 22 o
RAT{end+1} = {'rat47b21', 'hp', 'flicker',  'spont', 'cc1', 'fl1', 'es0', 'rp0'}; % 23 x



% Locus ceroelus (LC) Sessions ---------------------
RAT = {};
RAT{end+1} = {'rat7z2',   'lc', 'fl5.5.20', 'none',  'cc0', 'fl0', 'fs0', 'es0'}; % 1
RAT{end+1} = {'rat851',   'lc', 'fl5.5.20', 'none',  'cc0', 'fl0', 'fs0', 'es0'}; % 2
RAT{end+1} = {'ratba1',   'lc', 'fl-sagg',  'spont', 'cc0', 'fl0', 'fs0', 'es0'}; % 3       
RAT{end+1} = {'rat8n1',   'lc', 'flicker',  'none',  'cc0', 'fl1', 'fs1', 'es0'}; % 4
RAT{end+1} = {'ratan2',   'lc', 'flicker',  'none',  'cc0', 'fl1', 'fs1', 'es0'}; % 5
RAT{end+1} = {'ratb81',   'lc', 'flicker',  'spont', 'cc0', 'fl1', 'fs1', 'es0'}; % 6     
RAT{end+1} = {'ratbc1',   'lc', 'flicker',  'none',  'cc0', 'fl1', 'fs1', 'es0'}; % 7
RAT{end+1} = {'ratbf1',   'lc', 'flicker',  'none',  'cc0', 'fl1', 'fs1', 'es0'}; % 8
RAT{end+1} = {'ratbg1',   'lc', 'flicker',  'none',  'cc0', 'fl1', 'fs1', 'es0'}; % 9


% for N = 1:length(RAT),
%   mana2brain(RAT{N}{1},'spont');
% end

% POOR REGISTRATION : rat6q1 rat6s1 rat8s1 ratai2 rat47b21




for N = 1:length(RAT),
  tmpses = goto(RAT{N}{1});
  if isfield(tmpses.grp,'spont'),
    tmpgrp = getgrp(tmpses,'spont');
  elseif isfield(tmpses.grp,'fstim'),
    tmpgrp = getgrp(tmpses,'fstim');
    tmpgrp = getgrp(tmpses,'fstim');
  elseif isfield(tmpses.grp,'estim'),
    tmpgrp = getgrp(tmpses,'estim');
  elseif isfield(tmpses.grp,'flicker'),
    tmpgrp = getgrp(tmpses,'flicker');
  else
    tmpgrp = getgrp(tmpses,RAT{N}{4});
  end
  ananame = tmpgrp.ana{1};
  anaindx = tmpgrp.ana{2};
  anasli  = tmpgrp.ana{3};
  matfile = sprintf('%s.mat',ananame);
  ANA = load(matfile,ananame);
  ANA = ANA.(ananame){anaindx};
  fprintf('%s(%s) %s{%d} %d/%d\n',tmpses.name,tmpgrp.name,...
          ananame,anaindx,length(anasli),size(ANA.dat,3));
  
end
  


% rat6e1(spont) rare{1} 3/3
% rat6k1(spont) rare{2} 3/240
% rat6q1(spont) rare{1} 3/3
% rat6s1(spont) rare{1} 3/3
% rat6z1(spont) rare{1} 3/3
% rat7c1(spont) rare{1} 3/3
% rat7e1(spont) rare{1} 4/4
% rat7j1(spont) rare{1} 4/4
% rat8s1(spont) rare{1} 4/4
% rat9v2(spont) rare{1} 9/9
% rat9g1(spont) rare{1} 7/7
% rat9h1(spont) rare{1} 9/9
% rat9x2(spont) rare{1} 9/9
% rata71(spont) rare{1} 9/9
% rataa1(spont) rare{1} 9/9
% rataf1(spont) rare{1} 9/9
% ratac2(spont) rare{1} 5/5
% ratag2(spont) rare{1} 5/5
% ratai2(spont) rare{1} 5/5
% rataz1(spont) rare{1} 5/9
% rat47an2(spont) flash{1} 4/4
% ratau2(spont) rare{1} 4/4
% rat47b21(spont) rare{1} 4/4

% !!! rataf1/rataa1 as 1/2 the best.




% rat7z2(fstim) rare{1} 8/8
% rat851(fstim) rare{1} 8/8
% ratba1(estim) rare{1} 8/8   **  LC
% rat8n1(estim) rare{1} 8/8
% ratan2(fstim) rare{1} 10/10
% ratb81(spont) rare{1} 8/8   ** LC 2
% ratbc1(fstim) rare{1} 8/8   *  LC
% ratbf1(fstim) rare{1} 8/8   *
% ratbg1(fstim) rare{1} 8/8   *

