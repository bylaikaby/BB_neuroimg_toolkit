function varargout = findchan(SesName,GrpNames,SigName,pval)
%FINDCHAN - Find channels driven by the stimulus (for exclusion)
% varargout = FINDCHAN (SesName,GrpName,SigName) loads the desired signal
% (SigName) from a control group during which stimulation is expected
% to cause changes in neural activity and examines whether
% stimulus-induced modulation is significant. It returns all channels
% driven by the stimulus.
%
% H = FINDCHAN (SesName,GrpName,SigName) returns a string of zeros
% and ones; Zero means the default assumption (H0) cannot be
% rejected, and in this case means bad channel (default is that
% background and stimulus activity are coming from the same
% population); One means they are different;
%
% [H,p] = FINDCHAN (SesName,GrpName,SigName) the probability of 0/1
% over all experiments of the group;
%  
% Examples:
% chan = findchan('c98nm1',1);
%
VERBOSE = 0;
if nargin < 2,
  help findchan;
  return;
end;

if nargin < 3,
  SigName = 'LfpH';
end;

if nargin < 4,
  pval = 0.99;
end;

Ses = goto(SesName);

if isa(GrpNames,'char'),
  tmp=GrpNames;
  clear GrpNames;
  GrpNames{1} = tmp;
end;

K=1;
for GrpNo=1:length(GrpNames),
  grp = getgrpbyname(Ses,GrpNames{GrpNo});

  fprintf('%s Group: %s\n', gettimestring, GrpNames{GrpNo});
  fprintf('Processing Experiment ... ');
  for N=1:length(grp.exps),
    ExpNo = grp.exps(N);
    fprintf('%d ', ExpNo);
    Sig = sigload(SesName,ExpNo,SigName);
    if strcmpi(Sig.dir.dname,'Cln') | ...
          strcmpi(Sig.dir.dname,'Gamma') | ...
          strcmpi(Sig.dir.dname,'Lfp') | ...
          strcmpi(Sig.dir.dname,'ClnSpc'),
      if VERBOSE,
        fprintf('FINDCHAN: Signal %s is unrectified\n', Sig.dir.dname);
        fprintf('FINDCHAN: Using rms(%s)\n', Sig.dir.dname);
      end;
      Sig = sigrms(Sig);
    end;
    tmpH = sigttest(Sig);
    GrpH(:,K) = tmpH(:);
    K=K+1;
  end;
  fprintf('\n%s Done!\n');
end;
p = mean(GrpH,2);
p = p(:);
H = p;
H(find(p>=pval))=1;
H(find(p<pval))=0;

if nargout >= 1,
  varargout{1}=H;
end;

if nargout == 2,
  varargout{2} = p;
end;
