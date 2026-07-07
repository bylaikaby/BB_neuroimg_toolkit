function fix_clnspc(SESSION,EXPS)
% fix_clnspc : 
%   add 'ClnSpc.dir.spcfile'
%
% VERSION : 0.90  YM  16.Feb.04
%

Ses = goto(SESSION);
if nargin < 2,  EXPS = validexps(Ses);  end

if ~exist('SIGS','dir'),	mkdir(pwd,'SIGS'); end;
for ExpNo = EXPS,
  spcfile = catfilename(Ses,ExpNo,'clnspc');
  vars = who('-file',spcfile);
  if isempty(strmatch('ClnSpc',vars)), continue;  end

  fprintf('%s fixing %s... ', gettimestring, spcfile);
  % load ClnSpc
  load(spcfile);
  ClnSpc.dir.spcfile = catfilename(Ses,ExpNo,'clnspc');
  % save ClnSpc
  save(spcfile,'ClnSpc');
  clear ClnSpc;
  fprintf('done.\n');
  pack;
end;
