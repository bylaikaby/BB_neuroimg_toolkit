function [CSD CSD_ELEPOS] = csd_standard(DAT,ELE_POS,varargin)
%CSD_STANDARD - Compute CSD by the classical method.
%  CSD = CSD_STANDARD(DATA,...) computes CSD by the classical method.
%  The CSD is the 2nd order spatial derivative.
%
%  NOTE :
%    1. "DATA" must be a matrix of (TIME,CHANNEL)
%    2. "ELE_POS" as electrode positions in mm
%    3. "CSD" as (TIME,CHANNEL) in A/m^3 or nA/mm^3
%
%  Supported options are :
%    'Vaknin'       : 0|1, Vaknin correction (Vaknin, DiScenna and Teyler 1988)
%    'Cond_Cortex'  : conductivity in the cortex [S/m], default as 0.3
%
%  REFERENCE :
%    Nicholson and Freeman, J. Neurophysiology, 1975. 38(2):356-68.
%    Mitzdorf, Physiol Rev, 1985. 65(1):37-100.
%    Pettersen et al., J. Neuroscience Methods, 2006. 154(1-2):116-33.
%
%  VERSION :
%    0.90 16.02.11 YM  pre-release
%
%  See also ICSD_DELTA


% OPTIONS
VAKNIN_CORRECTION = 1;
COND_CORTEX       = 0.3;   % [S/m]
SP_FILTER         = 1;


for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'vaknin'}
    VAKNIN_CORRECTION = varargin{N+1};
   case {'cond','condcortex','cond_cortex','condactivity'}
    COND_CORTEX = varargin{N+1};
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
if length(unique(round(diff(ELE_POS)*1000)/1000)) > 1,
  error(' ERROR %s: "ELE_POS" must be iso-distance.\n',mfilename);
end



if any(VAKNIN_CORRECTION),
  % extrapolate first/last channels
  NEWDAT = zeros(size(DAT,1),size(DAT,2)+2);
  NEWDAT(:,1)   = DAT(:,1);
  NEWDAT(:,2:end-1) = DAT;
  NEWDAT(:,end) = DAT(:,end);
  DAT = NEWDAT;
  clear NEWDAT;
  h = nanmean(diff(ELE_POS));
  ELE_POS = [ELE_POS(1)-h  ELE_POS(:)'  ELE_POS(end)+h];
end

CSD_ELEPOS = ELE_POS(2:end-1);


ELE_POS      = ELE_POS * 1.0e-3;       % [m]


Dmat = sub_dmat(ELE_POS);

CSD = -COND_CORTEX * DAT * Dmat;  % in [A/m^3] or [nA/mm^3]

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
  Dmat2 = D1(size(DAT,2),nanmean(abs(diff(ELE_POS))));
  CSD2 = -COND_CORTEX * Dmat2 * DAT';
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
