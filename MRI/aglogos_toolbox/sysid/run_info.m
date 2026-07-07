function RES = run_info(TYPE)
%RUN_INFO - Show experiment info
%  EXAMPLE :
%    INFO = run_info('polar')
%    INFO = run_info('spont')
%
  
SES = flsesgrp(TYPE);

RES = {};
for N = 1:length(SES),
  tmpses = goto(SES{N}{1});
  tmpgrp = getgrp(SES{N}{1},SES{N}{2}{1});
  tmpinf = expgetpar(tmpses,tmpgrp);

  pv = tmpinf.pvpar;
  %keyboard
  fprintf('%s(%s,nexp=%d) : %s fa=%g nseg=%d TRvol=%g TRsli=%g TRseg=%g effTE=%g TRrecov=%g\n',...
          tmpses.name,tmpgrp.name,length(tmpgrp.exps),...
          pv.acqp.PULPROG,pv.fa,pv.nseg,pv.imgtr,pv.slitr,pv.segtr,pv.effte,pv.recovtr);
  fprintf('         matrix=%gx%gx%g(%dx%dx%d,nt=%d) FOV=%gx%g',...
          pv.actres(1),pv.actres(2),pv.slithk,...
          pv.actsize(1),pv.actsize(2),pv.nsli,...
          pv.nt,pv.fov(1),pv.fov(2));
  fprintf('  reco %gx%g(%dx%d)\n',pv.res(1),pv.res(2),pv.nx,pv.ny);
  
  
  
  
  RES{N} = pv;

end
