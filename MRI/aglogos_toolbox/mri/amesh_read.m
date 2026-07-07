function AMESH = amesh_read(ameshfile,varargin)
%AMESH_READ - Read the Amira-Mesh file.
%  AMESH = amesh_read(ameshfile,...) reads the Amira-Mesh file.
%
%  EXAMPLE :
%    AMESH = amesh_read('d:/temp/amira-file.am')
%
%  VERSION :
%    0.90 27.07.17 YM  pre-release
%
%  See also amesh2itksnap amesh2list fopen fclose fgetl strtrim

VERBOSE = 0;
BREAK_DATA = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case  {'verbose'}
    VERBOSE = any(varargin{N+1});
  end
end



if any(VERBOSE),  fprintf(' reading %s...',ameshfile);  end
TEXTS = {};
fid = fopen(ameshfile,'rt');
while feof(fid) == 0,
  tmptxt = fgetl(fid);
  if any(BREAK_DATA) && ~isempty(tmptxt) && tmptxt(1) == '#',
    if any(strfind(tmptxt,'Data section follows')),  break;  end
  end
  TEXTS = cat(2,TEXTS,tmptxt);
end
fclose(fid);

if any(VERBOSE),  fprintf(' %d lines.\n',length(TEXTS));  end


TEXTS = strtrim(TEXTS);

% get "AmiraMesh"
AMESH.AmiraMesh = subGetAmiraMesh(TEXTS);

% get "Parameters-Materials".
AMESH.Parameters.Materials = subGetMaterials(TEXTS);

% AMESH.Parameters.Content     = subGetItem(TEXTS,'Content');
% AMESH.Parameters.BoundingBox = subGetItem(TEXTS,'BoundingBox');
% AMESH.Parameters.CoordType   = subGetItem(TEXTS,'CoordType');
% AMESH.Parameters.TransformationMatrix = subGetItem(TEXTS,'TransformationMatrix');

% AMESH.Data = subGetData(TEXTS,AMESH.AmiraMesh.binary,AMESH.AmiraMesh.version);

return


% -----------------------------------------------------
function AmiraMesh = subGetAmiraMesh(TEXTS)

AmiraMesh = [];
iStart = sub_find_str(TEXTS,1,'AmiraMesh',0);
if ~any(iStart), return;  end

tmptxt = TEXTS{iStart};
tmpi = strfind(lower(tmptxt),'binary-');
if ~any(tmpi), return;  end

tmptxt = tmptxt(tmpi+7:end);
[s_bin, v_ver] = strtok(tmptxt,' ');

AmiraMesh.binary  = s_bin;
AmiraMesh.version = str2num(v_ver);

return



% -----------------------------------------------------
function MATERIALS = subGetMaterials(TEXTS)

MATERIALS = [];
iStart = sub_find_str(TEXTS,1,'Materials {',1);

N = iStart;
while N < length(TEXTS),
  N = N + 1;
  
  tmptxt = TEXTS{N};
  % empty/skip comments
  if isempty(tmptxt),  continue;  end
  if tmptxt(1) == '#',  continue;  end

  is = strfind(tmptxt,'{');
  ie = strfind(tmptxt,'}');
  if any(ie),  break;  end
  if any(is),
    % entering to a new "material".
    tmpmat.name  = strtrim(tmptxt(1:is(1)-1));
    tmpmat.id    = [];
    tmpmat.color = [];
    for K = N:length(TEXTS),
      tmptxt = TEXTS{K};
      % empty/skip comments
      if isempty(tmptxt),  continue;  end
      if tmptxt(1) == '#',  continue;  end
      id = strfind(tmptxt,'Id ');
      ic = strfind(tmptxt,'Color ');
      ie = strfind(tmptxt,'}');
      if any(id),
        tmpmat.id    = str2num(tmptxt(3:end));
      end
      if any(ic),
        % may need to remove '"'
        tmpmat.color = str2num(strrep(tmptxt(6:end),'"',''));
        %tmpmat.color = str2num(tmptxt(6:end));
      end
      if any(ie),
        MATERIALS = cat(2,MATERIALS,tmpmat);
        N = K;
        break;
      end
    end
  end

end


return


% =======================================================
function iFound = sub_find_str(TEXTS,iStart,mystr,SkipComments)
% =======================================================
iFound = [];
for N = iStart:length(TEXTS),
  tmptxt = TEXTS{N};
  if isempty(tmptxt),  continue;  end
  % skip comments
  if any(SkipComments) && tmptxt(1) == '#',  continue;  end
  if any(strfind(tmptxt,mystr)),
    iFound = N;  break;
  end
end

return
