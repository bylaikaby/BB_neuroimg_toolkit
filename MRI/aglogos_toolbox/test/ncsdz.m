function [CSD CSD_POS] = ncsdz(LFP,ELE_POS,METHOD,varargin)
%NCSDZ - Compute current-source density in depth from LFP.
%  [CSD CSD_POS] = NCSDZ(LFP,ELE_POS,METHOD,...) computes current-source density 
%  in depth from the given LFP/ELE_POS.
%  Note that 
%    1. "LFP" must be a matrix of (TIME,CHANNEL) in [V]
%    2. "ELE_POS" as electrode positions in [mm]
%    3. "CSD" as (TIME,CHANNEL) in [A/m^3] or [nA/mm^3], +/- as source/sink.
%
%  "METHOD" can be 'standard', 'delta-icsd', 'step-icsd'.
%
%  1. 'standard' : classical CSD
%    The standard CSD is the 2nd order spatial derivative of LFP.
%    "ELE_POS" must be iso-distance.
%
%    Supported options for 'standard' csd are :
%      'Vaknin'       : 0|1, Vaknin correction (Vaknin, DiScenna and Teyler 1988)
%      'Cond_Cortex'  : conductivity in the cortex [S/m], default as 0.3
%      'Spf'          : 0|1, apply 3point spatial filtering to CSD.
%
%  2. 'delta-icsd' : delta-source iCSD.
%    The delta-iCSD is assumed to have cylindical symmetry and to be localized in 
%    infinitely thin sheets with homogenous activity throuout the sheet (in other
%    words, infinitely thin disk of the given activity diameter).
%    Supported options for 'delta-icsd' are :
%      'Cond_Cortex'  : conductivity in the cortex [S/m], default as 0.3
%      'Cond_Outside' : conductivity outside [S/m], default as 0.3
%      'ActivityDiameter' : activity diameter [mm], default as 0.5
%      'Spf'          : 0|1, apply 3point spatial filtering to CSD.
%
%  3. 'step-icsd' : step iCSD.
%    Supported options for 'step-icsd' are :
%      'Cond_Cortex'  : conductivity in the cortex [S/m], default as 0.3
%      'Cond_Outside' : conductivity outside [S/m], default as 0.3
%      'ActivityDiameter' : activity diameter [mm], default as 0.5
%      'Spf'          : 0|1, apply 3point spatial filtering to CSD.
%
%  NOTES :
%    - Slightly better results when CSD from averaged LFP, rather than averaged CSD from raw LFP.
%    - When 3points-filter is applied, it may shift ridge/trough far.
%
%  EXAMPLE :
%    >> ncsdz('test',[],'standard')
%    >> ncsdz('test',[],'delta-icsd')
%
%  REFERENCE :
%    1. Nicholson and Freeman, 1975, J. Neurophysiology, 38(2):356-68.
%    2. Mitzdorf, 1985, Physiol Rev, 65(1):37-100.
%    3. Vaknin, DiScenna and Teyler, 1988, J. Neuroscience Methods, 24(2):131-5.
%    4. Pettersen et al., 2006, J. Neuroscience Methods, 154(1-2):116-33.
%
%  VERSION :
%    0.90 17.02.11 YM  pre-release, packed codes.
%
%  See also CSDplotter(by Pettersen)

if nargin < 3,  eval(['help ' mfilename]);  return;  end


% OPTIONS : common
COND_CORTEX       = 0.3;   % conductiviy in the cortex [S/m]
SPF_APPLY         = 1;     % apply 3point spatial filter to CSD
SPF_B0            = 0.54;  % 3point filter: center coef.
SPF_B1            = 0.23;  % 3point filter: neighboring coef.

% OPTIONS : standard
VAKNIN_CORRECTION = 1;     % extrapolates the first/last.

% OPTIONS : delta-icsd
COND_OUTSIDE      = 0.3;   % conductivity ourside brain[S/m]    
ACT_DIAMETER      = 0.5;   % activity diameter [mm]


% SET OPTIONS
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'cond','condcortex','cond_cortex'}
    COND_CORTEX = varargin{N+1};
   case {'condout','condoutside','cond_out','cond_outside'}
    COND_OUTSIDE = varargin{N+1};
   case {'spf','sp_filter','spfilter'}
    SPF_APPLY = varargin{N+1};
   case {'vaknin'}
    VAKNIN_CORRECTION = varargin{N+1};
   case {'activitydiameter' 'd' 'actdiameter'}
    ACT_DIAMETER = varargin{N+1};
  end
end

% TEST MODE...
if ischar(LFP) && strcmpi(LFP,'test'),
  TEST_MODE = 1;
  LFP = rand(1000,10)*1.0e-3*0.5;
  ELE_POS = 0.1:0.1:1;
else
  TEST_MODE = 0;
end


% check dimensional size
if size(LFP,2) ~= length(ELE_POS),
  error(' ERROR %s: length(ELE_POS)=%d must be the same as size(LFP,2)=2.\n',mfilename,length(ELE_POS),size(LFP,2));
end

% check electrode positions
if any(diff(ELE_POS) <= 0),
  error(' ERROR %s: "ELE_POS" must be in ascending order.\n',mfilename);
end


ELE_POS      = ELE_POS * 1.0e-3;       % [m]
ACT_DIAMETER = ACT_DIAMETER * 1.0e-3;  % [m]


