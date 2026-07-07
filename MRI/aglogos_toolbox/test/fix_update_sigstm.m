function fix_update_sigstm(Ses,EXPS)


Ses = goto(Ses);
if nargin < 2,  EXPS = validexps(Ses);  end

% EXPS is given by group name.
if ischar(EXPS),  EXPS = getexps(EXPS);  end


for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  
  
  
end



