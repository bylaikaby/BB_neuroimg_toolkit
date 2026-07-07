function varargout = matlas2roi(Ses,GrpName,varargin)
%MATLAS2ROI - Coregister the atlas to the given anatomy and make ROIs.
%  MATLAS2ROI(SESSION,GRPNAME,...) coregisters the atlas to the given anatomy and
%  makes ROIs.
%
%  EXAMPLE :
%    >> matlas2roi('rat7e1','spont')
%
%  VERSION :
%    0.90 03.10.11 YM  pre-release
%
%  See also spm_coreg mratatlas2mng mratatlas2ana mrhesusatlas2ana
%           mana2brain mana2epi mroi2roi_coreg mroi2roi_shift

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;   end


Ses = goto(Ses);

if strncmpi(Ses.name,'rat',3),
  if ismanganese(Ses,GrpName),
    mratatlas2mng(Ses,GrpName,varargin{:});
  else
    mratatlas2ana(Ses,GrpName,varargin{:});
  end
else
  mrhesusatlas2ana(Ses,GrpName,varargin{:});
end

return
