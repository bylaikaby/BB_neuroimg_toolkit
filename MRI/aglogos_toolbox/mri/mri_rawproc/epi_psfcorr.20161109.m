function V = epi_psfcorr(V,PSF_PATH,varargin)
%EPI_PSFCORR - PSF correction
%  V = EPI_PSFCORR(V,PSF_PATH,...) runs PSF correction.
%
%  Supported options are :
%    'shiftsize'  : PSF shift size
%    'threshould' : Masking threshold
%    'upsample'   : upsampling
%
%  NOTE :
%   Phase correction (if needed) must be processed before PSF correction.
%
%  VERSION :
%    0.90 07.11.2016 DB
%
%  See also fidcopyreadnew interpft distcfast brurproc_phcorr bruproc bruproc_gui

if nargin < 2,  eval(['help ' mfilename]); return;  end

% OPTIONS
SHIFT_SIZE  = [0 0];
MASKING_THR = 0.2;
UPSAMPLE_V  = 4;
VERBOSE     = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'shiftsz' 'shiftsize' 'psfshiftsize' 'psfshift'}
    if ~isempty(varargin{N+1}),
      SHIFT_SIZE = vargin{N+1};
    end
   case {'thr' 'thres' 'threshold' 'psfmaskthr'}
    if any(varargin{N+1}),
      MASKING_THR = varargin{N+1};
    end
   case {'upsample' 'upsampling' 'psfupsample' 'psfupsamp'}
    if any(varargin{N+1}),
      UPSAMPLE_V = varargin{N+1};
    end
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
  end
end


if any(VERBOSE),  fprintf(' %s :',mfilename);  end

if ischar(V),
  % "V" as 2dseq file
  V = pvread_2dseq(V);
end


DATCLASS = class(V);
V = single(V);


if any(VERBOSE),  fprintf(' fidcopyreadnew(fidCopy_EG).');  end
[~, psfdat] = fidcopyreadnew(PSF_PATH,'fidCopy_EG');
if any(VERBOSE),  fprintf(' psfsize[%s].',deblank(sprintf('%d ',size(psfdat))));  end




if any(VERBOSE),  fprintf(' distcfast(shift=[%s], thr=%g, upsample=%d).',...
                          deblank(sprintf('%d ',SHIFT_SIZE)),MASKING_THR,UPSAMPLE_V);  end

fsz = size(V);
% do PSF-correction
% if implemented in gui, the readin can be interactive
% the zero filling of the psf-data is not optional
% user could set the circshift parameters
% and the masking threshold, 3rd param of distcfast
psfdat = permute(interpft(permute(interpft(permute(psfdat,[4 1 2 3]), fsz(2)),[3 2 4 1]), fsz(2)),[2 1 3 4]);
V = distcfast(V,circshift(psfdat,SHIFT_SIZE),MASKING_THR,UPSAMPLE_V);


eval(['V = ' DATCLASS '(V);']);  % revert data class

if any(VERBOSE),  fprintf(' done.\n');  end

return
