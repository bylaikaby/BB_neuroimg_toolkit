function showadf(SesName,ExpNo,chan,startT,endT)
%SHOWADF - Show raw ADF data
%  SHOWADF(SESSION,ExpNo) shows the raw data saved in the adf/adfw files
%
%  NKL 12.08.06   

  
  
if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 5,
  endT = 10;         % 10 seconds
end;

if nargin < 4,
  startT = 1;
end;

if nargin < 3,
  chan=1;
end;

Ses = goto(SesName);
if ~isnumeric(ExpNo),
  fprintf('SHOWADF: the second argument must be numeric (ExpNo)\n');
  return;
end;

adf = subReadAdf(Ses,ExpNo,chan);
startT = 1000 * startT;
endT   = 1000 * endT;
adf.dat(:,end) = adf.dat(:,end) * 0.5;

mfigure([100 100 1000 800]);
t = [0:length(adf.dat)-1]*adf.dx*1000;

plot(t, adf.dat(:,end),'r');
hold on;
plot(t, adf.dat(:,1),'k');
if nargin > 3,
  set(gca,'xlim',[startT endT]);
end;
xlabel('Time in msec');
ylabel('ADC points');

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to get electric stimulation timings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function adfdat = subReadAdf(Ses,ExpNo,ChanNo)

Ses = goto(Ses);
grp = getgrp(Ses,ExpNo);
par = expgetpar(Ses,ExpNo);

if isfield(grp,'esch') & ~isempty(grp.esch),
  ESChan = grp.esch(1);
else
  ESChan = length(grp.hardch) + 1;  % last channel as electric stimulation
end

fprintf('SHOWADF: reading adf_info\n');
physfile = expfilename(Ses,ExpNo,'phys');
[chan,obsp,sampt,obslen] = adf_info(physfile);
if ESChan > chan,
  physfile = expfilename(Ses,ExpNo,'phys2');
  if ~exist(physfile,'file'),  return;  end
  [chan2,obsp,sampt,obslen] = adf_info(physfile);
  if chan+chan2 < ESChan,  return;  end
end

adfdat.session = Ses.name;
adfdat.grpname = grp.name;
adfdat.ExpNo   = ExpNo;
tmpsig = adfdat;

fprintf('SHOWADF: reading data... ');
tmpdat(:,1) = adfread(Ses,ExpNo,1,ChanNo);
tmpdat(:,2) = adfread(Ses,ExpNo,1,ESChan);
fprintf(' Done!\n');

adfdat.dat = tmpdat(:,2);
adfdat.dx      = sampt/1000.0 * par.adf.tfactor;
adfdat.dxorg   = sampt/1000.0;

baseidx = getStimIndices(adfdat,'blank',0,0);

mbase = mean(adfdat.dat(baseidx));
sbase = std(adfdat.dat(baseidx));

% now extract timing of microstimulation
adfdat.dat = adfdat.dat - mbase;

% amplitude should above the threshould.
tmpt = find(abs(adfdat.dat) > sbase*10);
% each pulse should be separated more than 1ms.
tmpdt = diff([0;tmpt]);
tmpidx = find(tmpdt > round(0.001/adfdat.dx));
% select it
tmpt = tmpt(tmpidx);

adfdat.t_pts   = tmpt;
adfdat.t_sec   = tmpt * adfdat.dx;
adfdat.dat = tmpdat;
clear tmpdat;
return;
