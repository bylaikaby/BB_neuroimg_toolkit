function sessupgrp(SESSION,SuperGrpName,SigType,Signame)
%SESSUPGRP - Makes groups of "groups" to compute site-RFs
% SESSUPGRP can concatanate different groups using different
% movies to generate superaverages for the computation of
% either site-RF or contrast functions.
%
% See also SESGRPMAKE, GRPMAKE, CATSIG
% AB 16.09.04 - supports dep signals

if nargin == 0, help sessupgrp;  return;  end

Ses = goto(SESSION);

if nargin < 3,
  SigType = 'all';
end;

if nargin < 2,
  SuperGrpName = [];
end;

if nargin < 4,
  Signame=[];
end

if ~any(strcmp(SigType,{'all';'rf';'dep';'img'})),
  error('usage: sessupgrp(SESSION,GROUPS,SIGTYPE)');
end;

if strcmp(SigType,'all') | strcmp(SigType,'rf')
  g = Ses.ctg.rfGrps;
  if isempty(g), return; end;
  for G=1:length(g),
    if isempty(g{G}), continue; end;
    oGrpFileName = g{G}{1}{1};
    if ~isempty(SuperGrpName) & ~strcmp(oGrpFileName,SuperGrpName),
      continue;
    end;
    GrpNames = g{G}{2};
    fprintf('%d/%d: ',G,length(g));
    fprintf('Processing SuperGroup: %s\n',oGrpFileName);
    fprintf('Included groups: ');
    fprintf('%s ',GrpNames{:});
    fprintf('\n');
    DoCatRfGrp(Ses,GrpNames,oGrpFileName);
  end;
end;


if strcmp(SigType,'all') | strcmpi(SigType,'dep')
  g = Ses.ctg.chcfGrps;

  for G=1:length(g),
    oGrpFileName = g{G}{1}{1};
    if ~isempty(SuperGrpName) & ~strcmp(oGrpFileName,SuperGrpName),
      continue;
    end;
    GrpNames = g{G}{2};
    fprintf('%d/%d: ',G,length(g));
    fprintf('Processing SuperGroup: %s\n',oGrpFileName);
    fprintf('Included groups: ');
    fprintf('%s ',GrpNames{:});
    fprintf('\n');
	if isempty(Signame),
	  for con=1:length(Ses.ctg.GrpDEPSigs),
		DoCatDepGrp(Ses,GrpNames,oGrpFileName, Ses.ctg.GrpDEPSigs{con});
	  end;
	else
	  DoCatDepGrp(Ses,GrpNames,oGrpFileName, Signame);
	end;
  end;
	
end

if strcmp(SigType,'all') | strcmpi(SigType,'img')
  g = Ses.ctg.chcfGrps;
  for G=1:length(g),
    oGrpFileName = g{G}{1}{1};
    if ~isempty(SuperGrpName) & ~strcmp(oGrpFileName,SuperGrpName),
      continue;
    end;
    GrpNames = g{G}{2};
    fprintf('%d/%d: ',G,length(g));
    fprintf('Processing SuperGroup: %s\n',oGrpFileName);
    fprintf('Included groups: ');
    fprintf('%s ',GrpNames{:});
    fprintf('\n');
	if isempty(Signame),
	  for sig=1:length(Ses.ctg.GrpImgSigs),
		DoCatImgGrp(Ses,GrpNames,oGrpFileName, Ses.ctg.GrpImgSigs{sig});
	  end;
	else
	  DoCatImgGrp(Ses,GrpNames,oGrpFileName, Signame);
	end;
  end;
	
