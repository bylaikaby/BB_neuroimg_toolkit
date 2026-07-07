function oSig = gettrial(Sig)
%GETTRIAL - Split observation period in trials and return average response per trial.
% GETTRIAL splits observation periods including repetition of a stimulus condition. The
% function will average the trial responses and will return the mean of the responses.
%
% NOTE: GLM analysis may run by examining responses only during one of the trials and
% subsequently selecting the time series of the other conditions by using the same voxel
% map.
%
% Sessions may have groups with trials and groups with continuous observation periods
% (e.g. spontaneous activity, hyperc experiments, etc.). SESGETTRIAL examines the field 
% GRP.normo.anap.gettrial.status; If it's 1, then gettrial is called.
%
% The sorting parameter (trial or stim) is defined by
% GRPP.glm(1).sort = 'trial';
% And the trial to be used for analysis by
% GRPP.glm(1).selsort = 5;
%
%
% TO DEBUG:
%   n03qv1/1        Mutliple same trials in obsp
%   n03qv1/81       Mutliple different trials in obsp
%   m02lx1/1        No trials
%  
% See also SESGETTRIAL XFORM
%  
% NKL 20.07.04
  
if nargin < 1,
  help gettrial;
  return;
end;

if isstruct(Sig),
  SesName = Sig.session;
  GrpName = Sig.grpname;
  ExpNo = Sig.ExpNo(1);     % NKL: Use ExpNo(1) in case we have a group file
else
  SesName = Sig{1}.session;
  GrpName = Sig{1}.grpname;
  ExpNo = Sig{1}.ExpNo(1);
end;

Ses = goto(SesName);
grp = getgrpbyname(Ses, GrpName);
anap = getanap(Ses,ExpNo);

% Do not split in trials if status is zero!
if ~anap.gettrial.status,
  fprintf('Group %s has no trials; Skipping...\n', grp.name);
  oSig = {};
  return;
end;

if isstruct(Sig),
  % If it's a structure (e.g. blp) convert to 1D cell-array
  % In the end of the function 1D arrays will become a structure again
  signame = Sig.dir.dname;
  info = Sig.info;
  Sig = {Sig};
else
  signame = Sig{1}.dir.dname;
  info = Sig{1}.info;
end;

% GET SORT-PARAMETERS
pars = getsortpars(Ses,ExpNo);

DIM=ndims(Sig{1}.dat)+1;

for ModelNo=1:length(Sig),                % For all signals (e.g. roiTs with many ROIs)

  tmp = sigsort(Sig{ModelNo},pars.trial);
  
  % sigsort will return a structure if the obsp has always the same trial
  % In this case the .dat field is extended to DIM (ndims+1) to include the individual trials.
  if isstruct(tmp),
    tmp = {tmp};
  end;

  % N=TrialNO
  for N=1:length(tmp),                                          % e.g. model-no
    if strcmp(anap.gettrial.Xmethod,'none'),
      oSig{ModelNo}{N} = tmp{N};
    else
      oSig{ModelNo}{N} = xform(tmp{N},anap.gettrial.Xmethod,anap.gettrial.Xepoch);
    end;
      
    oSig{ModelNo}{N}.dir.dname    = sprintf('t%s',Sig{1}.dir.dname);

    if strcmp(Sig{1}.dir.dname,'blp'),
      oSig{ModelNo}{N}.dsp.func     = 'dsptblp';
    else
      oSig{ModelNo}{N}.dsp.func     = 'dspglmts';
    end;

    % We average multiple occurrences of the same trial
    % The dimension DIM is one-more than the unsorted signal's dimension!
    oSig{ModelNo}{N}.dat          = hnanmean(oSig{ModelNo}{N}.dat,DIM);

    % And we update the info-structure, so the user knows when was the last modification and
    % what exactly it was
    oSig{ModelNo}{N}              = sigupdate(oSig{ModelNo}{N});

    if ~isfield(anap.gettrial,'Convolve'),
      fprintf('The Ses.anap.gettrial structure should be edited in descr. file\n');
      keyboard;
    end;

    % If the signal is a neuro-signal, then convolve to generate regressors for fMRI but
    % also keep the original data for neural analysis
    if strcmp(Sig{ModelNo}.dir.dname,'blp'),

      if anap.gettrial.Convolve,
        tmpsig = oSig{ModelNo}{N};
        tmpsig = xform(tmpsig,anap.gettrial.Xmethod,anap.gettrial.Xepoch);
        oSig{ModelNo}{N}.org = tmpsig.dat;
        oSig{ModelNo}{N} = sigconv(oSig{ModelNo}{N});
      end
      
      if anap.gettrial.newFs,
        oSig{ModelNo}{N}.orgdx = oSig{ModelNo}{N}.dx;
        oSig{ModelNo}{N} = sigresample(oSig{ModelNo}{N},anap.gettrial.newFs);
      end;
    
    end;
    
  end;
end;

% If it's a neural-signal, then 1D cells should be converted into structures
% roiTs (where the first dimensions is model-number) should remain cell arrays for
% compatibility with all our functions, even if only one model exists...
if strcmp(Sig{1}.dir.dname,'blp'),
  if length(oSig) == 1,
    oSig = oSig{1};
  end;
end;
return;

