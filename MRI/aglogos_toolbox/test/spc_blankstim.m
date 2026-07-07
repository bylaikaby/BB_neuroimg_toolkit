function varargout = spc_blankstim(SESSION,ExpNo)
% [MTMblank MTMmovie f] = SPC_BLANKSTIM(SESSION,EXPNO)
%blp = sigload('c98nm1',40,'blp');


%lfp = squeeze(blp.dat(:,:,8));
%mua = squeeze(blp.dat(:,:,end));
%Fs = 1/blp.dx;
%NFFT = 256;

if nargin == 0,
  SESSION = 'c98nm1';
  ExpNo   = 10;
end



SIG = sigload(SESSION,ExpNo,'Cln');

grp = getgrp(SIG.session,SIG.ExpNo(1));
if isfield(grp,'findch') & ~isempty(grp.findch),
  SIG.dat(:,grp.findch) = [];
  SIG.chan(grp.findch) = [];
end

% JUST FOR DEBUGGING...
%SIG.dat = SIG.dat(:,1:5);
%SIG.dat = SIG.dat(1:round(size(SIG.dat,1)/4),:);


% I don't need 7kHz data, so decimate it to 2kHz
fac = round(1/SIG.dx/2000);
fprintf(' %s: sigdecimate[%.1f-->%.1fkHz]...',...
        mfilename,1/SIG.dx/1000, 1/SIG.dx/1000/fac);
SIG = sigdecimate(SIG,fac);
fprintf(' done.\n');

%SIG = sigrmarchfact(SIG);


Fs = 1/SIG.dx;
NFFT = 2^nextpow2(2/SIG.dx);


blank = getStimIndices(SIG,0);
%movie = getStimIndices(SIG,'movie');
movie = getStimIndices(SIG,'anystim');
movie = movie(1:length(blank));

lfp = SIG.dat;


% spectrum by pmtm
NW = 3;
MTMblank = [];  MTMmovie = [];
fprintf(' %s: spec[NCh=%d,NFFT=%d(%.1fs)] ',...
        mfilename,size(lfp,2),NFFT,NFFT*SIG.dx);
for iCh = size(lfp,2):-1:1,
  fprintf('.');

  %[Pxx,f] = pmtm(lfp(blank,iCh),NW,NFFT,Fs);
  %MTMblank(:,iCh) = Pxx;
  %[Pxx,f] = pmtm(lfp(movie,iCh),NW,NFFT,Fs);
  %MTMmovie(:,iCh) = Pxx;
  
  [Pxx,f] = pwelch(lfp(blank,iCh),NFFT,NFFT/2,NFFT,Fs);
  MTMblank(:,iCh) = Pxx;
  [Pxx,f] = pwelch(lfp(movie,iCh),NFFT,NFFT/2,NFFT,Fs);
  MTMmovie(:,iCh) = Pxx;
  
  %[B,f,t] = specgram(lfp(blank,iCh),NFFT,Fs);
  %B = mean(abs(B),2);  Pxx = B.*B;
  %MTMblank(:,iCh) = Pxx;
  %[B,f,t] = specgram(lfp(movie,iCh),NFFT,Fs);
  %B = mean(abs(B),2);  Pxx = B.*B;
  %MTMmovie(:,iCh) = Pxx;
end
MTMf = f;
fprintf(' done.\n');


if nargout > 0,
  %[MTMblank MTMmovie f]
  varargout{1} = MTblank;
  varargout{2} = MTmovie;
  varargout{3} = f;
  return;
end





tmptitle = sprintf('%s Exp=%d(%s) PSD ratio of movie/blank',...
                    SIG.session,SIG.ExpNo(1),SIG.grpname);
figure('Name',tmptitle);

subplot(2,1,1);
%plot(MTMf,mean(MTMmovie,2)./mean(MTMblank,2),'color','b','linewidth',2);
plot(MTMf,mean(MTMmovie./MTMblank,2),'color','b','linewidth',2);
%plot(MTMf,MTMmovie./MTMblank);
hold on; grid on;
set(gca,'xlim',[0.5 500],'ylim',[0.4 7],...
        'xscale','log','yscale','log');
for F = [13 43 73 158],
  line([F F],get(gca,'ylim'),'color','r');
  text(F,max(get(gca,'ylim')),num2str(F));
end
xlabel('Frequency in Hz');
ylabel('PSD ratio of movie/blank');


subplot(2,1,2);
plot(MTMf,mean(MTMblank,2),'color','b','linewidth',2);
hold on; grid on;
plot(MTMf,mean(MTMmovie,2),'color','r','linewidth',2);
legend('blank','movie');
set(gca,'xlim',[0.5 500],...
        'xscale','log','yscale','log');
for F = [13 43 73 158],
  line([F F],get(gca,'ylim'),'color','r');
  text(F,max(get(gca,'ylim')),num2str(F));
end
xlabel('Frequency in Hz');
ylabel('PSD movie/blank');
