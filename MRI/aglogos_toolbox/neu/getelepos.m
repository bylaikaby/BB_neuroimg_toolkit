function npairs = getelepos(SESSION, GrpName)
%GETELEPOS - returns correct electrode position and distances
% GETELEPOS is used to place the "electrodes" where they belong and
% compute interelectrode distances
%
% The numbers within the hardch array m u s t be absolutely correct
% for the math analysis to make sense. each number m u s t
% correspond to the location of the electrode in the brain. the way
% our 4x4 grid is, electrode location is:
% 01 02 03 04
% 05 06 07 08
% 09 10 11 12
% 13 14 15 16
% The math analysis computes inter-electrode distance by evaluating
% the expression i = hardchan(i)
%
% EXAMPLE OF DESCRIPTION FILE
% ses.confunc.sigs		= {'LfpL', 'LfpM', 'LfpH', 'Mua', 'Sdf'};
% ses.confunc.algs		= {'kc'};
% ses.confunc.eleconfig	= [01 02 03 04; 05 06 07 08; ...
%						   09 10 11 12; 13 14 15 16];
% ===========================================================================
% ALL RELATED TO OUR MATH-BIZZ
% IMPORTANT NOTE:
% We have our Sig.dat with NxM
% N is the record length (depends on how long the obs period is)
% M is the number of CHANNELS
% **************************************************************
% YOU CAN ONLY USE NUMBER IN THE RANGE 1:length(hardch)
% When you want to take electrode 3 and 5 you should write:
% x1 = Sig.dat(:,ses.grp.name.hardch(3))
% x2 = Sig.dat(:,ses.grp.name.hardch(5))
% These two time series correspond to the positions
% ses.confunc.eleconfig(ses.grp.name.hardch(3))
% ses.confunc.eleconfig(ses.grp.name.hardch(5))
% In this file, where channel 12 was bad and the cable of electrode
% 16 was put into the 12, to get the channel 16 you have to do:
% mychan = find(ses.grp.name.hardch == 16);
% **************************************************************
% 
% IF YOU WANT TO ACCESS ONE PARTICULAR ELECTRODE USE THE
% EXPRESSION: Electrode 5 = ses.confunc.eleconfig(ses.grp.name.hardch(5))
% ===========================================================================

if ~nargin,
  SESSION = 'c98nm1';
  GrpName = 'movie1';
end;

VERBOSE = 1;

Ses = goto(SESSION);
grp = getgrpbyname(Ses,GrpName);

cf = Ses.anap.confunc;
cfg = cf.eleconfig;
[dim1, dim2] = size(cfg);

if VERBOSE,
  fprintf('getelepos: SESSION %s, GrpName %s\n', Ses.name,GrpName);
end;

dist  = getAllDist(Ses.anap.confunc.eleconfig) * Ses.anap.confunc.eledist;
pairs = getAllPairs( dim1, dim2);
for N=1:length(pairs),
  for K=1:size(pairs{N}),
	np{N}(K,1) = chanfromgrid(Ses,grp,pairs{N}(K,1));
	np{N}(K,2) = chanfromgrid(Ses,grp,pairs{N}(K,2));
  end;
end;

M=1;
for N=1:length(pairs),
  KK=1;
  NOTHING_THERE = 1;
  for K=1:size(pairs{N}),
	if ~(isnan(np{N}(K,1)) | isnan(np{N}(K,2))),
	  NOTHING_THERE=0;
	  npairs{M}.dat(KK,:) = np{N}(K,:);
	  KK=KK+1;
	end;
  end;
  if ~NOTHING_THERE,
	ndist(M) = dist(N);
	M=M+1;
  end;
end;

for N=1:length(npairs),
  npairs{N}.dist = ndist(N);
end;

if ~nargout,
  dspnpairs(Ses,grp,npairs);
end;
return;

%**************************************************************************
function dspnpairs(Ses,grp,npairs)
%**************************************************************************

if ~isfield(Ses.anap.confunc,'curtype'),
  
  TIT=sprintf('getelepos: Session: %s, Group: %s',  Ses.name, grp.name);
  mfigure([50 100 1100 800],TIT);
  set(gcf,'color',[0 0 .1]);
  set(gca,'xcolor','w');
  set(gca,'ycolor','w');
  
  COLPLOTS=4;
  ROWPLOTS=round(length(npairs)/COLPLOTS)+1;
  
  for N=1:length(npairs),
	hd(N) = subplot(ROWPLOTS,COLPLOTS,N);
	for C=1:size(Ses.anap.confunc.eleconfig,1),
	  plot(repmat([C],[size(Ses.anap.confunc.eleconfig,2) 1]),...
		   [1:size(Ses.anap.confunc.eleconfig,2)],'sk',...
		   'linestyle','none','markersize',8,'markerfacecolor','r');
	  hold on;
	end
	set(gca,'ydir','reverse');
	set(gca,'xtick',[],'ytick',[]);
	set(gca,'xlim',[-0.5 5],'ylim',[-0.5 5]);
	
	for C=1:size(npairs{N}.dat,1);
	  hold on;
	  [y1,x1] = find(Ses.anap.confunc.eleconfig==grp.hardch(npairs{N}.dat(C,1)));
	  [y2,x2] = find(Ses.anap.confunc.eleconfig==grp.hardch(npairs{N}.dat(C,2)));
	  line([x1 x2],[y1 y2],'color', 'y', 'linewidth',1);
	end
	set(gca,'color',[0 0 .8]);
	title(sprintf('Distance %5.3f (%d)', npairs{N}.dist,...
				  size(npairs{N}.dat,1)),'color','w');
  end;
