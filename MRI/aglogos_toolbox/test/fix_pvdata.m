function fix_text(DATAPATH,SCANS)

SRCSTR = '/nmr/J02.NW1/';
DSTSTR = '/nmr/F05.NW1/';

% subject
TXTFILE = fullfile(DATAPATH,'subject');
subFixText(TXTFILE,SRCSTR,DSTSTR);

% acqp/method,
for N=1:length(SCANS),
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'acqp');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'method');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
end


%d3proc/procs/reco/visu_pars
for N=1:length(SCANS),
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','1','d3proc');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','1','procs');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','1','reco');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','1','visu_pars');
    subFixText(TXTFILE,SRCSTR,DSTSTR);

    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','2','d3proc');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','2','procs');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','2','reco');
    subFixText(TXTFILE,SRCSTR,DSTSTR);
    TXTFILE = fullfile(DATAPATH,sprintf('%d',SCANS(N)),'pdata','2','visu_pars');
    subFixText(TXTFILE,SRCSTR,DSTSTR);

end




return










function subFixText(TXTFILE,SRCSTR,DSTSTR)


fprintf('%s: ',TXTFILE);

if ~exist(TXTFILE,'file'),
    fprintf(' not found, skip\n');
    return
end

fprintf('reading...');
% load the file
texts = {};
fid = fopen(TXTFILE,'r');
k = 1;
while feof(fid) == 0,
  texts{k} = fgetl(fid);
  %texts{k} = fgets(fid);
  k = k + 1;
end
fclose(fid);



% do something
CHANGED = 0;
for N=1:length(texts),
    if ~isempty(strfind(texts{N},SRCSTR)),
        texts{N} = strrep(texts{N},SRCSTR,DSTSTR);
        CHANGED = 1;
        break;
    end
end

if CHANGED == 0,
    fprintf(' no change, skip.\n');
    return
end



% backup first
BAKFILE = sprintf('%s.bak',TXTFILE);
if ~exist(BAKFILE,'file'),
    movefile(TXTFILE,BAKFILE);
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
    fprintf(fid,'%s\n',texts{N});
  else
    fprintf(fid,'\n');
  end
end
fclose(fid);


fprintf(' done.\n');

