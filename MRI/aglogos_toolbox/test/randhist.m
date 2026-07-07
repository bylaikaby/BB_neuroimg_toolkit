function [rhist nodes seq] = randhist(nstate,lookback,nrep)
if nargin < 2,  lookback = 2;  end
if nargin < 3,  nrep = 1;      end

nnodes = nstate^(lookback+1);

fprintf(' nodes..'); drawnow;
nodes = zeros(nnodes,lookback+1,'int16');
for N = 0:nnodes-1,
  %for N = 0:9,
  tmpi = N;
  for K = lookback:-1:0, 
    nodes(N+1,K+1) = mod(floor(tmpi),nstate);
    tmpi = tmpi / nstate;
  end
end
%nodes
%nodes = nodes(randperm(nnodes),:);  % makes slower to find the solution


fprintf(' adjacent..'); drawnow;

adjacent = zeros(nnodes,nnodes,'int8');
% for N = 1:nnodes,
%   for K = 1:nnodes,
%     if (all(nodes(N,2:end) == nodes(K,1:end-1))),
%       adjacent(N,K) = 1;
%     end
%   end
% end
% adjacent0 = adjacent;
% adjacent(:) = 0;
for N = 1:nnodes,
  offs = mod(N-1,nnodes/nstate)*nstate;
  for K = 1:nstate,
    adjacent(N,K+offs) = 1;
  end
end

%fprintf('%d',isequal(adjacent0,adjacent));



seq = NaN(1,nnodes);

set(0,'RecursionLimit',40000);
fprintf(' searching(%d)...',nnodes);


startidx = randperm(nnodes);

tic
for N = 1:length(startidx),
  inode = startidx(N);
  seq(:) = NaN;
  last_cand = [];
  for K = 1:nnodes,
    if all(nodes(inode,1:lookback) == nodes(K,2:end)),
      last_cand(end+1) = K;
    end
  end
  [seq iseq] = try_visit(inode,0,seq,nnodes,nnodes,adjacent,last_cand);
  if iseq == nnodes,
    fprintf('\n%4d: ok %s- %s',N, sprintf('%3d ',nodes(seq(1),:)),sprintf('%3d ',nodes(seq(end),:)));
    break;
  else
    fprintf('\n%4d: failed.',N);
  end
end
fprintf(' %gs',toc);


rhist = nodes(seq(1),:);
for K = 2:length(seq),
  rhist(end+1) = nodes(seq(K),end);
end


%plot(rhist);  hold on;
fprintf(' done.\n');

return




function [seq iseq] = try_visit(inode,iseq,seq,nseq,nnodes,adjacent,last_cand)

iseq      = iseq + 1;
seq(iseq) = inode;


if iseq == nseq,  return;  end

%last_cand(last_cand == inode) = 0;
%if (all(last_cand == 0)),  return;  end



for K = 1:nnodes,
  if adjacent(inode,K) == 1 && ~any(seq == K),
    [tmpseq,tmpi] = try_visit(K,iseq,seq,nseq,nnodes,adjacent,last_cand);
    if tmpi == nseq,
      seq  = tmpseq;
      iseq = tmpi;
      %fprintf('\n%d/%d',tmpi,nseq);
      return;
    else
      %fprintf('\n%d/%d',tmpi,nseq);
    end
  end
end


return

