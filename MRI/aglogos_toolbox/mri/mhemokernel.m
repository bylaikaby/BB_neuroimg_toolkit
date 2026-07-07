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

if verLessThan('matlab','7.10'),
  % stop warning of gampdf(0)
  warning('off','MATLAB:log:logOfZero');
end

IRTLEN = round(TLEN_SEC/IRTDX);   % 25 sec duration as default
IRT = (0:IRTLEN-1) * IRTDX;		% see impresp.mat/supir.t
switch lower(Model),
 case {'hipp'},
  % PARS were estimated in the program RPHRF (call rphrf('rat');)
  % RIPPLE: pars = [4.7235    0.5551    0.2873    0.7716    0.5950    0.1579];  
  % MUA: 3.1664    1.0889    0.0912    0.4472    0.2858   -0.0007  
  pars = [3.1664    1.0889    0.0912    0.4472    0.2858   -0.0007];
  t = IRT;
  IR = gampdf(t,pars(1),pars(2))-pars(3)*exp(-((t-(t(end)*pars(4)))/(t(end)*pars(5))).^2)+pars(6);
  info.func  = 'gampdf-hipp';
  info.pars = pars;
  
 case {'mnkhipp'},
  % PARS were estimated in the program RPHRF (call rphrf('rat');)
  % RIPPLE: pars = [4.7235    0.5551    0.2873    0.7716    0.5950    0.1579];  
  % MUA: 3.1664    1.0889    0.0912    0.4472    0.2858   -0.0007  
  pars = [1.8962    2.1750   18.3297    0.9390    0.1372];
  t = IRT;
  IR = pars(3) * gampdf(t,pars(1),pars(2))-pars(4)*exp(-((t-(t(end)/2))/(t(end)/1.8)).^2) + pars(5);
  info.func  = 'gampdf-hipp';
  info.pars = pars;
  
 case {'pl'},
  pars = [ 2.5072    2.0252   14.5366    0.3470   +0.13];
  t = IRT;
  IR = pars(3) * gampdf(t,pars(1),pars(2))-pars(4)*exp(-((t-(t(end)/2))/(t(end)/1.8)).^2) + pars(5);
  info.func  = 'gampdf-pl';
  info.pars = pars;
  
 case {'sr'},
  pars = [2.7257    1.3970   12.1245   -0.0463   -0.2495];
  t = IRT;
  IR = pars(3) * gampdf(t,pars(1),pars(2))-pars(4)*exp(-((t-(t(end)/2))/(t(end)/1.8)).^2) + pars(5);
  info.func  = 'gampdf-sr';
  info.pars = pars;
  
 case {'cx'},
  pars = [ 3.3551    1.6207   17.1944    0.0994   -0.1638];
  t = IRT;
  IR = pars(3) * gampdf(t,pars(1),pars(2))-pars(4)*exp(-((t-(t(end)/2))/(t(end)/1.8)).^2) + pars(5);
  info.func  = 'gampdf-cx';
  info.pars = pars;
  
 case {'th'},
  pars = [ 4.9295    1.4165   11.5837    2.1273    1.2567];
  t = IRT;
  IR = pars(3) * gampdf(t,pars(1),pars(2))-pars(4)*exp(-((t-(t(end)/2))/(t(end)/1.8)).^2) + pars(5);
  info.func  = 'gampdf-th';
  info.pars = pars;
  
 case {'gampdf','hemo'}
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

% normalize .dat so that sum(abs(HEMO.dat)) = 1;
HEMO.dat = HEMO.dat / sum(abs(HEMO.dat));


if nargout > 0,
  varargout{1} = HEMO;
else
  if nargin>3,    col = varargin{1};  else    col = 'k'; end;
  if nargin>4,    lw = varargin{2};  else    lw = 2; end;
  %  figure('Name',sprintf('%s: %s',datestr(now),mfilename));
  T = (0:length(HEMO.dat)-1)*HEMO.dx;
  %plot(T, HEMO.dat);
  HEMO.dat = (1/HEMO.dx)*HEMO.dat/max(abs(HEMO.dat));
  plot(T, HEMO.dat,'color',col,'linewidth',lw);
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



if verLessThan('matlab','7.10'),
  warning('on','MATLAB:log:logOfZero');
end


return;

