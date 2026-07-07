function Cln = getcln_n97fs(Cln,grp,evt)
%GETCLN_N97FS - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
% A BUG OF THE QNX-PROGRAM RELATED TO CHANGE FROM InterTriggerTime
% to InterVolumeTime.
%
% See also GETCLN

NoObsp = Cln.evt.NoObsp;

if strfind(Cln.session,'n97fs1') > 0,
  switch lower(grp.name),
   case { 'flash1', 'flash2', 'flash3','flash4','flash5','flash6'}
	% There was a confusion in the ess-program (already fixed),
    % since 'InterTriggerTime' was changed to 'InterVolumeTime';
    Cln = getcln_npbugfix(Cln,grp);
	% 'Quit' button caused the problem.
	% QNX program was fixed to change nothing on Quit-callback.
	%Cln.stm.conditions{1} = [0 1 2 3];
	%Cln.stm.conditions{1} = [0 2 1 3];
	%Cln.stm.conditions{1} = [0 1 2 3];
	%Cln.stm.conditions{1} = [0 2 1 3];
	%Cln.stm.conditions{1} = [0 1 2 3];
	%Cln.stm.conditions{1} = [0 2 1 3];
	for k=1:length(Cln.stm.conditions),
	  conds = Cln.stm.conditions{k};
	  if conds(1) ~= 0,
		Cln.stm.conditions{k} = [0 conds(1:end-1)];
	  end
	end
   otherwise
  end
elseif strfind(Cln.session,'n97fs2') > 0,
  switch lower(grp.name),
   case { 'flash1', 'flash2', 'flash3','flash4','flash5','flash6'}
	% 'Quit' button caused the problem.
	% QNX program was fixed to change nothing on Quit-callback.
	for k=1:length(Cln.stm.conditions),
	  conds = Cln.stm.conditions{k};
	  if conds(1) ~= 0,
		Cln.stm.conditions{k} = [0 conds(1:end-1)];
	  end
	end
   otherwise
  end  
end


