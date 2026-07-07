function fix_300604(Ses,EXPS)
% fix folowing things
%
% removes .usr, .grp, .evt, .stm for signals.
% corrects .dx for neural signals.
%


Ses  = goto(Ses);
if nargin < 2, EXPS = validexps(Ses); end

fprintf('fix_300604 : ''%s'', NEXPS=%d\n',Ses.name,length(EXPS));


if exist('SesPar.mat','file'),  delete SesPar.mat;  end
sesdumppar(Ses,EXPS);


return;



for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  grp = getgrp(Ses,ExpNo);
  par = [];
  fprintf(' [%3d]: exp%03d ',N,ExpNo);
  if isimaging(grp),
    % tcImg
    filename = catfilename(Ses,ExpNo,'tcImg');
    if exist(filename,'file'),
      fprintf('tcImg.');
      tcImg = subsigload(filename,'tcImg');
      tcImg = subfix(tcImg,par);
      save(filename,'tcImg');
      clear tcImg;
    end
  end
  if isrecording(grp),
    par = expgetpar(Ses,ExpNo);
    % Cln, ClnSpc
    filename = catfilename(Ses,ExpNo,'Cln');
    if exist(filename,'file'),
      fprintf('Cln.');
      Cln = subsigload(filename,'Cln');
      Cln = subfix(Cln,par);
      save(filename,'Cln');
      clear Cln;
    end
    filename = catfilename(Ses,ExpNo,'ClnSpc');
    if exist(filename,'file'),
      fprintf('ClnSpc.');
      ClnSpc = subsigload(filename,'ClnSpc');
      ClnSpc = subfix(ClnSpc,par);
      save(filename,'ClnSpc');
      clear ClnSpc;
    end
  end
  % others
  filename = catfilename(Ses,ExpNo,'mat');
  if exist(filename,'file'),
    signames = whofile(filename);
    if ~isempty(signames),
      load(filename);
      for K = 1:length(signames),
        fprintf('%s.',signames{K});
        eval(sprintf('%s = subfix(%s,par);',signames{K},signames{K}));
      end
      feval(@save,filename,signames{:});
      feval(@clear,signames{:});
    end
  end
  fprintf(' done.\n');
end

% grouped tcImg
if exist('tcimg.mat','file'),
  fprintf(' tcimg.mat: ');
  filename = 'tcimg.mat';
  signames = whofile(filename);
  if ~isempty(signames),
    load(filename);
    for K = 1:length(signames),
      fprintf('.');
      eval(sprintf('%s = subfix(%s,par);',signames{K},signames{K}));
    end
    feval(@save,filename,signames{:});
    feval(@clear,signames{:});
  end
  fprintf(' done.\n');
end

fprintf('fix_220404 DONE.\n');

    


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = subsigload(fname,SigName)
Sig = load(fname,SigName);
eval(sprintf('Sig = Sig.%s;',SigName));

return;


  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Sig = subfix(Sig,par)
%
%
if isfield(Sig,'usr'),
  if isfield(Sig,'dir') & strcmpi(Sig.dir.dname(1:3),'Cln'),
  else
    Sig = rmfield(Sig,'usr');
  end
end

if isfield(Sig,'grp'),
  Sig = rmfield(Sig,'grp');
end

if isfield(Sig,'evt'),
  Sig = rmfield(Sig,'evt');
end

if isfield(Sig,'stm'),
  Sig = rmfield(Sig,'stm');
end

if ~isfield(Sig,'dir'),  return;  end

if ~isfield(Sig.dir,'dname'), return;  end

switch Sig.dir.dname(1:3),
 case {'Cln','Lfp','pLf','Mua','pMu','Spk','Sdf','Gam',}
  if ~isfield(Sig,'dxorg'),
    Sig.dxorg = Sig.dx;
  end
  Sig.dx = Sig.dxorg * par.adf.tfactor;
end

return;
