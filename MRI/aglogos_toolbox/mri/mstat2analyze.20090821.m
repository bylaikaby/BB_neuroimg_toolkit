function mstat2analyze(varargin)
%MSTAT2ANALYZE - saves the statistics for rois in anz-file
% MSTAT2ANALYZE(SESSION,GRPEXP,ROI,MODEL,TRIAL,ALPHA,...) loads the
% statistics and saves it to statanz.img and statanz.hdr
%
% See also MVOXSELECT

if issig(varargin{1}),
  roiTs = varargin{1} ;
  RoiName = varargin{2} ;
  MODEL = varargin{3} ;
  if nargin > 3,
    TRIAL = varargin{4} ;
  end
  if nargin > 4,
    ALPHA = varargin{5} ;
  end
  if nargin > 5,
    varargin = varargin(6:end) ;
  else
    varargin = {} ;
  end
  roiTs = mvoxselect(roiTs,RoiName,MODEL,TRIAL,ALPHA,varargin{:}) ;
else
  session = varargin{1} ;
  GRPEXP = varargin{2} ;
  RoiName = varargin{3} ;
  MODEL = varargin{4} ;
  if nargin > 4,
    TRIAL = varargin{5} ;
  end
  if nargin > 5,
    ALPHA = varargin{6} ;
  end
  if nargin > 6,
    varargin = varargin(7:end) ;
  else
    varargin = {} ;
  end 
  if ischar(session),
    session = getses(session) ;
  end
  roiTs = mvoxselect(session,GRPEXP,RoiName,MODEL,TRIAL,ALPHA,varargin{:}) ;
end
anap = getanap(session,GRPEXP) ;

imagedata = zeros(size(roiTs.ana)) + 0 ;
data = roiTs.stat.dat ;

for N = 1:size(roiTs.coords,1),
  imagedata(sub2ind(size(roiTs.ana),roiTs.coords(N,1),roiTs.coords(N,2),roiTs.coords(N,3))) = data(ind2sub(size(roiTs.ana),N)) ;
end

imagedim = int16([4,size(imagedata)]) ;
if length(imagedim) < 5,
  imagedim(length(imagedim)+1:5) = int16(1) ;
end
header = hdr_init( ...
                  'extends',16384, ... % header_key
                  ... % image_dimension
                  'dim',imagedim, ...
                  ...%'vox_units','', ...
                  'datatype','double', ...
                  ...%'bitpix', , ...
                  'pixdim',single([roiTs.ds(1:2),roiTs.ds(3),roiTs.dx]), ...
                  'vox_offset',0, ...
                  'cal_max',max(imagedata(:)), ...
                  'cal_min',min(imagedata(:)), ...
                  'glmax',max(imagedata(:)), ...
                  'glmin',min(imagedata(:)), ...
                  ... % data_history
                  'orient',0 ...
                  ) ;

anzfile = fullfile(session.sysp.matdir,session.sysp.dirname,'statanz') ;
anz_write(anzfile,header,imagedata) ;
%anz_view(sprintf('%s.img',anzfile),'cmap','hot','anascale',[0.0 30.0 1.8]) ;
