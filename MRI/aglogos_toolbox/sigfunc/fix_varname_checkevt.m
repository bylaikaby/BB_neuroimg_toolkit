function fix_varname_checkevt(ses,gname)
%FIX_VARNAME_CHECKEVT - Fixes the wrong variable name (checkele*) as checkevt*.
%
%
%  EXAMPLE :
%    >> fix_varname_checkevt('F12m05','spont')
%
%  VERSION :
%    0.90 05.06.2017 YM  pre-release
%
%  See also

if nargin == 0,  eval(['help ' mfilename]); return;  end


DO_OVERWRITE = 1;

ses = goto(ses);
grp = getgrp(ses,gname);

grpdir = fullfile(pwd,grp.name);

tmpfiles = dir(fullfile(grpdir,sprintf('%s_%s_checkele_*.mat',ses.name,grp.name)));
for F = 1:length(tmpfiles),
  tmpf = tmpfiles(F);
  if any(tmpf.isdir),  continue;  end
  fprintf(' %s: ',tmpf.name);
  
  % 1st rename it
  srcfile = fullfile(grpdir,tmpf.name);
  dstfile = fullfile(grpdir,strrep(tmpf.name,'_checkele_','_checkevt_'));
  
  if exist(dstfile,'file'),
    if any(DO_OVERWRITE),
      tmpsrc = dstfile;
      tmpdst = [tmpsrc,'.bak'];
      A = java.io.File(tmpsrc);
      A.renameTo(java.io.File(tmpdst));
    else
      % no need to do, skipp...
      fprintf(' checkevt* exists already, skipped.\n');
      continue;
    end
  end
  fprintf(' rename(checkevt).');
  %movefile(srcfile,dstfile,'f');
  %keyboard
  A = java.io.File(srcfile);
  A.renameTo(java.io.File(dstfile));
  
  matfile = dstfile;
  % load the variable and rename/save
  matvars = whos('-file',matfile);
  fprintf(' load.');
  vars = load(matfile);
  fprintf(' save.');
  for V = 1:length(matvars),
    srcname = matvars(V).name;
    dstname = strrep(srcname,'checkele_','checkevt_');
    eval(['tmpvar = vars.' srcname ';']);
    if iscell(tmpvar),
      for K = 1:numel(tmpvar),
        if isfield(tmpvar{K},'args') && isfield(tmpvar{K}.args,'SigName'),
          tmpvar{K}.args.SigName = strrep(tmpvar{K}.args.SigName,'checkele_','checkevt_');
        end
      end
    else
      for K = 1:numel(tmpvar),
        if isfield(tmpvar(K),'args') && isfield(tmpvar(K).args,'SigName'),
          tmpvar(K).args.SigName = strrep(tmpvar(K).args.SigName,'checkele_','checkevt_');
        end
      end
    end
    eval([dstname '=tmpvar;']);
    if V == 1,
      save(matfile,dstname,'-v7.3');
    else
      save(matfile,dstname,'-v7.3','-append');
    end
    eval(['clear tmpvar ' dstname]);
  end
  clear vars;
  fprintf(' done.\n');
end




return


% --------------------------------------------
function fix_varname()


