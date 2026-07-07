function batch_update_grpname(ses,gnames,varargin)
%BATCH_UPDATE_GRPNAME - Update grpname of Cln/blp/mblp/Sdf/Spkt/tcImg/roiTs/froiTs/mfroiTs.
%   batch_update_grpname(ses) updates grpname of Cln/blp/mblp/Sdf/Spkt/tcImg/roiTs/froiTs/mfroiTs.
%
%  EXAMPLE :
%    >> update_grpname('F12m04');          % updates espont/fspont/spont1/spont2/vspont
%    >> update_grpname('E10gv1','vspont')  % updates vspont
%
%  VERSION :
%    0.90 01.06.2017 YM  pre-release
%    0.91 02.06.2017 YM  use siginfo() without loading all data field.
%    0.92 05.06.2017 YM  accepts 'gnames' as the 2nd arg.
%    0.93 16.09.2017 YM  updates '.session' also.
%
%  See also siginfo

if nargin == 0,  eval(['help ' mfilename]); return;  end

if nargin < 2,  gnames = {};  end


SigNames = {'Cln', 'blp', 'Sdf', 'Spkt', 'mblp', ...
            'tcImg', 'roiTs', 'froiTs' 'mfroiTs' };
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'sig' 'sigs' 'signame' 'signames'}
    SigNames = varargin{N+1};
  end
end
if ischar(SigNames),  SigNames = { SigNames };  end




ses = getses(ses);

if isempty(gnames)
  % automatically updates if  espont/fspont/spont1/spont2/vspont/ephys
  gnames = getgrpnames(ses);
  for G = 1:length(gnames)
    switch lower(gnames{G})
     case {'espont' 'fspont' 'vspont'...
           'spont' 'spont1' 'spont2' 'spont3' 'spont4' 'spont5' ...
           'ephys' 'ephys1' 'ephys2' 'ephys3' 'ephys4' 'ephys5' }
      update_siggrpname(ses,gnames{G},'sigs',SigNames)
    end
  end
else
  % updates the given grpname(s)
  if ~iscell(gnames),  gnames = { gnames };  end
  for G = 1:length(gnames)
    update_siggrpname(ses,gnames{G},'sigs',SigNames)
  end
end

return

function update_siggrpname(Ses,GrpName,varargin)
%
%  EXAMPLE :
%    >> update_signame('F12m04','fspont')
%
%  VERSION :
%    0.90 01.06.2017 YM  pre-release
%
%  See also


SigNames = {'Cln', 'blp', 'Sdf', 'Spkt', 'mblp', ...
            'tcImg', 'roiTs', 'froiTs' 'mfroiTs' };
for N = 1:2:length(varargin)
  switch lower(varargin{N})
   case {'sig' 'sigs' 'signame' 'signames'}
    SigNames = varargin{N+1};
  end
end
if ischar(SigNames),  SigNames = { SigNames };  end



Ses = goto(Ses);
grp = getgrp(Ses,GrpName);
exps = grp.exps;



% should accept the session with a single var in a single matfile.
if sesversion(Ses) < 2
  error('ERROR %s: sesversion=1 is not supported\n');
end


for D = 1:length(SigNames)
  vname = SigNames{D};
  fprintf('%s %s %s %s ----------------------------\n',mfilename,Ses.name,grp.name,vname);
  for E = 1:length(exps)
    ExpNo = exps(E);
    matfile = sigfilename(Ses,ExpNo,vname);
    if ~exist(matfile,'file'),  continue;  end
    matvars = whos('-file',matfile);
    if length(matvars) == 1
      fprintf(' %3d/%d %s %s(exp=%d): check.',E,length(exps),Ses.name,vname,ExpNo);
      sinfo = siginfo(Ses,ExpNo,vname);
      if strcmpi(sinfo.grpname,grp.name) && strcmpi(sinfo.session,Ses.name)
        fprintf(' ok (no update).\n');
        continue;
      end
      %fprintf(' to be processed\n');  continue;  % for debug without load/save...
      fprintf(' load.');
      var = load(matfile,vname);
      var = var.(vname);
      DO_SAVE = 0;
      if iscell(var)
        for N = 1:length(var)
          var{N}.session = Ses.name;
          var{N}.grpname = grp.name;
          DO_SAVE = 1;
        end
      else
        for N = 1:length(var)
          var(N).session = Ses.name;
          var(N).grpname = grp.name;
          DO_SAVE = 1;
        end
      end
      if any(DO_SAVE)
        fprintf(' saving.');
        eval([vname '=var;']);
        save(matfile,vname,'-v7.3');
        eval(['clear ' vname]);
      end
      fprintf(' done.\n');
    end
  end
end

return
