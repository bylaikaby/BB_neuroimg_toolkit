function [varargout] = sesgetsig(SESSION,varargin)
%SESGETSIG - Extracts signals of SigNames from EXSP/GrpName of a session
%	[Cln,Lfp] = SESGETSIG('a003x1',[10:12],{'Cln','Lfp'}), extracts
%	the cleaned neural signal and the LFPs from experients 10 through 12.
%	[Cln,Lfp] = SESGETSIG('a003x1',{'p12c100','p24c100'},{'Cln','Lfp'}),
%	extracts the cleaned signal and LFPs of groups p12c100 etc.
%
%	AUTH: HM 23.11.00, v2A.
%	[Cln,Lfp] = SESGETSIG('a003x1',[10:12],{'Cln','Lfp'});
%	varargout{n}{m}: n-th signal type e.g. Lfp,Mua,etc. m-th group
%
%   16.02.04 YM   supports Cln/ClnSpc/tcImg in sub-directory.
%
%	See also GETSES, GRPMK, SESGRPMAKE

VERBOSE = 0;

%%% CHECK INPUT:

Ses = goto(SESSION);
if isunix Ses.DataMatlab = '/y/MriData'; end;
if isunix Ses.sysp.matdir = '/y/DataMatlab/'; end;

% Check signal name(s):
if isa(varargin{end},'char'),
  SigName = varargin(end);
  varargin(end) = [];
elseif isa(varargin{end},'cell'),
  SigName = varargin{end};
  varargin(end) = [];
else,
  error('Last input arg. must be a valid "signal name".');
  SigName = {};
end;

% Check group name(s) or experiment(s):
if isa(varargin{1},'char'),
  GrpName = varargin(1);
  varargin(1) = [];
  EXPS = [];
elseif isa(varargin{1},'cell'),
  GrpName = varargin{1};
  varargin(1) = [];
  EXPS = [];
elseif isa(varargin{1},'double'),
  GrpName = [];
  EXPS = varargin{1};
  varargin(1) = [];
  %   if ~isempty(varargin) & isa(varargin{1},'double'),
  %      OBSPS = varargin{1};
  %      varargin(1) = [];
  %else,
  %   OBSPS = [];
  %   end;
else,
  error('Can''t identify experiment no. or group name.');
end;

NoExp = length(EXPS(:));
NoGrp = length(GrpName(:));
NoSig = length(SigName(:));

varargout = cell(size(SigName));
if isempty(GrpName),	% IF experiments given...
  if NoExp ==1,
    ExpNo = EXPS(1);
    for N=1:length(SigName),
      switch SigName{N},
       case {'Cln'}
        MatFile = catfilename(Ses,ExpNo,'cln');
       case {'tcImg'}
        MatFile = catfilename(Ses,ExpNo,'tcimg');
       case {'ClnSpc'}
        MatFile = catfilename(Ses,ExpNo,'clnspc');
       otherwise
        MatFile = catfilename(Ses,ExpNo,'mat');
      end
      if VERBOSE,
        fprintf('sesgetsig: Read file: %s\n',MatFile);
      end;
      varargout{N} = matsigload(MatFile,SigName{N});
    end
    %MatFileName = hstrfext(Ses.expp(ExpNo).physfile,'.mat');
    %MatFile = strcat(Ses.sysp.matdir,Ses.dirname,'/',MatFileName);
    %[varargout{:}] = matsigload(MatFile, SigName{:});	% ***
  else,
    tmp = varargout;
    for ExpNo = 1:NoExp,
      [tmp{:}] = sesgetsig(Ses,EXPS(ExpNo),SigName);
      for SigNo = 1:NoSig,
        varargout{SigNo}{ExpNo} = tmp{SigNo};
      end;
    end;
    for SigNo = 1:NoSig,
      varargout{SigNo} = reshape(varargout{SigNo},size(EXPS));
    end;
  end;
  
else,	   % IF groups given...
  if NoGrp ==1,
    GrpNo = 1;
    MatFileName = strcat(GrpName{GrpNo},'.mat');
    MatFile = strcat(Ses.sysp.matdir,Ses.dirname,'/',MatFileName);
    [varargout{:}] = matsigload(MatFile, SigName{:});	% ***
  else,
    tmp = varargout;
    for GrpNo = 1:NoGrp,
      [tmp{:}] = sesgetsig(Ses,GrpName{GrpNo},SigName);
      for SigNo = 1:NoSig,
        varargout{SigNo}{GrpNo} = tmp{SigNo};
      end;
    end;
    for SigNo = 1:NoSig,
      varargout{SigNo} = reshape(varargout{SigNo},size(GrpName));
    end;
  end;
end;

return;
