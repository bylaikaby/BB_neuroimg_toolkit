function showautoplot(SESSION)
%SHOWAUTOPLOT - shows autoplot data
% SHOWAUTOPLOT load the autoplot.mat file and displays the data
% in our usual format.

if nargin < 1,
  error('usage: showautoplot(SESSION);');
end;

Ses = goto(SESSION);

if ~exist('autoplot.mat','file'),
  error('AutoPlot.mat file does not exist; Run sesautoplot first\n');
end;

if ~exist('AutoPlotStimuli.mat','file'),
  error('AutoPlotStimuli.mat file does not exist; Run sesautoplot first\n');
end;

load autoplotstimuli;
load autoplot;
dspautoplot;


