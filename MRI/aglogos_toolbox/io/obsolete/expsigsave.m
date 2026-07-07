function expsigsave(SESSION,ExpNo, varargin)
%EXPSIGSAVE - Saves Sig to matfile of SESSION and ExpNo
%	EXPSIGSAVE(SESSION, ExpNo, varargin)
%	expsigsave: Load vars from mat-file directly into vars in workspace.
%	usage: [varargout] = expsigsave(File, varargin):
%	NKL, 10.10.02

Ses = goto(SESSION);
File = catfilename(Ses,ExpNo,'mat');
save(File, '-append', varargin{:});
fprintf('File %s saved!\n', File);
return;
