function RES = flmulticor(TYPE)
%FLTMULTICOR - Script to call the TESTMULTICOR function
  
SES = flsesgrp(TYPE);

RoiName = 'all'; EleName = 'all';

RoiName = 'eleV1';  EleName = 'V1';
RoiName = 'eleV2';  EleName = 'V2';

%RoiName = 'V1';  EleName = 'V2';
%RoiName = 'V2';  EleName = 'V1';


RES = {};
for N = 1:length(SES),
  tmpres = testmulticor(SES{N}{1},SES{N}{2}{1},'plot',1,...
                   'RoiName',RoiName,'StimGroup','none');
  if isempty(tmpres),  continue;  end
  RES{end+1} = tmpres;
  clear tmpres;
end
return


