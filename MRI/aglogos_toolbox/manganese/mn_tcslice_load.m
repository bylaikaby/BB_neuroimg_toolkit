function [tcImg matfile] = mn_tcslice_load(SESSION,GRPNAME,SLICE,REALIGNED)
%MN_TCSLICE_LOAD - Loads time course of given CORONAL slice.
%  TCIMG = MN_TCSLICE_LOAD(SESSION,GRPNAME,SLICE,[REALIGNED=1]) loads
%  time course of given CORONAL slice as tcImg structure.
%  [TCIMG, MATFILE] = MN_TCSLICE_LOAD(SESSION,GRPNAME,SLICE,[REALIGNED=1]) also
%  loads and returns tcImg in addition to its associated filename.
%
%  EXAMPLE :
%    tcImg = mn_tcslice_load('d03se1','mdeftinj',10);  % load realigned tcImg of slice 10
%    tcImg = mn_tcslice_load('d03se1','mdeftinj',36);  % load tcImg of slice 36
%    mn_tcslice_load('d03se1','mdeftinj',62);          % assign tcImg into "caller" workspace.
%
%
%  VERSION :
%    0.90 16.06.05 YM  pre-release
%    0.91 20.06.05 YM  sets "tcImg.dir.tcimgfile" correctly.
%
%  See also MN_SPM2MAT, ASSIGNIN


if nargin == 0,  help mn_tcslice_load; return;  end

if nargin < 4,  REALIGNED = 1;  end

if REALIGNED > 0,
  DIR_TCSLICE = 'TC_SLICE_REALIGNED';
else
  DIR_TCSLICE = 'TC_SLICE_RAW';
end

Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);


matfile = sprintf('%s_%s_sl%03d.mat',Ses.name,grp.name,SLICE);
matfile = fullfile(pwd,DIR_TCSLICE,matfile);

if exist(matfile,'file') == 0,
  fprintf('\n%s ERROR: ''%s'' not found.\n',mfilename,matfile);
  tcImg = {};
else
  tcImg = load(matfile,'tcImg');
  tcImg = tcImg.tcImg;
  % it is better to update, since this may be used when saving data.
  tcImg.dir.tcimgfile = matfile;
end

if nargout == 0,
  assignin('caller','tcImg',tcImg);
end



return;
