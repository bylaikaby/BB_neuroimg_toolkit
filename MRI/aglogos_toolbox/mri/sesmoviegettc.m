function sesmoviegettc(SESSION,EXPS,ExpNo)
%SESMOVIEGETTC - Get Time series on the basis of reference session
% SESMOVIEGETTC - This ensures that will be always using the same
% grid for computing the distances.

% See also MOVIETTEST MCORANA MCORIMG MKMODEL

if nargin < 3,		% Default reference is the first experiment
  ExpNo = 1;
end;

Ses	= goto(SESSION);
grps = getgroups(Ses);
filename = catfilename(Ses,ExpNo);
if ~exist(filename,'file'),
  fprintf('sesmoviettest: Reference file %s was not found\n',filename);
  keyboard;
end;

ref = matsigload(filename,'zsts');

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for ExpNo = EXPS,
  fname = catfilename(Ses,ExpNo);
  grp = getgrp(Ses,ExpNo);
  var = who('zsts','-file',fname);
  if ~isempty(var),
	fprintf('Reading zsts from %s\n', fname);
	load(fname,'zsts');
  else
	zsts = ref;
	for K=1:length(zsts),
	  zsts{K}.grpname		= grp.name;
	  zsts{K}.ExpNo			= ExpNo;
	end;
	fprintf('Using refence-zsts from file %s\n', filename);
  end;
  
  for SliceNo = 1:length(zsts),
	FSCAN=1;
	if ~isfield(zsts{SliceNo}.stm,'v'), FSCAN=0; end;
	if isempty(zsts{SliceNo}.stm.v), FSCAN=0; end;
	if ~any(zsts{SliceNo}.stm.v{1}), FSCAN=0; end;
	if ~FSCAN,
	  csts{SliceNo}.stm = ref{SliceNo}.stm;
	end;

	zsts{SliceNo}.map = ref{SliceNo}.map;
	zsts{SliceNo}.xy = ref{SliceNo}.xy;
	zsts{SliceNo}.dat = [];
  end;

  moviegettc(Ses,ExpNo,zsts);
end;