else
  
  TIT=sprintf('getelepos: Session: %s, Group: %s',  Ses.name, grp.name);
  mfigure([50 100 800 800],TIT);
  for N=1:length(npairs),
	COL = [rand rand rand];

	d = Ses.anap.confunc.idist;
	for C=1:size(Ses.confunc.eleconfig,1),
	  plot(d*repmat([C],[size(Ses.anap.confunc.eleconfig,2) 1]),...
		   d*[1:size(Ses.anap.confunc.eleconfig,2)],'sk',...
		   'linestyle','none','markersize',2,'markerfacecolor','k');
	  hold on;
	end;
	tmp = (1+size(Ses.anap.confunc.eleconfig)) * Ses.anap.confunc.idist;
	limx = [0 tmp(1)]; limy = [0 tmp(2)];
	set(gca,'ydir','reverse');
	set(gca,'xlim',limx,'ylim',limy);
	for M=1:length(grp.hardch),
	  [x,y] = find(Ses.anap.confunc.eleconfig==grp.hardch(M));
	  plot(d*x,d*y,'sr','linestyle','none','markersize',6);
	end;
	
	for C=1:size(npairs{N}.dat,1);
	  hold on;
	  [x1,y1] = find(Ses.anap.confunc.eleconfig==grp.hardch(npairs{N}.dat(C,1)));
	  [x2,y2] = find(Ses.anap.confunc.eleconfig==grp.hardch(npairs{N}.dat(C,2)));
	  line(d*[x1 x2],d*[y1 y2],'color', COL , 'linewidth',1);
	end
	title(sprintf('Inter-Dot Distance %5.3f mm',Ses.anap.confunc.idist));
  end;

end;


return;


%**************************************************************************
function [chan, x, y] = chanfromgrid(Ses,grp,GridPos)
%**************************************************************************
chan = find(grp.hardch==GridPos);
if isempty(chan),
  chan = NaN;
  return;
end;

if nargout > 1,
  [x, y] = find(Ses.anap.confunc.eleconfig==GridPos);
end;
return;

%**************************************************************************
function pairarray = getAllPairs( dim1, dim2)
%**************************************************************************
%GETALLPAIRS - returns all combinations of index pairs of a dim1 x
% dim2 matrix, clustered in a cell array by different distances
% Andrei 9/30/03
filename = sprintf('Pairs%dx%d.mat',dim1,dim2);
if exist(filename,'file'),
  pairarray = matsigload(filename,'pairs');
else
  if nargin == 1,  m = dim1;  n = dim1; end;
  if nargin  == 2,   m = dim1;  n = dim2; end;
  if (n < 2) | (m < 2)
    error('dim1 and dim2 must be greater than 1');
  end

  % generate M x N points on coordinate system 
  ind = 1;
  for K = 1:m
    for L = 1:n
	  chan( ind:ind+1) = [K L];
	  ind = ind + 2;
    end
  end
  chan = reshape( chan, 2, m*n)';
  label = pdist( chan);

  % associate distances with the generated points
  ind = 1;
  for K = 1 : m*n
    for L = K+1 : m*n
	  pair( ind).val = [K L];
	  pair( ind).dist = label( ind);
	  ind = ind + 1;
    end
  end

  % sort points based on distance
  [pair indices] = fieldsort( pair, 'dist');
  cellind = 1;
  ind = 1;
  bSwitch = 0; % when to switch to next cell of dist cell array
  for K = 1 : size( pair, 2)-1
    if pair(K).dist ~= pair(K+1).dist
	  bSwitch = 1;
    else
	  bSwitch = 0;
    end;
    if bSwitch
	  pairarray{ cellind}(ind:ind+1) = pair(K).val;
	  pairarray{ cellind} = reshape( pairarray{ cellind}, 2, (ind+1)/2)';
	  cellind = cellind + 1;
	  ind = 1;        
    else
	  pairarray{ cellind}(ind:ind+1) = pair(K).val;
	  ind = ind + 2;
    end;
  end;
  pairarray{ cellind}(ind:ind+1) = pair(K+1).val;                      % account for last index
  pairarray{ cellind} = reshape( pairarray{ cellind}, 2, (ind+1)/2)'; % reshape last distance matrix
end;
return;

%**************************************************************************
function [s, indices] = fieldsort( s, cField)
%**************************************************************************
% sorts a cell structure array based on a numeric field
nSize = size( s, 2);
indices = 1:nSize;
for K = 1 : nSize
    for L = 1 : nSize - K
        if s(L).(cField) > s(L+1).(cField)
            temp = s(L);
            s(L) = s(L+1);
            s(L+1) = temp;
            nTemp = indices(L);
            indices(L) = indices(L+1);
            indices(L+1) = nTemp;
        end
    end
end			   

%**************************************************************************
function distval = getAllDist(EleGrid)
%**************************************************************************
[m,n] = size(EleGrid);
% generate M x N points on coordinate system 
ind = 1;
for K = 1:m
    for L = 1:n
        chan( ind:ind+1) = [K L];
        ind = ind + 2;
    end
end
chan = reshape( chan, 2, m*n)';
label = pdist( chan);

% get the all possible distance values
tmp = sort(label);
ind = 1;
for K = 1:length(tmp)-1
    if tmp(K) ~= tmp(K+1)
        distval(ind) = tmp(K);
        ind = ind + 1;
    end;
end;
distval(ind) = tmp(K);


