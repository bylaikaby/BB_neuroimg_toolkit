% pop_loaddat7() - Load a Curry7 (neuroscan) DAT file.
%
% Usage:
%   >> EEG = pop_loaddat7; % pop-up window mode
%   >> EEG = pop_loaddat7( filename, 'key', 'val', ...);
%
% Graphic interface:
%
%
% Inputs:
%   filename       - name of Curry7 dat file (incl. extension)
%
% Optional inputs:
%   'samples'      - sample selection as [start end] in sample-points
%   'channels'     - channel selection as a numeric vector
%   'invertstim'   - 0|1, invert stimulus bits
%   'invertresp'   - 0|1, invert response bits
%
% Outputs:
%   EEG            - EEGLAB EEG structure
%   command        - history string
%
% Author: Yusuke Murayama, MPI for Biological Cybernetics, 2014-
%
% See also nscan_loaddat7 pop_loadcnt pop_loaddat

function varargout = pop_loaddat7(filename, varargin)
%POP_LOADDAT7 - Load a Curry7 (neuroscan) DAT file.
%  EEG = POP_LOADDAT7(FILENAME,...) loads a Curry7 (neuroscan) DAT file.
%
%  EXAMPLE :
%    EEG = pop_loaddat7(filename)
%
%  VERSION :
%    0.90 27.01.14 YM  pre-release, MPI Tuebingen
%    0.91 10.02.14 YM  clean-up.
%
%  See also nscan_loaddat7

%  COPYRIGHT (C) 2014 Yusuke Murayama,  Max Planck Institute for Biological Cybernetics
%  Simplified BSD License, see readme.txt for detail.

EEG     = [];
command = '';

%if nargin < 1, eval(['help ' mfilename]); return;  end

% options
iPERIOD    = [];
iCHANS     = [];
InvertStim = 0;
InvertResp = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'period' 'srange' 'sample' 'samples'}
    iPERIOD = varargin{N+1};
   case {'chans' 'channels' 'chan' 'channel'}
    iCHANS  = varargin{N+1};
   case {'invertstim' 'invert_stim' 'invert stimulus' 'invertstimulus'}
    InvertStim = any(varargin{N+1});
   case {'invertresp' 'invert_resp' 'invert response' 'invertresponse'}
    InvertResp = any(varargin{N+1});
  end
end


if nargin < 1,
  % ask user
  [filename, filepath] = uigetfile(...
      {'*.DAT;*.dat', 'Curry7 DAT file (*.dat)'; ...
       '*.*',         'All Files (*.*)' }, ...
      ['Choose a Curry7 DAT file -- ' mfilename]);
  drawnow;
  if isequal(filename,0),  return;  end
  fullpath = fullfile(filepath, filename);
  
  % popup window parameters
  uigeom = { [1 0.5] [1 0.5] [1 0.2 0.2] };
  uilist = { { 'style' 'text' 'string' 'Period (samples; e.g., [10 1000]; default: all):'} ...
             { 'style' 'edit' 'string' ''} ...
             { 'style' 'text' 'string' 'Channels (e.g., [1:5 7]; default: all):'} ...
             { 'style' 'edit' 'string' ''} ...
             { 'style' 'text' 'string' 'Invert Trigger Bits:'} ...
             { 'style' 'checkbox' 'value' any(InvertStim) } ...
             { 'style' 'checkbox' 'value' any(InvertResp) } ...
           };
  result = inputgui(uigeom, uilist, ['pophelp(''' mfilename ''')'], 'Load a Curry7 dataset');
  if isempty(result),  return;  end

  options = [];
  if ~isempty(result{1}),
    iPERIOD = str2num(result{1});
    options = [ options ', ''period'',' result{1} ];
  end
  if ~isempty(result{2})
    iCHANS  = str2num(result{2});
    options = [ options ', ''chans'',' result{1} ];
  end
  if ~isempty(result{3}),
    InvertStim = result{3};
    options = [ options ', ''invert_stim'',' num2str(result{3}) ];
  end
  if ~isempty(result{4}),
    InvertResp = result{4};
    options = [ options ', ''invert_resp'',' num2str(result{4}) ];
  end

else
  fullpath = filename;
  options = vararg2str(varargin);
end


[EEG, DAP, RS3, CEO] = nscan_loaddat7(fullpath, ...
                                      'period',iPERIOD, 'channels',iCHANS, ...
                                      'invert_stim',InvertStim, ...
                                      'invert_resp',InvertResp);

varargout{1} = EEG;
if nargout >= 2
  if isempty(options),
    command = sprintf('EEG = %s(''%s'');',mfilename,fullpath);
  else
    command = sprintf('EEG = %s(''%s''%s);',mfilename,fullpath,options);
  end
  varargout{2} = command;
end
if nargout >= 3
  varargout{3} = DAP;
  varargout{4} = RS3;
  varargout{5} = CEO;
end


return
