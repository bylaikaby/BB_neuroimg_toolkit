function  chkhilcor()

RANDSTATE = [
    0.7454
    0.9229
    0.4423
    0.5731
    0.2816
    0.8399
    0.5117
    0.0347
    0.6014
    0.0487
    0.4931
    0.0563
    0.0641
    0.6525
    0.7764
    0.8240
    0.4181
    0.2283
    0.8182
    0.0509
    0.8131
    0.2493
    0.4001
    0.4621
    0.5224
    0.0595
    0.1792
    0.0786
    0.4952
    0.7860
    0.2451
    0.7692
    0.0000
         0
         0
            ];	% --> corr() =  0.004



%rand('state')
%rand('state',RANDSTATE);

MAX_N = 20;
%MAX_N = 5;
BLP_TEST = 1;


  
CCLN     = [];
CRAWCHAN = [];
CRAWBAND = [];
CHILCHAN = [];
CHILBAND = [];
for N = 1:MAX_N,
  fprintf(' %2d/%d: ',N,MAX_N);
  [CLN, BLP, ccln, crawch, crawband, chilch, chilband] = subChkHilCorr(BLP_TEST);
  CCLN     = cat(1,CCLN, ccln);
  CRAWCHAN = cat(2,CRAWCHAN,crawch(:));
  CRAWBAND = cat(3,CRAWBAND,crawband);
  CHILCHAN = cat(2,CHILCHAN,chilch(:));
  CHILBAND = cat(3,CHILBAND,chilband);
end

CCLNm     = mean(CCLN);         CCLNs     = std(CCLN,1);
CRAWCHANm = mean(CRAWCHAN,2);   CRAWCHANs = std(CRAWCHAN,1,2);
CRAWBANDm = mean(CRAWBAND,3);   CRAWBANDs = std(CRAWBAND,1,3);
CHILCHANm = mean(CHILCHAN,2);   CHILCHANs = std(CHILCHAN,1,2);
CHILBANDm = mean(CHILBAND,3);   CHILBANDs = std(CHILBAND,1,3);


fprintf('\n\nRESULT\n');
fprintf('===========================================\n');
fprintf(' N = %d:  DUR=%.2fs\n',MAX_N,CLN.dur);
fprintf('===========================================\n');
fprintf(' Cln-Chan corr: % .4f +- %.4f\n',CCLNm,CCLNs);

fprintf('=BLP-RAW==========================================\n');
for N = 1:size(BLP.dat,3),
  band = BLP.info.band{N};
  fprintf(' BLP-Chan corr %6s [%3d %4d]: % .4f +- %.4f\n',...
          band{2},band{1}(1),band{1}(2),CRAWCHANm(N),CRAWCHANs(N));
end  


fprintf('=BLP-RAW==========================================\n');
for N = 1:size(BLP.dat,3),
  band1 = BLP.info.band{N};
  for K = 1:size(BLP.dat,3),
    if K == N,  continue;  end
    band2 = BLP.info.band{K};
    fprintf(' BLP-BLP corr %6s-%6s: % .4f +- %.4f\n',...
            band1{2},band2{2},CRAWBANDm(N,K), CRAWBANDs(N,K));
  end
  fprintf('-------------------------------------------\n');
end



fprintf('=BLP-HIL==========================================\n');
for N = 1:size(BLP.dat,3),
  band = BLP.info.band{N};
  fprintf(' BLP-Chan corr %6s [%3d %4d]: % .4f +- %.4f\n',...
          band{2},band{1}(1),band{1}(2),CHILCHANm(N),CHILCHANs(N));
end  


fprintf('=BLP-HIL==========================================\n');
for N = 1:size(BLP.dat,3),
  band1 = BLP.info.band{N};
  for K = 1:size(BLP.dat,3),
    if K == N,  continue;  end
    band2 = BLP.info.band{K};
    fprintf(' BLP-BLP corr %6s-%6s: % .4f +- %.4f\n',...
            band1{2},band2{2},CHILBANDm(N,K), CHILBANDs(N,K));
  end
  fprintf('-------------------------------------------\n');
end

return;






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CLN BLP CCLN CRAWCHAN CRAWBAND CHILCHAN CHILBAND] = subChkHilCorr(BLP_TEST)


fprintf(' Cln...');
CLN.session = 's02nm1';	% just to avoid error
CLN.ExpNo   = 1;		% just to avoid error
CLN.grpname = 'movie1';	% just to avoid error
CLN.grp     = {};		% just to avoid error
CLN.stm     = {};		% just to avoid error
CLN.dir.dname = 'Cln';	% just to avoid error




%CLN.grp.ofs        = 4;        % Cut off the first 2 seconds
%CLN.grp.len        = 280;      % The length will be 60 seconds.


CLN.dx     = 1/7000;	% sampling rate in sec
CLN.dur    = 60;		% duration in sec,  of couse decreasing this result higher corr. in
                        % lower freqencies.
CLN.NoChan = 2;			% number of channels


%CLN = sigload('s02nm1',1,'Cln');
%CLN.NoChan = 2;
%CLN.chan = CLN.chan(1:CLN.NoChan);
%CLN.dur    = size(CLN.dat,1)*CLN.dx;


if BLP_TEST == 0,
  CLN.offset = 0;
else
  CLN.offset = 10;
end



