RET = debug_adfx_raw('D:\Temp\20170117_7T_test\20170117_test_001.adfx');


base = nanmean(RET.dat(1:1000,:),1);

RET.dat = bsxfun(@minus, RET.dat, base);

CHANS = [1 12+1 22];

figure;
subplot(3,1,1);
plot(RET.dat(:,CHANS));
legend('chan1','chan13', 'chan22');

nlags = 4000;
[c1, lags] = xcorr(RET.dat(:,CHANS(1)), RET.dat(:,CHANS(2)), nlags);
[c2, lags] = xcorr(RET.dat(:,CHANS(1)), RET.dat(:,CHANS(3)), nlags);

subplot(3,1,2);
plot(lags,[c1(:),c2(:)]);
legend('chan1-chan13','chan1-chan22');

[maxv, maxi] = max(c1);
i1 = lags(maxi);
[maxv, maxi] = max(c2);
i2 = lags(maxi);


w1 = circshift(RET.dat(:,CHANS(2)),i1);
w2 = circshift(RET.dat(:,CHANS(3)),i2);

subplot(3,1,3);
plot([RET.dat(:,CHANS(1)), w1(:), w2(:)]);
legend('chan1','chan13', 'chan22');

title(sprintf('circshift = %d, %d',i1,i2));


% i1 = -1650, i2 = -1423