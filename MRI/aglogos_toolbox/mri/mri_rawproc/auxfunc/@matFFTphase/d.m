% Two and threedimensional (centered) Fourier transformation
% where the input can be subject to rigid body motion:
%    derivative
%
% (c) by Hannes Nickisch & Alexander Loktyushin, 
%                               MPI for Biological Cybernetics, 2011 February 02

function dAi = d(A,kind,i)

  if nargin<2, kind = 'none'; end                   % default kind of derivative
  if nargin<3                                         % default derivative index
    i = 0;
  else
    i = fix(i);
  end                             
  if strcmp(kind,'all')             % kind of derivative
    A.dkind = kind; else error('Select either none or all.')
  end
  A.di = i;               % which derivative, 0 means all of the respective kind
  dAi = A;                                                  % assign output
  
  