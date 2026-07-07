function [CSD CSD_ELEPOS] = icsd_delta(DAT,ELE_POS,varargin)
%ICSD_DELTA - Compute delta-source iCSD.
%  CSD = ICSD_DELTA(DATA,...) computes delta-source iCSD.
%  The CSD is assumed to have cylindical symmetry and to be localized in 
%  infinitely thin sheets with homogenous activity throuout the sheet (
%  in other words, infinitely thin disk of the given activity diameter).
%
%  NOTE :
%    1. "DATA" must be a matrix of (TIME,CHANNEL)
%    2. "ELE_POS" as electrode positions in mm
%    3. "CSD" as (TIME,CHANNEL) in A/m^3 or nA/mm^3
%
%  Supported options are :
%    'Cond_Cortex'  : conductivity in the cortex [S/m], default as 0.3
%    'Cond_Outside' : conductivity outside [S/m], default as 0.3
%    'ActivityDiameter' : activity diameter [mm], default as 0.5
%
%  REFERENCE :
%    Pettersen et al., J. Neuroscience Methods, 2006. 154(1-2): p116-33.
%
%  VERSION :
%    0.90 16.02.11 YM  pre-release
%
%  See also CSD_STANDARD


% OPTIONS
COND_CORTEX       = 0.3;   % [S/m]
COND_OUTSIDE      = 0.3;   % [S/m]    
ACT_DIAMETER      = 0.5;   % [mm]
SP_FILTER         = 1;

for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'cond','condcortex','cond_cortex'}
    COND_CORTEX = varargin{N+1};
   case {'condout','condoutside','cond_out','cond_outside'}
    COND_OUTSIDE = varargin{N+1};
   case {'sp_filter','spfilter','spf'}
    SP_FILTER = varargin{N+1};
  end
end

% TEST MODE...
if ischar(DAT) && strcmpi(DAT,'test'),
  TEST_MODE = 1;
  DAT = rand(1000,10)*1.0e-3*0.5;
  ELE_POS = 0.1:0.1:1;
else
  TEST_MODE = 0;
end

% check electrode positions
if any(diff(ELE_POS) <= 0),
  error(' ERROR %s: "ELE_POS" must be in ascending order.\n',mfilename);
end


ELE_POS      = ELE_POS * 1.0e-3;       % [m]
ACT_DIAMETER = ACT_DIAMETER * 1.0e-3;  % [m]


Fmat = sub_fdelta(ELE_POS,ACT_DIAMETER,COND_CORTEX,COND_OUTSIDE);
%Fmat(1)
%save('d:/temp/Fmat0.mat','Fmat');

CSD = DAT * (Fmat^-1);  % in [A/m^3] or [nA/mm^3]


if any(SP_FILTER),
  NEWCSD = zeros(size(CSD,1),size(CSD,2)+2);
  NEWCSD(:,1)   = CSD(:,1);
  NEWCSD(:,2:end-1) = CSD;
  NEWCSD(:,end) = CSD(:,end);
  CSD = NEWCSD;
  clear NEWCSD;
  Smat = sub_spfmat(size(CSD,2),0.54,0.23);
  CSD = CSD * Smat;
end


if any(TEST_MODE)
  F2   = F_delta(ELE_POS,ACT_DIAMETER,COND_CORTEX,COND_OUTSIDE);
  CSD2 = F2^-1*DAT';
  CSD2 = CSD2';
  if any(SP_FILTER),
    NEWCSD = zeros(size(CSD2,1),size(CSD2,2)+2);
    NEWCSD(:,1)   = CSD2(:,1);
    NEWCSD(:,2:end-1) = CSD2;
    NEWCSD(:,end) = CSD2(:,end);
    CSD2 = NEWCSD;
    clear NEWCSD;
    CSD2 = CSD2 * Smat;
  end
  figure;
  plot([CSD(:,3) CSD2(:,3) CSD(:,3)-CSD2(:,3)]);
  legend('this','orig','diff')
  keyboard
end


return




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Fmat = sub_fdelta(ELE_POS,d,cond,cond0)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NEle = length(ELE_POS);
Fmat = zeros(NEle,NEle);

r = d/2;
%h = abs(ELE_POS(2)-ELE_POS(1));
h = min(abs(diff(ELE_POS)));

for C = 1:NEle,
  zc = ELE_POS(C);    % zc as position of CSD space
  for E = 1:NEle,
    ze = ELE_POS(E);  % ze as position of electrode
    
    tmpv1 = sqrt((zc-ze)^2 + r^2) - abs(zc-ze);
    tmpv2 = sqrt((zc+ze)^2 + r^2) - abs(zc+ze);
    
    Fmat(C,E) = h / (2*cond) * (tmpv1 + (cond-cond0)/(cond+cond0)*tmpv2);
  end
end

%cond, cond0, d, h

Fmat = Fmat';

return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Smat = sub_spfmat(NEle,b0,b1)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Smat = zeros(NEle,NEle-2);

c = b0 + 2*b1;
b0 = b0/c;
b1 = b1/c;

for C = 2:NEle-1,
  Smat(C-1,C-1) =  b1;
  Smat(C,  C-1) =  b0;
  Smat(C+1,C-1) =  b1;
end

return
