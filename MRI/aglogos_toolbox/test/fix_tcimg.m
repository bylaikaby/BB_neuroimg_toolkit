function fix_tcimg(Ses,EXPS)
%FIX_TCIMG - fixes problems of tcImg
%  FIX_TCIMG(SES,EXP) fixes problems of tcImg.
%
%  VERSION :
%    0.90 13.12.07 YM  pre-release
%
%  See also sesimgload imgload

if nargin == 0,  eval(sprintf('help %s',mfilename)); return;  end

if nargin < 2,  EXPS = [];  end



% GET BASIC INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(Ses);
EXPS = getexps(Ses,EXPS);


for iExp = 1:length(EXPS),
  ExpNo = EXPS(iExp);
  fprintf('%3d/%d: fixing tcImg ExpNo=%d...',iExp,length(EXPS),ExpNo);
  subDoFix(Ses,ExpNo);
  fprintf(' done.\n');
end

return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to fix problems
function subDoFix(Ses,ExpNo);

anap = getanap(Ses,ExpNo);
if ~isfield(anap,'imgload') | isempty(anap.imgload),  return;  end

matfile = catfilename(Ses,ExpNo,'tcImg');
tcImg = load(matfile,'tcImg');
if isempty(tcImg),  return;  end
tcImg = tcImg.tcImg;

img = tcImg.dat;
tcImg.dat = [];

if ~isfield(anap.imgload,'ISUBSTITUTE'),
  anap.imgload.ISUBSTITUTE = 0;
end
if ~isfield(anap.imgload,'ISUBSTITUTE_RAND'),
  anap.imgload.ISUBSTITUTE_RAND = 1;
end



pareval(anap.imgload);

if ISUBSTITUTE,
  fprintf(' substituting(%d,rand=%d).',ISUBSTITUTE,ISUBSTITUTE_RAND);
  for NS=1:size(img,3),
    img(:,:,NS,1:ISUBSTITUTE) = img(:,:,NS,ISUBSTITUTE+1:2*ISUBSTITUTE);
    if ISUBSTITUTE_RAND, 
      idx = 1:ISUBSTITUTE;
      for x = 1:size(img,1),
        for y = 1:size(img,2),
          img(x,y,NS,idx) = img(x,y,NS,idx(randperm(ISUBSTITUTE)));
        end
      end
    end
  end;
  SAVE_DATA = 1;
end



if SAVE_DATA,
  fprintf('saving.');
  tcImg.dat = img;
  save(matfile,'tcImg');
end

return
