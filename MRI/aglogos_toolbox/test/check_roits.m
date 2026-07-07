function check_roits(Ses,EXPS)
%check_roits - checks whether spatian smoothing was applied or not.
%
%

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end
if nargin < 2,  EXPS = [];  end

Ses = goto(Ses);
EXPS = getexps(Ses,EXPS);

fprintf('%s: Data=''%s''\n',mfilename,pwd);
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%3d/%d %s ExpNo=%3d: ',iExp,length(EXPS),Ses.name,ExpNo);
  if isimaging(Ses,ExpNo),
    roiTs = sigload(Ses,ExpNo,'roiTs');
    is_ok = sub_check(roiTs);
    if is_ok,
      fprintf('ok.\n');
    else
      fprintf('RUN sesareats() again !!!!\n');
    end
  else
    fprintf('not imaging, skip\n');
  end
  
end

return


function is_ok = sub_check(roiTs)

is_ok = 1;
for iRoi = 1:length(roiTs),
  tmpinfo = roiTs{iRoi}.info;
  if tmpinfo.IMIMGPRO > 0 & tmpinfo.IFILTER > 0,
    is_ok = 0;  break;
  end
end

return
