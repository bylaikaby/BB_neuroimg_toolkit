function fixframedata(SESSION,EXPS)
% FIXFRAMEDATA : compute movie frame data and replace it.
%
% VERSION : 0.90 02.10.03 YM
% SEEALSO : vgetframedata.m

Ses = goto(SESSION);

if nargin == 1,  EXPS = validexps(Ses);  end
if isa(EXPS,'char'),
  eval(sprintf('grp = Ses.grp.%s;',EXPS));
  EXPS = grp.exps;
end

for ExpNo = EXPS,
  grp = getgrp(Ses,ExpNo);
  if ~strncmp(grp.name,'movie',5),  continue;  end
  fprintf('%s: fixframedata: ExpNo=%d\n',gettimestring,ExpNo);
  matfile = catfilename(Ses,ExpNo,'mat');
  movie = subGetMovie(Ses,ExpNo);
  vars = who('-file',matfile);
  load(matfile);
  for N=1:length(vars),
    varname = vars{N};
    fprintf('%s...',varname);
    switch varname
     case {'Cln','ClnSpc','LfpL','LfpM','LfpH','Mua','Spkt','Sdf'}
      %load(matfile,varname);
      eval(sprintf('%s.movie = movie;',varname));
      %save(matfile,'-append',varname);
      %eval(sprintf('clear %s;',varname));
     otherwise
    end
  end
  cmd = sprintf('save(matfile');
  for N=1:length(vars),
    cmd = strcat(cmd,sprintf(',''%s''',vars{N}));
  end
  cmd = strcat(cmd,');');
  eval(cmd);
  for N=1:length(vars),
    eval(sprintf('clear %s;',vars{N}));
  end
  clear movie; memory; pack;
  fprintf('done.\n');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function movie = subGetMovie(Ses,ExpNo);

DECFRAC = 3;
name = catfilename(Ses,ExpNo,'phys');
[NoChan,NoObsp,dx,obslen] = adf_info(name);
dx = dx / 1000.0;
Cln = getcln(Ses,ExpNo);
Cln.dir.videofile = catfilename(Ses,ExpNo,'video');
Cln.dx = dx * DECFRAC;
iadfofs = round((Cln.grp.adfoffset/dx)/DECFRAC) + 1;
iadflen = round((Cln.grp.adflen/dx)/DECFRAC);

movie = vgetframedata(Ses,ExpNo,1,iadfofs*Cln.dx,iadflen*Cln.dx);
