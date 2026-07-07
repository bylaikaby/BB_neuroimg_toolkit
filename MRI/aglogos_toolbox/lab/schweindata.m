%AXELPLOT - read Axel's xls file and plot data.
%  USAGE :
%   AXELPLOT(XLSFILE)         % plot data %   DAT = AXELPLOT(XLSFILE)   % read data %
%  AXELPLOT(XLSFILE) will read "sheet3" of XLSFILE.
%  'sheet3' must have a numeric matrix, 1st raw as frequency, 1st column as distance.
%
%  TESTED WITH 
%	saline_test01.xls, saline_test02.xls
%   schwein_02.xls, schwein_03.xls
%   schwein_01_sprung_korrektur.xls
%
%  VERSION :
%    02.05.05 YM  pre-release
%
%  See also XLSREAD

if nargin == 0,  help axelplot; return;  end
  

XLS_DIR = 'L:/projects/yusuke/axel';

[DATA,DISTANCE,FREQ] = subGetAxelData(xlsfile,XLS_DIR); if isempty(FREQ),
  return;
end

if nargout == 0,
  h = subPlotAxelData(xlsfile,DISTANCE,FREQ,DATA); else
  Axel.file = xlsfile;
  Axel.dat  = DATA;
  Axel.dist = DISTANCE;
  Axel.freq = FREQ;
  varargout{1} = Axel;
end
return;


% READ EXEL FILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DATA,DISTANCE,FREQ] = subGetAxelData(xlsfile,XLS_DIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DATA = [];  DISTANCE = [];  FREQ = [];

[fp,fr,fe] = fileparts(xlsfile);
% if full-path, then use it ignoring XLS_DIR.
if ~isempty(fp),
  XLS_DIR = fp;
end

xlsfile = fullfile(XLS_DIR,strcat(fr,fe)); if ~exist(xlsfile,'file'),
  fprintf(' %s: ''%s'' not found.\n',mfilename,xlsfile);
  return;
end


if str2num(version('-release')) >= 14,
  [num,txt,raw] = xlsread(xlsfile,'sheet3'); else
  [num,txt] = xlsread(xlsfile,'sheet3'); end

if isempty(num),
  fprintf(' %s: no data in ''sheet3'' of %s.\n',mfilename,xlsfile);
  fprintf(' %s: Please cut/paste from ''sheet1'', 1st raw as frequency, 1st column as distance.\n',mfilename);
  return;
else
  FREQ = num(1,2:end); 
  DISTANCE = num(2:end,1);
  DATA = num(2:end,2:end);
end

% remove NaN if exist
nanidx = find(isnan(FREQ));
if ~isempty(nanidx),
  FREQ(nanidx) = [];
  DATA(:,nanidx) = [];
end
nanidx = find(isnan(DISTANCE));
if ~isempty(nanidx),
  DISTANCE(nanidx) = [];
  DATA(nanidx,:) = [];
end

DISTANCE = DISTANCE(:)';
FREQ     = FREQ(:)';
return;


% PLOT AXEL DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Hfig = subPlotAxelData(xlsfile,DISTANCE,FREQ,DATA);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fp,fr,fe] = fileparts(xlsfile);  xlsfile = strcat(fr,fe);

Hfig = figure('Name',xlsfile,...
              'DefaultAxesFontName','Comic Sans MS',...
              'DefaultAxesFontSize',10,...
              'DefaultAxesFontWeight','bold',...
              'PaperType','A4', 'PaperOrientation','landscape',...
              'BackingStore','on', 'DoubleBuffer','on',...
              'InverthardCopy','on');


surf(DISTANCE,FREQ,DATA');%,'linestyle','none'); %shading interp;
grid on;

set(gca,'ylim',[min([10 min(FREQ)]) max(FREQ)],...
        'ydir', 'reverse',  'yscale','log'); set(gca,'xlim',[0 max(DISTANCE)], 'xdir', 'reverse');

title(strrep(xlsfile,'_','\_'));
xlabel('Distance in mm');
ylabel('Frequency in Hz');
zlabel('Pk-Pk Amplitude in mV');
h = colorbar;
set(h,'pos',[0.83  0.6000  0.03 0.33],'units','normalized');
return;

