function atconvert(SESSION,ExpNo)
%ATCONVERT - Convert the data collected by Andreas Tolias
% ATCONVERT converts the spikes, lfps and tetrode raw signals into
% Lfp, Spkt/Sdf and Cln structures and saves them into mat files.
%
% NOTES:
% The Spkt/Sdf structures have the data of one well-isolated cell
% as a single channel. To run coherence or kc analysis we can treat
% all channels having the same distance intraD.
% The Spkt can be a cell array, indicating the existence of
% multiple tetrodes. In such case the inter-tetrode distance must
% be calculated by knowing the grid used in the experiments. A
% function is needed to generate the pairs to examine (atgetpairs)
% and the distance between each of them (atgetdist).
% Cln needs only atgetpairs (intratetrode distance is intraD)
% Lfp needs atgetpairs and atgetdist
% NKL 12.10.03

if ~nargin,
  SESSION = 'd98at1';
  ExpNo = 1;
end;

if nargin & nargin < 2,
  error('usage: atconvert(SESSION,ExpNo);');
end;

Ses = goto(SESSION);
fprintf(' %s atconvert: Processing ExpNo=%d, file %s\n',...
		getTimeString, ExpNo, catfilename(Ses,ExpNo,'mat'));
clnfilename = catfilename(Ses,ExpNo,'cln');
neufilename = catfilename(Ses,ExpNo,'atphys');
filename = catfilename(Ses,ExpNo,'mat');
sigs = feval('who','-file',neufilename);

% WIRE-DATA LIKE OUR Cln; SAVE IN SesDir/CLNDATA
if any(strcmp(sigs,'tet'))
  fprintf('atconvert: found/processing "tet" in %s\n',clnfilename);
  atgetcln(Ses,ExpNo);
end;

% atSdf and muaSdf saved in SesDir
if any(strcmp(sigs,'res')),
  fprintf('atconvert: found/processing "res" in %s\n',filename);
  atgetspikes(Ses,ExpNo);
end;

if any(strcmp(sigs,'muares')),
  fprintf('atconvert: found/processing "muares" in %s\n',filename);
  atgetmuares(Ses,ExpNo);
end;

% LFPs
if any(strcmp(sigs,'lfp')),
  fprintf('atconvert: found/processing "lfp" in %s\n',filename);
  atgetlfp(Ses,ExpNo);
end;

