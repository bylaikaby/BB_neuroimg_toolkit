% Two and threedimensional (centered) Fourier transformation
% where the input can be subject to rigid body motion:
%    matrix vector multiplication
%
% (c) by Alexander Loktyushin, MPI for Biological Cybernetics, 2011 February 19

function y = mvm(A,x,ctransp)

  t = A.t(:);                                                 % translation
  if strcmp(A.dkind,'none')
    if ctransp                                % translation after after rotation
      y = A.F'*(conj(t).*x(:));
    else
      y = t.*(A.F*x(:));
    end
    if A.ndims == 3
      y = y/sqrt(2);
    end;
  elseif strcmp(A.dkind,'all')
    if ctransp
      y = conj(A.dt) .* (x(:)*ones(1,2));
      for dd=1:2
        y(:,dd) = A.F'*y(:,dd); 
      end
    else        
      if A.ndims == 3
        y = zeros(prod(A.imsz),2);
        y(:,1) = A.F*x(:);
        y(:,2) = A.dt(:).*y(:,1);
        y(:,1) = t.*y(:,1);
        y = y/sqrt(2);
      else
        if size(A.phase_add,1) == 2
          y = zeros(prod(A.imsz),3);
          y(:,1) = A.F*x(:);
          y(:,2) = A.dt(:,1).*y(:,1);
          y(:,3) = A.dt(:,2).*y(:,1);
          y(:,1) = t.*y(:,1);          
        else
          y = zeros(prod(A.imsz),2);
          y(:,1) = A.F*x(:);
          y(:,2) = A.dt(:).*y(:,1);
          y(:,1) = t.*y(:,1);
        end;
      end;
    end;
  else
    error('Transpose of rot derivative is not implemented.');
  end