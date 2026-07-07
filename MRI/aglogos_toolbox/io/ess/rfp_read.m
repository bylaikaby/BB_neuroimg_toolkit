function RFP = rfp_read(RFPFILE,varargin)
%RFP_READ - Reads receptive field parameters from the RFP file.
%  RFP = RFP_READ(RFPFILE,...) reads receptive field parameters from the RFP file.
%  Supported options are
%    'verbose'  :  0|1, verbose or not.
%
%  RFP = 
%    file: 'y:/temp/B06_2803(2016).rfp'
%       n: 7
%      rf: {1x7 cell}  <--- Receptive Field Information
%        rf{X}.center: [3.6800 -8.1270]         <--- XYcenter of RF in deg.
%        rf{X}.size:   [1.1120 1.3030]          <--- XYsize of RF in deg. 
%        rf{X}.angle:  0                        <--- RF angle
%        rf{X}.inf:    'track1 20.5 contra (R)' <--- RF text info
%        rf{X}.color:  'lightgray'              <--- RF color to plot
%
%  EXAMPLE :
%    rfp = rfp_read('y:/temp/B06_2803(2016).rfp')
%    rfp_plot(rfp,'xlim',[-10 10])
%
%  NOTE :
%    'rfp-file' can be created with MriStim program by hand-plotting of 
%    receptive fields.
%
%  VERSION :
%    1.00 29.08.00 YM  pre-release
%    1.01 31.03.08 YM  use uigetfile() if 'RFPFILE' is empty string.
%    1.02 10.09.08 YM  supports 'verbose'.
%    1.02 21.12.10 YM  clean-up codes.
%
%  See also rfp_plot stm_read pdm_read hst_read

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

% initialize output
RFP = [];

VERBOSE = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

% pick up a file
if isempty(RFPFILE)
  [rfpfile, pathname] = uigetfile(...
      {'*.rfp', 'RFP Files (*.rfp)'; ...
       '*.*',   'All Files (*.*)'}, ...
      'Pick a rfp file',pwd);
  if isequal(rfpfile, 0) || isequal(pathname,0), 
    fprintf(' %s: uigetfile() canceled.\n',mfilename);
    return;
  end
  rfpfile = fullfile(pathname,rfpfile);
  clear pathname;
end

if ~exist(RFPFILE,'file'),
  if VERBOSE,
    fprintf(' WARNING %s: ''%s'' not found.\n',mfilename,rfpfile);
    %error('\n ERROR %s:  ''%s'' not found.\n',mfilename,RFPFILE);
  end
  return
end


% read text
txtline = {};
fid = fopen(RFPFILE,'r');
while 1
  if feof(fid),  break;  end
  tmpline = fgetl(fid);
  tmpline = strtrim(deblank(tmpline));
  % remove comments following '#'
  ci = findstr(tmpline,'#');
  if ~isempty(ci), tmpline = tmpline(1:ci(1)); end
  if isempty(tmpline),  continue;  end
  txtline = cat(2,txtline,tmpline);
  %txtline{end+1} = tmpline;
end
fclose(fid);


% find parameters
nrf = 0;  rf = {};
for N=1:length(txtline)
  [t0,r0] = strtok(txtline{N});
  if findstr(t0,'beginLoadNewRF')
    %nrf = nrf + 1;
  elseif findstr(t0,'endLoadNewRF')
    nrf = nrf + 1;
  elseif findstr(t0,'loadRFCenter')
    [t1,r1] = strtok(r0,' ');
    [t2,r2] = strtok(r1,' ');
    rf{nrf+1}.center(1) = str2num(t1);
    rf{nrf+1}.center(2) = str2num(t2);
  elseif findstr(t0,'loadRFSize')
    [t1,r1] = strtok(r0,' ');
    [t2,r2] = strtok(r1,' ');
    rf{nrf+1}.size(1) = str2num(t1);
    rf{nrf+1}.size(2) = str2num(t2);
  elseif findstr(t0,'loadRFAngle')
    [t1,r1] = strtok(r0);
    rf{nrf+1}.angle = str2num(t1);
  elseif findstr(t0,'loadRFColor')
    [t1,r1] = strtok(r0);
    rf{nrf+1}.color = t1;
  elseif findstr(t0,'loadRFText')
    istr = findstr(r0,'"');
    %[t1,r1] = strtok(r0,' "')
    rf{nrf+1}.inf = r0(istr(1)+1:istr(2)-1);
  end
end



% prepare the result
RFP.file = RFPFILE;
RFP.n    = nrf;
RFP.rf   = rf;



return
