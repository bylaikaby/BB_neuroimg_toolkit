function SIG = testmrs(varargin)
%TESTMRS - Plot FID waveforms.
%  SIG = TESTMRS(Ses,ExpNo)
%  SIG = TESTMRS(FIDFILE) plots FID waveforms.
%
%  EXAMPLE :
%    testmrs('a14pz2',1)    % by using a session file
%    testmrs('//nas1/mridata_wks8/A14.pZ2/12/fid')
%    testmrs('//nas1/mridata_wks8/A14.pZ2/12/fid','time','msec')
%
%  VERSION :
%    0.90 03.06.14 YM  pre-release
%    0.91 04.06.14 YM  supports "ser" and fitting.
%
%  See also pvread_fid

if nargin < 1,  eval(['help ' mfilename]); return;  end



if ischar(varargin{1}) && any(strfind(varargin{1},'fid'))
  fidfile = varargin{1};
  ivar = 2;
elseif ischar(varargin{1}) && any(strfind(varargin{1},'ser'))
  fidfile = varargin{1};
  ivar = 2;
else
  fidfile = expfilename(varargin{1},varargin{2},'fid');
  ivar = 3;
end


% OPTIONS ------------------------------------------------------
PLOT_IN_PTS = 1;
DO_FIT      = 1;
for N = ivar:2:length(varargin)
  switch lower(varargin{N})
   case {'time'}
    if any(strcmpi({'ms' 'msec'},varargin{N+1})),
      PLOT_IN_PTS = 0;
    else
      PLOT_IN_PTS = 1;
    end
   case {'fit'}
    DO_FIT = any(varargin{N+1});
  end
end



[fid, imgp] = pvread_fid(fidfile);


SIG.filename = fidfile;
SIG.tspect   = imgp.dimsize(1);
SIG.trep     = imgp.imgtr;
SIG.dat      = double(fid);
SIG.imgp     = imgp;


sub_plot(SIG,PLOT_IN_PTS,DO_FIT);

return


% -------------------------------------------------
function sub_plot(SIG,IN_PTS,DO_FIT)
% -------------------------------------------------

if nargin < 2,  IN_PTS = 1;  end
if nargin < 3,  DO_FIT = 0;  end


tmpv = 1:size(SIG.dat,3);

nfid = size(SIG.dat,3);
tmpv = zeros(1,nfid);
%tmpv(randperm(nfid,round(nfid/2))) = 1;
tmpv(round(nfid/2)+1:end) = 1;

if any(IN_PTS)
tmpt = 1:size(SIG.dat,1);  % in points
else
tmpt = (0:size(SIG.dat,1)-1)*SIG.tspect * 1000;  % in msec
end

figure('Name',sprintf('%s: %s',mfilename,SIG.filename));
pos = get(gcf,'pos');
pos(3) = pos(3)*1.5;
pos(2) = pos(2)-pos(4)*0.5;  pos(4) = pos(4)*1.5;
set(gcf,'pos',pos);

subplot(3,2,1);
tmpdat  = real(SIG.dat);
tmpdat0 = nanmean(tmpdat(:,:,tmpv==0),3);
tmpdat1 = nanmean(tmpdat(:,:,tmpv==1),3);
plot(tmpt,[tmpdat0, tmpdat1]);
%title('real');
ylabel('real');
grid on;
set(gca,'xlim',[tmpt(1) tmpt(end)]);
legend('1st-half','2nd-half','location','NorthEast');

subplot(3,2,2);
tmpdat  = imag(SIG.dat);
tmpdat0 = nanmean(tmpdat(:,:,tmpv==0),3);
tmpdat1 = nanmean(tmpdat(:,:,tmpv==1),3);
plot(tmpt,[tmpdat0, tmpdat1]);
%title('imag');
ylabel('imag');
grid on;
set(gca,'xlim',[tmpt(1) tmpt(end)]);
legend('1st-half','2nd-half','location','NorthEast');

