function [pxx, fv, t] = pmtmspectrogram(x, window, noverlap, nfft, fs, nw)

%PMTMSPECTROGRAM Multitaper-based spectrogram
%
% INPUT
%   The input structure follows that of SPECTROGRAM. Note however, that in
%   this case, if WINDOW is specified as an array, only its lenght is used
%   and no taper is actually applied to the data. If WINDOW is a scalar
%   (integer) then it specifies the window length.
%
%   The meaning of the other inputs is the same as for function
%   SPECTROGRAM.

if nargin<6
    nw = 2;
end

if isvector(window) && ~isscalar(window)
    nwind = length(window);
else
    nwind = window;
end
nx = length(x);

ncol = fix((nx-noverlap)/(nwind-noverlap));


% Pre-process X
colindex = 1 + (0:(ncol-1))*(nwind-noverlap);
rowindex = (1:nwind)';
xin = zeros(nwind,ncol);

% Put x into columns of xin with the proper offset
xin(:) = x(rowindex(:,ones(1,ncol))+colindex(ones(nwind,1),:)-1);

for col=1:ncol
    
    [pxxTmp, fv] = pmtm(xin(:,col), nw, nfft, fs);
    
    if col==1
        pxx = zeros(size(pxxTmp,1), ncol);
    end
    
    pxx(:,col) = pxxTmp;
    
end

% colindex already takes into account the noverlap factor; Return a T
% vector whose elements are centered in the segment.
t = ((colindex-1)+((nwind)/2)')/fs; 