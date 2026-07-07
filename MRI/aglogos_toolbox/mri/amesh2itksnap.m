function amesh2itksnap(ameshfile)
%AMESH2ITKSNAP : Read the Amira-Mesh file and dumps "materials" as text for ITK-SNAP.
%  AMESH2ITKSNAP(AMESHFILE) reads the Amira-Mesh file and dumps "materials" 
%  as text for ITK-SNAP.
%
%  NOTE :
%    The internal value of a ROI seems to be ID-1.
%
%  EXAMPLE :
%    amesh2itksnap('rathead16T_atlas.Labels.am');
%
%  VERSION :
%    0.90 18.12.13 YM  derived from amesh2list().
%    0.91 27.07.17 YM  uses amesh_read().
%
%  See also amesh_read amesh2list


if nargin < 1,  eval(['help ' mfilename]); return;  end


AMESH = amesh_read(ameshfile,'verbose',1);
MATERIALS = AMESH.Parameters.Materials;


% sort by "id"
tmpv = [MATERIALS(:).id];
[tmpv tmpi] = sort(tmpv);
MATERIALS = MATERIALS(tmpi);
clear tmpv tmpi;


[fp fr fe] = fileparts(ameshfile);
txtfile = fullfile(fp,sprintf('%s.itksnap.txt',fr));

% make a backup file, if needed
if exist(txtfile,'file'),
  x = dir(txtfile);
  bakfile = sprintf('%s.%s.txt',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'));
  bakfile = fullfile(fp,bakfile);
  copyfile(txtfile,bakfile,'f');
end

% write-out a list of "material".
fprintf(' writing materials(%d) to %s...',length(MATERIALS),txtfile);
nroi = 0;
fid = fopen(txtfile,'wt');
fprintf(fid,'################################################\n');
fprintf(fid,'# ITK-SnAP Label Description File\n');
fprintf(fid,'# File format: \n');
fprintf(fid,'# IDX   -R-  -G-  -B-  -A--  VIS MSH  LABEL\n');
fprintf(fid,'# Fields: \n');
fprintf(fid,'#    IDX:   Zero-based index \n');
fprintf(fid,'#    -R-:   Red color component (0..255)\n');
fprintf(fid,'#    -G-:   Green color component (0..255)\n');
fprintf(fid,'#    -B-:   Blue color component (0..255)\n');
fprintf(fid,'#    -A-:   Label transparency (0.00 .. 1.00)\n');
fprintf(fid,'#    VIS:   Label visibility (0 or 1)\n');
fprintf(fid,'#    IDX:   Label mesh visibility (0 or 1)\n');
fprintf(fid,'#  LABEL:   Label description \n');
fprintf(fid,'################################################\n');
fprintf(fid,'    0     0    0    0        0  0  0    "Clear Label"\n');

for N = 1:length(MATERIALS)
  tmpmat = MATERIALS(N);
  tmpval = tmpmat.id - 1;    % values should be id-1
  if ~any(tmpval) || tmpval <= 0,    continue;  end
  
  tmprgb = round(tmpmat.color*255);
  if isempty(tmprgb),
    tmprgb = [255 255 255];
  end
  % IDX R G B A VIS IDX Label
  fprintf(fid,'%5d   %3d  %3d  %3d        1  1  1    "%s"\n',...
          tmpval, tmprgb(1), tmprgb(2), tmprgb(3), tmpmat.name);
  nroi = nroi + 1;
end
fclose(fid);
fprintf(' done(nroi=%d).\n',nroi);

return
