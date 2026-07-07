% Image quality metric selection aux function
% Input: cmetric : metric index
%        p       : p-norm value (Default 0.7)
% Output:
% psi            : metric function
% dpsi           : derivative of the metric function

function [psi, dpsi] = choose_metric(cmetric,p)

if nargin < 2
  p = 0.7;
end;

switch cmetric
  case 1                                                               % L2
    psi  = @(z) z.*conj(z);
    dpsi = @(z) 2*z;
  case 2                                                               % L1
    psi  = @(z) abs(z);
    dpsi = @(z) sign(z);
  case 3                                                       % complex L1
    ep = 1e-12;
    psi   = @(z) sqrt(z.*conj(z)+ep);
    dpsi  = @(z) z./psi(z);
  case 4                                                    % smooth p-norm
    ep = 1e-15;
    psi = @(z) sum( (z.*conj(z)+ep).^(p/2) );
    dpsi = @(z) (p*z).*(z.*conj(z)+ep).^(p/2-1);
  case 5                                                % entropy criterion
    % v = @(u) sqrt(u.*conj(u))/sqrt(u'*u);
    % psi = @(u) -v(u)'*log(v(u));
    % dpsi = @(u) -(v(u).*(1+log(v(u)))./conj(u) - sign(u).*v(u) * (v(u)'*(1 + log(v(u)))) / sqrt(u'*u));

    % following ones are ~x2 faster.
    psi  = @choose_metric5_psi;
    dpsi = @choose_metric5_dpsi;
  case 6
    ep = 1e-8;                                     % stabilisation constant
    
    v = @(u) sqrt(u.*conj(u)+ep^2)/sqrt(u'*u+ep^2);   % stabilised function
    psi = @(u) -v(u)'*log(v(u));             % stabilised entropy criterion
    s = @(u) -(1+log(v(u)));                             % derivative df/dv
    dpsi = @(u) u.*v(u).*s(u)./(u.*conj(u)+ep^2) - u*(v(u)'*s(u)) / (u'*u+ep^2);
  case 7                                                            % l1/l2
    ep = 1e-8;
    l2  = @(z) ep+sqrt(z'*z); dl2  = @(z) z./sqrt(z'*z);
    l1   = @(z) sum(sqrt(z.*conj(z)+ep)); dl1  = @(z) z./sqrt(z.*conj(z)+ep);
    
    psi   = @(z) l1(z)./l2(z); dpsi  = @(z) ( dl1(z).*l2(z) - l1(z).*dl2(z) )./(l2(z).^2);
  case 8                                                         % L0 approx
    psi  = @(z) (1/p^2)*z.*conj(z).*(abs(z)<=p) + (abs(z)>p);
    dpsi = @(z) (2/p^2)*z.*(abs(z)<=p);
  otherwise
    psi = 1;
    dpsi = 1;
end;
