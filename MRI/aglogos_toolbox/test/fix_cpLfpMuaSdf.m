function fix_cpLfpMuaSdf(SESSION,GrpName,Node)
%
% copy Lfp/Mua/Sdf from Y: to clustered PC. 
%
  
Ses = goto(SESSION);
grp = getgrpbyname(Ses,GrpName);
EXPS = grp.exps;

srcpath = 'y:/DataMatlab';
dstpath = sprintf('//%s/Y/DataMatlab',Node);
if exist(sprintf('%s/%s',dstpath,Ses.dirname)) == 0,
  mkdir(dstpath,Ses.dirname);
end

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  filename = catfilename(Ses,ExpNo,'mat');
  % get filename
  [fp,fn,fe] = fileparts(filename);
  fn = strcat(fn,fe);
  srcfile = sprintf('%s/%s/%s',srcpath,Ses.dirname,fn);
  dstfile = sprintf('%s/%s/%s',dstpath,Ses.dirname,fn);
  fprintf(' fix_cpXXX: [%2d/%d] %s --> %s ...',...
          N,length(EXPS),srcfile,dstfile);
  % load data
  load(srcfile,'LfpH','Mua','Sdf');
  % save data
  if exist(dstfile,'file') == 2
    %keyboard
    %save(dstfile,'-append','LfpH','Mua','Sdf');
  else
    save(dstfile,'LfpH','Mua','Sdf');
  end
  fprintf('done.\n');
end
