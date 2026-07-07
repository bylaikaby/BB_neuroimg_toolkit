function mnimgload(SESSION,EXPS)
%MNIMGLOAD - Load all images of a tracer-session (e.g. MDEFT Anatomy Scans)
% MNIMGLOAD will load all T1-weighted images of a tracer-session as individual files. These
%
% files will be "concatanated" only after the definition of ROIs.
%
% VERSION :
%    1.00 08.07.05 YM  supports o02wu1/wx1.
%    1.01 20.02.11 YM  cleanup/supports "mnimgloadavr".
%
% See also IMGLOAD, IMG_WRITE, MGETTCIMG


Ses = goto(SESSION);

if ~exist('EXPS','var') || isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);

  if isfield(grp,'done') && grp.done,
    fprintf('%s mnimgload [%3d/%d]: ExpNo=%d skipped (grp.done=1).\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
	continue;
  end;
  if isfield(grp,'mnimgloadavr') && ~isempty(grp.mnimgloadavr),
    fprintf('%s mnimgload [%3d/%d]: ExpNo=%d skipped (mnimgloadavr).\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
    continue;
  end
  

  if isimaging(Ses,grp.name),
    fprintf('%s mnimgload [%3d/%d]: ''%s'' ExpNo=%d ScanReco=[%d %d]',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),grp.name,ExpNo,...
            Ses.expp(ExpNo).scanreco(1), Ses.expp(ExpNo).scanreco(2));

    % 02.09.04 YM
    % TO MAKE PERMUTED DATA TO BE COMPATIBLE WITH MROI,
    % NOW GRP.ns1/ns2 is obsolete, use GRP.slicrop instead.
    % GRP.slicrop = [slice-start, slice-SIZE];
    if isfield(Ses.expp(ExpNo),'slicrop') && ~isempty(Ses.expp(ExpNo).slicrop),
      SLICROP = Ses.expp(ExpNo).slicrop;
    else
      if isfield(grp,'slicrop'),
        SLICROP = grp.slicrop;
      else
        SLICROP = [];
      end
    end
    
    if ~isempty(SLICROP),
      ns1 = SLICROP(1);
      ns2 = SLICROP(1) + SLICROP(2) - 1;
      tcImg = DOimgload(Ses,ExpNo,ns1,ns2);
    else
      tcImg = DOimgload(Ses,ExpNo);
    end
    % 17.06.05 YM
    % print outs size of tcImg.dat.
    fprintf(' sz=[%d %d %d %d] saving...',...
            size(tcImg.dat,1),size(tcImg.dat,2),size(tcImg.dat,3),size(tcImg.dat,4));
    % save tcImg
    if sesversion(Ses) >= 2,
      sigsave(Ses,ExpNo,'tcImg',tcImg,'verbose',0);
    else
      if ~exist(fileparts(tcImg.dir.tcimgfile),'dir'),
        [fp,fr,fe] = fileparts(fileparts(tcImg.dir.tcimgfile));
        mkdir(fp,strcat(fr,fe));
      end
      if ~exist(tcImg.dir.tcimgfile,'file'),
        save(tcImg.dir.tcimgfile,'tcImg','-v7.3');
      else
        save(tcImg.dir.tcimgfile,'tcImg','-append','-v7.3');
      end
    end
    fprintf(' done.\n');
  else
    fprintf('%s mnimgload [%d/%d]: ExpNo=%d not imaging.\n',...
            datestr(now,'HH:MM:SS'),N,length(EXPS),ExpNo);
  end;
end;
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OtcImg = DOimgload(SESSION,ExpNo,ns1,ns2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses                 = goto(SESSION);				% Get Session Information
grp                 = getgrp(Ses,ExpNo);
if isfield(Ses.expp(ExpNo),'dirname') && ~isempty(Ses.expp(ExpNo).dirname),
  pvpar             = getpvpars(fullfile(Ses.sysp.DataMri,Ses.expp(ExpNo).dirname),...
                                Ses.expp(ExpNo).scanreco(1),Ses.expp(ExpNo).scanreco(2));
else
  pvpar             = getpvpars(Ses,ExpNo);
end

tcImg.session		= Ses.name;
tcImg.grpname		= grp.name;
tcImg.ExpNo			= ExpNo;

tcImg.dir.dname		= 'tcImg';
tcImg.dir.scantype	= 'MDEFT';
tcImg.dir.scanreco	= Ses.expp(ExpNo).scanreco;
tcImg.dir.imgfile	= expfilename(Ses,ExpNo,'2dseq');
tcImg.dir.evtfile	= 'none';
tcImg.dir.tcimgfile	= sigfilename(Ses,ExpNo,'tcimg');


if length(pvpar.reco.RECO_fov) > 2,
  zres = pvpar.reco.RECO_fov(3)*10/pvpar.nsli;
else
  %zres = mean(pvpar.acqp.ACQ_slice_sepn);
  zres = pvpar.slithk;
end


if isfield(Ses.expp(ExpNo),'imgcrop') && ~isempty(Ses.expp(ExpNo).imgcrop),
  IMGCROP = Ses.expp(ExpNo).imgcrop;
elseif isfield(grp,'imgcrop'),
  IMGCROP = grp.imgcrop;
else
  IMGCROP = [];
end



% DISPLAY
tcImg.dsp.func		= 'dspimg';
tcImg.dsp.args		= {};
tcImg.dsp.label		= {'Readout'; 'Phase Encode'; 'Slice'; 'Time Points'};
tcImg.usr.imgcrop   = IMGCROP;
tcImg.dat           = [];
tcImg.ds			= [pvpar.res zres];
if isfield(grp,'imgtr'),
  tcImg.dx            = grp.imgtr;
else
  fprintf(' %s: tcImg.dx as 1, this is arbitral.\n',mfilename);
  tcImg.dx           = 1;
end
 

%%% ------------------------------------------
%%% READ IMAGE AND PHYSIOLOGY PARAMETERS
%%% ------------------------------------------
nx		= pvpar.nx;
ny		= pvpar.ny;
ns		= pvpar.nsli;
if strcmpi(Ses.name,'j008v2') && strcmpi(grp.name,'mdeftinj'),
  ns		= 140;
end

if ~isempty(IMGCROP),
  x1 = IMGCROP(1);
  x2 = IMGCROP(3) + x1 - 1;
  y1 = IMGCROP(2);
  y2 = IMGCROP(4) + y1 - 1;
else
  x1      = 1;	y1 = 1;
  x2      = nx;	y2 = ny;
end
t1      = 1;
t2      = 1;

if ~exist('ns1','var'),
  ns1 = 1;
end;

if ~exist('ns2','var'),
  ns2 = ns;
end;

if ~exist(tcImg.dir.imgfile,'file'),
  fprintf('File %s does not exist!\n',tcImg.dir.imgfile);
  keyboard;
end;

if strcmpi(pvpar.reco.RECO_byte_order,'bigEndian'),
  img=read2dseq(tcImg.dir.imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'s');
else
  img=read2dseq(tcImg.dir.imgfile,nx,x1,x2,ny,y1,y2,ns,ns1,ns2,t1,t2,'n');
end

tcImg.dat = int16(img);
% for N=size(img,3):-1:1,
%   tcImg.dat(:,:,N) = imresize(img(:,:,N),[128 128]);
% end;


% 02.09.04 YM, permute tcImg.dat
if isfield(grp,'permute') && ~isempty(grp.permute),
  tcImg.dat = permute(tcImg.dat,grp.permute);
  tcImg.ds  = tcImg.ds(grp.permute);
end
if isfield(grp,'flipdim') && ~isempty(grp.flipdim),
  for iDim = 1:length(grp.flipdim),
    tcImg.dat = flipdim(tcImg.dat,grp.flipdim(iDim));
  end
end


if nargout == 1,
  OtcImg = tcImg;
end;

return;


