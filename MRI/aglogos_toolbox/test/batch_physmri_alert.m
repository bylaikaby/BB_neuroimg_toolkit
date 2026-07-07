ses = {};
for N = 1:length(ses),
  try,
    %sesdumppar(ses{N}{1});
    %sesimgload(ses{N}{1});
    sesrealign(ses{N}{1});  close all;
    %sesareats(ses{N}{1});
  catch,
    txtfile = sprintf('Y:/DataMatlab/tmp/%s_%s.txt',ses{N}{1},mfilename);
    fid = fopen(txtfile,'at+');
    fprintf(fid,'%s: FAILED %s sesrealign() by %s\n',datestr(now),ses{N}{1},lasterr);
    fclose(fid);
  end
end



ses = seslist('alert');
for N = 1:length(ses),
  try,
    exps = getexps(ses{N}{1});
    par = expgetpar(ses{N}{1},exps(1));
    
    fprintf('%s %d: imgtr=%g\n',ses{N}{1},exps(1),par.pvpar.imgtr);
    %ClnSpc = alsigload(ses{N}{1},exps(1),'ClnSpc');
    %fprintf('%s %d: imgtr=%g  ClnSpc.dx=%g ClnSpc.df=%g\n',...
    %        ses{N}{1},exps(1),par.pvpar.imgtr,ClnSpc.dx(1),ClnSpc.dx(2));
    
    %sesdumppar(ses{N}{1});
    %sesimgload(ses{N}{1});
    %sesrealign(ses{N}{1});  close all;
    %sesareats(ses{N}{1});
    %alsesgettrial(ses{N}{1});
    %sesgrpmake(ses{N}{1},[],'troiTs');
    %almkmodel(ses{N}{1},[]);
    %sesgroupcor(ses{N}{1});
    %sesgroupglm(ses{N}{1});
  catch,
    txtfile = sprintf('Y:/DataMatlab/tmp/%s_%s.txt',ses{N}{1},mfilename);
    fid = fopen(txtfile,'at+');
    fprintf(fid,'%s: FAILED %s by %s\n',datestr(now),ses{N}{1},lasterr);
    fclose(fid);
  end
end
