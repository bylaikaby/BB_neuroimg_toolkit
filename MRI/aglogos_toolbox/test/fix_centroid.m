function fix_centroid(SESSION,EXPS)
%FIX_CENTROID - adds 'centroid' field to tcImg
%
% VERSION : 0.90  YM  08.10.06
%

Ses = goto(SESSION);
if nargin < 2,  EXPS = validexps(Ses);  end

fprintf('--------------------------------------------------\n');
fprintf('%s %s: %s ',datestr(now,'HH:MM:SS'), mfilename, Ses.name);
for ExpNo = EXPS,
  fprintf('%d.',ExpNo);
  matfile = catfilename(Ses,ExpNo,'tcImg');
  load(matfile,'tcImg');
  tcImg.centroid = mcentroid(tcImg.dat,tcImg.ds);
  save(matfile,'tcImg');
end;

fprintf('\n');