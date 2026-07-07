function statsave(Ses,GrpExp,SigName,StatName,StatData,varargin)
%STATSAVE - Saves Statistical data
%  STATSAVE(Ses,GrpExp,SigName,StatName,StatData,...) saves statistical data.
%
%  VERSION :
%    0.90 06.02.12 YM  pre-release
%    0.91 09.07.13 YM  no appending.
%
%  See also statfilename statload sigsave

if nargin < 5,  help statsave; return;  end


Ses = getses(Ses);

filename = statfilename(Ses,GrpExp,SigName,StatName);

sigsave(Ses,GrpExp,StatName,StatData,'file',filename,'append',0);

return
