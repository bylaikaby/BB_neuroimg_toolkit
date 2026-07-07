function catgrpmovie(SESSION,GrpNames,oGrpFileName)
%CATGRPMOVIE - Concatanates all movie-groups into one large group.
% CATGRPMOVIE(SESSION,arg2) the function is used to group all
% data. Regardless of which movie was shown the RF should be the
% same; so we average to see what we "get".

if nargin < 1,
  error('catgrpmovie: usage catgrpmovie(SESSION);');
end;

Ses = goto(SESSION);
GrpSigs = getrfsigs(Ses);

SpecialGroups = {'autoplot';'test';'misc'};
if isfield(Ses,'SpecialGroups'),
  SpecialGroups = Ses.SpecialGroups;
end;

if nargin < 3,
  oGrpFileName = sprintf('%s_movgrp.mat',Ses.name);
end;

if nargin < 2,
  GrpNames = fieldnames(Ses.grp);
end;

for SigNo = 1:length(GrpSigs),
  
  SigName = GrpSigs{SigNo};

  if SigNo == 1,
	F=1; X=1; Y=1; C=1;
	for GrpNo=1:length(GrpNames),
	  if ~strncmp(GrpNames{GrpNo},'movie',5),
		fprintf('catgrpmovie: Group %s is not movie-data; Skipping...\n');
		continue;
	  end;
	  filename = strcat(GrpNames{GrpNo},'.mat');
	  Sig = matsigload(filename,SigName);
	  F = max(F,size(Sig.dat,1));
	  X = max(X,size(Sig.dat,2));
	  Y = max(Y,size(Sig.dat,3));
	  C = max(C,size(Sig.dat,4));
	end;
	ldat = zeros(F,X,Y,C);
  end;

  for GrpNo=1:length(GrpNames),
	if ~strncmp(GrpNames{GrpNo},'movie',5),
	  fprintf('catgrpmovie: Group %s is not movie-data; Skipping...\n');
	  continue;
	end;
	filename = strcat(GrpNames{GrpNo},'.mat');
	Sig = matsigload(filename,SigName);
	fprintf('catgrpmovie: Processing group file %s ...',filename);
	for N=1:length(Ses.revcor.LFP_THR),
	  if size(Sig.dat,2) ~= X | size(Sig.dat,3) ~= Y,
		fprintf('Resizeing movie before averaging...');
		for Frame=1:size(Sig.dat,1),
		  for Chan=1:size(Sig.dat,4),
			ldat(Frame,:,:,Chan) = ...
				imresize(squeeze(Sig.dat(Frame,:,:,Chan)),[X Y],'bilinear');
		  end;
		end;
		Sig.dat = ldat;
		fprintf('Done!\n');
	  end;
	  
	  if GrpNo==1,
		oSig{N} = Sig;
	  else
		oSig{N} = grpgrp(oSig{N},Sig);
	  end;
	end;
	fprintf('catgrpmovie: Done\n');
  end;

  for N=1:length(Ses.revcor.LFP_THR),
	oSig{N}.dat = oSig{N}.dat/length(GrpNames);
  end;

  if length(oSig)==1,
	oSig = oSig{1};
  end;
  clear Sig;
  eval(sprintf('%s = oSig;', SigName));
  clear oSig;

  if exist(strcat(oGrpFileName,'.mat'),'file'),
	save(strcat(oGrpFileName,'.mat'),'-append',SigName);
	fprintf('catgrpmovie: Appended %s in file %s\n',...
		  SigName, oGrpFileName);
  else
	save(strcat(oGrpFileName,'.mat'),SigName);
	fprintf('catgrpmovie: Saved %s in file %s\n',...
		  SigName, oGrpFileName);
  end;
end;

clear ldat;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ogrp = grpgrp(ogrp,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   session: 'c98nm1'
%    grpname: 'movie1'
%      ExpNo: 1
%        dir: [1x1 struct]
%        dsp: [1x1 struct]
%        grp: [1x1 struct]
%        evt: [1x1 struct]
%        stm: [1x1 struct]
%       chan: [1 2 3 4 5 6 7 8 9 10 11 16 13 14 15]
%         dx: 1
%      movie: [1x1 struct]
%      range: [20 90]
%        dat: [4-D double]
ogrp.grpname = cat(2,ogrp.grpname,'-',grp.grpname);
ogrp.dat = ogrp.dat + grp.dat;

