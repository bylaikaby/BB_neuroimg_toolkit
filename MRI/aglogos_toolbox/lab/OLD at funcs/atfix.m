function atfix
%ATFIX - fix at-transfer
% tet, res, lfp, mua

% 17.10.03 17:17
SESSION='d98at1';
Ses = goto(SESSION);
atana(Ses,'atsdf');
atana(Ses,'atlfp');
atana(Ses,'muares');
return;

% 17.10.03 17:02
SESSION='d98at1';
Ses = goto(SESSION);
EXPS = [37:48];
for N=EXPS,
  filename=catfilename(Ses,N,'mat');
  load(filename);
  muaSpkt.dir.dname = 'muaSpkt';
  muaSdf.dir.dname = 'muaSdf';
  save(filename,'muaSpkt','muaSdf');
  fprintf('Fixed file %s\n',filename);
end;
return;

SESSION='d98at1';
Ses = goto(SESSION);
EXPS = validexps(Ses);
for N=1:12,
  neufilename=catfilename(Ses,N,'atphys');
  load(neufilename,'lfp','res','muares','tet');
  save(catfilename(Ses,N,'atphys'),'tet');
  fprintf('.');
  save(catfilename(Ses,12+N,'atphys'),'res');
  fprintf('.');
  save(catfilename(Ses,24+N,'atphys'),'lfp');
  fprintf('.');
  save(catfilename(Ses,36+N,'atphys'),'muares');
  fprintf('.\n');
end;
return;  

SESSION='d98at1';
Ses = goto(SESSION);
EXPS = validexps(Ses);
for N=9:length(EXPS),
  ExpNo = EXPS(N);
  filename=catfilename(Ses,ExpNo,'atphys');
  load(filename,'lfp','res','muares','tet');
  save(filename,'lfp','res','muares','tet');
  fprintf('saved %s\n', filename);
end;
return;

for N=9:length(EXPS),
  [aSpkt,aSdf] = matsigload(filename,'atSpkt','atSdf');

  CH=1;
  for M=1:length(aSpkt),
	if M==1,
	  atSpkt = aSpkt{1};
	  atSdf = aSdf{1};
	  atSpkt = rmfield(atSpkt,{'SpikeTimeUnits', 'interD', 'intraD', 'TetNo'});
	  atSdf = rmfield(atSdf,{'SpikeTimeUnits', 'interD', 'intraD', 'TetNo'});
	else
	  atSpkt.times{M,1} = aSpkt{M}.times{1};
	  atSpkt.dat = cat(2,atSpkt.dat,aSpkt{M}.dat);
	  atSdf.dat = cat(2,atSdf.dat,aSdf{M}.dat);
	end;
	
	for C=1:size(aSdf{M}.dat,2),	% EACH CELL IS A CHANNEL
	  atSpkt.chan(CH) = (aSpkt{M}.TetNo-1) * Ses.confunc.maxchan + C;
	  atSdf.chan(CH) = (aSdf{M}.TetNo-1) * Ses.confunc.maxchan + C;
	  CH=CH+1;
	end;
  end;

  clear aSpkt aSdf;
  save(filename,'-append','atSpkt','atSdf');
  fprintf('SPIKES appended in %s\n', filename);
end;
  
  
  
  
return;
SESSION='d98at1';
Ses = goto(SESSION);
Ses = atgetconfig(Ses,'cell');
EXPS = validexps(Ses);
for N=1:length(EXPS),
  ExpNo = EXPS(N);
  filename=catfilename(Ses,ExpNo,'mat');
  [aSpkt,aSdf] = matsigload(filename,'atSpkt','atSdf');

  CH=1;
  for M=1:length(aSpkt),
	if M==1,
	  atSpkt = aSpkt{1};
	  atSdf = aSdf{1};
	  atSpkt = rmfield(atSpkt,{'SpikeTimeUnits', 'interD', 'intraD', 'TetNo'});
	  atSdf = rmfield(atSdf,{'SpikeTimeUnits', 'interD', 'intraD', 'TetNo'});
	else
	  atSpkt.times{M,1} = aSpkt{M}.times{1};
	  atSpkt.dat = cat(2,atSpkt.dat,aSpkt{M}.dat);
	  atSdf.dat = cat(2,atSdf.dat,aSdf{M}.dat);
	end;
	
	for C=1:size(aSdf{M}.dat,2),	% EACH CELL IS A CHANNEL
	  atSpkt.chan(CH) = (aSpkt{M}.TetNo-1) * Ses.confunc.maxchan + C;
	  atSdf.chan(CH) = (aSdf{M}.TetNo-1) * Ses.confunc.maxchan + C;
	  CH=CH+1;
	end;
  end;

  clear aSpkt aSdf;
  save(filename,'-append','atSpkt','atSdf');
  fprintf('SPIKES appended in %s\n', filename);
end;


return;  
SESSION='d98at1';
Ses = goto(SESSION);
EXPS = validexps(Ses);
for N=1:length(EXPS),
  ExpNo = EXPS(N);
  filename=catfilename(Ses,ExpNo,'mat');
  [mSpkt,mSdf] = matsigload(filename,'muaSpkt','muaSdf');
  for M=1:length(mSpkt),
	if M==1,
	  muaSpkt = mSpkt{1};
	  muaSdf = mSdf{1};
	else
	  muaSpkt.times{M,1} = mSpkt{M}.times{1};
	  muaSpkt.dat = cat(2,muaSpkt.dat,mSpkt{M}.dat);
	  muaSdf.dat = cat(2,muaSdf.dat,mSdf{M}.dat);
	end;
	muaSpkt.chan(M) = mSpkt{M}.TetNo;
	muaSdf.chan(M) = mSdf{M}.TetNo;
  end;
  
  muaSpkt = rmfield(muaSpkt,{'SpikeTimeUnits', 'interD', 'intraD', 'TetNo'});
  muaSdf = rmfield(muaSdf,{'SpikeTimeUnits', 'interD', 'intraD', 'TetNo'});
  save(filename,'-append','muaSpkt','muaSdf');
  fprintf('MUA appended in %s\n', filename);
end;


