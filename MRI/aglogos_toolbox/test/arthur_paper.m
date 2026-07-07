%function arthur_paper

SESSION = 'f01m91';
GRPNAME = 'polar1';

NUM_AVERAGES = [ 1 2 5 10 20 50 100 150 ];


Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


ExpNo = grp.exps(1);


fprintf('%s: reading roiTs: ',mfilename);
allV1 = {};
for iExp = 1:length(grp.exps),
  ExpNo = grp.exps(iExp);
  fprintf('%d.',ExpNo);
  roiTs = sigload(Ses,ExpNo,'roiTs');
  sortp = getsortpars(Ses,ExpNo);
  % find V1 and concatinate
  expV1 = {};
  for N = 1:length(roiTs),
    if strcmpi(roiTs{N}.name,'v1'),
      tmpV1 = sigsort(roiTs{N},sortp.trial);
      if isempty(expV1),
        expV1 = tmpV1;
        expV1.slice = -1;
        expV1.r = {};
        expV1.p = {};
      else
        expV1.dat = cat(2,expV1.dat, tmpV1.dat);
        expV1.coords = cat(1,expV1.coords,tmpV1.coords);
      end
    end
  end
  if isempty(allV1),
    allV1 = expV1;
  else
    allV1.dat = cat(3,allV1.dat,expV1.dat);
  end
end
allV1.ExpNo = grp.exps;
fprintf(' done.\n');

fprintf(' %s making model...',mfilename);
ExpNo = grp.exps(1);
mdl = expgetstm(Ses,ExpNo,'hemo');
sortp = getsortpars(Ses,ExpNo);
mdl = sigsort(mdl,sortp.trial);
mdl.dat = mdl.dat(:,1);
mdl = { mdl };
fprintf(' done.\n');



fprintf(' %s corr: ',mfilename);
corV1 = {};
rpidx = randperm(size(allV1.dat,3));
for N = 1:length(NUM_AVERAGES),
  fprintf('%d.',NUM_AVERAGES(N));
  tmpV1 = allV1;
  idx = rpidx(1:NUM_AVERAGES(N));
  tmpV1.dat = squeeze(mean(tmpV1.dat(:,:,idx),3));
  tmpV1 = matscor({tmpV1},mdl);
  corV1{N} = tmpV1{1};
  corV1{N}.naverages = NUM_AVERAGES(N);
  corV1{N}.randperm  = idx;
end
fprintf(' done.\n');







fprintf('N:  mean r,  num trials to average\n');
for N = 1:length(corV1),
  fprintf('%2d: r=%.3f n=%d\n',N,mean(corV1{N}.r{1}),corV1{N}.naverages)
end













%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
