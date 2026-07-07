function PARAMS = nscan_loadtxt(TXTFILE,varargin)
%NSCAN_LOADTXT - Load a text file of Curry7(Neuroscan) as it is.
%  PARAMS = NSCAN_LOADTXT(TXTFILE,...) loads a text file of Curry7(neuroscain) as it is.
%  This function just reads parameters as chars without converting
%  to numerics.  NSCAN_LOADPAR7() does numeric conversion.
%
%  EXAMPLE :
%    dap = nscan_loadpar7('D:/Temp/Acquire 01.dap');
%    rs3 = nscan_loadpar7('D:/Temp/Acquire 01.rs3');
%    ceo = nscan_loadpar7('D:/Temp/Acquire 01.ceo');
%
%  VERSION :
%    0.90 23.01.14 YM  pre-release, MPI Tuebingen
%    0.91 10.02.14 YM  clean-up
%
%  See also nscan_loadpar7 nscan_strconv nscan_loaddat7

%  COPYRIGHT (C) 2014 Yusuke Murayama,  Max Planck Institute for Biological Cybernetics
%  Simplified BSD License, see readme.txt for detail.


if nargin < 1, eval(['help ' mfilename]); return;  end

if ~exist(TXTFILE,'file'),
  error(' ERROR %s : ''%s'' not found.\n',mfilename,TXTFILE);
end


% load the file
texts = {};
if sub_is_utf8(TXTFILE),
  [fid, message] = fopen(TXTFILE, 'rt','n','utf-8');
  fseek(fid,3,'bof');  % MATLAB can't handle BOM...
else
  [fid, message] = fopen(TXTFILE, 'rt');
end
while feof(fid) == 0,
  tline = fgetl(fid);
  if ~isequal(tline,-1)
    texts = cat(2,texts,tline);
  end
end
fclose(fid);

PARAMS = [];
cur_param = '';
in_alist  = 0;
for N = 1:length(texts)
  tmpline = strtrim(texts{N});
  if isempty(tmpline), continue;  end
  
  %x = strtrim(regexp(tmpline,' +|	+','split'));
  x = strtrim(regexp(tmpline,'[ \t]+','split'));
  if length(x) >= 2 && ~strcmp(x{2},'='),
    %x{2}
    switch x{2}
     case {'START'}
      cur_param = x{1};
      in_alist = 0;
      continue;
     case {'START_LIST' 'START_LIST	#'}
      cur_param = x{1};
      in_alist = 1;
      continue;
     case {'END' 'END_LIST' 'END_LIST	#'}
      cur_param = '';
      in_alist = 0;
      continue;
    end
  end
	
  if isempty(cur_param),  continue;  end
  
  if any(in_alist),
    % 'tab' as a 'space'
    %x = strtrim(regexp(strrep(strtrim(tmpline),'	',' '),' +','split'));
    if ~isfield(PARAMS.(cur_param),'List'),
      %PARAMS.(cur_param).List = cell(ListNrRows,ListNrColumns);
      %iRow = 1;
      PARAMS.(cur_param).List = {};
    end
    % in some special cases, parameters should not be split...
    try
      if any(strcmpi({'LABELS' 'LABELS_OTHERS'},cur_param))
        PARAMS.(cur_param).List = cat(1,PARAMS.(cur_param).List,{tmpline});
      else
        PARAMS.(cur_param).List = cat(1,PARAMS.(cur_param).List,x);
      end
    catch
      %keyboard
    end
    
  else
    tmpi = strfind(tmpline,'=');
    tmpstr = strtrim(tmpline(1:tmpi-1));
    if any(tmpstr)
      PARAMS.(cur_param).(tmpstr) = strtrim(tmpline(tmpi+1:end));
    end
  end
end


return





% =======================================================
function IS_UTF8 = sub_is_utf8(filename)
% =======================================================

IS_UTF8 = 0;

if ~exist(fullfile(filename),'file'),
 error('\n ERROR %s: No such file, %s\n',mfilename,filename);
end

bom = [];
fid = fopen(filename,'rb');
try
  bom = fread(fid,2,'uint8=>uint8');
catch
end
fclose(fid);

if length(bom) >= 2,
  % 0xEF=239, 0xBB=187, see hex2dec()
  if bom(1) == 239 && bom(2) == 187,
    IS_UTF8 = 1;
  end
end

return