switch lower(METHOD),
 case {'standard' 'std' 'normal' 'classic' 'csd'}
  % check electrode positons
  if length(unique(round(diff(ELE_POS)*1000)/1000)) > 1,
    error(' ERROR %s: "ELE_POS" must be iso-distance for ''%s''.\n',mfilename,METHOD);
  end
  % Vaknin correction extrapolates the first/last channels
  if any(VAKNIN_CORRECTION),
    [LFP ELE_POS] = sub_vaknin(LFP,ELE_POS);
  end
  CSD_POS = ELE_POS(2:end-1);
  Dmat = sub_dmat(ELE_POS);
  CSD = -COND_CORTEX * LFP * Dmat;  % [A/m^3] or [nA/mm^3]
  
 case {'delta-icsd' 'deltaicsd' 'dicsd'}
  CSD_POS = ELE_POS;
  Fmat = sub_fdelta(ELE_POS,ACT_DIAMETER,COND_CORTEX,COND_OUTSIDE);
  %Fmat(1)
  %save('d:/temp/FmatNew.mat','Fmat');
  CSD = LFP * (Fmat^-1);            % [A/m^3] or [nA/mm^3]

 case {'step-icsd' 'stepicsd'}
  CSD_POS = ELE_POS;
  Fmat = sub_fconst(ELE_POS,ACT_DIAMETER,COND_CORTEX,COND_OUTSIDE,1.0e-6);
  CSD = LFP * (Fmat^-1);            % [A/m^3] or [nA/mm^3]
  
  
 otherwise
  error(' ERROR %s: unsupported METHOD(%s), must be ''standard'' or ''delta-icsd''.\n',mfilename,METHOD);
end


if any(SPF_APPLY),
  CSD  = sub_vaknin(CSD,[]);
  Smat = sub_spfmat(size(CSD,2),SPF_B0,SPF_B1);
  CSD  = CSD * Smat;
end



if exist('TEST_MODE','var') && any(TEST_MODE),
  % use Pettersen's method to verify.
  switch lower(METHOD),
   case {'standard' 'std' 'normal' 'classic' 'csd'}
    Dmat2 = D1(size(LFP,2),nanmean(abs(diff(ELE_POS))));
    CSD2 = -COND_CORTEX * Dmat2 * LFP';
    CSD2 = CSD2';
   case {'delta-icsd' 'deltaicsd' 'dicsd'}
    F2   = F_delta(ELE_POS,ACT_DIAMETER,COND_CORTEX,COND_OUTSIDE);
    CSD2 = F2^-1*LFP';
    CSD2 = CSD2';
   case {'step-icsd' 'stepicsd'}
    F2 = sub_fconst(ELE_POS,ACT_DIAMETER,COND_CORTEX,COND_OUTSIDE,1.0e-6);
    CSD2 = F2^-1*LFP';
    CSD2 = CSD2';
  end
  if any(SPF_APPLY),
    CSD2  = sub_vaknin(CSD2,[]);
    CSD2  = CSD2 * Smat;
  end
  figure;
  iCh = 3;
  plot([CSD(:,iCh) CSD2(:,iCh) CSD(:,iCh)-CSD2(:,iCh)]);
  legend('this','Pettersen','diff');
  title(strrep(sprintf('%s(%s) TEST iCh=%d',mfilename,METHOD,iCh),'_','\_'));
  grid on;
  xlabel('Time in points');
  ylabel('CSD');
end


return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [NEWLFP NEWPOS] = sub_vaknin(LFP,ELE_POS)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Vaknin correction extrapolates first/last channels
NEWLFP = zeros(size(LFP,1),size(LFP,2)+2);
NEWLFP(:,1)       = LFP(:,1);
NEWLFP(:,2:end-1) = LFP;
NEWLFP(:,end)     = LFP(:,end);

if nargout == 1,  return;  end

h = nanmean(diff(ELE_POS));
NEWPOS = [ELE_POS(1)-h  ELE_POS(:)'  ELE_POS(end)+h];

return



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Dmat = sub_dmat(ELE_POS)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NEle = length(ELE_POS);
%h = abs(ELE_POS(2)-ELE_POS(1));
%h = min(abs(diff(ELE_POS)));
h = nanmean(abs(diff(ELE_POS)));

Dmat = zeros(NEle,NEle-2);

for C = 2:NEle-1,
  Dmat(C-1,C-1) =  1;
  Dmat(C,  C-1) = -2;
  Dmat(C+1,C-1) =  1;
end

Dmat = Dmat / h^2;

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
function Fmat = sub_fconst(ELE_POS,d,cond,cond0,tol)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NEle = length(ELE_POS);
Fmat = zeros(NEle,NEle);

r = d/2;
%h = abs(ELE_POS(2)-ELE_POS(1));
h = min(abs(diff(ELE_POS)));

for E = 1:NEle,
  ze = ELE_POS(E);    % ze as position of electrode
  for C = 1:NEle,
    %zc = ELE_POS(C);  % zc as position of CSD plane
    if C == 1,
      a = max(0,ELE_POS(C)-h/2);
    else
      a = ELE_POS(C) - (ELE_POS(C)-ELE_POS(C-1))/2;
    end
    if C == NEle,
      b = ELE_POS(C) + h/2;
    else
      b = ELE_POS(C) + (ELE_POS(C+1)-ELE_POS(C))/2;
    end
    
    tmpv1 = quad(@sub_cylinder, a, b, tol, [],  ze, r, cond);
    tmpv2 = quad(@sub_cylinder, a, b, tol, [], -ze, r, cond);
    
    Fmat(E,C) = tmpv1 + (cond-cond0)/(cond+cond0)*tmpv2;
  end
end

Fmat = Fmat';

return
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function V = sub_cylinder(zeta,z,r,cond)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
V = 1./(2.*cond).*(sqrt(r^2+((z-zeta)).^2)-abs(z-zeta));
return


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Smat = sub_spfmat(NEle,b0,b1)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2,  b0 = 0.54;  end
if nargin < 3,  b1 = 0.23;  end

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
