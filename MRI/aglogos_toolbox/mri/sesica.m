function sesica(SesName)
%SESICA - Get ICA for all session groups
% NKL 8.6.09
  
Ses = goto(SesName);
grpnames = getgrpnames(Ses);

for N=1:length(grpnames),
  fprintf('\n PROCESSING GROUP: %s\n', upper(grpnames{N}));
  getica(SesName, grpnames{N});
  
  tcICA =  icaload(SesName, grpnames{N});
  
  
end;

