function seslfpmuacont(SESSION,EXPS,METHOD)
%SESLFPMUACONT
%
%  VERSION :
%    0.90 09.05.05 YM  pre-release
%  See also SESPLOTLFPMUACONT, SESFITLFPMUACONT

if nargin == 0,  help seslfpmuacont; return;   end
if nargin <  3,  METHOD = 'cor';  end

Ses = goto(SESSION);
if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end


for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);

  fprintf('%s %s [%d/%d]: ExpNo=%d(%s) Method:%s\n',...
          gettimestring,mfilename,N,length(EXPS),ExpNo,grp.name,METHOD);

  switch lower(METHOD),
   case {'coh'}
    SIG = lfpmuacoh(Ses,ExpNo);
   case {'cor','corr'}
    SIG = lfpmuacont_fft(Ses,ExpNo,'cor');
   case {'mi'}
    SIG = lfpmuacont_fft(Ses,ExpNo,'mi');
   case {'kc'}
    SIG = lfpmuacont_fft(Ses,ExpNo,'kc');
   otherwise
    fpritnf('%s error: sorry Method=''%s'' is not supported yet.\n',mfilename,METHOD);
    return;
  end

  if ~isempty(SIG),
    [fp,fr,fe] = fileparts(catfilename(SESSION,ExpNo,'mat'));
    matfile = sprintf('%s_%s.mat',fr,SIG.dir.dname);
    matfile = fullfile(fp,'Contrasts',matfile);
    fprintf(' Saving "%s" into %s ...', SIG.dir.dname,matfile);
    if ~exist(fileparts(matfile),'dir'),
      [fp,fr,fe] = fileparts(fileparts(matfile));
      mkdir(fp,strcat(fr,fe));
    end
    eval(sprintf('%s = SIG;',SIG.dir.dname));
    save(matfile,SIG.dir.dname);
    eval(sprintf('clear SIG %s;',SIG.dir.dname));
    fprintf(' done.\n');
  end
end
