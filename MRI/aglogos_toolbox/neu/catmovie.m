function oSig = catmovie(SESSION, GrpName, SigName)
%CATMOVIE - concatanate signals from mat files into a group file
% CATMOVIE is a subroutine called by the group-maker grpnmk.m, which
% is a version of grpmk.m grouping only neurophysiology data.
%
% See also GRPMK GRPNMK
%
% NKL, 28.04.03

if nargin < 3,
  error('catmovie: usage catmove(SESSION,GrpName,SigName)');
end;
  
Ses = goto(SESSION);
eval(sprintf('grp = Ses.grp.%s;', GrpName));
EXPS = grp.exps;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AVERAGING STATISTICAL MAPS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf(' catmovie: %s, %s: ',Ses.name, SigName);
for nexp=1:length(EXPS),
  ExpNo = EXPS(nexp);
  fprintf('%d.',ExpNo);
  Sig = sesgetsig(Ses,ExpNo,SigName);
  if nexp==1,
	oSig = Sig;
  else  
	oSig.dat = oSig.dat + Sig.dat;
  end;
end;
fprintf('\n');
oSig.dat = oSig.dat./nexp;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS HERE WORKS WITH THE ORIGINAL DATA INSTEAD OF ZSCORE MAPS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try,
for nexp=1:length(EXPS),
  ExpNo = EXPS(nexp);
  fprintf('catmovie: Ses: %s, ExpNo: %d, Sig: %s\n',Ses.name, ExpNo,SigName);
  wSigName = who('-file',catfilename(Ses,ExpNo,'mat'),SigName);
  if isempty(wSigName),
	oSig = [];
	return;
  end;
  
  Sig = sesgetsig(Ses,ExpNo,SigName);
  Sig = DoConvert(Sig);
  if nexp==1,
	oSig = Sig;
	mvdata = Sig.movie;
  else
	oSig.idat = cat(5,oSig.idat,Sig.idat);
  end;
end;
catch,
  disp(lasterr);
  keyboard;
end;

clear Sig;
dirs = getdirs;
moviefile = strcat(dirs.movdir,mvdata.name);
[fp,fn,fe] = fileparts(moviefile);
MovieMatFile = sprintf('%s/%s.mat',fp,fn);
load(MovieMatFile);
bkg = mean(imgmean,3);
bkgstd = mean(imgstd,3);
oSig = DoTTest(oSig,bkg,bkgstd);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoTTest(Sig,Bkg,BkgStd)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
alpha = 0.01;
oSig = rmfield(Sig,{'dat'});
NoImg = size(Sig.idat,5);
NoBkg = 100;				% Fixed in video files
cf = (NoImg+NoBkg)/(NoImg*NoBkg);
df = NoBkg + NoImg -2;
Bkg2Std = BkgStd.*BkgStd;

for Frame=size(Sig.idat,1):-1:1,
  for ChanNo=size(Sig.idat,4):-1:1,
	% This here should generate a imgdim1 X imgdim2 X length(grp.exps)
	mimg = mean(squeeze(Sig.idat(Frame,:,:,ChanNo,:)),3);
	simg = std(squeeze(Sig.idat(Frame,:,:,ChanNo,:)),1,3);
	v = cf * ((NoImg-1)*simg.*simg + (NoBkg-1)*Bkg2Std)/df;
	Y = (mimg-Bkg);
	ix = find(v);
	t = zeros(size(Y));
	t(ix) = Y(ix)./sqrt(v(ix));
	pval  = 1 - tcdf(t,df);
    pval = 2 * min(pval,1-pval);
	oSig.idat(Frame,:,:,ChanNo) = BkgStd;
	bix = find(BkgStd);
	oSig.idat(bix) = Y(bix)./BkgStd(bix);
%	oSig.idat(Frame,:,:,ChanNo) = Y./BkgStd;
	oSig.pval(Frame,:,:,ChanNo) = pval;
  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function oSig = DoConvert(Sig)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example of Sig.idat Frames Y   X  RGB   Chan
%					  3    180 240   3    15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = rmfield(Sig,{'dat','std','vid','usr'});
for Frame=size(Sig.idat,1):-1:1,
  for ChanNo=size(Sig.idat,5):-1:1,
	tmp = squeeze(Sig.idat(Frame,:,:,:,ChanNo));		
	DIFF = Sig.vid.idatmax(ChanNo) - Sig.vid.idatmin(ChanNo);
	tmp = squeeze(DIFF*(double(tmp)/255) + Sig.vid.idatmin(ChanNo));
	oSig.idat(Frame,:,:,ChanNo) = squeeze(mean(tmp,3));
  end;
end;



