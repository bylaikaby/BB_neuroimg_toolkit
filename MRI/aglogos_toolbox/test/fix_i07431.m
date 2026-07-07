% fix some problems in i07431

SES = 'i07431';

ses = goto(SES);
exps = getexps(SES);




for iExp = 1:length(exps),
  ExpNo = exps(iExp);
  vname = sprintf('exp%04d',ExpNo);
  PAR = load('SesPar.mat',vname);
  PAR = PAR.(vname);
  
  STIM_ID = PAR.stm.v{1};
  STIM_TYPE = PAR.stm.stmtypes;
  tmpid = min(find(strcmpi(STIM_TYPE,'microstim'))) - 1;
  for K = 1:length(STIM_ID),
    if strcmpi(STIM_TYPE{STIM_ID(K)+1},'microstim'),
      STIM_ID(K) = tmpid;
    end
  end


  PAR.stm.v{1} = STIM_ID;
  PAR.evt.obs{1}.params.stmid = STIM_ID(:);
  

  eval(sprintf('%s = PAR;',vname));
  save('SesPar.mat',vname,'-append');
end
