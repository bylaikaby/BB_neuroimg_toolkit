

SES = 'rat47an2';



DATA_DIR = '\\wks6\data\rat47.aN2';


xfiles = dir(DATA_DIR);
for N = 1:length(xfiles),
  tmp = xfiles(N);
  if tmp.isdir,  continue;  end
  [fp fr fe] = fileparts(tmp.name);
  if ~any(strcmpi(fe,{'.adf' '.adfw' '.dgz' '.evt'})), continue;  end
  if ~any(strfind(fr,'rat74aN2')),  continue;  end
  srcfile = fullfile(DATA_DIR,tmp.name);
  dstfile = fullfile(DATA_DIR,strrep(tmp.name,'rat74aN2','rat47aN2'));
  fprintf('%3d: %s-->%s\n',N,srcfile,dstfile);
  %movefile(srcfile,dstfile,'f');
  %keyboard
  A = java.io.File(srcfile);
  A.renameTo(java.io.File(dstfile));
end



DATA_DIR = '\\wks6\data\rat47.aN2\stmfiles';


xfiles = dir(DATA_DIR);
for N = 1:length(xfiles),
  tmp = xfiles(N);
  if tmp.isdir,  continue;  end
  [fp fr fe] = fileparts(tmp.name);
  if ~any(strcmpi(fe,{'.hst' '.pdm' '.prt' '.rtp' '.stm'})), continue;  end
  if ~any(strfind(fr,'rat74aN2')),  continue;  end
  srcfile = fullfile(DATA_DIR,tmp.name);
  dstfile = fullfile(DATA_DIR,strrep(tmp.name,'rat74aN2','rat47aN2'));
  fprintf('%3d: %s-->%s\n',N,srcfile,dstfile);
  %movefile(srcfile,dstfile,'f');
  A = java.io.File(srcfile);
  A.renameTo(java.io.File(dstfile));
end

