SES = rpsessions('monkey','hp','spont');

  
for N = 1:length(SES),
  fprintf('%2d/%d %s.=======================================\n', N,length(SES),SES{N});
  %jname = batch(@roi2glm, 0, {SES{N}, 'spont'});
  SesName = SES{N};
  GrpName = 'spont';
  rpsesgettrial(SesName, GrpName, 'froiTs');
  sesgrpmake(SesName, GrpName,'rpfroiTs');
  sesgroupglm(SesName, GrpName,'sigs','rpfroiTs');
  fprintf('\n=======================================\n\n\n', SES{N});
end;


% N = 1:4 done,  2012.01.20 19:30

