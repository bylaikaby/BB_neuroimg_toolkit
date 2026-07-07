function Cln = getcln_c01jw1(Cln,grp,evt)
%GETCLN_C01JW1 - microstimulation experiments were done by old program.
%
% See also GETCLN

switch lower(grp.name),
 case { 's50h20ua', 's50h40ua', 's50h80ua' ,'s50h160ua' }
  voldt = 0.25;
  ntrigsPerVol = 2;
  conditions = grp.v;
  condids = [0];
  triallen = sum(grp.t{1})*voldt;
  % fix grp
  Cln.grp.voldt = voldt;
  Cln.grp.labels = { grp.stminfo };
  Cln.grp.condids = condids;
  Cln.grp.conditions = conditions;
  Cln.grp.triallen = triallen;
  % fix evt
  Cln.evt.numTriggersPerVolume = ntrigsPerVol;
  for k=1:Cln.evt.NoObsp,
    Cln.evt.params{k}.trialid = 0;
    Cln.evt.params{k}.stmid = grp.v{k}';
    Cln.evt.params{k}.stmdur = grp.t{k}';
    Cln.evt.params{k}.prm{1} = zeros(1,32);
  end
  % fix stm
  Cln.stm.voldt = voldt;
  Cln.stm.labels = { grp.stminfo };
  Cln.stm.condids = condids;
  Cln.stm.conditions = conditions;
  for N = 1:length(grp.validobsp),
    Cln.stm.v{N}  = [grp.v{N} 0];   % the tail as 'blank';
    Cln.stm.dt{N} = grp.t{N} * voldt;
    % 28.05.03 YM
    % no averaging of stimulus timing here.
    % reshapeobsp.m called by getcond.m will do averaging.
    Cln.stm.t{N}  = Cln.evt.times{N}.stm/1000.;
    if isempty(Cln.stm.t{N}), continue;  end
    if Cln.stm.t{N}(end) > grp.adflen,
      Cln.stm.t{N}(end) = grp.adflen;
    else
      Cln.stm.t{N}(end+1) = grp.adflen;
    end
  end
  
  
 otherwise
  % nothing to be changed.
end