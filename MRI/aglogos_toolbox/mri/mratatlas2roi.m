function mratatlas2roi(varargin)
%MRATATLAS2ROI - Create/Extract ROIs after coregistration.
%  MRATATLAS2ROI(ANZFILE,...)
%  MRATATLAS2ROI(SES,GRPNAME,...) creates/extracts ROIs after coregistation.
%
%  NOTE :
%    - This function calles mratatlas2mng() for manganese experiments.
%    - This function calles mratatlas2ana() for epi experiments.
%
%  REQUITEMENT :
%    SPM, http://www.fil.ion.ucl.ac.uk/spm
%    ATLAS database by AJ Schwarz et. al
%    MUST ACCEPT LICENCE AGREEMENT IN ratBrain_copyright_licence_2007-02-13.doc and README.v5.
%
%  VERSION :
%    0.90 09.03.11 YM  pre-release
%
%  See also mratatlas2ana mratatlas2mng spm_coreg

if nargin == 0,  eval(sprintf('help %s;',mfilename)); return;  end

if subIsAnzfile(varargin{1}),
  % called like mratatlas2roi(anzfile,...)
  mratatlas2ana(varargin{1},varargin{2:end});
else
  Ses = goto(varargin{1});
  if nargin < 2,
    Grp = '';
  else
    Grp = varargin{2};
  end
  if isempty(Grp), Grp = getgrpnames(Ses);  end
  % called like mratatlas2roi(Ses,{Grp1,Grp2,...},...)
  if iscell(Grp),
    for N = 1:length(Grp),
      mratatlas2roi(Ses,Grp{N},varargin{3:end});
    end
    return
  end
  % called like mratatlas2roi(Ses,Grp,...)
  grp = getgrp(Ses,Grp);
  if ismanganese(Ses,grp),
    mratatlas2mng(Ses,grp.name,varargin{3:end});
  else
    mratatlas2ana(Ses,grp.name,varargin{3:end});
  end
end


return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function v = subIsAnzfile(x)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(x),  x = x{1};  end
v = 0;
if ~ischar(x),  return;  end
[fp fr fe] = fileparts(x);
if any(strcmpi(fe,{'.hdr','.img'})),  v = 1;  end

return
