function print_expdate(Ses,EXPS)
%PRINT_EXPDATE
%
% VERSION : 0.90 30.06.04 YM  first release
%
% See also STM_READ, EXPGETPAR

if nargin == 0, help print_expdate; return;  end

Ses = goto(Ses);
if nargin == 1,
  EXPS = sort(validexps(Ses));
end


for iExp = EXPS,
  par = expgetpar(Ses,iExp);
  fprintf('%3d: %s\n',iExp,par.stm.date);
end

