function mnglmana(SESSION,GRPNAME,varargin)
%MNGLMANA - Runs glm analysis for manganese experiment.
%  MNGLMANA(SESSION)
%  MNGLMANA(SESSION,GRPNAME) runs glm analysis for managnese experiment.
%
%  EXAMPLE :
%    >> mnglmana('rat361','mdeftinj','models',{'Mn_Inj'},'normalize','CPu');
%
%  VERSION :
%    0.90 18.01.06 YM  pre-release
%    0.91 12.09.10 YM  calls mnregress()
%
%  See also MNREGRESS MNCORANA MVIEW SESGLMANA

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if nargin < 2,  GRPNAME = {};  end

MODELS = {};
DO_NORMALIZE = 'global';


Ses = goto(SESSION);
grp = getgrp(Ses,GRPNAME);
anap = getanap(Ses,grp);
if isfield(anap,'mnglmana'),
  if isfield(anap.mnglmana,'models')
    MODELS = anap.mnglmana.models;
  end
  if isfield(anap.mnglmana,'normalize'),
    DO_NORMALIZE = anap.mnglmana.normalize;
  end
end


for N = 1:2:length(varargin),
  switch lower(varargin{N})
   case {'normalize','norm','normalization'}
    DO_NORMALIZE = varargin{N+1};
   case {'model','models'}
    MODELS = varargin{N+1};
  end
end



fprintf('MNGLMANA: Session %s, Group %s\n', Ses.name,grp.name);

mnregress(Ses,grp,MODELS,'normalize',DO_NORMALIZE);


return;
