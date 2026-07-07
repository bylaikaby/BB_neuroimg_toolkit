SESSION='m02lx1';

Ses = goto(SESSION);
EXPS = validexps(Ses);

% cfzsts  
% chzsts  
% icazsts 
% refzsts 
% zsts    

for N=1:length(EXPS),
  ExpNo = EXPS(N);
  filename=catfilename(Ses,ExpNo);
  fprintf('%3d/%3d ExpNo: %d, File: %s\n',N,length(EXPS),ExpNo,filename);

  s = load(filename);
  names = fieldnames(s);
  NewK = 1;
  clear newnames;
  for K=1:length(names),
    if ~(strcmp(names{K},'cfzsts') |...
          strcmp(names{K},'cfzsts') |...
          strcmp(names{K},'chzsts') |...
          strcmp(names{K},'icazsts') |...
          strcmp(names{K},'refzsts') |...
          strcmp(names{K},'mricf') |...
          strcmp(names{K},'mrich') |...
          strcmp(names{K},'xcor') |...
          strcmp(names{K},'zsts')),
      newnames{NewK} = names{K};
      NewK = NewK + 1;
    end;
  end;
  
  for K=1:length(newnames),
    eval(sprintf('%s = s.%s;',newnames{K},newnames{K}));
  end;

  save(filename, newnames{:});
  fprintf('*** Updated File: %s\n',filename);
end;

          
     
  
