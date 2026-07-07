function sescormrineu(SESSION,varargin)
%SESCORMRINEU - compute xcor with neural models
% SESCORMRINEU (SESSION) - uses LFP/MUA signals and convolution to
% create a model for voxel selection.

Ses = goto(SESSION);

if ~isfield(Ses,'ImgGrps'),
  fprintf('Ses.ImgGrps field was not found; see m02lx1 and edit..\n');
  return;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IT ASSUMES THAT SPONTANEOUS ACTIVITY IS A L W A Y S AT THE END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N=1:length(Ses.ImgGrps),
  mgrpcormrineu(Ses,Ses.ImgGrps{N}{2});
end;

