function sesgrpstat(SESSION,GrpNames,LOG)
%SESGRPSTAT - Group all statistical values and functions
% SESGRPSTAT groups all the values and functions computed by
% EXPGETSTAT.
% ????????????????????? MORE DOCS
% See also SIGSTS

EXCLUDES = {'spont','baseline'};

Ses = goto(SESSION);

if nargin < 3,
  LOG=0;
end;

if nargin < 2 | isempty(GrpNames),
	grps = getgroups(Ses);
	for N=1:length(grps),
	  GrpNames{N} = grps{N}.name;
	end;
else
  if isa(GrpNames,'char'),
	tmp = GrpNames; clear GrpNames;
	GrpNames{1} = tmp;
  end;
end;

if LOG,
  LogFile=strcat('SESGRPSTAT_',Ses.name,'.log');	% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

for N=1:length(GrpNames),
  grp=getgrpbyname(Ses,GrpNames{N});
  filename = strcat(grp.name,'.mat');
  if any(strncmp(EXCLUDES,grp.name,5)),
    continue;
  end;

  for K=1:length(grp.exps),
    ExpNo = grp.exps(K);
    [stslfp,stsmua,stssdf] = sigload(Ses,ExpNo,'stslfp','stsmua','stssdf');
    if isempty(stslfp) | isempty(stsmua) | isempty(stssdf),
      fprintf('SESGRPSTAT: No stsSIG was found\n');
      keyboard;
    end;
   
    fprintf('%s: Proc Ses: %s, Group: %s, ExpNo = %d\n', ...
            gettimestring, Ses.name, grp.name,ExpNo);

    if K==1,
      grplfp = stslfp;
      grpmua = stsmua;
      grpsdf = stssdf;
    else
      grplfp.bacr = cat(3,grplfp.bacr,stslfp.bacr);
      grpmua.bacr = cat(3,grpmua.bacr,stsmua.bacr);
      grpsdf.bacr = cat(3,grpsdf.bacr,stssdf.bacr);

      grplfp.sacr = cat(3,grplfp.sacr,stslfp.sacr);
      grpmua.sacr = cat(3,grpmua.sacr,stsmua.sacr);
      grpsdf.sacr = cat(3,grpsdf.sacr,stssdf.sacr);

      %      pval: 6.6667e-004
      %       bkg: [1x15 double]
      %       stm: [1.1191 1.0971 ...
      %    bkgstd: [0.9977 1.0041 ...
      %    stmstd: [1.6928 1.7035 ...
      %         t: [66.8863 62.1884 ...
      %       idx: [1 1 1 1 1 1 1 1 1 1 1 0 1 1 0]

      grplfp.tt.pval = cat(1,grplfp.tt.pval,stslfp.tt.pval);
      grplfp.tt.bkg = cat(1,grplfp.tt.bkg,stslfp.tt.bkg);
      grplfp.tt.stm = cat(1,grplfp.tt.stm,stslfp.tt.stm);
      grplfp.tt.bkgstd = cat(1,grplfp.tt.bkgstd,stslfp.tt.bkgstd);
      grplfp.tt.stmstd = cat(1,grplfp.tt.stmstd,stslfp.tt.stmstd);
      grplfp.tt.t = cat(1,grplfp.tt.t,stslfp.tt.t);

      grpmua.tt.pval = cat(1,grpmua.tt.pval,stsmua.tt.pval);
      grpmua.tt.bkg = cat(1,grpmua.tt.bkg,stsmua.tt.bkg);
      grpmua.tt.stm = cat(1,grpmua.tt.stm,stsmua.tt.stm);
      grpmua.tt.bkgstd = cat(1,grpmua.tt.bkgstd,stsmua.tt.bkgstd);
      grpmua.tt.stmstd = cat(1,grpmua.tt.stmstd,stsmua.tt.stmstd);
      grpmua.tt.t = cat(1,grpmua.tt.t,stsmua.tt.t);

      grpsdf.tt.pval = cat(1,grpsdf.tt.pval,stssdf.tt.pval);
      grpsdf.tt.bkg = cat(1,grpsdf.tt.bkg,stssdf.tt.bkg);
      grpsdf.tt.stm = cat(1,grpsdf.tt.stm,stssdf.tt.stm);
      grpsdf.tt.bkgstd = cat(1,grpsdf.tt.bkgstd,stssdf.tt.bkgstd);
      grpsdf.tt.stmstd = cat(1,grpsdf.tt.stmstd,stssdf.tt.stmstd);
      grpsdf.tt.t = cat(1,grpsdf.tt.t,stssdf.tt.t);
    
      grplfp.bmedian = cat(1,grplfp.bmedian,stslfp.bmedian);
      grplfp.smedian = cat(1,grplfp.smedian,stslfp.smedian);
      grpmua.bmedian = cat(1,grpmua.bmedian,stsmua.bmedian);
      grpmua.smedian = cat(1,grpmua.smedian,stsmua.smedian);
      grpsdf.bmedian = cat(1,grpsdf.bmedian,stssdf.bmedian);
      grpsdf.smedian = cat(1,grpsdf.smedian,stssdf.smedian);
    end;
  end;
  stslfp = grplfp; clear grplfp;
  stsmua = grpmua; clear grpmua;
  stssdf = grpsdf; clear grpsdf;
  
  if ~exist(filename,'file'),
    save(filename,'stslfp','stsmua','stssdf');
    fprintf('%s: Saved in file %s\n', gettimestring, filename);
  else
    save(filename,'-append','stslfp','stsmua','stssdf');
    fprintf('%s: Appended in file %s\n', gettimestring, filename);
  end;
end

if LOG,
  diary off;
end;

