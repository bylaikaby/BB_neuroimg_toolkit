function otcImg = mreshapeobsp(tcImg,Pattern,ModelNo)
%MRESHAPEOBSP - Average trials of one observation period
% otcImg = mreshapeobsp(tcImg,Pattern,ModelNo), is used for
% observation period with mulitple identical stimulation. It can
% increase SNR by detecting onset of stimulation through the MRI events
% and average triggerred to any given desired event.
%
% SEEALSO : SESGETCOND GETCOND GETPAT MRESHAPEOBSP_xxxx

if nargin < 3,  ModelNo = 1;  end;

% tcImg.dat(time,chans,obsp)  -> otcImg.dat(time,chans,nrepeats)
%DIM = length(size(tcImg.dat));

% tcImg.dat === X * Y * Slices * Time Points
DIM = 5;  % ALWAYS BE 3
otcImg = tcImg;
otcImg.dat = [];

% NOTE THAT THE MEANING OF "Pattern" is different.
if length(Pattern) == 1,
  % NEW CODE..., GET CONDITIONS ACCORDING TO TRIALID IN EVT-DATA.
  % NOTE: ONLY A SINGLE OBS PERIOD IS ACCEPTABLE.
  % get on-time of conditon and stimulus.
  % since there are delays between trial-start and stimont in MRI,
  % use the on time of the first stimulus in that corresponding trial.
  NoObsp = tcImg.evt.NoObsp;
  id_pattern = tcImg.stm.conditions{Pattern+1};
  stim_dt = [];  stim_v = [];  stim_t = [];
  for ObspNo = 1:NoObsp,
	pack;
    conds   = find(tcImg.evt.params{ObspNo}.trialid == Pattern);
    % check empty or not
	if isempty(conds), continue;  end
    condt   = tcImg.evt.times{ObspNo}.ttype;
    condt(end+1) = tcImg.evt.times{ObspNo}.end;
	
	% THIS IS NOT STIMON REALLY... IT'S ALL STIMULUS EVENTS, ON OR
    % OFF. AT THE QNX SIDE WE TAKE "EVERTHING" AS STIMULUS (EVEN IF
    % IT IS THE BACKGROUND...
    stimont = tcImg.evt.times{ObspNo}.stm';

    % parameter names, values
    prmnames  = tcImg.evt.prmnames;
    prmvalues = tcImg.evt.params{ObspNo}.prm{conds(1)}(1:length(prmnames))';
    % time-window in secs
	if isfield(tcImg.grp,'triallen'),
	  condur = tcImg.grp.triallen;
	else
	  condur = sum(tcImg.stm.dt{ObspNo}(1:length(id_pattern)));
	end
    tidx = 1:round(condur/tcImg.dx);
    % pick up relevant period.
    for k=1:length(conds),
      % find nearest stimon time
      ontidx = find(stimont >= condt(conds(k)) & stimont < condt(conds(k)+1));

	  % NKL 06.09.03 Added this for compatibility
	  TrialEnd = ((condt(conds(k)+1))-condt(conds(k)))/1000.0;

      % double-check, stimids must be the same as id_pattern.
      stmids = tcImg.evt.params{ObspNo}.stmid(ontidx)';
      if any(stmids(:) ~= id_pattern(:)),
        fprintf('\n mreshapeobsp: same trial_id but pattern differs.');
        fprintf(' conds=%d, ObspNo=%d ',k, ObspNo);
        continue;
      end
      % now selects dat
      ont = stimont(ontidx(1));
      tsel = tidx + round(ont/tcImg.dx/1000.);

      % Since the trial-length tends to be shorter than expected,
      % the last trial may cause the trouble of 'index exceeds ...'.
      % TAIL NaN to lacked part of data.
      if max(tsel) > size(tcImg.dat,4),
        fprintf('\n mreshapeobsp: data filled by NaN. ');
        fprintf('max(tsel)=%fs, size(tcImg.dat,4)=%fs ',...
                max(tsel)*tcImg.dx,size(tcImg.dat,4)*tcImg.dx);
        tend = size(tcImg.dat,4);
        tmpdata(:,:,:,find(tsel <= tend)) = squeeze(tcImg.dat(:,:,:,min(tsel):tend));
		% 22.05.03 NaN cause problem with show(ClnSpc)
		% We set missing values to ZERO!!!
        tmpdata(:,:,:,find(tsel >  tend)) = 0;
        tmpdata(:,:,:,find(tsel >  tend)) = 0;
        otcImg.dat = cat(DIM,otcImg.dat,tmpdata);
      else
        otcImg.dat = cat(DIM,otcImg.dat,squeeze(tcImg.dat(:,:,:,tsel)));
      end
      % variables for otcImg.stim
      if isempty(stim_dt),
        stim_dt = tcImg.stm.dt{ObspNo}(ontidx);
        stim_v  = tcImg.stm.v{ObspNo}(ontidx);
      end
      stim_t(:,k) = stimont(ontidx)' - ont;
    end
  end
  stim_t_avr = mean(stim_t,2)'/1000;
  %stim_t_avr(find(stim_t_avr > condur)) = condur;
  
  otcImg.cond.pattern   = Pattern;
  otcImg.cond.prmnames  = prmnames;
  otcImg.cond.prmvalues = prmvalues;

  otcImg.stm.dt = {};
  otcImg.stm.v  = {};
  otcImg.stm.t  = {};

  otcImg.stm.labels = tcImg.stm.labels(Pattern+1);
  otcImg.stm.condids = Pattern;
  otcImg.stm.conditions = id_pattern;
  otcImg.stm.dt{1} = stim_dt;
  otcImg.stm.v{1}  = [stim_v 0];

  % NKL 06.09.03 Added this for compatibility
  otcImg.stm.t{1}  = [stim_t_avr TrialEnd];
  otcImg.stm.prmnames = prmnames;
  otcImg.stm.prmvalues = prmvalues;

else
  % now look for the particular pattern.
  
  pat = getpat(tcImg,Pattern,ModelNo);
  try,
	for N=1:length(pat.t1),
	  t1 = round(pat.t1(N) / tcImg.dx);
	  t2 = round(pat.t2(N) / tcImg.dx);
	  if N==1,
		dt = t2-t1;
	  end;
	  if t2 <= size(tcImg.dat,4),
		otcImg.dat = cat(DIM,otcImg.dat,tcImg.dat(:,:,:,t1+1:t1+dt));
	  end;
	end;
	otcImg.cond.pattern = Pattern;

  catch,
	disp(lasterr);
	keyboard
  end;
end

