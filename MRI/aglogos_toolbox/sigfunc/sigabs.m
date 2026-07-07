function Sig = sigabs(Sig)
%SIGABS - Full-Rectify signal abs(Sig)
% SIGABS(Sig) returns the absolute value of the Sig.dat
% NKL, 19.05.03

% DoUndo = 0;
% if isstruc(Sig),
%   DoUndo = 1;
%   Sig = {Sig};
% end;

% for N=1:length(Sig),
%   Sig{N}.dat = abs(Sig{N}.dat);
% end;

% if DoUndo,
%   Sig = Sig{1};
% end;



if iscell(Sig),
  for K = 1:numel(Sig),
    Sig{K} = sigabs(Sig{K});
  end
  return
end


Sig.dat = abs(Sig.dat);

return
