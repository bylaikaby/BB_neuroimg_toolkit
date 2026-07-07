function Sdf = spkt2sdf(Spkt,varargin)
%SPKT2SDF - Generate Sdf structure from Spkt.
%  Sdf = SPKT2SDF(Spkt,...) generate Sdf structure from Spkt.
%
%  EXAMPLE :
%    Spkt = sigload(Ses,ExpNo,'Spkt')
%    Sdf = spkt2sdf(Spkt)
%
%  VERSION :
%    0.90 18.02.13 YM  moved from siggetspk().
%
%  See also spksdf siggetspk xform

if nargin < 1,  eval(['help ' mfilename]); return;  end

Ses   = goto(Spkt.session);
ExpNo = Spkt.ExpNo(1);
%par   = expgetpar(Ses,ExpNo);
anap  = getanap(Ses,ExpNo);

CONV2SDU  = 1;
SDFRATE   = 250;
SDFKERNEL = 0.025;
DoAverage = 0;
VERBOSE   = 1;


% update by anap
if isfield(anap,'siggetspk'),
  if isfield(anap.siggetspk,'conv2sdu'),
    CONV2SDU = anap.siggetspk.conv2sdu;
  end;
  if isfield(anap.siggetspk,'sdfkernel'),
    SDFKERNEL = anap.siggetspk.sdfkernel;
  end;
  if isfield(anap.siggetspk,'sdfrate'),
    SDFRATE = anap.siggetspk.sdfrate;
  end;
end

% update by input arguments
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'conv2sdu' 'normalize'}
    CONV2SDU  = varargin{N+1};
   case {'rate' 'sdfrate'}
    SDFRATE   = varargin{N+1};
   case {'kernel' 'sdfkernel'}
    SDFKERNEL = varargin{N+1};
   case {'averate' 'doaverage'}
    DoAverage = varargin{N+1};
   case {'verbose'}
    VERBOSE   = varargin{N+1};
  end
end

if VERBOSE,
  fprintf(' %s: Sdf[%gHz,kernel=%gms]...',mfilename,SDFRATE,SDFKERNEL*1000);
end

Sdf     = Spkt;
Sdf     = rmfield(Sdf,'times');
Sdf     = rmfield(Sdf,'dt');
if isfield(Sdf,'times_spkcdt'),
  Sdf = rmfield(Sdf,'times_spkcdt');
end

Sdf.dat = spksdf(Spkt,SDFRATE,SDFKERNEL);
Sdf.dx  = 1/SDFRATE;

if isfield(Spkt,'dxorg'),
  Sdf.dxorg = Sdf.dx / Spkt.dx * Spkt.dxorg;
end

Sdf.dir.dname = 'Sdf';
Sdf.dsp.func = 'dspsig';
Sdf.dsp.args = {'color';[0 .7 0];'linestyle';'-';'linewidth';0.5};
Sdf.dsp.label{1} = 'Time in seconds';
Sdf.dsp.label{2} = 'Spike Density';

% if isfield(par,'stm'),
%   Sdf.stm = par.stm;
% else
%   Sdf.stm = {};
% end
% if isfield(par,'evt'),
%   Sdf.evt = par.evt;
% else
%   Sdf.evt = {};
% end

if isnumeric(CONV2SDU),
  tmpstr = 'none';
  if CONV2SDU == 1,
    tmpstr = 'tosdu';
  elseif CONV2SDU == 2,
    tmpstr = 'detrend';
  elseif CONV2SDU == 3,
    tmpstr = 'zerobase';
  end
  CONV2SDU = { tmpstr '' };
elseif ischar(CONV2SDU),
  CONV2SDU = { CONV2SDU '' };
end
if ~isempty(CONV2SDU),
  tmpmethod = CONV2SDU{1};
  tmpepoch  = '';
  if length(CONV2SDU) > 1,
    tmpepoch = CONV2SDU{2};
  end
  if ~isempty(tmpmethod) && ~any(strcmpi({'none','no'},tmpmethod)),
    %if VERBOSE,
      fprintf(' xform(%s,%s)...',tmpmethod,tmpepoch);
    %end
    Sdf = xform(Sdf,tmpmethod,tmpepoch);
  end
end

Sdf.(mfilename).conv2sdu  = CONV2SDU;
Sdf.(mfilename).sdfkernel = SDFKERNEL;
Sdf.(mfilename).sdfrate   = SDFRATE;

% We don't really need this, because sigload takes care of the STM updates
% Sdf = rmfield(Sdf,{'stm','evt','grp'});

if DoAverage,
  if VERBOSE,
    fprintf('\n %s[WARNING]: Averaging Sdf...',mfilename);
  end
  Sdf.dat  = squeeze(nanmean(Sdf.dat,3));
end

if isfield(Spkt,'movie'),
  Sdf.movie = Spkt.movie;
end;

if VERBOSE, fprintf(' done.\n');  end


return
