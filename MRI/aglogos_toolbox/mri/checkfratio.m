function checkfratio(SesName,GrpName,BlpExtract)
%CHECKFRATIO - Try different frequency bands to optimize independence of BLPs
%
if nargin < 3,
  BlpExtract = 1;
end;

if nargin < 2 | isempty(GrpName),
  GrpName = 'fix';
end;

if BlpExtract,
  sesgetblp(SesName,GrpName);
  sesgrpmake(SesName,GrpName,'blp');
end;

almkmodel(SesName);
sesgroupglm(SesName,GrpName);
algetfratio(SesName,GrpName);
  
  
  