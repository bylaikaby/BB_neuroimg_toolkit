function batch_corana(SesName)
%BATCH_CORANA - Batch file to run all preprocessing and SESCORANA for fMRI data
% batch_corana(SesName) runs all necessary steps to apply the correlation analysis on fMRI
% data. Models can be stimulus-based or neural-signal based.
%
% NKL 06.01.2006
  
if nargin < 1,
  help batch_corana;
  return;
end;

fprintf('BATCH_CORANA: Running sesareats(%s)...\n',SesName);
sesareats(SesName);

fprintf('BATCH_CORANA: Running sesgettrial(%s)...\n',SesName);
sesgettrial(SesName);

fprintf('BATCH_CORANA: Running sescorana(%s)...\n',SesName);
sescorana(SesName);

fprintf('BATCH_CORANA: Running sesglmana(%s)...\n',SesName);
sesglmana(SesName);

fprintf('BATCH_CORANA: Running sesgrpmake(%s)...\n',SesName);
sesgrpmake(SesName);

fprintf('BATCH_CORANA: Running sesgetmask(%s)...\n',SesName);
sesgetmask(SesName);

if 0,
  glmshow('j04yz1','normo');
  glmshow('j04yz1','mionnorm');
  glmshow('j04yz1','normostim');
  glmshow('j04yz1','hyp6pin');
end;

