% for test
%SES{01} = 'm02lx1';

% for movie STS
%SES{01} = 'n03mt1';
%SES{02} = 'n02mv1';
%SES{03} = 'c01nn1';
%SES{04} = 'j02np1';
%SES{05} = 'd04qd1';
SES{06} = 'j02qf1';

for iSes = 1:length(SES),
  if isempty(SES{iSes}), continue; end
  SESSION = SES{iSes};

  %sesdumppar(SESSION);
  %sesimgload(SESSION);
  
  sesareats(SESSION);
  sesgrpmake(SESSION,[],'roiTs');
  sessupgrp(SESSION,'zmov01','img','roiTs');
  
  sesconfunc(SESSION,[],'kc');
  sesgrpmake(SESSION,[],'kc2');
  sessupgrp(SESSION,'zmov01','dep','kc2');

  %sesconfunc(SESSION,[],'minew');

end
