function check_pvpar(Ses,EXPS)
%check_pvpar - checks pvpar.
%
%

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end
if nargin < 2,  EXPS = [];  end

Ses = goto(Ses);
EXPS = getexps(Ses,EXPS);

fprintf('=====================================================\n');
fprintf('%s: Data=''%s''\n',mfilename,pwd);
for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%3d/%d %s ExpNo=%3d: ',iExp,length(EXPS),Ses.name,ExpNo);
  if isimaging(Ses,ExpNo),
    par = expgetpar(Ses,ExpNo);
    pvpar = par.pvpar;
    reco = par.pvpar.reco;
    fprintf('%s %s res=[%g %g %g] dx=%g\n',reco.RECO_byte_order,reco.RECO_wordtype,...
            pvpar.res(1), pvpar.res(2), pvpar.slithk, pvpar.imgtr);
  else
    fprintf('not imaging, skip\n');
  end
  
end

return
