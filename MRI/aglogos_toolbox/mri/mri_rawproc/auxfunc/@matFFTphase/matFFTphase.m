% Translation only motion
%
% A = matFFTphase(sz,phase_add,complex,type)
%
%
% (c) Alexander Loktyushin,     MPI for Biological Cybernetics, 2012

function A = matFFTphase(sz, phase_add, complex, isfft)

  %% general info
  A.ndims = numel(sz);                            % Are we doing 2d or 3d stuff?
  if A.ndims<2 || A.ndims>3, error('We support only 2d and 3d.'), end
  A.imsz = sz; sz = prod(A.imsz)*[1,1];
  if nargin<3, complex = 1; end, if numel(complex)==0, complex = 1; end
  if numel(complex)==1, complex = complex*[1,1]; end
  center = ceil((A.imsz-1)/2)+1; A.center = center;          % center in k-space
    
  %% derivatives
  A.dkind = 'none';                    % kind of derivative, either rot or trans
  A.di = 0;               % which derivative, 0 means all of the respective kind

  %% translation
  % The outcome of the computations below is
  %  1) a vector A.t implementing the translation;
  %  2) a set of vectors A.dt needed for the translation derivatives;
  %  3) a vector A.tc needed to correct for the rotation that is not exactly
  %     done around the center.

  A.phase_add = phase_add(:);
  
  if length(phase_add(:)) == A.imsz(2)*2
    if numel(A.phase_add)>A.ndims
      A.phase_add = reshape(A.phase_add,[2,A.imsz(2:end)]);
    end
    [A.t,A.dt] = phase_corr_diag(A.imsz,A.phase_add);
  elseif length(phase_add(:)) == prod(A.imsz)
    A.phase_add = reshape(A.phase_add,A.imsz);
    [A.t,A.dt] = phase_diag_full(A.imsz,A.phase_add);
  else
    if numel(A.phase_add)>A.ndims
      A.phase_add = reshape(A.phase_add,[1,A.imsz(2:end)]);
    end
    [A.t,A.dt] = phase_diag(A.imsz,A.phase_add);
  end;
 
  if isfft
    A.F = matFFTN(A.imsz); 
  else
    A.F = 1; 
  end;
  
  %% construct matrix class, inherit from mat
  A = class(A,mfilename,mat(sz,complex));


% Compute diagonal phase equivalent in Fourier space
function [t,dt] = phase_diag(sz,tr)
  ndims = numel(sz);

  for d=1:ndims-1
    t = repmat(exp(1i*tr),[sz(1) 1 1]);
    dt = t.*1i;
  end;
  
function [t,dt] = phase_diag_full(sz,tr)
  t = exp(1i*tr);
  dt = t.*1i;  
  
% Compute diagonal translation equivalent in Fourier space
function [t,dt] = phase_corr_diag(sz,tr)
  ndims = numel(sz); N = prod(sz);      % number of dimensions, number of pixels
  %t = ones(sz); dt = ones(N,ndims);
  
  dt = ones(N,2);
  t = repmat(exp(1i*tr(1,:)),[sz(1) 1 1]);
  %dt(:,1) = t(:).*1i;
  
  d = 1;
  
  rp = ((1:sz(d))-fix(1+sz(d)/2))/sz(d);    % ramp in direction of dimension d
  rp = -2i*pi*reshape(rp,[ones(1,d-1),sz(d),ones(1,ndims-d)]);
  erp = exp(bsxfun(@times,rp,tr(2,:,:)));           % tr is singleton in dim 1
  t = bsxfun(@times, t, erp);
  
  dt(:,1) = t(:)*1i;
  dtdd = bsxfun(@times, t, rp);
  dt(:,2) = dtdd(:);
  
  %{
  for dd=1:2
    dtdd = bsxfun(@times, reshape(dt(:,dd),sz), erp);
    if dd==1
      dtdd = bsxfun(@times, dtdd, rp);
    end
    dt(:,dd) = reshape(dtdd,N,1);
  end
  %}

