function Sig = picksig(arg1,arg2,varargin)
%PICKSIG - Loads a signal using Ses information (OBSOLETE)
% PICKSIG is similar to matsigload etc. Eventually there should be
% only one function; so I have to get rid of it and replace all
% calls in show, showchan and sesshow with the appropriate function.
%
% See also MATSIGLOAD SESGETSIG SESSHOW SHOW SHOWCHAN
%
% VERSION : 1.00 NKL, 01.05.03

if nargin < 3,
  DispError;
  return;
else
  SESSION = arg1;
  Ses = goto(SESSION);
  if isa(arg2,'char'),
	GrpName = arg2;
	eval(sprintf('grp = Ses.grp.%s;', GrpName));
	ExpNo = grp.exps(1);
	filename = strcat(GrpName,'.mat');
  elseif isa(arg2,'double'),
	ExpNo = arg2;
	grp = getgrp(Ses,ExpNo);
	GrpName = grp.name;
	filename = catfilename(Ses,ExpNo,'mat');
  else
	DispError;
	return;
  end;
end;

tmp = load( filename, varargin{:});

for n= 1:length(varargin(:)),
   try,
      Sig{n} = getfield(tmp,varargin{n});
   catch,
      Sig{n} = [];
      fprintf('picksig: no "%s" not in "%s"\n',varargin{n}, filename);
   end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DispError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('picksig: usage: picksig(arg1,arg2,arg3);\n');
  fprintf('picksig: arg1 = Session Name\n');
  fprintf('picksig: arg2 = [Group Name or Exp Number]\n');
  fprintf('picksig: arg3 = Signal name\n');
return;







