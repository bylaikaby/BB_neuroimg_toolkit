function npairs = atgetelepos(SESSION, GrpName, cfgType)
%ATGETELEPOS - returns correct electrode position and distances
% ATGETELEPOS (SESSION, GrpName, cfgType) is used to place the
% "electrodes" where they belong and compute interelectrode
% distances. For the data of Andreas we have the following possible
% configurations that are determined by the argument cfgType
% [tetrode, wire, cell].
% ===========================================================================
% THE TETRODE CONFIGURATION (ONLY FOR atLFP)
% ===========================================================================
% TETCONFIG = [ 10 08 07 06; ...
%			  11 09 05 04; ...
%			  13 12 02 03; ...
%			  15 14 1 16];
% TETDIST = 0.200;			% 200 microns
% ses.confunc.intraD		= 0.050;	% 50 microns between wires
% ses.confunc.intraC		= 0.015;	% 15 microns between "cells"

% ===========================================================================
% ASSUMED TETRODE-WIRE CONFIGURATION (FOR CLN)
% ===========================================================================
% WIRECONFIG = [1 2;
%			  3 4];
% WIREDIST = 0.050;
%
% ===========================================================================
% VIRTUAL ELECTRODE CONFIGURATION
% THIS HERE IS A SHORTCUT TO EXPRESS MULTIPLE CELLS, ISOLATED WITH
% THE CLUSTERING PERFORMED BY ANDREAS, AS NEURONS COLLECTED WITH
% DIFFERENT ELECTRODES VERY CLOSE TO EACH OTHER. WE ASSUME THERE
% WON'T BE MORE THAN 16 CELLS PER TETRODE.
% FOR atSpkt/atSdf nd muaSpkt muaSdf
% ===========================================================================
% CELLCONFIG	= [ 01 02 03 04; ...
%				05 06 07 08; ...
%			    09 10 11 12; ...
%				13 14 15 16];
% CELLDIST = 0.015;
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
  SESSION = 'd98at1';
  GrpName = 'spont1';
  cfgType = 'wire';
end;

if nargin & nargin < 3,
  cfgType = 'wire';
end;

if nargin & nargin < 2,
  error('usage: atgetelepos(SESSION,GrpName,cfgType);');
end;

VERBOSE = 1;

Ses = atgetelepos_goto(SESSION);	% Just to get the Ses structure
grp = getgrpbyname(Ses,GrpName);

Ses = atgetconfig(Ses,cfgType);
[dim1, dim2] = size(Ses.confunc.eleconfig);

if VERBOSE,
  fprintf('atgetelepos: SESSION %s, GrpName %s\n', Ses.name,GrpName);
end;

dist  = getAllDist(Ses.confunc.eleconfig) * Ses.confunc.idist;
if strcmp(cfgType,'cell'),
  load('Pairs12x12.mat');
  LIM = [-0.05 12.05];
  SQ_SIZE=2;
else
  pairs = getAllPairs( dim1, dim2);
  SQ_SIZE=8;
  LIM = [-0.5 5];
end;

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
  dspnpairs(Ses,grp,npairs,SQ_SIZE,LIM);
end;
return;

%**************************************************************************
function dspnpairs(Ses,grp,npairs,SQ_SIZE,LIM)
%**************************************************************************
mfigure([100 100 700 700],'Unique Intra-Electrode Distances');

eleconfig	= Ses.confunc.eleconfig;
idist		= Ses.confunc.idist;
maxchan		= Ses.confunc.maxchan;
chan		= Ses.confunc.chan;

try,
COLPLOTS=Ses.confunc.subplot(1);
ROWPLOTS=Ses.confunc.subplot(2);

for N=1:length(npairs),
  hd(N) = subplot(ROWPLOTS,COLPLOTS,N);
  for C=1:size(Ses.confunc.eleconfig,1),
	plot(repmat([C],[size(Ses.confunc.eleconfig,2) 1]),...
		 [1:size(Ses.confunc.eleconfig,2)],'sk',...
		 'linestyle','none','markersize',SQ_SIZE,'markerfacecolor','k');
	hold on;
  end
  set(gca,'ydir','reverse');
  set(gca,'xtick',[],'ytick',[]);
  set(gca,'xlim',LIM,'ylim',LIM);

  for C=1:size(npairs{N}.dat,1);
	hold on;
	[y1,x1] = find(Ses.confunc.eleconfig==chan(npairs{N}.dat(C,1)));
	[y2,x2] = find(Ses.confunc.eleconfig==chan(npairs{N}.dat(C,2)));
	line([x1 x2],[y1 y2],'color', 'b', 'linewidth',1);
  end
  title(sprintf('Distance %5.3f (%d)\', npairs{N}.dist,...
				size(npairs{N}.dat,1)));
end;
catch,
  disp(lasterr);
  keyboard;
end;

return;


%**************************************************************************
function [chan, x, y] = chanfromgrid(Ses,grp,GridPos)
%**************************************************************************
chan = find(Ses.confunc.chan==GridPos);
if isempty(chan),
  chan = NaN;
  return;
end;

if nargout > 1,
  [x, y] = find(Ses.confunc.eleconfig==GridPos);
end;
return;

%**************************************************************************
function [pairarray, distval] = getAllPairs( dim1, dim2)
%**************************************************************************
%GETALLPAIRS - returns all combinations of index pairs of a dim1 x
% dim2 matrix, clustered in a cell array by different distances
% Andrei 9/30/03

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


%**************************************************************************
function Ses = atgetelepos_goto(SESSION)
%**************************************************************************
if isa(SESSION,'char'),
	Ses = atgetelepos_getses(SESSION);
else
	Ses = SESSION;
end;

cDir = strcat(Ses.sysp.matdir,Ses.dirname,'/');
cd(cDir);

%**************************************************************************
function ses = atgetelepos_getses(SessionName)
%**************************************************************************
ses.name	= '';
ses.dirname = '';
OS = computer;				% Operating system.
if isunix,   OS = 'UNIX'; end;

ses.sysp = getdirs;
tmpDir = cd;				% Store cur dir.
cd(ses.sysp.sesdir);
name = strrep(SessionName, '.m', '');
if ~exist(name,'file'),
  fprintf('getses: SesFile %s does not exist!\n\n',strcat(name,'.m'));
  ses = {};
  return;
end;
eval(name);
cd(tmpDir);
ses.name = lower(strrep(ses.dirname,'.',''));

HOSTNAME = getHostName;
if strcmp(HOSTNAME,'win45') | strcmp(HOSTNAME,'win10'),
  if isfield(ses,'DVD') & ses.DVD,
	ses.DataMri = 'e:/';
	ses.DataNeuro = 'e:/';
  else
	ses.DataMri = 'f:/DataMri/';
	ses.DataNeuro = 'f:/DataNeuro/';
  end;
end;
if isfield(ses,'DataNeuro'),
  ses.sysp.physdir = ses.DataNeuro;
end;
if isfield(ses,'DataMri'),
  ses.sysp.mridir = ses.DataMri;
end;
if isfield(ses,'DataMatlab'),
  ses.sysp.matdir = ses.DataMatlab;
end;

