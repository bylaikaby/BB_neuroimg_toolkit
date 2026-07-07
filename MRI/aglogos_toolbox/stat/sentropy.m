function ent = sentropy(x);
%SENTROPY - Computes the entropy of a vector x
% SENTROPY computes the entropy of the signal directly from the
% signal's own distribution. For our highly resolved neural or fMRI
% signals no Parzen-windowing seems to be necessary. We estimate the
% size of bin width by calculating the median and standard deviation
% of the difference signal. The bin width is defined as
%       bwidth = me + 3 * sd;
% and the number of bins as
%       nbins = round((max(x(:))-min(x(:)))/bwidth);
% The density function of the signal's amplitude is given by
%       p = hist(x,nbins), which is normalized to  sum(p)
% Entropy is then calculated as
%       ent = -sum(p(ix,N) .* log(p(ix,N)));
%
% MODE = 0 will perform the parzen windowing
% MODE = 1 (Default) will ignore it.
%
% N.K. Logothetis 04.06.04
  
MODE = 1;

if length(size(x)) > 2,
  fprintf('SENTROPY(ENTROPY): handles only 2D Matrices\n');
  keyboard;
end;

if MODE == 0,                       % Apply Parzen windowing
  for M=1:size(x,2),
    x1 = x(:,M);
    [sortx,isortx] = sort(x1(:));
    dx = diff(sortx);
    me = nanmedian(dx);
    sd = nanstd(dx);
    bwidth = me + 3 * sd;
    nbins = round((max(x1(:))-min(x1(:)))/bwidth);
    
    EXTENSION=15;
    ngrid = 2 * EXTENSION + 1;
    x1 = cat(1,zeros(EXTENSION,1),x1,zeros(EXTENSION,1));
    g = normpdf([1:ngrid],ngrid/2,15);
    g = g(:)/sum(g);
    ix = find(dx>bwidth)+1; % Add one to estimate the index of sortx

    for N=1:length(ix),
      x1(isortx(ix(N))) = ...
          sum(x1(isortx(ix(N)):isortx(ix(N))+2*EXTENSION) .* g);
    end;
    x1 = x1(EXTENSION+1:end-EXTENSION);
    
    p = hist(x1,nbins);
    p = p(:)./sum(p);
    ix = find(p);
    ent(M) = -sum(p(ix) .* log(p(ix)));
  end;

else                                % Data-derived distribution
    
  % ===============================================================
  % B. WITHOUT SELECTIVE PARZEN WINDOWING
  % ===============================================================
  % Sort the signal, and compute the statistics of differences
  % For the sorted signal this gives an idea of the range of
  % discontinuities, that one could, in principle, bridge by applying
  % the Parzen window. For the physiology data, I suspect, there is
  % no need for windowing. The first results confirm the "suspicion"!
  dx = diff(sort(x(:)));
  me = nanmedian(dx);
  sd = nanstd(dx);
  
  % The unrectified signals have a perfectly gaussian distribution, but
  % the rectified ones do not. We therefore calculated the median as a
  % robust measure of location. For dispersion-measure, however, we do
  % not take the interquartile range (robust to outliers) but rather the
  % standard deviation that represents also some of the large
  % differences.
  bwidth = me + 3 * sd;
  nbins = round((max(x(:))-min(x(:)))/bwidth);
  
  % The hist function below will return the distribution of the
  % signal values. We normalized them to add to unity, and then
  % compute the amount of entropy.
  p = hist(x,nbins);
  if length(x) == prod(size(x)),
    p = p(:);
  end;
  p = p./repmat(sum(p),[size(p,1) 1]);
  for N=1:size(x,2),
    ix = find(p(:,N));
    ent(N) = -sum(p(ix,N) .* log(p(ix,N)));
  end;

end;
return;
