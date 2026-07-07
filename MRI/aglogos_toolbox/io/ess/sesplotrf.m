function sesplotrf(SESSION,GrpNames)
%SESPLOTRF - plots receptive fields (rfp) determined by hand.
%  SESPLOTRF(SESSION,GRPEXP) plots receptive fields (saved as .rfp) determined by hand.
%
%  EXAMPLE :
%    >> sesplotrf('m02lx1','movie1');
%
%  NOTE :
%    .rfp file is required to plot RFs.  It can be set as GRP.xxx.rfpfile, otherwise
%    the program assums (session-name).rfp as default.
%
%
%  VERSION :
%    0.90 16.01.06 YM  pre-release
%
%  See also PLOTRF

  
if nargin < 1,  eval(sprintf('help %s;',mfilename)); return;  end


if ~exist('GrpNames','var'),  GrpNames = {};  end


% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SESSION);
if isempty(GrpNames),
  GrpNames = getgrpnames(Ses);
end

if isnumeric(GrpNames),
  % GrpNames given as exp. number(s)
  GrpNames = getgrpnames(Ses,GrpNames);
end
if ischar(GrpNames),  GrpNames = { GrpNames };  end
GrpNames = unique(GrpNames);



% PLOT hand-plotted RFs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for N = 1:length(GrpNames),
  grp = getgrp(Ses,GrpNames{N});
  par = expgetpar(Ses,grp.exps(1));
  if isfield(par,'rfp') & ~isempty(par.rfp),
    plotRF('RFP',par.rfp);
    tmptxt = sprintf('%s %s: %s',Ses.name,grp.name,par.rfp.file);
    set(gcf,'Name',strrep(tmptxt,'_','\_'));
  else
    %rfpfile = catfilename(Ses,grp.exps(1),'rfp');
    %if exist(rfpfile,'file'),
    %  plotRF('rfpfile',rfpfile);
    %  tmptxt = sprintf('%s %s: %s',Ses.name,grp.name,rfpfile);
    %  set(gcf,'Name',strrep(tmptxt,'_','\_'));
    %else
    %  fprintf('%s: ''%s'' not found.\n',mfilename,rfpfile);
    %  fprintf('%s: Check your GRP.%s.rfpfile in %s.m.\n',mfilename,grp.name,Ses.name);
    %end
    fprintf('%s: no info for receptive fields, %s(%s).\n',mfilename,Ses.name,grp.name);
  end
end




return;