subplot(3,2,3);
tmpdat  = abs(SIG.dat);
tmpdat0 = nanmean(tmpdat(:,:,tmpv==0),3);
tmpdat1 = nanmean(tmpdat(:,:,tmpv==1),3);
plot(tmpt,[tmpdat0, tmpdat1]);
%title('abs');
ylabel('abs');
grid on;
set(gca,'xlim',[tmpt(1) tmpt(end)]);
if any(IN_PTS)
xlabel('time (pts)');
else
xlabel('time (ms)');
end
if any(DO_FIT) && ~any(IN_PTS);
  options = optimset('TolFun',1.0e-5,'MaxIter',60,'Display','off');
  fh = @(p,xdata)(p(1)*exp(-xdata/p(2)) + p(3));

  xdata = tmpt(:);
  %ydata = tmpdat0(:);
  ydata = nanmean(tmpdat,3);
  [minv, mini] = min(abs(ydata - max(ydata)*exp(-1)));
  pini  = [ydata(1) xdata(mini) 0];
  [p,resnorm,residual] = lsqcurvefit(fh,pini,xdata,ydata,[],[],options);

  text(0.02,0.05,sprintf('y=A*exp(-t/B)+C: A=%g, B=%g ,C=%g',p(1),p(2),p(3)),...
       'unit','normalized','horizontalalignment','left','verticalalignment','bottom');
  hold on;
  plot(xdata,fh(p,xdata),'r');
  line([p(2) p(2)],get(gca,'ylim'),'color',[1.0 0.6 0.6]);
  text(p(2),fh(p,p(2))*1.3,sprintf('  %gms',p(2)));

  legend('1st-half','2nd-half','A*exp(-t/B)+C','location','NorthEast');
else
  legend('1st-half','2nd-half','location','NorthEast');
end

subplot(3,2,4);
tmpdat  = angle(SIG.dat)/pi*180;
tmpdat0 = nanmean(tmpdat(:,:,tmpv==0),3);
tmpdat1 = nanmean(tmpdat(:,:,tmpv==1),3);
plot(tmpt,[tmpdat0, tmpdat1]);
%title('angle');
ylabel('angle (deg)');
grid on;
set(gca,'xlim',[tmpt(1) tmpt(end)]);
legend('1st-half','2nd-half','location','NorthEast');
if any(IN_PTS)
xlabel('time (pts)');
else
xlabel('time (ms)');
end

subplot(3,1,3);
tmpdat = abs(SIG.dat);
%tmpdat = SIG.dat;
tmpsig.dat(:,:,1) = nanmean(tmpdat(:,:,tmpv==0),3);
tmpsig.dat(:,:,2) = nanmean(tmpdat(:,:,tmpv==1),3);
tmpsig.dx  = SIG.tspect;
METHOD = 'fft';
switch lower(METHOD)
 case {'pwelch'}
  WindowType = 'hanning';
  WINDOW = hanning(512);
  tmpspc = sub_pwelch(tmpsig,WindowType,WINDOW,length(WINDOW)*2);
  tmpspc.dat = tmpspc.dat .* conj(tmpspc.dat);
  tmpdat0 = tmpspc.dat(:,:,1);
  tmpdat1 = tmpspc.dat(:,:,2);
  tmpsel  = (tmpspc.freq > 0 & tmpspc.freq <= 1/tmpsig.dx/2);
  plot(tmpspc.freq(tmpsel),[tmpdat0(tmpsel),tmpdat1(tmpsel)]);
  ylabel('PSD(abs)');
 otherwise
  NFFT = size(tmpsig.dat,1);
  Fs = 1/SIG.tspect;
  dF = Fs/NFFT;
  F = (0:(NFFT-1))*dF;
  tmpsel = find(F <= Fs/2);
  F = F(tmpsel);
  tmpspc.freq = F;
  tmpspc.dat(:,:,1) = fft(tmpsig.dat(:,:,1),NFFT)/size(tmpsig.dat,1);
  tmpspc.dat(:,:,2) = fft(tmpsig.dat(:,:,2),NFFT)/size(tmpsig.dat,1);
  tmpspc.dat = tmpspc.dat(tmpsel,:,:);
  tmpi = find(F == 0 | F == Fs/2);
  if any(tmpi)
    tmspc.dat(tmpi,:,:) = tmpspc.dat(tmpi,:,:)/2;
  end
  tmpspc.dat = tmpspc.dat .* conj(tmpspc.dat);
  
  tmpsel  = find(tmpspc.freq > 0 & tmpspc.freq <= 1/tmpsig.dx/2);
  plot(tmpspc.freq(tmpsel),[tmpdat0(tmpsel),tmpdat1(tmpsel)]);
  ylabel('Power-FFT(abs)');
  set(gca,'xlim',[0 tmpspc.freq(tmpsel(end))]);
  text(0.02,0.05,sprintf('dt=%gms, npts=%d, nfid=%d',SIG.tspect*1000,size(SIG.dat,1),size(SIG.dat,3)),...
       'unit','normalized','horizontalalignment','left','verticalalignment','bottom');
