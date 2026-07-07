function cblp = expconvblp(SesName,ExpNo,SpontGroup)
%EXPCONVBLP - Convolve BLP signals with an estimate of HRF (calls sigconv)
%
% EXPCONVBLP (SesName, ExpNo, SpontGroup) will load the blp signals of an experiment and
% convolve them with an HRF function computed from spontaneous activity. If no SpontGroup is
% defined the group with the name "spont" is searched; if it does not exist, the function
% exits with an error message.
%
% See also SESGETHRF
%
% NKL 01.08.04
  
if nargin < 2,
  help expconvblp;
  return;
end;

Ses = goto(SesName);

if nargin < 3,
  grpnames = fieldnames(Ses.grp);
  if ~any(strcmp(grpnames,'spont')),
    fprintf('EXPCONVBLP: No "spont" group was found\n');
    help expconvblp;
    return;
  end;
  SpontGroup = 'spont';
end;

fprintf('EXPCONVBLP: Loading file %s\n', catfilename(Ses,ExpNo));
sigload(Ses,ExpNo,'blp');
load(strcat(SpontGroup,'.mat'),'hrf');

% blp2sig will return time X chan X 1 (for band) X NoExp in group
hrf = blp2sig(hrf);

hrf.dat = squeeze(hrf.dat);
hrf = sigmedian(hrf,3);
hrf = sigmedian(hrf,2);

cblp = sigconv(blp,hrf);
cblp.dir.dname = 'cblp';
cblp = sigupdate(cblp);

if ~nargout,
  sigsave(Ses,ExpNo,'cblp',cblp);
end;



