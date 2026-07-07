
% [ 1] N02GU1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 2] N02GT1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 3] N02GE1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 4] N02GV1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 5] N02GD1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 6] N02GW1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 7] M02GW1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 8] M02GV1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [ 9] M02GY1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [10] M02GZ1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [11] M02GT1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [12] M02GS1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [13] N02GP1: Cln/ClnSpc  blp/cBlp/cSpc  glm/fratio  glm2
% [XX] B02GG1: no adf/adfw

% blp  : sesgetblp(SES)
% cBlp : sesgetep(SES)


tmp = seslist('alert');
for N=1:length(tmp),
  SES = tmp{N}{1};

  % Cln/ClnSpc -------------------
  % sesclnadjevt(SES);
  % sesgetcln(SES);
  % sesclnspc(SES);
  % print_datsize(SES)

  % blp/cBlp/cSpc ----------------
  % sesgetblp(SES);
  % sesgetep(SES);

  % make models ------------------
  %sesgrpmake(SES,[],'ClnSpc');
  %sesgrpmake(SES,[],'cBlp');
  %almkmodel(SES);
  
  % groupglm = 'before glm'
  %sesgroupglm(SES);
  %algetfratio(SES);

  % groupglm = 'after glm'
  %sesglmana(SES);
  algetfratio(SES);
  
end

