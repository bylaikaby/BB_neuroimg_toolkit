function grppca(SesName,GrpName,RoiName,Thr)
%GRPPCA - Compute the first 10 PCs of roiTs{RoiName}
% GRPPCA explain....
%
% NKL 01.08.04

if nargin < 4,
  Thr = 0.25;
end;

if nargin < 3,
  RoiName = 'ele';
end;

if nargin < 2,
  help grppca;
  return;
end;

Ses = goto(SesName);
grp = getgrpbyname(Ses,GrpName);

if ~isfield(grp,'actmap'),
  fprintf('GRPPCA: Group %s has no "actmap" field\n', grp.name);
  fprintf('GRPPCA: Edit description file %s\n', Ses.name);
end;

if ~exist(strcat(grp.actmap{1},'.mat'),'file'),
  fprintf('GRPPCA: actmap-group %s dooes not exist\n', grp.actmap{1});
  fprintf('GRPPCA: bproitsmean/bpcorana will run now\n');
  bproitsmean(Ses,grp.actmap{1});
  bpcorana(Ses,grp.actmap{1},Thr,1);
end;

troiTs = sigload(Ses,grp.actmap{1},'troiTs');
if isempty(troiTs),
  fprintf('GRPPCA: Group defined in actmap-field has no troiTs data\n');
  fprintf('GRPPCA: Run BPROITSMEAN(Ses,actmap-group) -- to get average roiTs\n');
  fprintf('GRPPCA: Run BPCORANA(Ses,Grp,0.15,1) - to select voxels\n');
  fprintf('GRPPCA: Then run SESGRPHRF(SesName)\n');
  keyboard
end;

% The trial ROI (troiTs) is a cell array, with each member representin one trial, that is one
% stimulation condition. For the CRA we select the activated voxels on the basis of a control
% group (e.g. polarflash). The selection represents the median map of r-values over different
% trials, and this median is a "common" map for all stimulus conditions.
% Here we check if this is true for the given data:

% FIRST CHECK WHETHER BPCORANA WAS EXECUTED -- to begin with...
if ~isfield(troiTs{1}{1},'origIdx'),
  fprintf('GRPPCA ERROR: No TS were selected; Run GRPCORANA\n');
  keyboard;
end;

% THEN CHECK WHETHER THE "SAMEMAP" OPTION OF BPCORANA WAS USED
if ~all(troiTs{1}{1}.origIdx==troiTs{2}{1}.origIdx),
  fprintf('GRPPCA: For CRA you must run bpcorana(Ses,Grp,0.15,SAMEMAP=1)\n');
  keyboard;
end;

troiTs = troiTs{1};                     % If it is the same, then get the first trial's map
troiTs = mroitsget(troiTs,[],RoiName);
idx = troiTs{1}.origIdx;                % Common mask for all signals
r = troiTs{1}.r{1};                     % and the corresponding r values

EXPS = grp.exps;

fprintf('GRPPCA: Grouping %s: ',GrpName);
for N=1:length(EXPS),
  ExpNo = EXPS(N);
  Sig = sigload(Ses,ExpNo,'roiTs');

  %???????????????? FIX THIS LATER ???????????????????????????????????
  Sig1 = mroitsget(Sig,1,RoiName);
  Sig1{1}.dat = median(Sig1{1}.dat(:,idx),2);
  Sig2 = mroitsget(Sig,2,RoiName);
  Sig2{1}.dat = median(Sig2{1}.dat(:,idx),2);

%  Sig{1}.r{1} = r;
%  Sig{1}.coords = Sig{1}.coords(idx,:);
  
  if N==1,
    oSig = Sig;
  else
    oSig{1}.dat    = cat(3,oSig{1}.dat,Sig{1}.dat);
%    oSig{1}.coords = cat(1,oSig{1}.coords,Sig{1}.coords);
%    oSig{1}.r{1}   = cat(1,oSig{1}.r{1}(:),Sig{1}.r{1}(:));
  end;
  fprintf('.');
end;

if 0,
  % HERE WE GIVE THE CHANCE OF SELECTING VOXELS AGAIN
  % If the user defined threshold is higher than that used by BPCORANA, select...
  rmin = min(abs(oSig{1}.r{1}(find(oSig{1}.r{1}))));
  if abs(Thr) > rmin,
    oSig = mroitssel(oSig,Thr);
  end;
end;

fprintf(' Done!\n');

% NOW GET THE PCs
% pcaTs = matspca(oSig);

signame = sprintf('%sTs', RoiName);
eval(sprintf('%s = oSig;', signame));

% DUMP SELECTED TIME SERIES INTO THE GROUP FILE
filename = strcat(GrpName,'.mat');
fprintf('GRPPCA: saving %s --> %s ...',GrpName,filename);
if exist(filename,'file'),
  save(filename,'-append',signame,'pcaTs');
else
  save(filename,signame,'pcaTs');
end;
fprintf('GRPPCA: Done\n');



  


