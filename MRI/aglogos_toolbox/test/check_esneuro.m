function check_esneuro(Ses,GrpExp)

if nargin < 1,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 2,  GrpExp = [];  end


Ses = goto(Ses);

% fprintf('%s: %s',Ses.name,pwd);
% if exist('microstim_timing.mat','file'),
%   %fprintf(' ok');
% else
%   fprintf(' microstim_timing.mat missing.');
% end
% fprintf(' done.\n');
% return




if any(GrpExp),
  EXPS = getexps(Ses,GrpExp);
else
  EXPS = getexps(Ses);
end



fprintf('%s: %s (nexp=%d): ',mfilename,Ses.name,length(EXPS));

for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  matfile = catfilename(Ses,ExpNo);
  vnames = who('-file',matfile);
  if ~any(strcmpi(vnames,'Sdf')),
    fprintf('%d.',ExpNo);
  else
    fprintf('.');
  end
  
  % if ismicrostimulation(Ses,ExpNo),
  %   Cln = sigload(Ses,ExpNo,'Cln');
  %   if ~isfield(Cln,'esinfo'),
  %     fprintf('%d.',ExpNo);
  %   else
  %     fprintf('.');
  %   end
  % end
end


fprintf(' done.\n');