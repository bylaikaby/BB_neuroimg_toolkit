function Cln = getcln_b01nm3(Cln,grp,evt)
%GETCLN_B01NM3 - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
% MULTIPLE OBSERVATION PERIODS.
%
% See also GETCLN

dgz = dg_read(Cln.dir.evtfile);

% stmdur is invalid since NumTriggers is not saved in event files.
% 27 as E_STIMULUS
for N = 1:length(Cln.evt.validobsp),
  stmdur = selectprm(dgz,Cln.evt.validobsp(N),27,1);
  Cln.grp.t{N} = stmdur';
  Cln.evt.params{N}.stmdur = stmdur';
  Cln.stm.dt{N} = stmdur' * Cln.grp.voldt;
end

NoObsp = Cln.evt.NoObsp;


% remove 250ms offset
for k=1:NoObsp,
  Cln.evt.times{k}.stm(1) = Cln.evt.times{k}.stm(1) + 250;
  Cln.stm.dt{k}(1) = Cln.stm.dt{k}(1) - 0.25;
  Cln.stm.t{k}(1) = Cln.stm.t{k}(1) + 0.25;
end
  

switch lower(grp.name),
 case { 'autoplot' }
  return;
 case { 'movstat' }
  for k=1:NoObsp,
    for x = 1:4,
      Cln.evt.times{k}.ttype(x) = Cln.evt.times{k}.stm((x-1)*3+1);
      Cln.evt.params{k}.trialid(x) = 0;
    end
  end
 case { 'flash' }
  for k=1:NoObsp,
    tmpprm = Cln.evt.params{k}.prm{1};
    if tmpprm(1) == 0 & tmpprm(2) == 0,
      Cln.evt.params{k}.trialid = 0;
    elseif tmpprm(1) == 1 & tmpprm(2) == 0,
      Cln.evt.params{k}.trialid = 1;
    elseif tmpprm(1) == 0 & tmpprm(2) == 1,
      Cln.evt.params{k}.trialid = 2;
    elseif tmpprm(1) == 1 & tmpprm(2) == 1,
      Cln.evt.params{k}.trialid = 3;
    elseif tmpprm(1) == 0 & tmpprm(2) == 2,
      Cln.evt.params{k}.trialid = 4;
    elseif tmpprm(1) == 1 & tmpprm(2) == 2,
      Cln.evt.params{k}.trialid = 5;
    end
  end
 otherwise
end

