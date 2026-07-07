function ROITABLE = matlas_roitable(filename)
%MATLAS_ROITABLE - returns a table of ROIs in the atlas package.
%  MATLAS_ROITABLE(FILENAME) returns a table of ROIs in the atlas package.
%  This function is called by MRATATLAS2ROI.
%
%  EXAMPLE :
%    >> filedir  = 'y:\DataMatlab\Anatomy\Rat_Atlas\GSKrat97templateMRI+atlas.v5\v5\96x96x120';
%    >> filename = 'atlas_structDefs';
%    >> roitable = matlas_roitable(fullfile(filedir,filename));
%
%   roitable{1} = { [4]    'oculomotor nucleus'    '3'    '-'    [0.1078] }
%                  uniq.num  fullname             Abbrev.   ?      ?
%   The character " will be remove from the string.
%   The character ' will be replaced by ^ for matlab.
%
%  VERSION :
%    0.90 08.08.07 YM  pre-release
%    0.91 04.07.13 YM  uses matlas_defs(), if needed.
%    0.92 27.07.17 YM  delimiter can be a space (for Saleem-3D).
%
%  See also mratatlas2roi matlas_defs

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if isempty(filename),
  tmp = matlas_defs('GSKrat97');
  filename = fullfile(tmp.template_dir,tmp.table_file);
  clear tmp;
end


ROITABLE = {};
if ~exist(filename,'file'),
  error('\nERROR %s: ROI-table file not found, ''%s''\n',mfilename,filename);
end

DELIMITER = '';

fid = fopen(filename,'rt');
while feof(fid) == 0,
  tmptxt = fgetl(fid);
  tmptxt = strtrim(tmptxt);  % remove leading/trailing white space.
  if isempty(tmptxt),  continue;  end
  % ignore comment lines
  if tmptxt(1) == '#' || tmptxt(1) == '%', continue;  end
  tmpinfo = {};
  % check which delimiter
  if isempty(DELIMITER),
    if any(strfind(tmptxt,char(9))),
      DELIMITER = char(9);   % char(9):horizontal tab as delimiter.
    else
      DELIMITER = ' ';
    end
  end
  for N=1:5,
    [str,tmptxt] = strtok(tmptxt,DELIMITER);
    if N==1 || N==5,
      tmpinfo{N} = str2num(str);
    else
      str = deblank(strrep(str,'"',''));
      str = strrep(str,'''','^');        % matlab doesn't like "'"...
      tmpinfo{N} = str;
    end
  end
  if isempty(tmpinfo),  continue;  end
  ROITABLE{end+1} = tmpinfo;
end
fclose(fid);


return
