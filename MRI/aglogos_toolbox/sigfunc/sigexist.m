function [res filename] = sigexist(Ses,ExpNo,SigName)
%SIGEXIST - Check if signal exist in a given experiment-file
% SIGEXIST uses "who" to check the existence of the required signal.
%
%  VERSION :
%    1.10 31.01.12 YM  use sigfilename().
%
%  See also sigfilename sigfilename_ver1

if ischar(Ses), Ses = getses(Ses);  end


if sesversion(Ses) >= 2,
  filename = sigfilename(Ses,ExpNo,SigName);
else
  switch lower(SigName),
   case {'cln'}
    filename = sigfilename_ver1(Ses,ExpNo,'cln');
   case {'clnspc'}
    filename = sigfilename_ver1(Ses,ExpNo,'clnspc');
   case {'tcimg'}
    filename = sigfilename_ver1(Ses,ExpNo,'tcimg');
   case lower(Ses.ctg.GrpDEPSigs),
    filename = sigfilename_ver1(Ses,ExpNo,'contrasts');
   case lower({'Spktblp','SpktCln','Brsttblp','BrsttCln',...
               'SpktGamma','SpktLfp','BrsttGamma','BrsttLfp'}),
    filename = sigfilename(Ses,ExpNo,SigName);
   case lower({'atSpktblp','atSpktCln','atBrsttblp','atBrsttCln'}),
    filename = sigfilename_ver1(Ses,ExpNo,SigName);
    
   otherwise
    filename = sigfilename_ver1(Ses,ExpNo,'mat');
  end
end



if exist(filename,'file'),
  tmp = who('-file',filename,SigName);
else
  tmp = [];
end

if isempty(tmp),
  res = 0;
else
  res = 1;
end;


return;
