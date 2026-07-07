function Cln = getcln_npbugfix(Cln)
%GETCLN_NPBUGFIX - THE FOLLOWING CODE LINES ARE SPECIFIC TO THIS SESSION THAT HAS
% A BUG OF THE QNX-PROGRAM RELATED TO CHANGE FROM InterTriggerTime
% to InterVolumeTime.
%
% See also GETCLN
  
% There was a confusion in the ess-program (already fixed),
% since 'InterTriggerTime' was changed to 'InterVolumeTime';
for k=1:size(Cln.stm.dt)
  Cln.stm.dt{k} = Cln.stm.dt{k} * Cln.evt.numTriggersPerVolume;
end
