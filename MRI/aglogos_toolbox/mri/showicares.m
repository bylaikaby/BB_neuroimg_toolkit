function showicares(varargin)
%SHOWICARES - Shows ICA results for SesName/GrpName/SigName
%
%  NOTE:
%   The parameters for using ICA are defined in the description file.
%  
%  EXAMPLE :
%    >> showicares('b07k81','polarinj1','roiTs');
%    >> showicares('m02lx1','movie1','ClnSpc')
%
%  VERSION :
%    0.90 07.11.07 YM  pre-relese
%
%  See also GETICA DSPICAMRI DSPICACLNSPC

[isica, SigName] = sub_isicasig(varargin{1});

if isica > 0,
  % called like showicares(ICASIG,...)
  switch SigName,
   case {'roiTs','troiTs'}
    dspicamri(varargin{:});
   case {'ClnSpc'}
    dspicaclnspc(varargin{:});
   otherwise
    error('\n ERROR %s: ICA of ''%s'' not supported yet.\n',mfilename,SigName);
  end
else
  % called like showicares(Ses,Grp,SigName,...)
  if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end
  SesName = varargin{1};
  GrpName = varargin{2};
  if isimaging(SesName,GrpName),
    anap = getanap(SesName,GrpName);
    if isfield(anap,'gettrial') & anap.gettrial.status > 0,
      SigName = 'troiTs';
    else
      SigName = 'roiTs';
    end
  else
    SigName = 'ClnSpc';
  end
  if nargin > 2,  SigName = varargin{3};  end
  switch SigName,
   case {'roiTs','troiTs'}
    dspicamri(SesName,GrpName,varargin{4:end});
   case {'ClnSpc'}
    dspicaclnspc(SesName,GrpName,varargin{4:end});
   otherwise
    error('\n ERROR %s: ''%s'' not supported yet.\n',mfilename,SigName);
  end
end


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [isica, signame] = sub_isicasig(SIG)
if length(SIG) > 1,  SIG = SIG(1);  end
if iscell(SIG),  SIG = SIG{1};  end

isica = 0;
if isfield(SIG,'ica') & isfield(SIG.ica,'dat'),
  isica = 1;
end
signame = '';
if isfield(SIG,'dir') & isfield(SIG.dir,'dname'),
  signame = SIG.dir.dname;
end

return
