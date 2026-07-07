%histogram of SUA
load spontaneous
figure
hist(m)
xlabel('Spontaneous firing rate (spikes/second)') 
ylabel('Number of neurons');
text(10,30,'mean = 3.3, skewness = 2.2, kurtosis = 7.5')

figure
fromn=2;ton=60;step=4;
% creates histogram of MUA from SUA data by rand permuations
mm=fromn:step:ton;
ploti=1;meann=[];skewn=[];kurnn=[];
mmua=[];
for mua = fromn : step : ton 
  
  for i = 1 : 3000
  
  
    mi=randperm(length(m));
    mmua(ploti,i)=mean(m(mi(1:mua)));
    
  end
  subplot(4,4,ploti);hist(mmua(ploti,:));
  title(strcat('# of neurons in MUA =  ',num2str(mua)))
  meann(ploti)=mean(mmua(ploti,:));
  skewn(ploti)=skewness(mmua(ploti,:));
  kurnn(ploti)=kurtosis(mmua(ploti,:));
  if ploti==ton
    xlabel('Spontaneous firing rate (spikes/second)') 
    ylabel('Number of neurons');
  end
  
  ploti=ploti+1;
end

figure
subplot(2,3,1);plot(mm,meann,'.--');
xlabel('Number of neurons in MUA') 
ylabel('Mean firing rate (spikes/second)');
axis([0 ton 2 5])
subplot(2,3,2);plot(mm,skewn,'.--')
xlabel('Number of neurons in MUA') 
ylabel('Skewness');
subplot(2,3,3);plot(mm,kurnn,'.--')
xlabel('Number of neurons in MUA') 
ylabel('Kurtosis');