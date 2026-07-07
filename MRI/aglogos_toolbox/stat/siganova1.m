function siganova1(Sig)
%SIGANOVA1 - Compute One-Way Anova between blank and stim conditions  

if nargin < 1,
  help siganova1;
  return;
end;

blk = sigselepoch(Sig,'blank');
stm = sigselepoch(Sig,'nonblank');

stm.dat = stm.dat(1:size(blk.dat,1),:);

for N=1:size(blk.dat,2),
  grp{N} = 'b';
end;

for N=size(blk.dat,2)+1:size(blk.dat,2)+size(stm.dat,2),
  grp{N} = 's';
end;

[p,tabl,stat] = anova1([blk.dat stm.dat],grp);
