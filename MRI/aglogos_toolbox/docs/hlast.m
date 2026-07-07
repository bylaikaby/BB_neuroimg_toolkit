function varargout = hlast(varargin)
%HLAST - Utility to list all recently updated Matlab scripts
% HLAST calls WHOUPDATED to find out which scripts were recently
% modified, and displays the list in a format that can be directly
% used as Matlab-Help.
%
% WHOUPDATED(X) prints all m-files that were updated in the last X
%   days.
% WHOUPDATED(DATE_STRING) prints all mfiles that were updated since
%   the date defined in DATE_STRING. The format of the string
%   DATE_STRING is "01-Jun-2004".
% list = WHOUPDATE(...) returns a list of updated m-files.
% Examples :
%   WHOUPDATED(5)              : lists files updated in last 5 days.
%   WHOUPDATED('28-May-2004')  : lists files updated since 28-May-2004.
%
% VERSION : 0.90 01.06.04 YM  first release
%
% See also DATENUM, DATESTR, CLOCK, DIR
%

if nargin < 1,
  list = whoupdated(1);
else
  list = whoupdated(varargin{:});
end;

clear hlastlist;
% clear functions;
dumpfirstlines(list);
rehash;
helpwin hlastlist;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function line = dumpfirstlines(list)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fname = 'hlastlist.m';
DIRS = getdirs;
filepath = sprintf('%sMatlab/docs/%s',DIRS.homedir,fname);

fid = fopen(filepath,'w');
fprintf(fid,'%%HLASTLIST - The file is the output of HLAST (list of most recent updates)\n');
l1 = 'It is created by HLAST which scans the directories for new mfiles';
l2 = 'HLAST - Displays the updates of the current day';
l3 = 'HLAST (X) Diplays the updates of the last X days';
l4 = 'HLAST (DATE_STRING) the updates the date in DATE_STRING';
l5 = '       DATE_STRING format is "01-Jun-2004"';

fprintf(fid,'%%%s\n%%%s\n%%%s\n%%%s\n%%%s\n',l1,l2,l3,l4,l5);
fprintf(fid,'%%\n%%See also\n');
NoAna = 1;
for N=1:length(list),
  myline = strcat('% ',list{N}.firstline(2:end));
  mypath = list{N}.fullpath;
  myline(strfind(myline,'.')) = ';';
  if ~isempty(strfind(lower(myline),'lastlist')),
    continue;
  end;

  if ~isempty(strfind(lower(mypath),'\matlab\ana\')),
    myanafiles{NoAna} = myline;
    NoAna = NoAna + 1;
    continue;
  end;
  
  fprintf(fid,'%s\n',myline);
end;

if exist('myanafiles') & ~isempty(myanafiles),
  fprintf(fid,'%%\n%%Updated Session Files\n');
  for N=1:length(myanafiles),
    fprintf(fid,'%s\n',myanafiles{N});
  end;
end;
    
fclose(fid);
return;



