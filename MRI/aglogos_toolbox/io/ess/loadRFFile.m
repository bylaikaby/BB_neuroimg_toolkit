function ret = loadRFFile(rffile)
% PURPOSE : To load receptive field parameters from a rffile.
% USAGE : ret = loadRFFile([rffile])
% VERSION : 1.00  29-Aug-2000  YM


RFPath = pwd;
  
% initialize output
ret = [];

% pick up a file
if ~exist('rffile','var')
  file = sprintf('%s\\*.rfp',pwd);
  rffile = pickfile('Select a RF file',RFPath,patt);
  if isempty(rffile), return; end
end

rffile = strrep(rffile,'\','/');
[rdir,fn,fe] = fileparts(rffile);
if ~length(rdir),
  rdir = '//ntserver/Home/Mri/MriStim/params/rfpfiles';
end
rfile = strcat(fn,fe);
rfullpath = sprintf('%s/%s',rdir,rfile);
ret.file = rfile;

% read text
fid = fopen(rfullpath,'r');
i = 1;
while 1
  line = fgets(fid,80);
  line = line(1:length(line)-1);
  if ~isstr(line),break,end;
  % remove comments following '#'
  ci = findstr(line,'#');
  if length(ci), line = line(1:ci(1)); end
  txtline{i} = line;
  i=i+1;
end
fclose(fid);

% find parameters
nrf = 0;
for N=1:length(txtline)
  [t0,r0] = strtok(txtline{N});
  if findstr(t0,'beginLoadNewRF')
    %nrf = nrf + 1;
  elseif findstr(t0,'endLoadNewRF')
    nrf = nrf + 1;
  elseif findstr(t0,'loadRFCenter')
    [t1,r1] = strtok(r0,' ');
    [t2,r2] = strtok(r1,' ');
    ret.rf{nrf+1}.center(1) = str2num(t1);
    ret.rf{nrf+1}.center(2) = str2num(t2);
  elseif findstr(t0,'loadRFSize')
    [t1,r1] = strtok(r0,' ');
    [t2,r2] = strtok(r1,' ');
    ret.rf{nrf+1}.size(1) = str2num(t1);
    ret.rf{nrf+1}.size(2) = str2num(t2);
  elseif findstr(t0,'loadRFAngle')
    [t1,r1] = strtok(r0);
    ret.rf{nrf+1}.angle = str2num(t1);
  elseif findstr(t0,'loadRFColor')
    [t1,r1] = strtok(r0);
    ret.rf{nrf+1}.color = t1;
  elseif findstr(t0,'loadRFText')
    istr = findstr(r0,'"');
    %[t1,r1] = strtok(r0,' "')
    ret.rf{nrf+1}.inf = r0(istr(1)+1:istr(2)-1);
  end
end

ret.n = nrf;
%ret.inf = chrfinf(ret.file);


