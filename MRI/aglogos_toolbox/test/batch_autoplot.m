SESSION = {};
%SESSION{01} = 'b01nm3';
SESSION{02} = 'b01nm4';	% May 15 2003 [1:10]  adflen =  52.5
SESSION{03} = 'b01nm5'; % Jul 04 2003 [1:10]  adflen = 102
SESSION{04} = 'b02nm1'; % Jul 09 2003 [1:10]  adflen = 104.5


SESSION{05} = 'd01nm4'; % May 08 2003 [21:40] adflen =  52.5  OK
SESSION{06} = 'd01nm5'; % Jun 25 2003 [1:5]   adflen = 104.5  
SESSION{07} = 'g02nm1'; % Jul 17 2003 [1:10]  adflen = 104.5  
SESSION{08} = 'g98nm2'; % Jun 17 2003 [26:35] adflen =  52.7 

SESSION{09} = 'b01nm3'; % Apr 25 2003  [16:22] adflen = 103.5  MULTI-OBS


for N = 1:length(SESSION),
  if isempty(SESSION{N}),  continue;  end
  %sesdumppar(SESSION{N},'autoplot');
end

for N = 1:length(SESSION),
  if isempty(SESSION{N}),  continue;  end
  %sesgetcln(SESSION{N},'autoplot');
end

for N = 1:length(SESSION),
  if isempty(SESSION{N}),  continue;  end
  %sesgetlfpmuaflt(SESSION{N},'autoplot');
end

for N = 1:length(SESSION),
  if isempty(SESSION{N}),  continue;  end
  %sesgetspk(SESSION{N},'autoplot');
end

for N = 1:length(SESSION),
  if isempty(SESSION{N}),  continue;  end
  sesclnspc(SESSION{N},'autoplot');
end

for N = 1:length(SESSION),
  if isempty(SESSION{N}),  continue;  end
  %sesautoplot(SESSION{N},'autoplot');
  %dspautoplot(SESSION{N});
  %saveas(gcf,'autoplot.fig');
end