end;  
  
  
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCatRfGrp(Ses,GrpNames,oGrpFileName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GrpSigs = getrfsigs(Ses);

for SigNo = 1:length(GrpSigs),
  
  SigName = GrpSigs{SigNo};

  if SigNo == 1,
	F=1; X=1; Y=1; C=1;
	for GrpNo=1:length(GrpNames),
	  if ~strncmp(GrpNames{GrpNo},'movie',5),
		fprintf('DoCatRfGrp: Group %s is not movie-data; Skipping...\n');
		continue;
	  end;
	  filename = strcat(GrpNames{GrpNo},'.mat');
	  Sig = matsigload(filename,SigName);
	  F = max(F,size(Sig.dat,1));	% FRAMES
	  X = max(X,size(Sig.dat,2));	% X-IMAGE DIMENSION
	  Y = max(Y,size(Sig.dat,3));	% Y-IMAGE DIMENSION
	  CL = max(C,size(Sig.dat,4));	% COLORS (RGB)
	  CH = max(C,size(Sig.dat,5));	% CHANNELS
	end;
	ldat = zeros(F,X,Y,CL,CH);
  end;

  for GrpNo=1:length(GrpNames),
	filename = strcat(GrpNames{GrpNo},'.mat');
	Sig = matsigload(filename,SigName);
	fprintf('DoCatRfGrp: Processing group file %s ...',filename);
	for N=1:length(Ses.revcor.LFP_THR),
	  if size(Sig.dat,2) ~= X | size(Sig.dat,3) ~= Y,
		fprintf('Resizeing movie before averaging...');
		for Frame=1:size(Sig.dat,1),
		  for Chan=1:size(Sig.dat,5),
			for Color=1:size(Sig.dat,4),
			ldat(Frame,:,:,Color,Chan) = ...
				imresize(squeeze(Sig.dat(Frame,:,:,Color,Chan)),[X Y],'bilinear');
			end;
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
	fprintf('DoCatRfGrp: Done\n');
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
	fprintf('DoCatRfGrp: Appended %s in file %s\n',...
		  SigName, oGrpFileName);
  else
	save(strcat(oGrpFileName,'.mat'),SigName);
	fprintf('DoCatRfGrp: Saved %s in file %s\n',...
		  SigName, oGrpFileName);
  end;
end;

clear ldat;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCatImgGrp(Ses,GrpNames,oGrpFileName,SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = {};  
fprintf(' sessupgrp.DoCatDepGrp: "%s"',SigName);
switch SigName,
 case Ses.ctg.GrpImgSigs
  for N = 1:length(GrpNames),
	fprintf(' %s',GrpNames{N});
	Sig = sigload(Ses,GrpNames{N},SigName);
	if N == 1,
	  oSig = Sig;
	  for K = 1:length(oSig), oSig{K}.grpname = oGrpFileName;  end
	else
	  for K = 1:length(oSig),
		oSig{K}.ExpNo = [oSig{K}.ExpNo, Sig{K}.ExpNo];
		%tmpdat = squeeze(Sig{K}.dat);
		tmpr   = Sig{K}.r{1};
		%oSig{K}.dat = cat(3,oSig{K}.dat,tmpdat);
		oSig{K}.r{1}= cat(2,oSig{K}.r{1},tmpr);
	  end
	end
  end
end
fprintf(' saving to %s...',oGrpFileName);
eval(sprintf('%s = oSig;',SigName));
if exist(strcat(oGrpFileName,'.mat'),'file'),
  save(strcat(oGrpFileName,'.mat'),'-append',SigName);
else
  save(strcat(oGrpFileName,'.mat'),SigName);
end;

fprintf(' done.\n');

return;
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DoCatDepGrp(Ses,GrpNames,oGrpFileName,SigName)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oSig = {};
fprintf(' sessupgrp.DoCatDepGrp: "%s"',SigName);
switch SigName,
 case Ses.ctg.GrpDEPSigs
  if strfind(SigName,'cor'), % Different length signals
    for N = 1:length(GrpNames),
      fprintf(' %s',GrpNames{N});
      Sig = sigload(Ses,GrpNames{N},SigName);
	  if isempty(Sig),
		continue;
	  end
      if N == 1,
        oSig = Sig;
		if ~isempty(oSig)
		  for K = 1:length(oSig), 
			oSig{K}.dat=squeeze(oSig{K}.dat); % grouped signal is M x 1 x N
			oSig{K}.err=squeeze(oSig{K}.err);
			oSig{K}.dat=mean(oSig{K}.dat,2);
			oSig{K}.err=mean(oSig{K}.err,2);
		  end
		end;
        for K = 1:length(oSig), oSig{K}.grpname = oGrpFileName;  end
      else
        for K = 1:length(oSig),
          oSig{K}.ExpNo = [oSig{K}.ExpNo, Sig{K}.ExpNo];
          tmpdat = squeeze(Sig{K}.dat);
          tmperr = squeeze(Sig{K}.err);
		  tmpdst = Sig{K}.dist;
		  tmpdat = mean(tmpdat,2);
		  tmperr = mean(tmperr,2); 
		  oSig{K}.dist= cat(2,oSig{K}.dist,tmpdst);
		  oSig{K}.dat = cat(1,oSig{K}.dat,tmpdat);
          oSig{K}.err = cat(1,oSig{K}.err,tmperr);
        end
      end
    end
	for N=1:length(GrpNames),
	  tmp=cat(2,oSig{K}.dist',oSig{K}.dat,oSig{K}.err);
	  tmp=sortrows(tmp,1);
	  oSig{K}.dist=tmp(:,1)';
	  oSig{K}.dat=tmp(:,2);
	  oSig{K}.err=tmp(:,3);
	end
	
  else % same length signals
    for N = 1:length(GrpNames),
      fprintf(' %s',GrpNames{N});
      Sig = sigload(Ses,GrpNames{N},SigName);
	  if isempty(Sig),
		continue;
	  end
      if N == 1,
        oSig = Sig;
		if ~isempty(oSig)
		  for K = 1:length(oSig), 
			oSig{K}.dat=squeeze(oSig{K}.dat); % grouped signal is M x 1 x O
			oSig{K}.err=squeeze(oSig{K}.err);
		  end
		end;
        for K = 1:length(oSig), oSig{K}.grpname = oGrpFileName;  end
      else
        for K = 1:length(oSig),
          oSig{K}.grpname = sprintf('%s-%s',oSig{K}.grpname,Sig{K}.grpname);
          oSig{K}.ExpNo = [oSig{K}.ExpNo, Sig{K}.ExpNo];
          tmpdat = squeeze(Sig{K}.dat);
          tmperr = squeeze(Sig{K}.err);
		  try
			oSig{K}.dat = cat(2,oSig{K}.dat,tmpdat);
		  catch
			keyboard;
		  end
          oSig{K}.err = cat(2,oSig{K}.err,tmperr);
          % FITTING...
          if isfield(oSig{K},'FIT'),
            Nprm = ndims(Sig{K}.FIT.param)+1;
            oSig{K}.FIT.ydata = cat(3, oSig{K}.FIT.ydata,Sig{K}.FIT.ydata);
            oSig{K}.FIT.param = cat(Nprm, oSig{K}.FIT.param,Sig{K}.FIT.param);
            oSig{K}.FIT.error = cat(2, oSig{K}.FIT.error,Sig{K}.FIT.error);
            oSig{K}.FIT.halfdist = cat(2, oSig{K}.FIT.halfdist,Sig{K}.FIT.halfdist);
          end
        end
      end
    end
    for K = 1:length(oSig),
      if isfield(oSig{K},'FIT'),
        Nprm = ndims(oSig{K}.FIT.param);
        oSig{K}.FIT.ydata = hnanmean(oSig{K}.FIT.ydata,3);
        oSig{K}.FIT.param = hnanmean(oSig{K}.FIT.param,Nprm);
        oSig{K}.FIT.error = hnanmean(oSig{K}.FIT.error,2);
        oSig{K}.FIT.halfdist = hnanmean(oSig{K}.FIT.halfdist,2);
      end
    end
  end
end
fprintf(' saving to %s...',oGrpFileName);
eval(sprintf('%s = oSig;',SigName));
if exist(strcat(oGrpFileName,'.mat'),'file'),
  save(strcat(oGrpFileName,'.mat'),'-append',SigName);
else
  save(strcat(oGrpFileName,'.mat'),SigName);
end;

fprintf(' done.\n');

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ogrp = grpgrp(ogrp,grp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try,
ogrp.grpname = cat(2,ogrp.grpname,'-',grp.grpname);
ogrp.dat = ogrp.dat + grp.dat;
catch,
  disp(lasterr);
  keyboard;
end;


