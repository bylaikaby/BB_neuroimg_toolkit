sesspktrigavr('s02nm1','movie3','Spkt','Cln',1);
sesspktrigavr('s02nm1','movie4','Spkt','Cln',1);
sesspktrigavr('s02nm1','movie1','Spkt','Cln',1);

sesspktrigavr('s02nm1','movie3','Spkt','Cln');
sesspktrigavr('s02nm1','movie4','Spkt','Cln');
sesspktrigavr('s02nm1','movie1','Spkt','Cln');


%sesspktrigavr('g97nm1','movie1','Spkt','Cln',1);
%sesspktrigavr('g97nm1','movie2','Spkt','Cln',1);

%sesspktrigavr('g97nm1','movie1','Spkt','Cln');
%sesspktrigavr('g97nm1','movie2','Spkt','Cln');



%return;


sesgetspk('c98nm3');  clear all; pack;
sesgetspk('g97nm1');  clear all; pack;
sesgetspk('s02nm1');  clear all; pack;


clear all; close all; pack;
sesgetblp('c98nm3');
%sesblpselfcon('c98nm3');
clear all; close all; pack;
sesgetblp('g97nm1');
%sesblpselfcon('g97nm1');
clear all; close all; pack;
sesgetblp('s02nm1');
%sesblpselfcon('s02nm1');

