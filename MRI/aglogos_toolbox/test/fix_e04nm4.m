ses = 'e04nm4';

EXPS = getexps('e04nm4');


for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%3d/%d:',ExpNo,length(EXPS));
  dstfile = catfilename(ses,ExpNo,'mat');
  srcfile = strrep(dstfile,'y:','//n08/Y');
  
  if any(strcmpi(who('-file',srcfile),'blp')),
    fprintf('loading blp...');
    load(srcfile,'blp');
    fprintf('appending blp to ''%s''...',dstfile);
    save(dstfile,'blp','-append');
    fprintf('[%s] done.',blp.info.date);
    clear blp;
  end
  fprintf('\n');
end