% CLN.dat    = rand(round((CLN.offset+CLN.dur+CLN.offset)/CLN.dx),CLN.NoChan);
% for iCh = 1:CLN.NoChan,
%   CLN.dat(:,iCh) = CLN.dat(randperm(size(CLN.dat,1)),iCh);
% end
CLN.dat    = randn(round((CLN.offset+CLN.dur+CLN.offset)/CLN.dx),CLN.NoChan);


% make sure low passed arround nyq. freq.
[b,a] = butter(8,0.8,'low');
for iCh = 1:CLN.NoChan,
  tmpdat = CLN.dat(:,iCh);
  tmpdat = (tmpdat - mean(tmpdat))./std(tmpdat);
  tmpdat = filtfilt(b,a,tmpdat);
  tmpdat = (tmpdat - mean(tmpdat))./std(tmpdat);
  CLN.dat(:,iCh) = tmpdat;
end

%corr(CLN.dat(:,1),CLN.dat(:,2))

% Fs   = 1/CLN.dx;
% NFFT = 2^nextpow2(1.0/CLN.dx);
% for iCh = size(CLN.dat,2):-1:1,
%   [tmpB,F,T] = specgram(CLN.dat(:,iCh),NFFT,Fs);
%   SPC(:,iCh) = mean(abs(tmpB),2);
% end
% figure;
% plot(F,SPC);  grid on;
% set(gca,'xlim',[0 4000]);
% ylabel('Spectrum Amplitude');
% xlabel('Frequency in Hz');


if BLP_TEST == 0,
  BLP = siggetblp(CLN);
else
  BLP = siggetblp_test(CLN);
  % remove offset periods
  sigofs  = round(CLN.offset/CLN.dx);
  siglen  = round(CLN.dur/CLN.dx);
  CLN.dat = CLN.dat([1:siglen]+sigofs,:);
  sigofs  = round(CLN.offset/BLP.dx);
  siglen  = round(CLN.dur/BLP.dx);
  BLP.dat = BLP.dat([1:siglen]+sigofs,:,:);
end


% compute envelops by Hilbert Transform
fprintf(' hilbert...');
DO_HIL = zeros(1,size(BLP.dat,3));
if BLP.info.lenvelop == 0,
  DO_HIL(BLP.info.lBands) = 1;
end
if BLP.info.menvelop == 0,
  DO_HIL(BLP.info.mBands) = 1;
end

clear DAT;
for iCh = size(BLP.dat,2):-1:1,
  for iBand = size(BLP.dat,3):-1:1,
    if DO_HIL(iBand) == 1,
      DAT(:,iCh,iBand) = abs(hilbert(BLP.dat(:,iCh,iBand)));
    else
      DAT(:,iCh,iBand) = BLP.dat(:,iCh,iBand);
    end
  end
end
BLP.hil = DAT;  clear DAT;




CCLN = corr(CLN.dat(:,1),CLN.dat(:,2));
for N = 1:size(BLP.dat,3),
  CRAWCHAN(N) = corr(BLP.dat(:,1,N),BLP.dat(:,2,N));
  CHILCHAN(N) = corr(BLP.hil(:,1,N),BLP.hil(:,2,N));
  for K = 1:size(BLP.dat,3),
    CRAWBAND(N,K,1) = corr(BLP.dat(:,1,N),BLP.dat(:,1,K));
    CHILBAND(N,K,2) = corr(BLP.hil(:,2,N),BLP.hil(:,2,K));
  end
end


fprintf('===========================================\n');
fprintf(' Cln-Chan corr: % .4f\n',CCLN);
return;


fprintf('===========================================\n');
fprintf(' Cln-Chan corr: % .4f\n',CCLN);

fprintf('=BLP-RAW==========================================\n');
for N = 1:size(BLP.dat,3),
  band = BLP.info.band{N};
  fprintf(' BLP-Chan corr %6s [%3d %4d]: % .4f\n',...
          band{2},band{1}(1),band{1}(2),CRAWCHAN(N));
end  


fprintf('=BLP-RAW==========================================\n');
for N = 1:size(BLP.dat,3),
  band1 = BLP.info.band{N};
  for K = 1:size(BLP.dat,3),
    if K == N,  continue;  end
    band2 = BLP.info.band{K};
    fprintf(' BLP-BLP corr %6s-%6s: % .4f  % .4f\n',...
            band1{2},band2{2},CRAWBAND(N,K,1), CRAWBAND(N,K,2));
  end
  fprintf('-------------------------------------------\n');
end



fprintf('=BLP-HIL==========================================\n');
for N = 1:size(BLP.dat,3),
  band = BLP.info.band{N};
  fprintf(' BLP-Chan corr %6s [%3d %4d]: % .4f\n',...
          band{2},band{1}(1),band{1}(2),CHILCHAN(N));
end  


fprintf('=BLP-HIL==========================================\n');
for N = 1:size(BLP.dat,3),
  band1 = BLP.info.band{N};
  for K = 1:size(BLP.dat,3),
    if K == N,  continue;  end
    band2 = BLP.info.band{K};
    fprintf(' BLP-BLP corr %6s-%6s: % .4f  % .4f\n',...
            band1{2},band2{2},CHILBAND(N,K,1), CHILBAND(N,K,2));
  end
  fprintf('-------------------------------------------\n');
end
