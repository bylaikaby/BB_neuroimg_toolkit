function showicadenoise(SESSION,ExpNo)
%SHOWICADENOISE - show ICA results (DEMO)
% SHOWICADENOISE (SESSION,ExpNo) 

if nargin < 1,
  SESSION='m02lx1';
  ExpNo=1;
end;

micadenoise;
