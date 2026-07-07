function sesgetlfpmuaflt(SESSION,EXPS,SigName)
%SESGETLFPMUAFLT - Get Lfp/Mua/LfpH etc.
% SESGETLFPMUAFLT - The function extracts the basic signals from Cln.
% arg2 can be ExpNo or GrpName
% SigName can be allsigs, lfp, rawlfp or mua
%
% case 'allsigs',			% Gamma, Lfp, Mua, LfpL, LfpM, LfpH
%   getbandsflt(Ses,ExpNo,{});
% case 'lfp';				% LfpL, LfpM, LfpH
%   getbandsflt(Ses,ExpNo,{'LfpL','LfpM','LfpH'});		
% case 'rawlfp';			% Gamma, Lfp
%   getbandsflt(Ses,ExpNo,{'Gamma','Lfp'});	
% case 'mua';				% Mua
%   getbandsflt(Ses,ExpNo,{'Mua'});		
%
% See also
% SESGETSIGS GETLFP GETMUA
% NKL 09.10.03
  
if nargin == 0,
  SESSION = 'c98nm1';
  EXPS = [1];
end

if nargin & nargin < 3,
  SigName = 'allsigs';
end;

Ses = goto(SESSION);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

LEN=length(EXPS);
for N = 1:length(EXPS),
  ExpNo = EXPS(N);
  fprintf('SESGETLFPMUAFLT: %3d/%3d ExpNo = %d\n', N,LEN,ExpNo);
  grp=getgrp(Ses,ExpNo);
  if isrecording(Ses,grp.name),
	switch lower(SigName),
     case 'allsigs',			% Gamma, Lfp, Mua, LfpL, LfpM, LfpH
      getbandsflt(Ses,ExpNo);
	 case 'lfp';				% LfpL, LfpM, LfpH
      getbandsflt(Ses,ExpNo,{'LfpL','LfpM','LfpH'});
      %getlfp(Ses,ExpNo);		
	 case 'rawlfp';				% Gamma, Lfp
      getbandsflt(Ses,ExpNo,{'Gamma','Lfp'});
      %getrawlfp(Ses,ExpNo);
     case {'lfp-only','lfponly'}
      getbandsflt(Ses,ExpNo,{'Lfp'});
	 case 'mua';				% Mua
      getbandsflt(Ses,ExpNo,{'Mua'});
      %getmua(Ses,ExpNo);
	 case 'umua';				% Mua
      getbandsflt(Ses,ExpNo,{'uMua'});
      %getmua(Ses,ExpNo);
	 otherwise,
	  fprintf('sesgetlfpmuaflt: Unknown signal name\n');
	  keyboard;
	end;
  end;
end;


