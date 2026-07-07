function quickana(SESSION,GRPNAME,INTERACTIVE)
%QUICKANA - runs a series of analysis for a quick check of data.
%  QUICKANA(SESSION,GRPNAME)
%
%  VERSION :
%    0.90 12.04.06 YM  pre-release
%
%  See also SESDUMPPAR SESASCAN SESIMGLOAD MROI SESAREATS SESCORANA SESGLMANA SESGRPMAKE MVIEW

if nargin ~= 2,  eval(sprintf('help %s;',mfilename)); return;  end  

if ~exist('INTERACTIVE','var'),  INTERACTIVE = 1;  end

if INTERACTIVE,
  tmptxt = sprintf('Q: Load basic parameters? Y/N[Y]: ');
  c = input(tmptxt,'s');
  if isempty(c), c = 'Y';  end
  % IF "YES" then process
  if c == 'y' || c == 'Y',
    sesdumppar(SESSION,GRPNAME);
    sesascan(SESSION);
    sesimgload(SESSION,GRPNAME);
  end
end

while INTERACTIVE,
  tmptxt = sprintf('\nQ: ROIs defined? Y/N[Y]: ');
  c = input(tmptxt,'s');
  if isempty(c), c = 'Y';  end
  % IF "YES" then break here.
  if c == 'y' || c == 'Y',  break;  end
  mroi(SESSION,GRPNAME);
end


sesareats(SESSION,GRPNAME);
%sescorana(SESSION,GRPNAME);
%sesglmana(SESSION,GRPNAME);

sesgettrial(SESSION,GRPNAME);
sesgrpmake(SESSION,GRPNAME);

mview(SESSION,GRPNAME);


return;

