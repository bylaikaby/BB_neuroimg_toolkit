SESSIONS = {
    'gre.c01',
    'gre.c02',
    'gre.c03',
    'gre.c04',
%    'gre.c05',  % NoChan of adf(5) and eeg(4) is different
    'gre.c06',
    'gre.c07',
    'gre.c08',
    'gre.c09',
    'gre.r25',
    'gre.s03',
%    'gre.s04',
%    'gre.s05',
%    'gre.s06',
    'gre.s07',
%    'gre.s08',
    'gre.s09',
%    'gre.s10',
    'gre.s11',
%    'gre.s12',
%    'gre.s15',
    'gre.s16',
    'gre.s17',
    'gre.s18',
    'gre.s21',
%    'gre.s22',
    'gre.s23',
    'gre.s24',
    'gre.s26',
    'gre.s27'
%    'gre.s28'
     ''      };


DataNeuro = '//Wks20/Data/DataNeuro/GregorData';

% % prints name of EssSystem
% for iSes = 1:length(SESSIONS),
%   if isempty(SESSIONS{iSes}),  continue;  end
%   sesdir = fullfile(DataNeuro,upper(SESSIONS{iSes}));
%   flist = dir(fullfile(sesdir,'*.dgz'));
%   fprintf('%s:',upper(SESSIONS{iSes}));
%   for iFile = 1:length(flist),
%     dgzfile = fullfile(sesdir,flist(iFile).name);
%     dg = dg_read(dgzfile);
%     fprintf(' %s=%s(%s) ',flist(iFile).name,dg.e_pre{1}{2},dg.e_pre{2}{2});
%   end
%   fprintf('\n');
% end

% return

% run grgetcln
for iSes = 1:length(SESSIONS),
  if isempty(SESSIONS{iSes}),  continue;  end
  %par = grLoadEvent(SESSIONS{iSes},1);
  grsesgetcln(SESSIONS{iSes});
end
