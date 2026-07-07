function hmri
%EDMRI - Edit MRI Documentation
% EDMRI reads the HMRI.HTM file with word to permit editing
%
% NKL 01.11.05
  
  arg = which('hmri.htm');
  cmd = sprintf('"c:/Program Files/Microsoft Office/OFFICE11/winword.exe" %s &',arg);
  system(cmd);









