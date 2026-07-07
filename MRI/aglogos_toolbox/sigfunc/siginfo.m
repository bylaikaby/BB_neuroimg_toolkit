function INFO = siginfo(varargin)
%SIGINFO - Get signal's information
%  INFO = SIGINFO(Sig) 
%  INFO = SIGINFO(Ses,Exp,SigName) gets signal's information.
%
%  NOTE :
%   -If 'Sig' is a cell/struct array, then this function retunrs
%    information only about the first element.
%   -Size of Sig.dat is given as INFO.datsize.
%
%  EXAMPLE :
%    tcImg = sigload('E10ea1',1,'tcImg');
%    x = siginfo(tcImg)
%    x = sigfinfo(Ses,Exp,SigName)
%
%  VERSION :
%    0.90 15.04.13 YM  pre-release
%    0.91 07.06.13 YM  supports reading from the HDF5 file.
%
%  See also issig signame h5mat_sig1info

if nargin == 0,  help siginfo; return;  end

% required fields
fields = { 'session' 'grpname' 'ExpNo' 'exps' ...
           'dx' 'dxorg' 'dat' ...
           'ds' 'ana' 'name' 'coords' ...
           'info' };


if issig(varargin{1})
  % called like siginfo(Sig)
  INFO = sub_sig(varargin{1},fields);
else
  % called like siginfo(Ses,Exp,SigName)
  INFO = h5mat_sig1info(varargin{:},'fields',fields);
end
return

% -----------------------------------------------------------
function INFO = sub_sig(Sig,FIELDS)
% -----------------------------------------------------------

INFO = [];

if isempty(Sig),  return;  end

if iscell(Sig),
  INFO = siginfo(Sig{1},FIELDS);
  return;
end

Sig = Sig(1);

INFO.signame = '';
INFO.session = '';
INFO.grpname = '';
INFO.ExpNo   = [];


for N = 1:length(FIELDS)
  tmpf = FIELDS{N};
  if isfield(Sig,tmpf)
    if strcmpi(tmpf,'dat')
      INFO.datsize = size(Sig.dat);
    else
      INFO.(tmpf) = Sig.(tmpf);
    end
  end
end


if isfield(Sig,'dir') && isfield(Sig.dir,'dname'),
  INFO.signame = Sig.dir.dname;
end


% validate group-name, sometime groupname is changed by the user....
if ~isempty(INFO.session) && ~isempty(INFO.grpname) && ~isempty(INFO.ExpNo),
  if ischar(INFO.session) && ischar(INFO.grpname),
    grpnames = getgrpnames(INFO.session);
    if ~any(strcmpi(grpnames,INFO.grpname)),
      grp = getgrp(INFO.session,INFO.ExpNo(1));
      INFO.grpname = grp.name;
    end
  end
end



return
