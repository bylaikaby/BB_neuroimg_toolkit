function [roiTs, Index] = mroitssel(roiTs,THR,IDX,STATNAME,Method,CLUSTERING)
%MROITSSEL - Select TS (columns) on the basis of r-value or p-value
% MROITSSEL(roiTs,THR) is used to select time series from roiTs on the
% basis of the correlation coefficient stored in the .r/.p field.
%
% SESSIONS USED TO DEBUG THIS FUNCTION
% 1. Single Pulses in obsp: K005x1/p2c100
% 2. Multiple Pulses in multitrial-obsp: F01PR1/polarflash
% 3. Variable Contrast Stimuli in the HYPERC experiments, NKL 29.12.2005
%
%
% NKL, 11.04.04
% YM,  01.08.04 supports also 'p' field, use like matsmap(roiTs,thr,[],'p').
% NKL, 13.07.05 selection based on r before averaging
% NKL, 29.12.05 even when selection is done on the basis of the r-value, the p defined in
%               anap.aval is taking into consideration. Namely:
%               idx = find(roiTs{N}.(STATNAME){NM} < anap.aval & ...
%               (abs(roiTs{N}.(STATNAME){NM}) > abs(THR(N))));
% YM,  06.04.06 supports troiTs.
%

if nargin < 1,  help mroitssel; return;  end

[SesName, ExpNo] = mgetroitsinfo(roiTs);
anap = getanap(SesName, ExpNo);

if nargin < 2,
  if ~isfield(anap,'rval'),
    fprintf('MROITSSEL: Cannot find the "rval" field in ANAP.\n');
    fprintf('MROITSSEL: Edit the description file (see for example J04vy1\n');
    keyboard;
  end;
  THR = anap.rval;
end;

if nargin < 3,  IDX = [];        end;
if nargin < 4,  STATNAME = 'r';  end
if nargin < 5,  Method = 'mean'; end;

if nargin < 6,
  if ~isfield(anap,'clustering'),
    fprintf('MROITSSEL: Cannot find the "clustering" field in ANAP.\n');
    fprintf('MROITSSEL: Edit the description file (see for example J04vy1\n');
    keyboard;
  end;
  CLUSTERING = anap.clustering;
end;

if ~iscell(roiTs),
  fprintf('mroitssel: expects a CELL ARRAY input\n');
  return;
end;


if iscell(roiTs{1}),
  % roiTs as troiTs
  for R = 1:length(roiTs),
    for T = 1:length(roiTs{R}),
      tmpTs = { roiTs{R}{T} };
      [tmpTs tmpidx] = mroitssel(tmpTs,THR,IDX,STATNAME,Method,CLUSTERING);
      roiTs{R}{T} = tmpTs{1};
      Index{R}{T} = tmpidx{1};
    end
  end
  return;
end



if strcmpi(STATNAME,'r') && ~isfield(roiTs{1},'r'),
  fprintf('mroitssel: expects an "r" field in roiTs\n');
  return;
end;
if strcmpi(STATNAME,'p') && ~isfield(roiTs{1},'p'),
  fprintf('mroitssel: expects an "p" field in roiTs\n');
  return;
end;

if length(THR) == 1,
  THR = repmat(THR,[1,length(roiTs)]);
end

% Default stastics-related flags
% anap.aval = 0.05;
% anap.bonferroni = 1;

