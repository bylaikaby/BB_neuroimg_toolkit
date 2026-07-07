function amesh2list(ameshfile,varargin)
%AMESH2LIST : Read the Amira-Mesh file and dumps "materials" as text.
%  AMESH2LIST(AMESHFILE) reads the Amira-Mesh file and dumps "materials" 
%  as text.
%
%  NOTE :
%    The internal value of a ROI seems to be ID-1.
%
%  EXAMPLE :
%    amesh2list('rathead16T_atlas.Labels.am');
%
%  VERSION :
%    0.90 24.05.13 YM  pre-release
%    0.91 07.06.13 YM  bug fix
%    0.92 05.07.13 YM  keeps compatibility to other atlas sets.
%    0.93 18.12.13 YM  accepts Color with '"'.
%    0.94 27.07.17 YM  use amesh_read().
%
%  See also amesh_read amesh2itksnap


if nargin < 1,  eval(['help ' mfilename]); return;  end

SAVEDIR = '';
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'savedir','save_dir'}
    SAVEDIR = varargin{N+1};
  end
end



AMESH = amesh_read(ameshfile,'verbose',1);
MATERIALS = AMESH.Parameters.Materials;


[fp fr fe] = fileparts(ameshfile);
if isempty(SAVEDIR)
  SAVEDIR = fp;
end
txtfile = fullfile(SAVEDIR,sprintf('%s.txt',fr));

% make a backup file, if needed
if exist(txtfile,'file'),
  x = dir(txtfile);
  bakfile = sprintf('%s.%s.txt',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'));
  bakfile = fullfile(SAVEDIR,bakfile);
  copyfile(txtfile,bakfile,'f');
end

% write-out a list of "material".
fprintf(' writing materials(%d) to %s...',length(MATERIALS),txtfile);
nroi = 0;
fid = fopen(txtfile,'wt');
for N = 1:length(MATERIALS)
  tmpmat = MATERIALS(N);
  tmpval = tmpmat.id - 1;    % values should be id-1
  if ~any(tmpval) || tmpval <= 0,    continue;  end
  % write-out this way to make compatible to other atlas sets
  % 1    2         3          4
  % val  fullname  shortname  composite?
  if any(strfind(tmpmat.name,' ')),
    fprintf(fid,'%4d\t"%s"\t"%s"\n',tmpval,tmpmat.name,tmpmat.name);
  else
    fprintf(fid,'%4d\t%s\t%s\n',tmpval,tmpmat.name,tmpmat.name);
  end
  nroi = nroi + 1;
end
fclose(fid);
fprintf(' done(nroi=%d).\n',nroi);

return

