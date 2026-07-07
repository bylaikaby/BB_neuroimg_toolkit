function toffs = mget_slicetime(Ses,ExpNo,varargin)
%MGET_SLICETIME - Get time offsets of each slice acquisition in sec.
%  TOFFS = MGET_SLICETIME(Ses,ExpNo) gets time offsets of each slice in seconds.
%
%  Supported options :
%    'average' : average timings among segments WITHOUT SERIOUS consideration.
%
%  EXAMPLE :
%    toffs = mget_slicetime('E10.ha1',10,'average',1);
%    toffs = mget_slicetime('E10.ha1',10,'average',0);
%
%  NOTE :
%    ACQ_obj_order/PVM_ObjOrderList is experimentally supported.
%
%  VERSION :
%    0.90 28.02.13 YM  pre-release
%    0.91 22.09.17 YM  supports parallel-imaging data, ObjOrderList.
%
%  See also getpvpars expgetpar pv_getpvpars

if nargin < 2,  eval(['help ' mfilename]); return;  end

DO_AVERAGE = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'average'}
    DO_AVERAGE = varargin{N+1};
  end
end


if ~isnumeric(ExpNo),
  ExpNo = getexps(Ses,ExpNo);
  ExpNo = ExpNo(1);
end

if ~isimaging(Ses,ExpNo),
  toffs = [];
  return;
end


p = expgetpar(Ses,ExpNo);
pv = p.pvpar;


if sub_IsParallelImaging(pv),
  toffs = sub_toffs_ParallelImaging(pv);
else
  toffs = sub_toffs_RegularImaging(pv,DO_AVERAGE);
end

return


% --------------------------------------------------------------
function IsPI = sub_IsParallelImaging(pv)
% --------------------------------------------------------------
IsPI = 0;
acqp = pv.acqp;
if any(strfind(lower(acqp.PULPROG),'dualslice')) || any(strfind(lower(acqp.PULPROG),'mbepi')),
  IsPI = 1;
end

return


% --------------------------------------------------------------
function toffs = sub_toffs_ParallelImaging(pv)
% --------------------------------------------------------------
acqp   = pv.acqp;
method = pv.method;

% ACQ_repetition_time or PVM_RepetitionTime
% ACQ_obj_order or PVM_ObjOrderList
ObjOrderList = method.PVM_ObjOrderList;   % pair numbers, not the slice numbers. i.e. 0=[0,10] if NBands=2, NSli=20
objtr = acqp.ACQ_repetition_time/1000/length(ObjOrderList);  % in sec

objoffs = (0:length(ObjOrderList)-1)*objtr;

if isfield(method,'NBands'),
  NBands = method.NBands;  if ischar(NBands), NBands = str2double(NBands);  end
  toffs = zeros(1,length(ObjOrderList)*NBands);
  slioffs = round(pv.nsli/NBands);
  for N = 1:NBands,
    tmpi = ObjOrderList + 1  + (N-1)*slioffs;
    toffs(tmpi) = objoffs;
  end
else
  fprintf(' WARNING %s: no "method.NBands", not supported yet.\n',mfilename);
  keyboard
end

return



% --------------------------------------------------------------
function toffs = sub_toffs_RegularImaging(pv,DO_AVERAGE)
% --------------------------------------------------------------

ObjOrderList = [];
if isfield(pv,'method') && isfield(pv.method,'PVM_ObjOrderList')
  ObjOrderList = pv.method.PVM_ObjOrderList;
elseif isfield(pv,'acqp') && isfield(pv.acqp,'ACQ_obj_order'),
  ObjOrderList = pv.acqp.ACQ_obj_order;
elseif isfield(pv,'acqp') && isfield(pv.acqp,'PVM_ObjOrderList'),
  % old data format (mixed acqp/imnd): getpvpars() by JP...
  ObjOrderList = pv.acqp.PVM_ObjOrderList;
end

if isempty(ObjOrderList),
  % assume normal ObjOrder, i.e. no reverse/interleaved.
  ObjOrderList = 0:pv.nsli-1;
end

ObjOrderList = ObjOrderList(:)';
tmpv = unique(ObjOrderList);
if length(tmpv) ~= pv.nsli && min(tmpv) ~= 0 && max(tmpv) ~= pv.nsli
  fprintf(' WARNING %s: invalid ObjOrderList, not supported yet.\n',mfilename);
  keyboard
end
clear tmpv;


if pv.nseg > 1,
  toffs = zeros(pv.nseg, pv.nsli);
  objoffs = (0:pv.nsli-1)*pv.slitr;
  for N = 1:pv.nseg,
    toffs(N,ObjOrderList+1) = objoffs + (N-1)*pv.segtr;
  end
  
  % toffs = zeros(pv.nseg, pv.nsli);
  % tseg = (0:pv.nseg-1)' * pv.segtr;
  % for iSli = 1:pv.nsli,
  %   toffs(:,iSli) = tseg + (iSli-1)*pv.slitr;
  % end
  
  if any(DO_AVERAGE)
    toffs = mean(toffs,1);
  end
else
  objoffs = (0:pv.nsli-1) * pv.slitr;
  toffs = zeros(1,pv.nsli);
  toffs(ObjOrderList+1) = objoffs;
end

return
