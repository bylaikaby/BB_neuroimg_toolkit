ses = es_phys_session('all');


for N=1:length(ses),
  EXPS = getexps(ses{N}{1});
  %blp = sigload(ses{N}{1},EXPS(end),'esblp');
  %fprintf('%s: ExpNo=%3d %s\n',ses{N}{1},EXPS(end),blp.info.date);
  Spkt = sigload(ses{N}{1},EXPS(end),'Spkt');
  fprintf('%s: ExpNo=%3d %g\n',ses{N}{1},EXPS(end),Spkt.siggetspk.threshold);
end

