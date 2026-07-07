function resp = sesimgcheck(SESSION,EXPS)
%SESIMGCHECK - Check the tcImg images of each valid experiment's MAT file
%	resp = SESIMGCHECK(SESSION,EXPS)
%	NKL, 24.10.02

Ses = goto(SESSION);

if ~exist('EXPS','var') | isempty(EXPS),
  EXPS = validexps(Ses);
end;
% EXPS as a group name or a cell array of group names.
if ~isnumeric(EXPS),  EXPS = getexps(Ses,EXPS);  end

for ExpNo = EXPS,
	name = catfilename(Ses,ExpNo,'tcimg');
	fprintf('sesimgcheck: Reading tcImg from %s\n', name);
	load(name,'tcImg');
	imagesc(mean(tcImg.dat,3)');
	daspect([1 1 1]);
	q=sprintf('File: %s, ExpNo: %d, Scan: %d',name,ExpNo,Ses.expp(ExpNo).scanreco(1));
	colormap(gray);
	resp(ExpNo) = yesorno(q);
end;



