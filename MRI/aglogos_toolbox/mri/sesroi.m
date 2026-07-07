function sesroi(SesName,Mode)
%SESROI - Generate the regions of interest (ROIs) used for analysis
% SESROI (SesName) - Invokes MROI for interactive definition of the
% ROIs, whose names are specified in Ses.roi.names.
%
% SESROI (SesName, Mode) - permits the definition of operation
% mode. Valid operation modes are:
%
% Mode == 'getroi' equivalent to SESROI (Sesname)
%
% Mode == 'update' invokes mcorana and logially "ANDs" the
%           correlation maps with the existing ROIs. SESROI will
%           append new structures in Roi.mat, each bearing the name of
%           a reference group (see HROI for details). SESROI can only
%           be used in the 'update' mode if the ROIs have already been
%           created by means of a SESROI(SesName) call.
%
% Mode ==  'reset' will remove any additional groups from the
%           Roi.mat file, which were created by the 'update' mode.
%
% NKL 16.04.04

if nargin < 1,
  help sesroi;
  return;
end;

if nargin < 2,
  Mode = 'getroi';
end;

Ses = goto(SesName);
switch Mode,
 case 'getroi',
  mroi(SesName);
 case 'update',
  if ~exist('Roi.mat','file'),
    fprintf('SESROI: Roi.mat not found\n');
    help sesroi;
    return;
  end;
  actmap = getactmap(Ses);  % Get all groups with distinct actmap
  for GrpNo = 1:length(actmap),
    xcor{GrpNo} = mcorana(Ses, actmap{GrpNo}{1}, actmap{GrpNo}{2});
  end;
  mroiupdate(Ses, xcor);
 case 'reset',
  mroireset(Ses);
 otherwise,
  fprintf('SESROI: Unknown Operation Mode\n');
  help sesroi;
end;
return;

