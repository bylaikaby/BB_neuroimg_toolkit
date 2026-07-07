function varargout = mcentroid(DAT,DS)
%MCENTROID - Computes centroid of tcImg.dat for detecting motion of the subject
%  XYZ = mcentroid(DAT) computes centroid of DAT.
%  XYZ = mcentroid(DAT,DS) does the same thing but takes into accout
%  of voxel size given as DS.
%
%  If DAT is (x,y,z), XYZ will be 3 elements.
%  If DAT is (x,y,z,t), XYZ will be XYZ(3,t)
%
%  DAT should be like (x,y,z,t).
%  DS  should be like [xres,yres,zres]
%
%  VERSION :
%    0.90 30.05.05 YM  pre-release.
%    0.91 03.06.05 YM  supports "DS" argument.
%
%  See also

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 2,   DS = [1 1 1];  end


NX = size(DAT,1);
NY = size(DAT,2);
NZ = size(DAT,3);

tmpX = reshape([1:NX],[NX,1,1]);
tmpX = repmat(tmpX,[1,NY,NZ]);

tmpY = reshape([1:NY],[1,NY,1]);
tmpY = repmat(tmpY,[NX,1,NZ]);

tmpZ = reshape([1:NZ],[1,1,NZ]);
tmpZ = repmat(tmpZ,[NX,NY,1]);


% to avoid memory problem, do it step by step.
for iT = 1:size(DAT,4),
  tmpdat = double(DAT(:,:,:,iT));
  sumXYZ = sum(tmpdat(:));
  XYZ(1,iT) = sum(tmpdat(:).*tmpX(:)) / sumXYZ * DS(1);
  XYZ(2,iT) = sum(tmpdat(:).*tmpY(:)) / sumXYZ * DS(2);
  XYZ(3,iT) = sum(tmpdat(:).*tmpZ(:)) / sumXYZ * DS(3);
  %XYZ(:,iT) = subGetCentroid(double(DAT(:,:,:,iT)));
end

if nargout,
  varargout{1} = XYZ;
  return;
else
  figure('Name',mfilename);
  tmpXYZ = XYZ;
  tmpXYZ(1,:) = XYZ(1,:) - XYZ(1,1);
  tmpXYZ(2,:) = XYZ(2,:) - XYZ(2,1);
  tmpXYZ(3,:) = XYZ(3,:) - XYZ(3,1);
  plot(tmpXYZ');
  legend('X','Y','Z');
  xlabel('Time in points');
  title('Centroid Time Course');
  if nargin > 1,
    ylabel('Shifts in mm');
  else
    ylabel('Shifts in voxsels');
  end
  grid on;
end



return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function XYZ = subGetCentroid(VOLDAT),

sumXYZ = sum(VOLDAT(:));


%tmpidx = zeros(size(VOLDAT));
if NY > 1,
  tmpidx = reshape([1:NX],[NX,1,1]);
  tmpidx = repmat(tmpidx,[1,NY,NZ]);
  %for N = 1:NX,
  %  tmpidx(N,:,:) = N;
  %end
  sumX = sum(VOLDAT(:).*tmpidx(:));
else
  sumX = sumXYZ;
end
  
if NY > 1,
  tmpidx = reshape([1:NY],[1,NY,1]);
  tmpidx = repmat(tmpidx,[NX,1,NZ]);
  %for N = 1:NY,
  %  tmpidx(:,N,:) = N;
  %end
  sumY = sum(VOLDAT(:).*tmpidx(:));
else
  sumY = sumXYZ;
end

if NZ > 1,
  tmpidx = reshape([1:NZ],[1,1,NZ]);
  tmpidx = repmat(tmpidx,[NX,NY,1]);
  %for N = 1:NZ,
  %  tmpidx(:,:,N) = N;
  %end
  sumZ = sum(VOLDAT(:).*tmpidx(:));
else
  sumZ = sumXYZ;
end

    
XYZ(1) = sumX / sumXYZ;
XYZ(2) = sumY / sumXYZ;
XYZ(3) = sumZ / sumXYZ;    
    
    
XYZ = CENT(:);
    
return;