for N=1:length(roiTs),

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SELECT TIME COURSES
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if isempty(IDX),
    % SELECT TIME COURSE ON THE BASIS OF STATISTICS
    % NKL 13.07.2005: roiTs.dat 256x200x10 (256 points, in 200 voxels, in 10 repetitions
    % roiTs.r{1} 200x10 (200 r values, in 10 repetitions of the stimulus)
    % To select the best from each repetition we avoid averaging;  instead select r values
    % after reshaping the array into: roiTs.dat (256x(200*10)) and roiTs.r{1} 256*200
    % This operation preservest the correspondence of time-course to r-value
    %
    if 0,
      s = size(roiTs{N}.dat);
      roiTs{N}.dat = reshape(roiTs{N}.dat,[s(1) prod(s(2:end))]);
      roiTs{N}.coords = permute(roiTs{N}.coords,[3 1 2]);
      s = size(roiTs{N}.coords);
      roiTs{N}.coords = reshape(roiTs{N}.coords,[s(1)*s(2) s(3)]);
    end;

    for M=1:length(roiTs{N}.(STATNAME)), % Mulitple models; % Reshape stat arrays
      s = size(roiTs{N}.(STATNAME){M});
      roiTs{N}.(STATNAME){M} = reshape(roiTs{N}.(STATNAME){M},[s(1)*s(2) 1]);
      if isfield(roiTs{N},'p'), roiTs{N}.p{M} = reshape(roiTs{N}.p{M},[s(1)*s(2) 1]); end;
      
      cval = anap.aval;
      if anap.bonferroni,
        cval = anap.aval / length(roiTs{N}.p{M});
      end;

      if strcmpi(STATNAME,'r'),
        idx = find(roiTs{N}.p{M} < cval & roiTs{N}.(STATNAME){M} > THR(N));
      else
        idx = find(roiTs{N}.(STATNAME){M} < cval);
      end;
      
      % NOW GET RID OF VOXELS BELOW THRESHOLD
      dat{M} = roiTs{N}.dat(:,idx);
      coords{M} = roiTs{N}.coords(idx(:),:);
      statname{M} = roiTs{N}.(STATNAME){M}(idx);
      if isfield(roiTs{N},'p'), p{M} = roiTs{N}.p{M}(idx); end;
      
      % APPLY CLUSTER ANALYSIS ONLY IF SELECTION IS DONE DI NUOVO
      % Check again as there is not quaranty we found modulation...
      % NOTE: DO NOT APPLY CUSTERDETECTION FOR TOO SMALL NUMBER OF VOXELS
      if all(CLUSTERING > 0) & ~isempty(idx) & length(idx)>=10,
        % AND ALSO OF VOXELS THAT ARE ISOLATED
        % The function returns the valid coordinates and the selection index that we'll use to
        % trim the data and the r values.
        if isempty(CLUSTERING) | length(CLUSTERING)==1,
          CLUSTERING = [8 20];
        end
        [coords{M}, idx] = mcluster3(coords{M},CLUSTERING(1),CLUSTERING(2));
        statname{M} = statname{M}(idx);
        if isfield(roiTs{N},'p'),
          p{M} = p{M}(idx);
        end;
        dat{M} = dat{M}(:,idx);
      end
    
      if nargout > 1,
        for M=1:length(roiTs{N}.(STATNAME)), % Mulitple models
          Index{N}{M} = idx;
        end;
      end;
    end;
    roiTs{N}.dat = dat;
    roiTs{N}.coords = coords;
    roiTs{N}.(STATNAME) = statname;
    if isfield(roiTs{N},'p'), roiTs{N}.p = p; end;
    
  else
    % USE INDEX FROM OTHER SELECTION (SEE FOR EXAMPLE FLSHOWGRP)
    % SEE ALSO MULREGRESS

    for M=1:length(roiTs{N}.(STATNAME)), % Mulitple models; % Reshape stat arrays
      s = size(roiTs{N}.(STATNAME){M});
      roiTs{N}.(STATNAME){M} = reshape(roiTs{N}.(STATNAME){M},[s(1)*s(2) 1]);
      if isfield(roiTs{N},'p'), roiTs{N}.p{M} = reshape(roiTs{N}.p{M},[s(1)*s(2) 1]); end;
      idx = IDX{N}{M};

      % NOW GET RID OF VOXELS BELOW THRESHOLD
      dat{M} = roiTs{N}.dat(:,idx);
      coords{M} = roiTs{N}.coords(idx(:),:);
      statname{M} = roiTs{N}.(STATNAME){M}(idx);
      if isfield(roiTs{N},'p'), p{M} = roiTs{N}.p{M}(idx); end;
      
      if CLUSTERING & ~isempty(idx) & length(idx)>=10,
        if isempty(CLUSTERING) | length(CLUSTERING)==1,
          CLUSTERING = [5 13];
        end
        [coords{M}, idx] = mcluster3(coords{M},CLUSTERING(1),CLUSTERING(2));
        statname{M} = statname{M}(idx);
        if isfield(roiTs{N},'p'),
          p{M} = p{M}(idx);
        end;
        dat{M} = dat{M}(:,idx);
      end
    end;    
    roiTs{N}.dat = dat;
    roiTs{N}.coords = coords;
    roiTs{N}.(STATNAME) = statname;
    if isfield(roiTs{N},'p'), roiTs{N}.p = p; end;
  end;
  
end;

