function sesconcat(SESSION,GRPNAMES,SIGNAMES,NEWEXPNO,NEWGRPNAME)
%SESCONCAT - concatinate signal(s)
%  SESCONCATINATE(SESSION,GRPNAMES,SIGNAMES,NEWEXPNO) concatinate signal(s).
%  The cancatinated signal will have a prefix of "cat", for an example,
%  "roiTs" becomes "catroiTs"
%
%  EXAMPLE :
%    >> sesconcatinate('d02hv1','visesmix','roiTs')
%    >> sesconcatinate('d02hv1','visesmix','roiTs',31) will concatanate and dump it into a
%    "raw" file corresponding to experiment 31
%
%  VERSION :
%    0.90 18.05.07 YM  pre-release
%
% TODO (URGENT):
%   1. PRESTIM ETC. DOES NOT WORK
%   2. WHEN WE CONCAT TRIALS THEY MUST BE AVERAGABLE... (NEW ROITS SHOULD BE READ FOR GETTRIAL...)
%
%
%  See also SIGLOAD SIGSAVE

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end


if nargin < 2,  GRPNAMES = {};  end
if nargin < 3,  SIGNAMES = {};  end


Ses = goto(SESSION);
if isempty(GRPNAMES),  GRPNAMES = getgrpnames(Ses);  end
if ischar(GRPNAMES),   GRPNAMES = { GRPNAMES };      end
if isempty(SIGNAMES),  SIGNAMES = {'roiTs'};         end
if ischar(SIGNAMES),   SIGNAMES = { SIGNAMES };      end



for G = 1:length(GRPNAMES),
  grp = getgrp(Ses,GRPNAMES{G});
  anap = getanap(Ses,GRPNAMES{G});
  for S = 1:length(SIGNAMES),
    iSigName = SIGNAMES{S};
    oSigName = sprintf('cat%s',iSigName);
    fprintf(' %s(%s): ',grp.name,iSigName);
    oSig = {};
    for iExp = 1:length(grp.exps),
      fprintf('.');
      ExpNo = grp.exps(iExp);
      iSig = sigload(Ses,ExpNo,iSigName);

      if anap.gettrial.status,
        for X=1:length(iSig),
          iSig{X} = iSig{X}{1};     % troiTs will be treated like roiTs
        end;
      end;

      oSig = subConcatinate(oSig,iSig,oSigName);
    end

    if nargin > 3 & isnumeric(NEWEXPNO),
      if ~exist('NEWGRPNAME','var'),
        help sesconcat;
        return;
      end;
      filename = sprintf('%s_%03d.mat',Ses.name,NEWEXPNO); 
      if findstr('roiTs',iSigName),
        SaveName = 'roiTs';
      else
        SaveName = iSigName;
      end;
      if iscell(oSig),
        for N=1:length(oSig),
          oSig{N}.dir.dname = SaveName;
          oSig{N}.grpname = NEWGRPNAME;
          oSig{N}.ExpNo = NEWEXPNO;
        end;
      else
        oSig.dir.dname = SaveName;
        oSig.grpname = NEWGRPNAME;
        oSig.ExpNo = NEWEXPNO;
      end;
      eval(sprintf('%s=oSig;',SaveName));
      clear oSig;
      fprintf('Saving %s in %s...',SaveName,filename);
      
      if exist(filename,'file'),
        save(filename,'-append',SaveName);
      else
        save(filename,SaveName);
      end;
      fprintf('Done!\n');
      fprintf('Updating parameter file...');
      sesdumppar(Ses.name,NEWEXPNO);
      fprintf('Done!\n');
    else
      sigsave(Ses,grp.name,oSigName,oSig);
    end;
  end
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = subConcatinate(oSig,iSig,oSigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(oSig),
  oSig = iSig;
  if iscell(oSig),
    for N = 1:length(oSig),  oSig{N}.dir.dname = oSigName;  end
  else
    oSig.dir.dname = oSigName;
  end
  return;
end

if iscell(iSig),
  for N = 1:length(iSig),
    oSig{N} = subConcatinate(oSig{N},iSig{N},oSigName);
  end
  return;
end

oSig.ExpNo(end+1:end+length(iSig.ExpNo)) = iSig.ExpNo;
oSig.ExpNo = sort(oSig.ExpNo);

switch lower(oSig.dir.dname),
 case {'tcimg','ttcimg','catttcimg'}
  % tcImg.dat as (x,y,z,t)
  TOFFS_SEC = size(oSig.dat,4)*oSig.dx;
  oSig.dat = cat(4,oSig.dat,iSig.dat);
  oSig.dir.dname = 'tcImg';
 otherwise
  % assume 1st dimension as 'time'
  TOFFS_SEC = size(oSig.dat,1)*oSig.dx;
  oSig.dat = cat(1,oSig.dat,iSig.dat);
end

return;

if isfield(oSig,'stm') & ~isempty(oSig.stm),
  if isfield(oSig.stm,'ntrials'),
    oSig.stm.ntrials = oSig.stm.ntrials + iSig.stm.ntrials;
  end
  seli = 1:length(iSig.stm.v{1});
  selo = 1:length(oSig.stm.v{1});
  if isfield(oSig.stm,'tvol'),
    TOFFS_VOL= sum(oSig.stm.tvol{1}(selo));
  end;
  
  oSig.stm.v{1}    = cat(2,oSig.stm.v{1},   iSig.stm.v{1});
  oSig.stm.val{1}  = cat(2,oSig.stm.val{1}, iSig.stm.val{1});
  oSig.stm.dt{1}   = cat(2,oSig.stm.dt{1},  iSig.stm.dt{1});
  oSig.stm.t{1}    = cat(2,oSig.stm.t{1}(selo),   iSig.stm.t{1}(seli) + TOFFS_SEC);
  if isfield(oSig.stm,'tvol'),
    oSig.stm.tvol{1} = cat(2,oSig.stm.tvol{1}(selo),iSig.stm.tvol{1}(seli) + TOFFS_VOL); 
  end;
  oSig.stm.time{1} = cat(2,oSig.stm.time{1}(selo),iSig.stm.time{1}(seli) + TOFFS_SEC);
end
return
