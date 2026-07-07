function dspfused(ai,fi,rthr,ARGS)
%DSPFUSED - Superimpose a functional map on the corresponding anatomical scan
% DSPFUSED(fi,ai,rthr) superimpose xcor on anatomy; if no rthr is defined all r values are
% shown on the anatomy scan.
%
% NKL 29.04.04
% YM  05.05.07 bug fix

if nargin < 3,
  rthr = 0;
end;

if nargin < 2,
  help dspfused;
  return;
end;

DEF.SWCLIP		= [0.1 0.9];
DEF.SWCOLORBAR	= 0;
DEF.SWGAMMA     = 0.7;
DEF.SWLUTSIZE	= 64;
DEF.SWLUTSCALE  = 1.1;

% ------------------------------------------
% IF ARGS EXIST..
% APPEND DEFAULTS ON THEM AND EVALUATE ALL
% ------------------------------------------
if exist('ARGS','var'),
  %ARGS = sctcat(ARGS,DEF);
  ARGS = sctmerge(DEF,ARGS);
else
  ARGS = DEF;
end;
pareval(ARGS);

if size(ai,1)~=size(fi,1) | size(ai,2)~=size(fi,2),
  fi = imresize(fi,size(ai),'nearest');
end

if ~isa(ai,'double'),  ai = double(ai);  end
if ~isa(fi,'double'),  fi = double(fi);  end

ai = imadjust(ai./max(ai(:)),SWCLIP, [0 1], SWGAMMA);	% clip/gamma-correct

if rthr,
  fi(find(abs(fi)<rthr)) = NaN;
end;

mx = max(abs(fi(:)));
if ~isnan(mx) & mx,
  fi = fi ./ mx;
  fs = fi;							% anatomy+function
else
  fs = ai;
end;


if 1,
  fLUT = SWLUTSIZE;
  aLUT = 2 * fLUT;
  
  anamap = gray(aLUT);
  posmap = hot(fLUT);
  negmap = zeros(fLUT,3);
  negmap(:,3) = [1:fLUT]'/fLUT;
  negmap(:,2) = flipud(brighten(negmap(:,3),-0.5));
  negmap(:,3) = brighten(negmap(:,3),0.5);
  negmap = flipud(negmap);
  
  cmap = [anamap; negmap; posmap];
  
  % anatomy must be [1:aLUT]
  ai = round(ai * (aLUT-1) + 1);  % [0 1] --> [1 aLUT]
  ai(find(ai(:) > aLUT)) = aLUT;
  ai(find(ai(:) < 1))    = 1;

  % functional should be [1:2*fLUT]+aLUT
  fi = fi/2 + 0.5;  % [-1 1] --> [0 1]
  fi = round(fi * (2*fLUT-1) + 1 + aLUT);  % [0 1] --> [1 2*fLUT]+aLUT
  fi(find(fi(:) > 2*fLUT+aLUT)) = 2*fLUT + aLUT;
  fi(find(fi(:) < 1+aLUT))      = 1+aLUT;

  % fuse anatomy and fuctional images
  fs  = fi;
  idx = find(isnan(fs));
  fs(idx) = ai(idx);
  subimage(fs',cmap);

else
  minfs = abs(min(fs(:)));			% to clip the blue LUT
  maxfs = max(fs(:));					% to clip the hot LUT

  % Lookup table size
  fLUT = SWLUTSIZE;
  aLUT = 2 * fLUT;

  tmphot = hot(fLUT);
  bmap = zeros(fLUT,3);
  bmap(:,3) = [1:fLUT]'/fLUT;
  bmap(:,2) = flipud(brighten(bmap(:,3),-0.5));
  bmap(:,3) = brighten(bmap(:,3),0.5);
  bmap = flipud(bmap);
  cmap=[gray(aLUT); bmap(1:round(fLUT*minfs),:); tmphot(1:round(fLUT*maxfs),:)];


  fs = fs + 1;						% [-1 1] -> [0 2]
  fs = (fs./2) + 1;					% [0 2] -> [1 2] (separate LUTs)
  idx = find(isnan(fs));				% all insignif. are NaN
  fs(idx) = ai(idx);					% all insignif. function = anatomy
  subimage(round((size(cmap,1)-1)*(fs'/(SWLUTSCALE*max(fs(:))))),cmap);
end


if SWCOLORBAR, colorbar; end;
%%daspect([1 1 1]);
axis off;




