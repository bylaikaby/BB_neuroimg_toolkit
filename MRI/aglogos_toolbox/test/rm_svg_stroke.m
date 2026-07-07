function rm_svg_stroke()



DIR = 'D:\Temp\CP3D_v2.2.1_080808\data';

for N = 1:151,
  svgfile = fullfile(DIR,sprintf('Figure %03d.svg',N));

  if ~exist(svgfile,'file'),  continue;  end
  sub_remove_stroke(svgfile);
end

return



function sub_remove_stroke(txtfile)

[fp fr fe] = fileparts(txtfile);

fprintf('%s%s :',fr,fe);

% load the file
fprintf(' read.');
texts = {};
fid = fopen(txtfile,'rt');
while feof(fid) == 0,
  texts = cat(2,texts,fgetl(fid));
end
fclose(fid);


UPDATED = 0;
for N = 1:length(texts),
  tmptxt = strtrim(texts{N});

  if strncmpi(tmptxt,'<path class="',13),
    fprintf(' "class" found, update by hand...\n');
    return
  elseif strncmpi(tmptxt,'<path fill="',12),
    % case for <path fill="#0F0532" stroke="#000000" stroke-width="3"...
    % if the marker, then skip..
    if strncmpi(tmptxt,'<path fill="#FFFF00"',20) continue;  end
    % ok now we need to remove stroke
    texts{N} = strrep(texts{N},'stroke="#000000" stroke-width="3" ','');
    UPDATED = 1;
  end
  
end


if any(UPDATED),
  fprintf(' save.');
  fid = fopen(txtfile,'wt');
  for N = 1:length(texts),
    fprintf(fid,'%s\n',texts{N});
  end
  fclose(fid);
  fprintf(' done.\n');
else
end


return


