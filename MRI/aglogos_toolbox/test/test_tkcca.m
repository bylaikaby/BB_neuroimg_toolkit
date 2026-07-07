RES   = sestkcca('rat6q1','spont','mri','roiTs','roi',{'pctx','actx'},'chans',3:4,'neu','blp','cv',0,'mrinorm','zcore');
REScv = sestkcca('rat6q1','spont','mri','roiTs','roi',{'pctx','actx'},'chans',3:4,'neu','blp','cv',1,'mrinorm','zcore');
save('D:/Temp/rat6q1_spont_tkcca(ctx).mat','RES','REScv');


RES   = sestkcca('rat6q1','spont','mri','roiTs','roi',{'hipp'},'chans',1:2,'neu','blp','cv',0,'mrinorm','zcore');
REScv = sestkcca('rat6q1','spont','mri','roiTs','roi',{'hipp'},'chans',1:2,'neu','blp','cv',1,'mrinorm','zcore');
save('D:/Temp/rat6q1_spont_tkcca(hip).mat','RES','REScv');



RES   = sestkcca('rat6s1','spont','mri','roiTs','roi',{'pctx','actx'},'chans',3:4,'neu','blp','cv',0,'mrinorm','zcore');
REScv = sestkcca('rat6s1','spont','mri','roiTs','roi',{'pctx','actx'},'chans',3:4,'neu','blp','cv',1,'mrinorm','zcore');
save('D:/Temp/rat6s1_spont_tkcca(ctx).mat','RES','REScv');


RES   = sestkcca('rat6s1','spont','mri','roiTs','roi',{'hipp'},'chans',1:2,'neu','blp','cv',0,'mrinorm','zcore');
REScv = sestkcca('rat6s1','spont','mri','roiTs','roi',{'hipp'},'chans',1:2,'neu','blp','cv',1,'mrinorm','zcore');
save('D:/Temp/rat6s1_spont_tkcca(hip).mat','RES','REScv');



RES   = sestkcca('b06sc1','spont','roi','V1','ele','V1','mri','roiTs','neu','blp','cv',0,'mrinorm','zcore');
REScv = sestkcca('b06sc1','spont','roi','V1','ele','V1','mri','roiTs','neu','blp','cv',1,'mrinorm','zcore');
save('D:/Temp/b06sc1_spont_tkcca(v1).mat','RES','REScv');
