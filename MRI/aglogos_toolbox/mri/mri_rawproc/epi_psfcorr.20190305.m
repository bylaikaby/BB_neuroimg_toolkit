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
%    0.91 19.06.2018 YM  bug fix.
%    0.92 20.06.2018 YM  support 'double' precision
%
%  See also fidcopyreadnew interpft distcfast brurproc_phcorr bruproc bruproc_gui

if nargin < 2,  eval(['help ' mfilename]); return;  end

% OPTIONS
SHIFT_SIZE  = [0 0];
MASKING_THR = 0.2;
UPSAMPLE_V  = 4;
DATA_CLASS = 'single';
if isfloat(V),  DATA_CLASS  = class(V);  end  % use the same data class as "V".
VERBOSE     = 1;
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'shiftsz' 'shiftsize' 'psfshiftsize' 'psfshift'}
    if ~isempty(varargin{N+1})
      SHIFT_SIZE = varargin{N+1};
    end
   case {'thr' 'thres' 'threshold' 'psfmaskthr'}
    if any(varargin{N+1})
      MASKING_THR = varargin{N+1};
    end
   case {'upsample' 'upsampling' 'psfupsample' 'psfupsamp'}
    if any(varargin{N+1})
      UPSAMPLE_V = varargin{N+1};
    end
   case {'datatype' 'dataclass' 'type' 'precision'}
    if strcmpi(varargin{N+1},'double')
      DATA_CLASS = 'double';
    else
      DATA_CLASS = 'single';
    end
   case {'verbose'}
    VERBOSE = any(varargin{N+1});
  end
end


if any(VERBOSE),  fprintf(' %s :',mfilename);  end

if ischar(V)
  % "V" as 2dseq file
  [V, Vpar] = pvread_2dseq(V);
else
  Vpar.method = [];
  Vpar.reco   = [];
  Vpar.acqp   = [];
end

%IS_INTEGER   = isinteger(V);
EPI_DATCLASS = class(V);
if strcmpi(DATA_CLASS,'double')
  V = double(V);
else
  V = single(V);
end


if ischar(PSF_PATH)
  if any(VERBOSE),  fprintf(' fidcopyreadnew(fidCopy_EG).');  end
  [~, psfdat] = fidcopyreadnew(PSF_PATH,'fidCopy_EG',Vpar.method,Vpar.reco,Vpar.acqp,...
                               0,'',[],[],'datatype',DATA_CLASS);
else
  psfdat = PSF_PATH;
end
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
% %psfdat = permute(psfdat,[4 1 2 3]);  % [nr nx ny nz]
% %psfdat = interpft(psfdat,fsz(2));
% %psfdat = permute(psfdat,[3 2 4 1]);  % [ny nx nz nr]
% %psfdat = interpft(psfdat,fsz(2));
% %psfdat = permute(psfdat,[2 1 3 4]);  % [nx ny nz nr]
% if size(psfdat,4) ~= fsz(2),
%   psfdat = permute(psfdat,[4 1 2 3]);  % [nr nx ny nz]
%   psfdat = interpft(psfdat,fsz(2));
%   psfdat = ipermute(psfdat,[4 1 2 3]); % [nx ny nz nr]
% end
% if size(psfdat,2) ~= fsz(2)
%   psfdat = permute(psfdat,[2 1 3 4]);  % [ny nx nz nr]
%   psfdat = interpft(psfdat,fsz(2));
%   psfdat = ipermute(psfdat,[2 1 3 4]); % [nx ny nz nr]
% end
V = distcfast(V,circshift(psfdat,SHIFT_SIZE),MASKING_THR,UPSAMPLE_V);

%if IS_INTEGER,  V = round(V);  end % intXX() function does rounding and do not round here since values may be
eval(['V = ' EPI_DATCLASS '(V);']);  % revert data class

if any(VERBOSE),  fprintf(' done.\n');  end

return
