

%SES = goto('D98AT1');
SES = goto('D98AT2');

fprintf('%s: loading data...',mfilename);

if strcmpi(SES.name,'D98AT1'),
  % load Cln structure
  load('SIGS/d98at1_001_CLN.mat','Cln');
  % load atSpkt structure
  load('d98at1_013.mat','atSpkt');
  % load Spkt structure
  load('d98at1_001.mat','Spkt');
else
  % load Cln structure
  load('SIGS/d98at2_001_CLN.mat','Cln');
  % load atSpkt structure
  load('d98at2_011.mat','atSpkt');
  % load Spkt structure
  load('d98at2_001.mat','Spkt');
end


CLN_IDX = 1;

fprintf(' plotting(chan=%d)...',CLN_IDX);
figure;

% plot cln signal
tcln = [1:size(Cln.dat,1)]*Cln.dx;
plot(tcln, Cln.dat(:,CLN_IDX));
hold on;

ylim = get(gca,'ylim');

% plot spikes by simple thresholding
tmpspk = zeros(1,Spkt.duration);
tmpspk(Spkt.times{CLN_IDX}) = - max(ylim)/2;
tspk   = [1:length(tmpspk)]*Spkt.dt;
plot(tspk,tmpspk,'g');
fprintf(' Spkt[%d]',length(find(tmpspk) ~= 0));


fprintf(' Cln.chan:%d Spk.chan:',Cln.chan(CLN_IDX));

% plot spikes by Andreas
tmpspk = zeros(1,atSpkt.duration);
%for N = 1:length(atSpkt.chan),
for N = 1:length(atSpkt.times),
  % WHY NEED TO "-1"??????????????????????
  %if atSpkt.chan(N) == Cln.chan(CLN_IDX)-1,
  % IS THIS CORRECT ??????????????????????
  %if atSpkt.chan(N) == floor(Cln.chan(CLN_IDX)/4),
  if atSpkt.chan(N) == 3,
    fprintf('%d.',atSpkt.chan(N));
    tmpspk(atSpkt.times{N}) = max(ylim)/2;
  end
end
tspk   = [1:length(tmpspk)]*atSpkt.dt;
plot(tspk,tmpspk,'r');
fprintf(' atSpkt[%d]',length(find(tmpspk) ~= 0));



grid on;
set(gca,'xlim',[0 1]);


fprintf(' done.\n');
