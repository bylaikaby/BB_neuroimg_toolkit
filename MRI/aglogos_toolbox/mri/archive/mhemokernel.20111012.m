function varargout = mhemokernel(Model,IRTDX,TLEN_SEC,varargin)
%MHEMOKERNEL - Returns the hemo dynamic response kernel as a signal structure
%  HEMO = MHEMOKERNEL(MODEL) returns hemo dynamic response kernel of 'MODEL'.
%  MHEMOKERNEL(MODEL) simply plots HDR kernel of 'MODEL'.
%
%  MODEL == 'gampdf'   : gampdf(t,10,0.4089)  Tmax=3.68sec
%  MODEL == 'fgampdf'  : gampdf(t,10,0.278)   Tmax=1.84sec
%  MODEL == 'vfgampdf' : gampdf(t,10,0.111)   Tmax=1.00sec
%  MODEL == 'ir'       : irmodel([0.4956 2.7456 3.3245 1.5615 31.8288 -0.0184], t)
%  MODEL == 'Cohen'    : t^8.6*exp(-t/0.547) MS.Cohen, Neuroimage(6),93-103 (1997)
%  MODEL == 'spm'      : spm_hrf(DT, [6 16 1 1 6 0 TLEN_SEC])
%  MODEL == 'spmnkl'   : spm_hrf(DT, [5 12 1 1 6 0 TLEN_SEC])
%  MODEL == 'opt'      : gampdf(t,10,0.0011)  Tmax=0.01sec
%
%  VERSION :
%    0.90 05.01.06 YM  moved contents from expgetstm.
%    0.91 23.03.06 YM  adds "Cohen" hemo dynamic response.
%    0.92 17.10.07 YM  adds "vfgampdf" as very-fast-gampdf
%    0.93 10.09.10 YM  adds "spm", "spmnkl"
%    0.94 22.06.11 YM  adds "opt" (tentative).
%
%  See also EXPGETSTM EXPMKMODEL

if nargin == 0,  help mhemokernel; return;  end


if ~exist('IRTDX','var') || isempty(IRTDX),
  IRTDX = 0.01;
end
if ~exist('TLEN_SEC','var') || isempty(TLEN_SEC),
  TLEN_SEC = 25;
end


IRTLEN = round(TLEN_SEC/IRTDX);   % 25 sec duration as default
IRT = (0:IRTLEN-1) * IRTDX;		% see impresp.mat/supir.t
switch lower(Model),
 case {'gampdf','hemo'}
  %%%%%%%%%%%%% ??????????????????????
%  1. Multiple gamma-functions may be needed for regressors
%  2. The undershoot is screwing things up!??? Something todo
%  3. The data still look not convincing
  
  % Lamda=10/Theta=0.4089 gives Tmax of 3.68s
  
  Lamda = 10;
  Theta = 0.4089;
  IR = gampdf(IRT,Lamda,Theta);
  info.func  = 'gampdf';
  info.lamda = Lamda;
  info.theta = Theta;
 
 case {'fgampdf','fhemo'}
  % Lamda/Theta values are arbitrary.
  % Lamda=10/Theta=0.204 gives Tmax of 1.84s (half of "gampdf")
  % Lamda=10/Theta=0.278 gives Tmax of 2.50s
  Lamda = 10;
  Theta = 0.278;
  IR = gampdf(IRT,Lamda,Theta);
  info.func  = 'gampdf';
  info.lamda = Lamda;
  info.theta = Theta;
  
 case {'hipp'},
  % Lamda/Theta values are arbitrary.
  % Lamda=10/Theta=0.204 gives Tmax of 1.84s (half of "gampdf")
  % Lamda=10/Theta=0.278 gives Tmax of 2.50s
  Lamda = 8;
  Theta = 0.342;
  IR = gampdf(IRT,Lamda,Theta);
  info.func  = 'gampdf';
  info.lamda = Lamda;
  info.theta = Theta;
  
 case {'opt'}
  % Lamda=10/Theta=0.011  gives Tmax of 0.1s
  % Lamda=10/Theta=0.0011 gives Tmax of 0.01s
  Lamda = 10;
  Theta = 0.0011;
  IR = gampdf(IRT,Lamda,Theta);
  info.func  = 'gampdf';
  info.lamda = Lamda;
  info.theta = Theta;
  
 
 case {'ir','irmodel'}
  PAR = [0.4956 2.7456 3.3245 1.5615 31.8288 -0.0184];
  IR = irmodel(PAR,IRT);
  info.func  = 'irmodel';
  info.par   = PAR;
 
 case {'cohen'}
  b = 8.6;  c = 0.547;
  IR = (IRT.^b).*exp(-IRT/c);
  info.func = 't^b*exp(-t/c)';
  info.b = b;
  info.c = c;
  
 case {'vfgampdf','vfhemo','veryfasthemo'}
  % Lamda=10/Theta=0.111 gives Tmax of 1.00s
  % Lamda=10/Theta=0.204 gives Tmax of 1.84s (half of "gampdf")
  % Lamda=10/Theta=0.278 gives Tmax of 2.50s
  Lamda = 10;
  Theta = 0.111;
  IR = gampdf(IRT,Lamda,Theta);
  info.func  = 'gampdf';
  info.lamda = Lamda;
  info.theta = Theta;
 
 case { 'spm', 'spmhrf' }
  PAR = [6 16 1 1 6 0 IRT(end)];  % spm defaults, see spm_hrf()
  IR  = spm_hrf(IRTDX, PAR);
  info.func = 'spm_hrf';
  info.par  = PAR;
  
 case { 'spmnkl' }
  PAR = [5 12 1 1 6 0 IRT(end)];  % copied from expmkmodel() for 'spmhrf'
  IR  = spm_hrf(IRTDX, PAR);
  info.func = 'spm_hrf';
  info.par  = PAR;
  
 otherwise
  error('%s ERROR: not supported mode=%s.\n',mfilename,Model);
end

% create signal structure
HEMO.name = Model;
HEMO.dx   = IRTDX;
HEMO.dat  = IR(:);
HEMO.info = info;

% normalize .dat so that sum(HEMO.dat) = 1;
HEMO.dat = HEMO.dat / sum(HEMO.dat);


if nargout > 0,
  varargout{1} = HEMO;
else
%  figure('Name',sprintf('%s: %s',datestr(now),mfilename));
  T = (0:length(HEMO.dat)-1)*HEMO.dx;
  plot(T, HEMO.dat);
  grid on;
  xlabel('Time in sec');  ylabel('Amplitude');
  title(sprintf('%s: MODE=%s DX=%gs TLEN=%gs',mfilename,Model,IRTDX,TLEN_SEC));
  set(gca,'xlim',[0 max(T)]);
  [maxv maxi] = max(HEMO.dat);
  hold on;
  tmpt = T(maxi);
  tmph = line([tmpt tmpt],get(gca,'ylim'),'color',[0.7 0.7 0]);
  set(tmph,'HandleVisibility','off');
  text(tmpt,maxv,sprintf('max=%.3fsec/%s',tmpt,Model));
end

return;

