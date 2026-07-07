function cdens = chargedensity(imp,cur,pdur)
%CHARGEDENSITY - Compute charge density from impedance and current values
% cdens = chargedensity(imp,cur,pdur)
% pdur - in seconds
% imp = KOhm
% cur = uAmps
%
% NKL 5.5.2006

if nargin < 3,
  pdur = 200;
end;

if nargin < 2,
  help chargedensity;
  return;
end;

imp = imp/1000;
t=pdur*10^-6;         % In seconds
I=cur*10^-6;          % In Amperes from MicroA

C = I .* (t/0.0003 * imp.^1.4);
C = C * 10^3 * 100;

if ~nargout,
  fprintf('Charge density: %5.2f mCoulomb/cm^2\n', C);
else
  cdens=C;
end;

