clear all;









ses = 'h05272';

%sesesremove(ses); 
%sesclnspc(ses);
sesgetblp(ses);
sesgetspk(ses);

sesgettrial(ses,[],{'ClnSpc','Spkt','Sdf','blp'});
sesesmean(ses)
sesgrpmake(ses,[],{'tClnSpc','tblp','esCln','esblp','esSdf','esSpkt'});









return




%SES{01} = 'e04nm1';  % LGN microstimulation (neurophys) --> 19.07.06  NO RECORD OF ES TIMING

%SES{02} = 'e04nm2';  % LGN microstimulation (neurophys) --> 02.08.06  31-36
SES{03} = 'f04nm1';  % LGN microstimulation (neurophys) --> 08.08.06
SES{04} = 'c03nm1';  % LGN microstimulation (neurophys) --> 10.08.06
% SES{05} = 'e04nm3';  % LGN microstimulation (neurophys) --> 23.08.06
% SES{06} = 'f04nm2';  % LGN microstimulation (neurophys) --> 31.08.06
% SES{07} = 'f05nm1';  % LGN microstimulation (neurophys) --> 05.09.06 (very good)
% SES{08} = 'e04nm4';  % LGN microstimulation (neurophys) --> 07.09.06

% SES{09} = 'd04nm5';  % LGN microstimulation (neurophys) --> 12.09.06
% SES{10} = 'h05nm1';  % LGN microstimulation (neurophys) --> 13.09.06
% SES{11} = 'f04nm3';  % LGN microstimulation (neurophys) --> 14.09.06
% SES{12} = 'e04nm5';  % LGN microstimulation (neurophys) --> 21.09.06
% SES{13} = 'f05nm2';  % LGN microstimulation (neurophys) --> 19.09.06 V2
% SES{14} = 'h05nm2';  % LGN microstimulation (neurophys) --> 26.09.06 V2?
% SES{15} = 'f04nm4';  % LGN microstimulation (neurophys) --> 02.10.06 V2?
% SES{16} = 'f05nm3';  % LGN microstimulation (neurophys) --> 05.10.06 V2


  sesgetblp('e04nm2',31:36);
  sesesmean('e04nm2');
  
  sesgetspk('e04nm2');
  
  sesgettrial('e04nm2');
  
  sesgrpmake('e04nm2');


for N = 1:length(SES),
  if isempty(SES{N}), continue;  end
  SESSION = SES{N};
  goto(SESSION);

  %delete SesPar.mat; sesdumppar(SESSION);
  %delete microstim_timing.mat; sesestimes(SESSION);
  %continue;

  sesgetcln(SESSION);
  sesesremove(SESSION);
  
  sesgetblp(SESSION);
  sesesmean(SESSION);
  
  sesgetspk(SESSION);
  
  sesgettrial(SESSION);
  
  sesgrpmake(SESSION);
  
end
