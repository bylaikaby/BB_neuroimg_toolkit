

matlabpool



SES = 'E10.a31';  EXPS = 1:10;

t0 = tic;
sesdumppar(SES,EXPS);
RES.sesdumppar = toc(t0);

t0 = tic;
sesimgload(SES,EXPS);
RES.sesimgload = toc(t0);

t0 = tic;
sesclnadjevt(SES,EXPS);
RES.sesclnadjevt = toc(t0);

t0 = tic;
sesgetcln(SES,EXPS);
RES.sesgetcln = toc(t0);

t0 = tic;
sesgetblp(SES,EXPS);
RES.sesgetblp = toc(t0);


matlabpool close;


% PCT 1  (in sec)
% RES = 
%       sesdumppar:   7.6893   (no parfor)
%       sesimgload: 201.2038
%        sesgetcln: 806.4209   (no parfor)
%        sesgetblp: 485.4303

% PCT 4  (in sec)
% RES = 
%       sesdumppar:   5.7690   (no parfor)
%       sesimgload:  91.6828
%        sesgetcln: 827.1184   (no parfor)
%        sesgetblp: 263.1552
