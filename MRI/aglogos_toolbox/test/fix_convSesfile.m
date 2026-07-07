function fix_convSesfile(sesname,projname)
%FIX_CONVSESFILE - converts old description file to new format.
% USAGE : fix_ConvSesfile(sesname,[projname])
% VERSION : 0.90 14.03.04 YM
%
% See also 
  
  

if nargin < 2, projname = '';  end

  
  
fprintf(' %s: ',sesname);

if ~exist(sesname,'file'),
  fprintf('ERROR!!!  file not found.\n');
  return;
end

SES = subGetSes(sesname);
eval(sesname);
sesfile = which(sesname);


% GROUPS
GROUPSTR = {};
GROUPSTR{1} = '% GROUPS :';
GROUPSTR{2} = sprintf('%%\t');
if isfield(SES,'grp') & isa(SES.grp,'struct'),
  grpnames = fieldnames(SES.grp);
  for N = 1:length(grpnames),
    GROUPSTR{end} = sprintf('%s %s',GROUPSTR{end},grpnames{N});
    if length(GROUPSTR{end}) > 60 & N < length(grpnames),
      GROUPSTR{end+1} = sprintf('%%\t');
    end
  end
end

% EXPERIMENTS
EXPSTR = sprintf('%% EXPERIMENTS : %d',length(SES.expp));

% ROIS
ROISTR = '% ROIS : ';
if isfield(SES,'roinames')
  for N = 1:length(SES.roinames),
    ROISTR = sprintf('%s %s',ROISTR,SES.roinames{N});
  end
end




% read all contents
fid = fopen(sesfile,'r');
oldtxt = {};
while 1,
  if feof(fid), break;  end
  oldtxt{end+1} = fgetl(fid);
end
fclose(fid);

% remove ses.SpecialGroups,
oldtxt = subRemove(oldtxt,'ses.SpecialGroups');
oldtxt = subRemove(oldtxt,'% ses.SpecialGroups');
% remove ses.confunc.algs
oldtxt = subRemove(oldtxt,'ses.confunc.algs');
% remove '% PLEASE MAKE SURE THE ELECTRODE'
oldtxt = subRemove(oldtxt,'% PLEASE MAKE SURE THE ELECTRODE POSITION AND ');

% replace ses.DataNeuro with SYSP.DataNeuro
oldtxt = subFindReplace(oldtxt,'ses.DataNeuro','SYSP.DataNeuro');
% replace ses.DataMri with SYSP.DataMri
oldtxt = subFindReplace(oldtxt,'ses.DataMri	','SYSP.DataMri'); % w/  tabs
oldtxt = subFindReplace(oldtxt,'ses.DataMri','SYSP.DataMri');  % w/o tabs
% replace ses.dirname with SYSP.dirname
oldtxt = subFindReplace(oldtxt,'ses.dirname	','SYSP.dirname'); % w/  tabs
oldtxt = subFindReplace(oldtxt,'ses.dirname','SYSP.dirname');  % w/o tabs
% replace ses.Quality with ANAP.Quality
oldtxt = subFindReplace(oldtxt,'ses.Quality	','ANAP.Quality'); % w/  tabs
oldtxt = subFindReplace(oldtxt,'ses.Quality','ANAP.Quality');  % w/o tabs


