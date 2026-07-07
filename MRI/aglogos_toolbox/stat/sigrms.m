function oSig = sigrms(Sig, Epochs, voldt)
%SIGRMS - Computes the RMS values for each window with size Sig.stm.voldt
% vals = sigrms (Sig) computes the root mean square of each wsize-window of a time series.
%
% oSig = SIGRMS (Sig) computes the RMS values of the blank and nonblank periods. If no output
% argument exists, the results will be displayed as bargraph.
%  
% oSig = SIGRMS (Sig, Epochs) computes the RMS values for all epochs defined in the input
% argument "Epochs".  If no output argument exists, the results will be displayed as bargraph.
%
% oSig = SIGRMS (Sig, 'window') computes the RMS values for all successive windows with length
% voldt; If no voldt is define the Ses.stm.voldt is used.
%
% See also EXPRMS
%
% NKL, 11.03.00

if ~exist('Epochs','var'),
  Epochs = {'blank'; 'nonblank'};
  EpochNames = {'blank'; 'stim'};
  StimID = [0 1];
else
  if isa(Epochs,'char'),
    tmp=Epochs; clear Epochs;
    Epochs{1} = tmp;
    StimID = find(strcmp(Epochs{1},Sig.stm.stmtypes));
    EpochNames{1} = Epochs{1};
  end;
  if isempty(Epochs),
    for N=1:length(Sig.stm.v{1}),
      Epochs{N} = sprintf('stim%d', Sig.stm.v{1}(N));
    end;
    StimID = Sig.stm.v{1};
    EpochNames = Sig.stm.stmtypes;
  else
    EpochNames = Epochs;
    ix = find(strcmp(EpochNames,'nonblank'));
    if ~isempty(ix),
      EpochNames{ix} = 'stim';
      StimID = zeros(length(EpochNames),1);
      StimID(ix)=1;
    end;
  end;
end;

oSig = rmfield(Sig,'dat');

if ~isfield(Sig,'stm'),
  fprintf('SIGRMS: Signal does not have the STM field\n');
  fprintf('SIGRMS: Try to load it by using sigload(SesName,ExpNo);\n');
  return;
end;

if ~exist('voldt','var') & ~isfield(Sig.stm,'voldt'),
  fprintf('SIGRMS: Sig.stm does not have the voldt field\n');
  fprintf('SIGRMS: Old version?? Check expgetpars\n');
  return;
end;

if length(Epochs)==1 & strcmp(Epochs{1},'window'),
  StimID = -1;
  if ~exist('voldt','var'),
    voldt = Sig.stm.voldt;
  end;
  LEN = round(voldt/Sig.dx);
  SIGLEN = size(Sig.dat,1);
  NREP = floor(SIGLEN/LEN);
  efflen = NREP * LEN;
  
  NoObsp = size(Sig.dat,3);
  NoChan = size(Sig.dat,2);
  
  for ObspNo = 1:NoObsp,
    for ChanNo = 1:NoChan,
      tmp = Sig.dat(1:efflen,ChanNo,ObspNo);
      tmp = reshape(tmp,[LEN NREP]);
      for N=1:size(tmp,2),
        v(N) = norm(tmp(:,N))./sqrt(LEN);
      end;
      vals(:,ChanNo,ObspNo) = v(:);
    end;
  end;
  
  oSig.dat = vals;
  oSig.dx = LEN * Sig.dx;
  oSig.names{1} = 'obsp';
  oSig.stmid = StimID;
else

  for N = 1:length(Epochs),
    ep{N} = sigselepoch(Sig,Epochs{N});
    for K=1:size(ep{N}.dat,2),
      rms = norm(ep{N}.dat(:,K))./sqrt(size(ep{N}.dat,1));
      oSig.dat(K,N) = rms;
    end;
  end;
  oSig.names = EpochNames;
  oSig.stmid = StimID;
  oSig.dx = Sig.dx;

end;
return;

