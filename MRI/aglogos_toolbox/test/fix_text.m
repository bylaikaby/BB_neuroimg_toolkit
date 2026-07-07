function fix_text(TXTFILE)


fprintf('%s: 'TXTFILE);


fprintf('reading...');
% load the file
texts = {};
fid = fopen(TXTFLIE,'r');
k = 1;
while feof(fid) == 0,
  texts{k} = fgetl(fid);
  %texts{k} = fgets(fid);
  k = k + 1;
end
fclose(fid);



% do something
for N=1:length(texts),
    if ~isempty(strfind(texts{N},'aaaabbbb')),
    end
end





% backup first
BAKFILE = sprintf('%s.bak',TXTFILE);
if ~exist(BAKFILE,'file'),
    copyfile(TXTFILE,BAKFILE);
end


fprintf('writing...');

fid = fopen(TXTFILE,'w');
for N = 1:length(texts),
  if length(texts{N}) > 0,
    if strncmp(texts{N}(end),sprintf('\n'),1),
      keyboard
    elseif strncmp(texts{N}(end),sprintf('\r'),1),
      keyboard
    end
    fprintf(fid,'%s\n',deblank(texts{N}));
  else
    fprintf(fid,'\n');
  end
end
fclose(fid);


fprintf(' done.\n');