% replace ses.GrpSigsExclude with CTG.exclGrps
oldtxt = subFindReplace(oldtxt,'ses.GrpSigsExclude','CTG.exclGrps');
% replace ses.GrpSigs with CTG.inclGrps
oldtxt = subFindReplace(oldtxt,'ses.GrpSigs','CTG.inclGrps');
% replace ses.SuperGrps with CTG.rfGrps
oldtxt = subFindReplace(oldtxt,'ses.SuperGrps','CTG.rfGrps');
% replace ses.chcfGrps with CTG.chcfGrps
oldtxt = subFindReplace(oldtxt,'ses.chcfGrps','CTG.chcfGrps');
% replace ses.winGrps with CTG.winGrps
oldtxt = subFindReplace(oldtxt,'ses.winGrps','CTG.winGrps');
% replace ses.ImgGrps with CTG.imgGrps
oldtxt = subFindReplace(oldtxt,'ses.ImgGrps','CTG.imgGrps');
% replace ses.ImgSpoGrps with CTG.imgSpoGrps
oldtxt = subFindReplace(oldtxt,'ses.ImgSpoGrps','CTG.imgSpoGrps');
% replace ses.anap with ANAP
oldtxt = subFindReplace(oldtxt,'ses.anap','ANAP');
% replace ses.revcor with ANAP.revcor
oldtxt = subFindReplace(oldtxt,'ses.revcor','ANAP.revcor');
% replace ses.confunc with ANAP.confunc
oldtxt = subFindReplace(oldtxt,'ses.confunc','ANAP.confunc');
% replace ses.roi with ROI.
oldtxt = subFindReplace(oldtxt,'ses.roi','ROI.');
% replace ses.RoiGroups with ROI.groups
oldtxt = subFindReplace(oldtxt,'ses.RoiGroups','ROI.groups');
% replace ses.gefi with ASCAN.gefi
oldtxt = subFindReplace(oldtxt,'ses.gefi','ASCAN.gefi');
% replace ses.mdeft with ASCAN.mdeft
oldtxt = subFindReplace(oldtxt,'ses.mdeft','ASCAN.mdeft');
% replace ses.ir with ASCAN.ir
oldtxt = subFindReplace(oldtxt,'ses.ir','ASCAN.ir');
% replace ses.msme with ASCAN.msme
oldtxt = subFindReplace(oldtxt,'ses.msme','ASCAN.msme');
% replace ses.epi13 with CSCAN.epi13
oldtxt = subFindReplace(oldtxt,'ses.epi13','CSCAN.epi13');
% replace ses.grpp with GRPP
oldtxt = subFindReplace(oldtxt,'ses.grpp','GRPP');
% replace ses.grp with GRP
oldtxt = subFindReplace(oldtxt,'ses.grp','GRP');
% replace expp( with EXPP(
oldtxt = subFindReplace(oldtxt,'expp(','EXPP(');
% replace .crop with .imgcrop
oldtxt = subFindReplace(oldtxt,'.crop','.imgcrop');
% replace '% GROUPING' with '% CATEGORIES (CTG) OF'
oldtxt = subFindReplace(oldtxt,'% GROUPING','% CATEGORIES (CTG) OF');



% rename ANAP.confucn.idst to ANAP.confunc.eledist
oldtxt = subFindReplace(oldtxt,'ANAP.confunc.idst','ANAP.confunc.eledist');
oldtxt = subFindReplace(oldtxt,'ANAP.confunc.idist','ANAP.confunc.eledist');
% rename ANAP.confucn.imgdst to ANAP.confunc.imgdist
oldtxt = subFindReplace(oldtxt,'ANAP.confunc.imgdst','ANAP.confunc.imgdist');


% make ASCAN.gefi{x}.elepos as a comment
idx = find(strncmp(oldtxt,'ASCAN.',length('ASCAN.')));
for N = 1:length(idx),
  if ~isempty(strfind(oldtxt{idx(N)},'.elepos')),
    oldtxt{idx(N)} = sprintf('%% %s',oldtxt{idx(N)});
  end
end


% remove ROI.groups to move before ROI.names later.
ROIGRPSTR = {};
for N = 1:length(oldtxt),
  idx = strfind(oldtxt{N},'ROI.groups');
  if ~isempty(idx) & isempty(strfind(oldtxt{N+1},'ROI.names')),
    selidx = [];
    for K = N:N+10,
      selidx(end+1) = K;
      ROIGRPSTR{end+1} = oldtxt{K};
      if oldtxt{K}(1) == '%',
        break;
      elseif ~isempty(strfind(oldtxt{K},'};')),
        break;
      end
    end
    idx = ones(1,length(oldtxt));
    idx(selidx) = 0;
    oldtxt = oldtxt(find(idx));
    break;
  end
end

% add a empty line at end of comment, if needed
ADD_EMPTY_LINE = 1;
for N = 1:length(oldtxt),
  if length(oldtxt{N}) == 0,
    ADD_EMPTY_LINE = 0;
    break;
  elseif strncmp(oldtxt{N},'SYSP.DataNeuro',length('SYSP.DataNeuro')),
    break;
  elseif strncmp(oldtxt{N},'SYSP.DataMri',length('SYSP.DataMri')),
  end
end
if ADD_EMPTY_LINE,
  tmpstr = '% basic information : data directories,';
  idx = find(strncmp(oldtxt,tmpstr,length(tmpstr)));
  if isempty(idx),
    % now look for other tag
    tmpstr = '% DEFINE DATA DIRECTORIES';
    idx = find(strncmp(oldtxt,tmpstr,length(tmpstr)));
    if isempty(idx),
      keyboard
    end
  end
  K = idx(1) - 2;
  if ~isempty(oldtxt{K}),
    oldtxt = {oldtxt{1:K},'',oldtxt{K+1:end}};
  end
end



% we have to find those before 'SYSP.DataNeuro'
EXPDATE = 0;  EXPDATESTR = '';
GROUPS  = 0;
EXPERIMENTS = 0;
ROIS    = 0;
COMMENT_END = 0;
for N = 1:length(oldtxt),
  tmpline = oldtxt{N};
  if length(tmpline) == 0,  COMMENT_END = N;  break;  end
  if length(tmpline) < 6, continue;  end
  switch tmpline(1:6),
   case {'% EXPD'},
    if strncmp(tmpline,'% EXPDATE',length('% EXPDATE')),
      EXPDATE = N;
      EXPDATESTR = tmpline(length('% EXPDATE')+1:end);
      % remove ':',';'
      EXPDATESTR = strrep(EXPDATESTR,':','');
      EXPDATESTR = strrep(EXPDATESTR,';','');
      % remove any blanks/tabs
      EXPDATESTR = deblank(EXPDATESTR);
      EXPDATESTR = strrep(EXPDATESTR,' ','');
      EXPDATESTR = strrep(EXPDATESTR,'	','');
    end
   case {'% GROU'}
    if strncmp(tmpline,'% GROUPS',length('% GROUPS')),
      GROUPS = N;
    end
   case {'% EXPE'}
    if strncmp(tmpline,'% EXPERIMENTS',length('% EXPERIMENTS')),
      EXPERIMETNS = N;
    end
   case {'% ROIS'}
    if strncmp(tmpline,'% ROIS',length('% ROIS')),
      ROIS = N;
    end
   case {'SYSP.D'}
    if strncmp(tmpline,'SYSP.DataNeuro',length('SYSP.DataNeuro')),
      break;
    end
  end
end

if COMMENT_END < 1,
  for N = 1:length(oldtxt),
    if ~isempty(strfind(oldtxt{N},'% basic information : data directories')),
      COMMENT_END = N - 2;
    end
  end
end

if COMMENT_END < 1,
  for N = 1:length(oldtxt),
    if ~isempty(strfind(oldtxt{N},'SYSP.DataNeuro')),
      COMMENT_END = N - 1;
    end
  end
end


% add SYSP.date
INSERT.SYSPDATE = 0;
if isempty(find(strncmp(oldtxt,'SYSP.date',length('SYSP.date')))),
  for N = COMMENT_END:length(oldtxt),
    tmpline = oldtxt{N};
    if strncmp(tmpline,'SYSP.dirname',length('SYSP.dirname')),
      INSERT.SYSPDATE = N+1;
      break;
    end
  end
end


INSERT.ROIGRP = 0;
for N = COMMENT_END:length(oldtxt),
  tmpline = oldtxt{N};
  if ~isempty(strfind(tmpline,'ROI.names')),
    if isempty(strfind(oldtxt{N-1},'ROI.groups')),
      INSERT.ROIGRP = N;
      break;
    end
  end
end


% add GRPP.GRPROI
% GRPSOISTR
GRPROISTR = 'GRPP.grproi		= ''RoiDef'';	% the name of a Group''s ROI; RoiDef is the default';

INSERT.GRPROI = 0;
idx = find(strncmp(oldtxt,'GRPP.grproi',length('GRPP.grproi')));
if isempty(idx),
  for N = COMMENT_END:length(oldtxt),
    tmpline = oldtxt{N};
    if strncmp(tmpline,'GRPP.',length('GRPP.')),
      INSERT.GRPROI = N+1;
    end
  end
  if INSERT.GRPROI < 1,
    for N = COMMENT_END:length(oldtxt),
      tmpline = oldtxt{N};
      if strncmp(tmpline,'GRP.',length('GRP.')),
        INSERT.GRPROI = N-1;  break;
      end
    end
  end
  if INSERT.GRPROI < 1,
    fprintf('  couldn''t find ses.grpp. or ses.grp');
  end
end


if EXPDATE < 1,
  INSERT.COMMENT = COMMENT_END;
else
  INSERT.COMMENT = EXPDATE + 1;
end




% check the content
newtxt = {};
for N = 1:length(oldtxt),
  if N == 1,
    % check the 1st line to be...
    %M02LX1 - Two-electrode, Movie Phys+MRI, Injection(Propofol)
    tmpstr = sprintf('%%%s',upper(sesname));
    if strncmp(oldtxt{N},tmpstr,length(tmpstr)),
      if isempty(strfind(oldtxt{N},projname)),
        % add projname
        fprintf(' projname-added ');
        oldtxt{N} = sprintf('%s, %s',oldtxt{N},projname);
      end
    else
      fprintf(' SESNAME-added ');
      % not found
      newtxt{1} = sprintf('%%%s - %s',upper(sesname),projname);
    end
  elseif N == INSERT.COMMENT,
    if ROIS == 0 & EXPERIMENTS == 0,
      for K = 1:length(GROUPSTR),
        newtxt{end+1} = GROUPSTR{K};
      end
      newtxt{end+1} = EXPSTR;
      newtxt{end+1} = ROISTR;
      newtxt{end+1} = '%';
    end
  elseif N == INSERT.SYSPDATE,
    newtxt{end+1} = sprintf('SYSP.date\t\t= ''%s'';',EXPDATESTR);
  elseif N == INSERT.ROIGRP,
    for K = 1:length(ROIGRPSTR),
      newtxt{end+1} = ROIGRPSTR{K};
    end
  elseif N == INSERT.GRPROI,
    if ~isfield(ses,'grpp') | ~isfield(ses.grpp,'grproi'),
      newtxt{end+1} = GRPROISTR;
    end
  end
  newtxt{end+1} = oldtxt{N};
end


% FINALY add authorship if needed
AUTHOR_STR = '% 15.03.04  AB JP MA NKL YM';
if isempty(find(strncmp(newtxt,AUTHOR_STR,length(AUTHOR_STR)))),
  for N = 1:length(newtxt),
    if length(newtxt{N}) == 0,
      newtxt = {newtxt{1:N-1},AUTHOR_STR,newtxt{N:end}};
      break;
    end
  end
end





fprintf('writing...');

fid = fopen(sesfile,'w');
for N = 1:length(newtxt),
  if length(newtxt{N}) > 0,
    if strncmp(newtxt{N}(end),sprintf('\n'),1),
      keyboard
    elseif strncmp(newtxt{N}(end),sprintf('\r'),1),
      keyboard
    end
    fprintf(fid,'%s\n',deblank(newtxt{N}));
  else
    fprintf(fid,'\n');
  end
end
fclose(fid);

fprintf(' done.\n');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newtxts = subRemove(oldtxts,rmstr)
selidx = ones(1,length(oldtxts));
idx = find(strncmp(oldtxts,rmstr,length(rmstr)));
if ~isempty(idx),
  selidx(idx) = 0;
end
newtxts = oldtxts(find(selidx));

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newtxts = subReplace(oldtxts,oldstr,newstr)
newtxts = oldtxts;
idx = find(strncmp(oldtxts,oldstr,length(oldstr)));
try
for N = 1:length(idx),
  newtxts{idx(N)} = strrep(newtxts{idx(N)},oldstr,newstr);
end
catch
  keyboard
end

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newtxts = subFindReplace(oldtxts,oldstr,newstr)
newtxts = oldtxts;
for N = 1:length(newtxts),
  idx = strfind(newtxts{N},oldstr);
  if ~isempty(idx),
    newtxts{N} = strrep(newtxts{N},oldstr,newstr);
  end
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ses = subGetSes(SessionName)

VERBOSE = 0;
  
ses.name	= '';
ses.dirname = '';
ses.sysp 	= [];
ses.acqp 	= [];
ses.expp 	= [];

ses.anap = getanap('default');  % get default analysis parameters


% ===========================================================================
% DEFAULT BLPs AND TO BE GROUPED SIGNALS
% Lfp [1 90] unrectified
% Gamma [24 90] unrectified
% LfpL/M/H Rectified in [1-12, 12-24, 24-90]
% MUA/SDF
% ===========================================================================
ses.RFSigs			= {'LfpH';'Mua';'Sdf'};
ses.SigBands		= {'Lfp', 'Gamma', 'Mua', 'Sdf'};

ses.GrpSigs			= {'LfpL';'LfpM';'LfpH';'Mua';'Spkt'; 'Sdf'};
ses.GrpRFSigs		= {'VLfpH3';'VMua3';'VSdf3'};
ses.GrpCFSigs		= {'cfLfp';'cfGamma';'cfMua';'cfSdf'};
ses.GrpCHSigs		= {'chLfp';'chGamma';'chMua';'chSdf'};
ses.GrpImgSigs		= {'Pts';'xcor'};

ses.grp  	= [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SYSP - SYSTEM PARAMETERS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ses.sysp = getdirs;

if VERBOSE == -1,
	ses.sysp
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ACQP - ACQUISITION PARAMETERS:	(common to (all) sessions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SPIKE-STREAMER'S ADC PARAMETERS
ses.acqp.win30.p	 = 7.0;
ses.acqp.win30.c	 = 4.0;
ses.acqp.win30.n	 = 16.0;					% Channels
ses.acqp.adfrate	 = 10000000.0/...
	(ses.acqp.win30.p*ses.acqp.win30.c*ses.acqp.win30.n);
ses.acqp.adfinterval = 1.0 / ses.acqp.adfrate;	% seconds

% PCL818 (EYE MOVEMENT) ADC PARAMETERS
ses.acqp.monchan(1) = cellstr('ecg');
ses.acqp.monchan(2) = cellstr('respflow');
ses.acqp.monchan(3) = cellstr('resppres');
ses.acqp.monchan(4) = cellstr('none');
ses.acqp.monchan	= ses.acqp.monchan';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVENTS USED IN THE MRI & PHYSIOLOGY EXPERIMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ses.acqp.evt = getevtcodes;
if VERBOSE == -1,
  ses.acqp.evt
end;

ses.acqp.tc.nsegments	= 8;				% 8-Shot images
ses.acqp.tc.imgacqt		= 20.48;			% mri acquisition window in ms
ses.acqp.tc.deadt		= 40;				% rephasing,sl-sel,and imgacqt

ses.acqp.epi13.nsegments= 8;				% 8-Shot images
ses.acqp.epi13.imgacqt	= 20.48;			% mri acquisition window in ms
ses.acqp.epi13.deadt	= 40;				% rephasing,sl-sel,and imgacqt

ses.acqp.mdeft.nsegments= 8;				% 8-Shot images
ses.acqp.mdeft.imgacqt	= 20.48;			% mri acquisition window in ms
ses.acqp.mdeft.deadt	= 40;				% rephasing,sl-sel,and imgacqt

ses.acqp.ir.nsegments= 8;					% 8-Shot images
ses.acqp.ir.imgacqt	= 20.48;				% mri acquisition window in ms
ses.acqp.ir.deadt	= 40;					% rephasing,sl-sel,and imgacqt

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EXPP - EXPERIMENTAL PARAMETERS: (session specific)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tmpDir = cd;				% Store cur dir.
% cd(ses.sysp.sesdir);
name = strrep(SessionName, '.m', '');
if ~exist(name,'file'),
  fprintf('fix_sesfile.subGetSes: SesFile %s does not exist!\n\n',strcat(name,'.m'));
  ses = {};
  return;
end;
eval(name);
% cd(tmpDir);
if exist('SYSP','var') & exist('EXPP','var'),
  % likely new format
  ses = subGetSesNew(SessionName);
  return;
end



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW REPLACE DEFAULTS AND TAKE CARE OF EMPTY FIELDS ETC...
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ses.name = lower(strrep(ses.dirname,'.',''));
if exist('expp','var'),
  ses.expp = expp;
else
  ses.expp = [];
end

HOSTNAME = ses.sysp.HOSTNAME;
if strcmp(HOSTNAME,'win45') | strcmp(HOSTNAME,'win10'),
  if isfield(ses,'DVD') & ses.DVD,
	ses.DataMri = 'e:/';
	ses.DataNeuro = 'e:/';
  else
	ses.DataMri = 'f:/DataMri/';
	ses.DataNeuro = 'f:/DataNeuro/';
  end;
end;

if isfield(ses,'DataNeuro'),
  ses.sysp.physdir = ses.DataNeuro;
end;

if isfield(ses,'DataMri'),
  ses.sysp.mridir = ses.DataMri;
end;

if isfield(ses,'DataMatlab'),
  ses.sysp.matdir = ses.DataMatlab;
end;


% SET DEFAULT GROUP PARAMETERS, IF NEEDED.
if isfield(ses,'grpp') & isfield(ses,'grp'),
  grpnames = fieldnames(ses.grp);
  grpparam = fieldnames(ses.grpp);
  for N = 1:length(grpnames),
    grp = eval(sprintf('ses.grp.%s',grpnames{N}));
    for K = 1:length(grpparam),
      if ~isfield(grp,grpparam{K}),
        eval(sprintf('ses.grp.%s.%s = ses.grpp.%s;',...
                     grpnames{N},grpparam{K},grpparam{K}));
      end
    end
  end
  % remove 'grpp'
  ses = rmfield(ses,'grpp');
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ses = subGetSesNew(SessionName)

VERBOSE = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% evaluate session file and get session/analysis info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ACQP  = {};  SYSP  = {};  ANAP = {};
ASCAN = {};  CSCAN = {};  ROI  = {};
GRP   = {};  CTG   = {};  EXPP = {};
% If no session file was specified, ask for one.
if nargin < 1,
  tmpDir = pwd;	% Store cur dir.
  cd(ses.sysp.sesdir);
  [SessionName,ses.sysp.sesdir] = uigetfile('*.m','Select a session file.');
  cd(ses.sysp.sesdir);	% ses.sysp.sesdir could have ben changed.
  name = strrep(SessionName, '.m', '');
  if ~exist(name,'file'),
    fprintf('getses: SesFile %s does not exist!\n\n',strcat(name,'.m'));
    ses = {};
    return;
  end;
  eval(name);
  cd(tmpDir);
else
  % tmpDir = cd;				% Store cur dir.
  % cd(ses.sysp.sesdir);
  name = strrep(SessionName, '.m', '');
  if ~exist(name,'file'),
    fprintf('getses: SesFile %s does not exist!\n\n',strcat(name,'.m'));
    ses = {};
    return;
  end;
  eval(name);
  % cd(tmpDir);
end;



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initiaize 'ses' structure.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ses.name	= lower(SessionName);
ses.date	= lower(SYSP.date);
ses.acqp 	= getacqp;
ses.sysp	= getdirs;
ses.anap	= getanap('default');	% get default analysis parameters
ses.ascan	= ASCAN;
ses.cscan	= CSCAN;
ses.roi		= ROI;
ses.grp		= GRP;
ses.ctg		= {};  % set later
ses.expp	= EXPP;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SYSP PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overwrite with SYSP of the session file.
if isa(SYSP,'struct'),
  fnames = fieldnames(SYSP);
  for N = 1:length(fnames),
    cmdstr = sprintf('ses.sysp.%s = SYSP.%s;',fnames{N},fnames{N});
    eval(cmdstr);
  end
end

switch lower(ses.sysp.HOSTNAME),
 case {'win45','win10'}
  % Nikos's laptop
  if isfield(ses,'DVD') & ses.DVD,
	ses.sysp.DataMri = 'e:/';
	ses.sysp.DataNeuro = 'e:/';
  end
end;

% overwrite those.
if isfield(ses.sysp,'DataNeuro'),
  ses.sysp.physdir = ses.sysp.DataNeuro;
end;
if isfield(ses.sysp,'DataMri'),
  ses.sysp.mridir = ses.sysp.DataMri;
end;
if isfield(ses.sysp,'DataMatlab'),
  ses.sysp.matdir = ses.sysp.DataMatlab;
end;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ANAP PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overwrite with ANAP of the session file
if isa(ANAP,'struct'),
  fnames = fieldnames(ANAP);
  for N = 1:length(fnames),
    cmdstr = sprintf('ses.anap.%s = ANAP.%s;',fnames{N},fnames{N});
    eval(cmdstr);
  end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CTG PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ===========================================================================
% DEFAULT BLPs AND TO BE GROUPED SIGNALS
% Lfp [1 90] unrectified
% Gamma [24 90] unrectified
% LfpL/M/H Rectified in [1-12, 12-24, 24-90]
% MUA/SDF
% ===========================================================================
ses.ctg.RFSigs			= {'LfpH';'Mua';'Sdf'};
ses.ctg.SigBands		= {'Lfp', 'Gamma', 'Mua', 'Sdf'};

ses.ctg.GrpSigs			= {'LfpL';'LfpM';'LfpH';'Mua';'Spkt'; 'Sdf'};
ses.ctg.GrpRFSigs		= {'VLfpH3';'VMua3';'VSdf3'};
ses.ctg.GrpCFSigs		= {'cfLfp';'cfGamma';'cfMua';'cfSdf'};
ses.ctg.GrpCHSigs		= {'chLfp';'chGamma';'chMua';'chSdf'};
ses.ctg.GrpImgSigs		= {'Pts';'xcor'};

% overwrite with CTG of the session file
if isa(CTG,'struct'),
  fnames = fieldnames(CTG);
  for N = 1:length(fnames),
    cmdstr = sprintf('ses.ctg.%s = CTG.%s;',fnames{N},fnames{N});
    eval(cmdstr);
  end
end




% SET DEFAULT GROUP PARAMETERS, IF NEEDED.
if isa(GRPP,'struct'),
  grpnames = fieldnames(ses.grp);
  grpparam = fieldnames(GRPP);
  for N = 1:length(grpnames),
    grp = eval(sprintf('ses.grp.%s',grpnames{N}));
    for K = 1:length(grpparam),
      if ~isfield(grp,grpparam{K}),
        eval(sprintf('ses.grp.%s.%s = GRPP.%s;',...
                     grpnames{N},grpparam{K},grpparam{K}));
      end
    end
  end
end



if VERBOSE == -1,
  ses.sysp
  ses.acqp.evt
end;

return;
