function pdmpars = pdm_read(pdmfile,varargin)
%PDM_READ - Get stim-paradigm parameters from the pdmfile.
%  PDMPARS = PDM_READ(PDMFILE,...) reads stim-paradigm parameters from the pdmfile.
%  Supported options are
%    'verbose'  :  0|1, verbose or not.
%
%  EXAMPLE :
%    pdmpars = pdm_read('\\Win49\N\DataNeuro\B06.FU1\stmfiles\b06FU1_001.pdm')
%
%  VERSION :
%    1.00 21.05.03 YM  first release
%    1.01 30.06.04 YM  warning fix for Matlab7
%    1.02 10.09.08 YM  supports 'verbose', uigetfile().
%
% See also stm_read hst_read tcl_read

if nargin == 0, help pdm_read; return;   end

% init output
pdmpars = [];


VERBOSE = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if isempty(pdmfile),
  [pdmfile, pathname] = uigetfile(...
      {'*.pdm', 'PDM Files (*.pdm)'; ...
       '*.*',   'All Files (*.*)'}, ...
      'Pick a pdm file',pwd);
  if isequal(pdmfile, 0) || isequal(pathname,0), 
    fprintf(' %s: uigetfile() canceled.\n',mfilename);
    return;
  end
  pdmfile = fullfile(pathname,pdmfile);
  clear pathname;
end


if ~exist(pdmfile,'file')
  if VERBOSE,
    fprintf(' WARNING %s: ''%s'' not found.\n',mfilename,pdmfile);
  end
  return;
end

% read text
pdmline = tcl_read(pdmfile);
if isempty(pdmline), return;  end
pdmpars.filename = pdmfile;

% process text
prmline = strmatch('MRIPDM::AddNewParam',pdmline);
if isempty(prmline),
  % pdm file used for 'rivaly' experiments.
  prmline = strmatch('newStmParam',pdmline);
end

nprm = 0;
ncmb = 1;
prmpars.prmNames = {};
prmpars.prmVars  = {};
pdmpars.nprmVars = [];
for i = 1:length(prmline)
  [t0,r0] = strtok(pdmline{prmline(i)});
  %fprintf(' %3d: %s   %s \n',i,pdmline{prmline(i)},t0);
  % get param-name
  [t1,r1] = strtok(r0);
  if t1(1) == '"', t1 = t1(2:end-1);  end
  % get param-values
  [t2,r2] = strtok(r1,'"');  [t2,r2] = strtok(r2,'"');
  if ~isempty(t2)
    nprm = nprm + 1;
    pdmpars.prmNames{nprm} = t1;
    pdmpars.prmVars{nprm} = str2num(t2);
    pdmpars.nprmVars(nprm) = length(pdmpars.prmVars{nprm});
    ncmb = ncmb * length(pdmpars.prmVars{nprm});
  end
end

pdmpars.nParams = nprm;
pdmpars.nPattByPrms = ncmb;