end
grid on;
legend('1st-half','2nd-half','location','NorthEast');
xlabel('freq (Hz)');

return



function SPC = sub_fft(SIG,WindowType,WINDOW,NFFT)

datsz = size(SIG.dat);
SIG.dat = reshape(SIG.dat,[datsz(1) prod(datsz(2:end))]);

NWINDOW = length(WINDOW);
OVERLAP = round(NWINDOW*0.5);
Fs      = 1/SIG.dx;

%F = Fs/2*linspace(0,1,round(NFFT/2));
%tmpsel = 1:round(NFFT/2);

% calculate unshifted frequency vector
dF = Fs/NFFT;
F = (0:(NFFT-1))*dF;
tmpsel = find(F <= Fs/2);

% dF = Fs/NFFT;
% F  = (0:dF:(Fs-dF)) - (Fs-mod(NFFT,2)*dF)/2;
% tmpsel = find(F >= 0);

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpidx = 1:NWINDOW;
  tmpspc = [];
  while tmpidx(end) < size(SIG.dat,1),
    tmpdat = double(SIG.dat(tmpidx,N)).*WINDOW(:);
    tmpfft = fft(tmpdat,NFFT)/NWINDOW;
    %tmpfft = 2*abs(tmpfft(1:round(NFFT/2))); % single sided
    tmpfft = 2*abs(tmpfft(tmpsel)); % single sided
    tmpspc = cat(2,tmpspc,tmpfft);
    tmpidx = tmpidx + (NWINDOW - OVERLAP);
  end
  tmpspc = abs(tmpspc);
  spcdat(:,N) = nanmean(tmpspc,2);
end

F = F(tmpsel);
% take care of DC, Fs/2
tmpi = find(F == 0 | F == Fs/2);
if any(tmpi),  spcdat(tmpi,:) = spcdat(tmpi,:)/2;  end

SIG.dat = reshape(SIG.dat,datsz);

datsz(1) = size(spcdat,1);
spcdat   = reshape(spcdat,datsz);

SPC.dat = spcdat;
SPC.freq = F;
SPC.method = 'mean-fft';
SPC.window  = WindowType;
SPC.nwindow = NWINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;

return


function SPC = sub_pwelch(SIG,WindowType,WINDOW,NFFT)

datsz = size(SIG.dat);
SIG.dat = reshape(SIG.dat,[datsz(1) prod(datsz(2:end))]);

NWINDOW = length(WINDOW);
OVERLAP = round(NWINDOW*0.5);
Fs      = 1/SIG.dx;

spcdat = [];
for N = size(SIG.dat,2):-1:1,
  tmpdat = double(SIG.dat(:,N));
  % note tmpspc as (f,t)
  [Pxx F] = pwelch(tmpdat,WINDOW,OVERLAP,NFFT,Fs);
  tmpspc = sqrt(Pxx);
  spcdat(:,N) = tmpspc(:);
end

SIG.dat = reshape(SIG.dat,datsz);

datsz(1) = size(spcdat,1);
spcdat   = reshape(spcdat,datsz);

SPC.dat = spcdat;
SPC.freq = F;
SPC.method  = 'pwelch';
SPC.window  = WindowType;
SPC.nwindow = NWINDOW;
SPC.overlap = OVERLAP;
SPC.nfft    = NFFT;
SPC.Fs      = Fs;

return
