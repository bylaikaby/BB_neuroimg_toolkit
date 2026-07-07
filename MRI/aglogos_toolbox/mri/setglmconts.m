function glmconts = setglmconts(TYPE,NAME,CONTMATRIX,varargin)
%SETGLMCONTS Sets glmconts structure in the description file.
%  GLMCONTS = SETGLMCONTS(TYPE,NAME,CONTMATRIX,varargin) sets glmconts structure
%  in the description file.
%
%  glmconts = setglmconts('f','General Effects',3) gives
%
%   glmconts.type             = 'f';
%   glmconts.name             = 'General Effects';
%   glmconts.contrastmatrix   = [3x3 double];
%   glmconts.pVal             = 5e-06;
%   glmconts.WhichDesign      = 1;
%   glmconts.SaveThisContrast = 1;
%
%  VERSION :
%    0.90 11.01.06 YM  pre-release
%
%  See also EVALUATECONTRASTS, EXPGLMANA, SESGLMANA

if nargin < 3,  eval(sprintf('help %s;',mfilename)); return;  end

if ~isempty(CONTMATRIX) && numel(CONTMATRIX) == 1,
  % CONTMATRIX is given as a number of dimensions
  N = CONTMATRIX;
  CONTMATRIX = eye(N);  CONTMATRIX(N,N) = 0;
end


% DEFAULT VALUES FOR glmconts structure %%%%%%%%%%%%%%%%%%%%%%%%%%%
glmconts.type             = TYPE;
glmconts.name             = NAME;
glmconts.contrastmatrix   = CONTMATRIX;
glmconts.pVal             = 0.05;
glmconts.WhichDesign      = 1;
glmconts.SaveThisContrast = 1;


N = 1;
while N < length(varargin),
  tmpname   = varargin{N};
  tmpvalue  = varargin{N+1};
  glmconts.(tmpname) = tmpvalue;
  N = N + 2;
end


return;
