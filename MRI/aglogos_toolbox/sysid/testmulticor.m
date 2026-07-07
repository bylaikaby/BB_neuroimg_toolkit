function RES = testmulticor(Ses,GrpExp,varargin)
%TESTMULTICOR - Testing multiple correlations
%  
% SET OPTIONS
METHOD     = 'corr';
RoiName    = 'eleV1';
EleName    = 'V1';
AddSpike   = 1;
ResampleHz = 'bold';
StimGrp    = 'none';  % for masking roits
DO_PLOT    = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roiname','roi'}
    RoiName = varargin{N+1};
   case {'ele','elename','elenames'}
    EleName = varargin{N+1};
   case {'method'}
    METHOD = varargin{N+1};
   case {'stimgrp','stimgroup'}
    StimGrp = varargin{N+1};
   case {'sdf','addsdf','add_sdf','add_spike','addspike'}
    ADD_SDF = varargin{N+1};
  case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'plot'}
    DO_PLOT = varargin{N+1};
  end
end
  


Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
if isnumeric(GrpExp) && ~isempty(GrpExp),
  EXPS = GrpExp;
else
  EXPS = grp.exps;
end

fprintf('%s %s: %s %s(%s)  ',datestr(now,'HH:MM:SS'),mfilename,...
        Ses.name,RoiName,METHOD);
if ischar(GrpExp) && ~isempty(GrpExp),
  fprintf('(%s,nexp=%d): ',GrpExp,length(EXPS));
else
  fprintf('(nexp=%d): ',length(EXPS));
end


mrimask = [];
if any(StimGrp) && ~strcmpi(StimGrp,'none'),
  fprintf(' mask(%s).',StimGrp);
  mrimask = mvoxselect(Ses,StimGrp,'all','fhemo+',[],0.01,'verbose',0);
end

fprintf('corr');
RES = [];
for iExp = 1:length(EXPS),
  fprintf('.');
  ExpNo = EXPS(iExp);
  tmpres = sub_multicor(Ses,ExpNo,RoiName,EleName,METHOD,mrimask,AddSpike,ResampleHz);  
  if isempty(tmpres),
    fprintf(' no Roi, skipping\n');
    return;
  end
  RES = sub_cat(RES,tmpres);
end


RES.dat = nanmean(RES.dat,4);

if DO_PLOT,
  sub_plot(RES);
end

fprintf(' done.\n');

return



function RES = sub_cat(RES,newres)

if isempty(RES),  
  RES = newres;
  RES      = rmfield(RES,'U');
  RES.fmri = rmfield(RES.fmri,{'x','projected'});
  RES.ephys = rmfield(RES.ephys,'projected');
  return
end

if isfield(RES,'exps'),
  RES.exps = cat(2,RES.exps,newres.exps);
end



RES.fmri.weights = cat(2,RES.fmri.weights,newres.fmri.weights);
for N = 1:length(RES.ephys),

  RES.ephys(N).weights = cat(3,RES.ephys(N).weights,newres.ephys(N).weights);
  RES.ephys(N).xcorr   = cat(2,RES.ephys(N).xcorr,  newres.ephys(N).xcorr);
end
  

return



function RES = sub_multicor(Ses,ExpNo,RoiName,EleName,METHOD,mrimask,AddSpike,ResampleHz)

[roits blp] = mrineu_load(Ses,ExpNo,'RoiName',RoiName,'EleName',EleName,...
                          'AddSpike',AddSpike,'ResampleHz',ResampleHz);
if ~isempty(mrimask),
  mrisig = mvoxlogical(roits,'and',mrimask);
end


roits.dat = nanmean(roits.dat,2);
roits.coords = [];
keyboard

  
  
  
return

