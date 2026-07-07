function stmpars = stm_read(stmfile,varargin)
%STM_READ - Get stimulus parameters from the stmfile.
%  STMPARS = STM_READ(STMFILE,...) reads stimulus parameters from the stmfile.
%  Supported options are
%    'verbose'  :  0|1, verbose or not.
%
%  EXAMPLE :
%    stmpars = stm_read('\\Win49\N\DataNeuro\B06.FU1\stmfiles\b06FU1_001.stm')
%
%  VERSION :
%    1.00 27.04.03 YM  first release
%    1.01 22.07.03 YM  bug fix for 'StimTypes' and 'StimDurations'.
%    1.02 15.05.04 YM  supports 'grouped objects'.
%    1.03 30.06.04 YM  return also experiment date.
%    1.04 14.08.07 YM  bug fix for StimObjIDs of mixed objs.
%    1.05 10.09.08 YM  supports 'verbose', uigetfile().
%    1.06 21.12.10 YM  clean-up codes.
%
% See also pdm_read hst_read tcl_read rfp_read

if nargin < 1, help stm_read; return;  end

% initialize output
stmpars = [];


VERBOSE = 1;
for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end

if isempty(stmfile),
  [stmfile, pathname] = uigetfile(...
      {'*.stm', 'STM Files (*.stm)'; ...
       '*.*',   'All Files (*.*)'}, ...
      'Pick a stm file',pwd);
  if isequal(stmfile, 0) || isequal(pathname,0), 
    fprintf(' %s: uigetfile() canceled.\n',mfilename);
    return;
  end
  stmfile = fullfile(pathname,stmfile);
  clear pathname;
end


if ~exist(stmfile,'file'),
  if VERBOSE,
    fprintf(' WARNING %s: ''%s'' not found.\n',mfilename,stmfile);
  end
  return;
end

% read lines
lines = tcl_read(stmfile,'comments',1);

% get date
tmpdate = '';  token = '# <Generated: ';
for N = 1:length(lines),
  tmptxt = lines{N};
  if ~isempty(strfind(tmptxt,token)),
    tmpdate = tmptxt(length(token)+1:end-1);
    break;
  end
end


stmpars.date = tmpdate;



% make a pars-struct of stimuli
for N = 1:length(lines),
  [parname,parvalue] = subGetPars(lines{N});
  if isempty(parname), continue;  end
  switch parname
   case { 'NumTrigPerVolume' }
    stmpars.NumTrigPerVolume = str2double(parvalue);
   case { 'StimTypes' }
    stmpars.StimTypes  = {};
    stmpars.StimObjIDs  = {};
    stmpars.StimGrp     = [];
    rem = parvalue;
    curstmgrp = 0;
    curstmid  = 0;
    while 1,
      [token,rem] = strtok(rem);
      if ~isempty(token),
        if token(1) == '{',
          idx = strfind(rem,'}');
          tmprem = rem(1:idx(1)-1);
          rem = rem(idx(1)+1:end);
          token = token(2:end);
          token = strrep(token,' ',''); % remove blanks
          tmptypes = { token };
          while 1,
            [token,tmprem] = strtok(tmprem);
            if ~isempty(token),
              tmptypes = cat(2,tmptypes,token);
              %tmptypes{end+1} = token;
            end
            if isempty(tmprem),  break;  end
          end
          tmpstr = sprintf('%s',tmptypes{1});
          for K = 2:length(tmptypes),
            tmpstr = sprintf('%s+%s',tmpstr,tmptypes{K});
          end
        else
          tmpstr   = token;
          tmptypes = { token };
        end
        stmpars.StimTypes{end+1}  = tmpstr;
        stmpars.StimObjIDs{end+1} = (0:length(tmptypes)-1) + curstmid;
        stmpars.StimGrp(end+1)    = curstmgrp;
        curstmid  = curstmid  + length(tmptypes);
        curstmgrp = curstmgrp + 1;
      end
      if isempty(rem), break; end
    end
   case { 'StimDurations' }
    stmpars.StimDurations = str2num(parvalue);
   otherwise
    % check pars of STMOBJ[0-9]
    if strcmp(parname(1:6),'STMOBJ'),
      % get stimid and attribute name
      sep = findstr(parname, '(');
      stmid = str2double(parname(7:sep-1)) + 1;
      pname = parname(sep+1:end-1);
      % check value whether string or numerics
      if ~isempty(parvalue) && ~any(isletter(parvalue)),
        % conver a string to a numeric array
        parvalue = str2num(parvalue);
      end
      %fprintf('stmid = %d, pname=%s\n',stmid,pname);
      %eval(['stmpars.stmobj{stmid}.',pname,'=parvalue;']);
      stmpars.stmobj{stmid}.(pname) = parvalue;
    end
  end
end


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [parname,parvalue] = subGetPars(txtline)
parname = '';  parvalue = '';
[token,rem] = strtok(txtline);
if strcmp(token,'set'),
  [parname, rem] = strtok(rem);
  [parvalue,rem] = strtok(rem);
  % remove '::'
  if strcmp(parname(1:2),'::'),
    parname = parname(3:end);
  end
  if strcmp(parvalue(1),'"'),
    % check complete end of '"'
    if strcmp(parvalue(end),'"') == 0,
      parvalue = strcat(parvalue,rem(1:findstr(rem,'"')));
    end
  elseif strcmp(parvalue(1),'{'),
    % check complete end of '{'
    if strcmp(parvalue(end),'}') == 0,
      parvalue = strcat(parvalue,rem(1:end));
    end
  end
  if strcmp(parname,''),
    parvalue, rem
  end
  % remove '"' or '}"
  if length(parvalue) <= 2,
    parvalue = '';
  elseif parvalue(end) == '"',
    parvalue = parvalue(2:end-1);
  elseif parvalue(end) == '}',
    parvalue = parvalue(2:end-1);
  end
end
