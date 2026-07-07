function em = emload(SESSION,arg2)
%EMLOAD - Loads a MAT file with our signals (Cln, tcImg, etc.)
%	emload: Load em from mat-file directly into vars in workspace.
%	usage: [varargout] = emload(File, varargin):
%	NKL, 10.10.02

if nargin < 1,
	error('usage: em = emload(SESSION,[GrpName/ExpNo]);');
end;

if nargin < 2,
	arg2 = 'fix';
end;

if isa(arg2,'char'),
	GrpName = arg2;
	name = strcat(GrpName,'.mat');
else
	ExpNo = arg2;
	name = catfilename(Ses,ExpNo,'mat');
end;

Ses = goto(SESSION);
load(name,'em');
