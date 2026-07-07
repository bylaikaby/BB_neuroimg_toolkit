SES = 'd04nm6';
EXP = getexps(SES);


for iExp = 1:length(EXP),
  ExpNo = EXP(iExp);
  matfile = catfilename(SES,ExpNo,'mat');
  if any(strcmpi(who('-file',matfile),'blp')),
    fprintf(' %2d: found blp.\n',ExpNo);
    continue;
  end
  %sesgetblp(SES,ExpNo);
end

