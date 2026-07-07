function hstpars = hst_read(hstfile,varargin)
%HST_READ - Get stim-history parameters from the hstfile.
%  HSTPARS = HST_READ(HSTFILE) reads stim-history parameters from the hstfile.
%  Supported options are
%    'verbose'  :  0|1, verbose or not.
%
%  EXAMPLE :
%    hstpars = hst_read('\\Win49\N\DataNeuro\B06.FU1\stmfiles\b06FU1_001.hst')
%
%  VERSION :
%    1.00 21.05.03 YM  first release
%
% See also stm_read pdm_read tcl_read

if nargin == 0, help hst_read; return;   end

% init output
hstpars = [];

VERBOSE = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if isempty(hstfile),
  [hstfile, pathname] = uigetfile(...
      {'*.hst', 'HST Files (*.hst)'; ...
       '*.*',   'All Files (*.*)'}, ...
      'Pick a hst file',pwd);
  if isequal(hstfile, 0) || isequal(pathname,0), 
    fprintf(' %s: uigetfile() canceled.\n',mfilename);
    return;
  end
  hstfile = fullfile(pathname,hstfile);
  clear pathname;
end


if ~exist(hstfile,'file'),
  if VERBOSE,
    fprintf(' WARNING %s: ''%s'' not found.\n',mfilename,hstfile);
  end
  return;
end

% read text
hstline = tcl_read(hstfile);
if isempty(hstline), return;  end
hstpars.filename = hstfile;

% process text
hstpars.numRepeats    = str2num(subGetPrmValue('MRIPDM::SetNumRepeats',hstline));
hstpars.numTrials     = str2num(subGetPrmValue('set MRIPDM::m_numTrials',hstline));
hstpars.numObsPeriods = str2num(subGetPrmValue('set MRIPDM::m_numObsPeriods',hstline));
hstpars.paramTable    = subGetPrmValue('array set MRIPDM::m_paramTable',hstline);
hstpars.paramIndices  = str2num(subGetPrmValue('set MRIPDM::m_paramIndices',hstline));
hstpars.paramStimIndices = str2num(subGetPrmValue('set MRIPDM::m_stimIndices',hstline));




% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pvar = subGetPrmValue(strpat, hstline)
pvar = '';
prmline = strmatch(strpat,hstline);
if isempty(prmline),  return;  end
[t0,r0] = strtok(hstline{prmline}(length(strpat)+1:end));
pvar = strcat(t0,r0);
if pvar(1) == '"',
  pvar = pvar(2:end-1);
end
