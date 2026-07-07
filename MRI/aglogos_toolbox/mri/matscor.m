function [roiTs corana] = matscor(roiTs,mdlsct,SHIFT_SEARCH)
%MATSCOR - Apply correlation analysis to the roiTs time series Xcor =
% MATSCOR (roiTs) uses the model "mdlsct" to search for time series in
% roiTs that correlate with stimulus changes.
%
% [R,P]=corrcoef(...) returns P, a matrix of p-values for testing the
% hypothesis of no correlation. Each p-value is the probability of
% getting a correlation as large as the observed value by random
% chance, when the true correlation is zero. If P(i,j) is small, say
% less than 0.05, then the correlation R(i,j) is significant.
%
%  VERSION :
%    1.00 11.04.04 NKL
%    1.01 16.06.08 YM  support mdlsct{}.bold_tfilter as [hpassHz, lpassHz]
%    2.00 06.02.12 YM  separates result as corana.
%
% See also MCOR MCORANA MCORIMG


if nargin < 3,
  SHIFT_SEARCH = 0;                % No xcor/lags are computed
end;

if nargin < 2,
  help matscor;
  return;
end;

NLAGS = round(SHIFT_SEARCH/roiTs{1}.dx);
NoRoi = length(roiTs);
NoModel = length(mdlsct);

corana = cell(size(roiTs));
for A = 1:NoRoi,
  % clear existing .r/.p
  if isfield(roiTs{A},'r')
    roiTs{A} = rmfield(roiTs{A},{'r' 'p'});
  end
  if isfield(roiTs{A},'mdl'),
    roiTs{A} = rmfield(roiTs{A},'mdl');
  end
  
  tmpdat = roiTs{A}.dat;
  idx = find(isnan(tmpdat(:)));
  tmpdat(idx) = 0;
  
  if isempty(tmpdat),
    fprintf('empty-dat(%d).',A);
    tmpr = zeros(size(roiTs{A}.coords,1),1);
    tmpp = ones(size(tmpr));
  end

  for M = NoModel:-1:1,
    tcutoffs = [];  lagfix = [];  tselect = [];
    % mdlsct{M} is a cell array containing models for each of roiTs
    if iscell(mdlsct{M}),
      tmpmdl = mdlsct{M}{A}.dat;
      %[roiTs{A}.r{M}, roiTs{A}.p{M}] = mcor(mdlsct{M}{A}.dat,roiTs{A}.dat,NLAGS);
      if isfield(mdlsct{M}{A},'bold_tfilter') & ~isempty(mdlsct{M}{A}.bold_tfilter),
        tcutoffs = mdlsct{M}{A}.bold_tfilter;
      end
      if isfield(mdlsct{M}{A},'lagfix') & ~isempty(mdlsct{M}{A}.lagfix),
        lagfix = round(mdlsct{M}{A}.lagfix/roiTs{A}.dx);
      end
      if isfield(mdlsct{M}{A},'tselect') & ~isempty(mdlsct{M}{A}.tselect),
        tselect = mdlsct{M}{A}.tselect;
      end
    else
      tmpmdl = mdlsct{M}.dat;
      %[roiTs{A}.r{M}, roiTs{A}.p{M}] = mcor(mdlsct{M}.dat,   roiTs{A}.dat,NLAGS);
      if isfield(mdlsct{M},'bold_tfilter') & ~isempty(mdlsct{M}.bold_tfilter),
        tcutoffs = mdlsct{M}.bold_tfilter;
      end
      if isfield(mdlsct{M},'lagfix') & ~isempty(mdlsct{M}.lagfix),
        lagfix = round(mdlsct{M}.lagfix/roiTs{A}.dx);
      end
      if isfield(mdlsct{M},'tselect') & ~isempty(mdlsct{M}.tselect),
        tselect = mdlsct{M}.tselect;
      end
    end;
    %lagfix
    if ~isempty(tmpdat),
      if ~isempty(tcutoffs),
        tmpdat2 = subDo_filter(tmpdat,roiTs{A}.dx,tcutoffs);
      else
        tmpdat2 = tmpdat;
      end
      if ~isempty(tselect),
        tmpidx = [1:round(tselect(2)/roiTs{A}.dx(1))] + round(tselect(1)/roiTs{A}.dx(1));
        tmpmdl  = tmpmdl(tmpidx);
        tmpdat2 = tmpdat2(tmpidx,:);
      end
      [tmpr tmpp] = mcor(tmpmdl,tmpdat2,NLAGS,lagfix);
    end
    
    corana{A}.session = roiTs{A}.session;
    corana{A}.grpname = roiTs{A}.grpname;
    corana{A}.ExpNo   = roiTs{A}.ExpNo;
    corana{A}.ana     = roiTs{A}.ana;
    corana{A}.coords  = roiTs{A}.coords;
    corana{A}.r{M}    = single(tmpr(:));
    corana{A}.p{M}    = single(tmpp(:));
    corana{A}.mdl{M}  = single(squeeze(tmpmdl(:,1,1)));
  end

end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to do filtering, cutoffs as [highpass lowpass]
function DAT = subDo_filter(DAT,DX,cutoffs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length(cutoffs) ~= 2,  return;  end
if all(cutoffs <= 0),  return;  end

nyq = 1.0/DX(1)/2;
if cutoffs(1) == 0,
  % low-pass
  [b,a] = butter(4,cutoffs(2)/nyq,'low');
elseif cutoffs(2) == 0,
  % high-pass
  [b,a] = butter(4,cutoffs(1)/nyq,'high');
else
  % band-pass
  [b,a] = butter(4,cutoffs/nyq,'bandpass');
end

if isvector(DAT),  DAT = DAT(:);  end

dlen   = size(DAT,1);
flen   = max([length(b),length(a)]);
idxfil = [flen+1:-1:2 1:dlen dlen-1:-1:dlen-flen-1];
idxsel = [1:dlen] + flen;

tmpdat  = filtfilt(b,a,DAT(idxfil,:));
DAT     = tmpdat(idxsel,:);

return

