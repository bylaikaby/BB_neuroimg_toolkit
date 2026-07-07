function showimginfo(SESSION,arg2,ImgName,ScanNo)
%SHOWIMGINFO - Display information about image in specified file
% SHOWIMGINFO(SESSION,FileName/ExpNo,ImgName) displays image info and
% stores it into a meta file that can be imported in PPT etc.
%
%	EXAMPLES
%	showimginfo('c01hl1',1);						-- info of tcImg
%	showimginfo('c01hl1','gcon');					-- info of tcImg
%	showimginfo('c01hl1','epi13fun01','epi13');		-- info of epi13
%	showimginfo('c01hl1','mdeft','mdeft');			-- info of mdeft{1}
%	showimginfo('c01hl1','mdeft','mdeft',2);		-- info of mdeft{2}
%
%	NKL, 30.11.02

if nargin < 4,
	ScanNo = 1;
end;

if nargin < 3,
	ImgName = 'tcImg';
end;

Ses = goto(SESSION);
s = sigload(Ses,arg2,ImgName);

figure('position',[5 400 512 256]);
set(gcf,'InvertHardCopy','off');
set(gcf,'color',[.1 .1 .3]);

if ~isstruct(s),
  s = s{ScanNo};
end;
dspimginfo(s);

