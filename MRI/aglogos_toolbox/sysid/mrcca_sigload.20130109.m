function [roits mdlts] = mrcca_sigload(Ses,GrpExp,varargin)
%MRCCA_SIGLOAD - Loads MRI(roiTs) and model signals.
%  [ROITS MDLTS] = mrcca_sigload(SESSION,GRP/EXP,...) loads MRI(roiTs) and
%  model signals.
%
%  Supported options are
%    MriSig     : 'roiTs' or else
%    RoiName    : roi selection for roits
%    ResampleHz : 'bold', 'blp' or any numeric number in Hz
%    MriNorm    : normalization
%
%  EXAMPLE :
%    [roits mdlts] = mrcca_sigload('e10ha1',6,'mrisig','roiTs','roi',{'hp'})
%
%  VERSION :
%    0.90 08.01.13 YM  pre-release
%
%  See also sigload expmrcca expmrcca_cv



MriSig     = 'roiTs';
ResampleHz = 'bold';

RoiName    = 'all';
MriNorm    = 'zscore';
VERBOSE    = 0;

for N = 1:2:length(varargin),
  switch lower(varargin{N}),
   case {'roi','roiname','roinames'}
    RoiName = varargin{N+1};
   case {'resample','resamplehz'}
    ResampleHz = varargin{N+1};
   case {'mrisig', 'mri'}
    MriSig = varargin{N+1};
   case {'mrinorm'}
    MriNorm = varargin{N+1};
  end
end

if isempty(MriNorm),  MriNorm = 'none';  end

if ischar(RoiName),  RoiName = { RoiName };  end


% GET BASIC INFO
Ses = goto(Ses);
grp = getgrp(Ses,GrpExp);
anap = getanap(Ses,GrpExp);

roits = {};
mdlts = [];


fprintf(' loading(%s)...', MriSig);
roits = sigload(Ses,GrpExp,MriSig);


for N = 1:length(RoiName)
  if any(strfind(RoiName{N},'.mat')),
    tmpts = load(RoiName{N},'model');
    tmpts = tmpts.model;
  else
    tmpts = mvoxselect(roits,RoiName{N},'none',[],1.0);
    tmpts.dat = nanmean(tmpts.dat,2);
  end
  if isempty(tmpts) || isempty(tmpts.dat),  continue;  end
  if isempty(mdlts)
    mdlts = tmpts;
    mdlts.name = { RoiName{N} };
  else
    mdlts.dat  = cat(2,mdlts.dat,tmpts.dat);
    mdlts.name = cat(2,mdlts.name,RoiName{N});
  end
end
clear tmpts;

% a cell array to sturcture
roits = mvoxselect(roits,'all',  'none',[],1.0);


if ischar(ResampleHz),
  switch lower(ResampleHz),
   case {'mri','bold','roits'}
    if ~isempty(mdlts) && mdlts.dx ~= roits.dx,
      if VERBOSE,  fprintf(' resampling(%gHz).',1/roits.dx);  end
      mdlts = sigresample(mdlts,roits.dx);
    end
   case {'mdl' 'model'}
    if ~isempty(roits) && mdlts.dx ~= roits.dx,
      if VERBOSE,  fprintf(' resampling(%gHz).',1/mdlts.dx);    end
      roits = sigresample(roits,mdlts.dx);
    end
   otherwise
    ResampleHz = [];
  end
elseif isnumeric(ResampleHz) && any(ResampleHz),
  if VERBOSE,
    fprintf(' resampling(%gHz).',ResampleHz);
  end
  if ~isempty(mdlts),
    % = sigresample(mdlts,1/ResampleHz);
    mdlts = siginterp1(mdlts,1/ResampleHz);
  end
  if ~isempty(roits),
    %roits = sigresample(roits,1/ResampleHz);
    roits = siginterp1(roits,1/ResampleHz);
  end
end



switch lower(MriNorm)
 case {'zscore'}
  fprintf(' MriNorm(%s)...', MriNorm);
  roits.dat = zscore(roits.dat);
  mdlts.dat = zscore(mdlts.dat);
end


return
