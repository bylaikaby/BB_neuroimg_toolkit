clc; close all; clear all;
diary off;
%if exist('fix_batch.log','file'),
%  diary('');
%  try
%    delete('fix_batch.log');
%  end
%end

%diary('fix_batch.log');

% polar flash
SESSIONS = {...
    'N03oW1',
    'C01ph1',
    'F01pr1'
    'G02PV1',
    'N03PY1',
    'J02PB1',
    'M02PD1',
    'D03PF1',
    'D04PK1',
    'E04PL1',
    'J02PP1' };
fprintf('PROJECT :PolarFlash, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Scotoma');
  %fix_300604(SESSIONS{N});
end


% debug sessions
SESSINS = {...
    'M02lx1',
    'C98nm1' };
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Scotoma');
  %fix_300604(SESSIONS{N});
end



% glass patterns
SESSIONS = {...
    'J02l61',
    'B987C1',
    'G977D1',
    'H007L1',
    'K007Z1',
    'H00871',
    'H008D1',
    'J008E1',
    'K008F1',
    'K00911',
    'N00aB1',
    'B01aE1',
    'B01dI1',
    'C01hl1',
    'J02hn1',
    'D01hq1',
    'N02l71',
    'S02l81' };
fprintf('PROJECT : Glass Patterns, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Glass Patterns');
  fix_300604(SESSIONS{N});
end

% Scotoma
SESSIONS = {...
    'D97571',
    'B00581',
%    'O979x1',
    'E01fe1',
    'E02hQ1',
    'E02iK1',
    'E02jc1',
    'E02jq1',
    'E01jS1', 
    'E02kd1',
    'E02kF1',
    'A01lG1',
    'E02mm1',
    'Q02mA1' };
fprintf('PROJECT : Scotoma, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Scotoma');
  fix_300604(SESSIONS{N});
end



% Attention
SESSIONS = {...
%    'F01kJ1',
    'C01kX1',
    'B02nm1' };
fprintf('PROJECT : Attention, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Attention');
  fix_300604(SESSIONS{N});
end


% Neuromod Phys
SESSIONS = {...
    'B00nm1',
    'D01nm1',
    'D01nm2' };
fprintf('PROJECT : Neuromod Phys, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Neuromod Phys');
  fix_300604(SESSIONS{N});
end


% Neuromod Phys+MRI
SESSIONS = {...
    'B00bi1',
    'B00cg1',
    'J00f11',
    'K00bk1',
    'K00dD1',
    'N00eb1' };
fprintf('PROJECT : Neuromod Phys+MRI, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Neuromod Phys+MRI');
  fix_300604(SESSIONS{N});
end


% Microstim
SESSIONS = {...
    'B009s1',
    'B00ae1',
    'B00au1',
    'B019i1',
    'B01lM1',
    'C019q1',
    'C01jW1',
    'D01lr1',
    'D97621',
    'F01kZ1',
    'H005W1',
    'H00ag1',
    'I009H1',
    'I00an1',
    'J007F1',
    'J00b21',
    'K005z1' };
fprintf('PROJECT : Microstim, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Microstimulation');
  fix_300604(SESSIONS{N});
end


% Flash Suppression Phys
SESSIONS = {...
    'B01nm3',
    'B01nm4',
    'B01nm5',
    'D01nm4',
    'D01nm5',
    'B02nm1',
    'G98nm1',
    'G98nm2' };
fprintf('PROJECT : Flash Suppression Phys, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Flash Suppression Phys');
  fix_300604(SESSIONS{N});
end


% Flash Suppression Phys+MRI
SESSIONS = {...
    'S02jT1'
    'C01jW1'
    'S02kv1'
    'F01kJ1'
    'S02kR1'
    'C01kX1' };
fprintf('PROJECT : Flash Suppression Phys+MRI, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Flash Suppression Phys+MRI');
  fix_300604(SESSIONS{N});
end


% Movie MRI
SESSIONS = {...
    'J03lS1',
    'M03lU1',
    'N03mt1',
    'N02mv1',
    'C01nN1',
    'J02nP1' };
fprintf('PROJECT : Movie MRI, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Movie MRI');
  fix_300604(SESSIONS{N});
end

% Movie Phys
SESSIONS = {...
%    'C98nm1',
    'G02nm1',
    'G97nm1',
    'R97nm1',
    'C98nm2',
    'A98nm1',
    'S02nm1',
    'B02nm2',
    'C98nm3',
    'C01nm1',
    'C01nm2',
    'E02nm1' };
fprintf('PROJECT : Movie Phys, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Movie Phys');
  fix_300604(SESSIONS{N});
end

% Movie Phys+MRI
SESSIONS = {...
    'N02lp1',
    'J00lq1',
%    'M02lx1',
    'G02lV1',
    'N02m21',
    'F01m91',
    'J00me1',
    'D01ml1',
    'G02mn1',
    'B01mz1' };
fprintf('PROJECT : Movie Phys+MRI, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Movie Phys+MRI');
  fix_300604(SESSIONS{N});
end




% Phys+MRI
SESSIONS = {...
    'D991i1',
    'D992Z1',
    'B972Y1',
    'H97361',
    'A003c1',
    'B003d1',
    'D973f1',
    'B973k1',
    'H973l1',
    'A003x1',
    'B004h1',
    'C974l1',
    'B005J1',
    'B005Y1',
    'H005v1',
    'K005X1',
    'B006D1',
    'K006I1',
    'H006L1',
    'I00951',
    'H009D1',
    'K009U1',
    'B00cS1',
    'J00dh1',
    'J00dJ1',
    'M02gs1',
    'G02j21',
    'B00401' };
fprintf('PROJECT : Phys+MRI, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Phys+MRI');
  fix_300604(SESSIONS{N});
end


% Fahad (random dots):
SESSIONS = {...
    'K02jP1',
    'K02l11',
    'K02lm1',
    'K02lF1' };
fprintf('PROJECT : Block Design (Fahad), N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Block Design (Fahad)');
  fix_300604(SESSIONS{N});
end


%Gregor :
SESSIONS = {...
    'B970q1',
    'C970Z1',
    'F971K1',
    'F973j1',
    'D974B1',
    'G974C1',
    'H974I1',
    'D974M1',
    'C995s1',
    'L00651',
    'I006P1' };
fprintf('PROJECT : Block Design (Gregor), N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Block Design (Gregor)');
  fix_300604(SESSIONS{N});
end


%Margaret :
SESSIONS = {...
    'B99Wr1',
    'E99WQ1',
    'H970w1',
    'D970J1',
    'C990Q1',
    'F970S1',
    'D970X1',
    'B971q1',
    'G981v1',
    'C97241',
    'D972i1',
    'C97311',
    'B983m1',
    'C993A1',
    'C973P1',
    'C993T1',
    'F003W1',
    'D974f1',
    'E004u1',
    'B004O1',
    'D975n1',
    'M00631',
    'B006R1',
    'J00731',
    'K00761',
    'I007c1',
    'B009L1',
    'N009M1',
    'C019T1',
    'B01a21',
    'J00aq1',
    'B01bs1',
    'J00bt1',
    'B01du1',
    'C01dL1',
    'C01ep1',
    'C01eK1',
    'I00f41' };
fprintf('PROJECT : Block Design (Margaret), N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Block Design (Margaret)');
  fix_300604(SESSIONS{N});
end


%Ocular Dominance :
SESSIONS = {...
    'F972w1',
    'D972J1' };
fprintf('PROJECT : Block Design (OculDom), N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Block Design (Ocular Dominance)');
  fix_300604(SESSIONS{N});
end



%Zoe :
SESSIONS = {...
    'I007v1',
    'K007w1',
    'B007T1',
    'B00851',
    'A019p1',
    'O979Z1',
    'N00a01',
    'C01af1',
    'B01ak1',
    'C01aA1',
    'C01br1',
    'J00eL1',
    'C01i21' };
fprintf('PROJECT : Block Design (Zoe), N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Block Design (Zoe)');
  fix_300604(SESSIONS{N});
end

%High res :
SESSIONS = {...
    'F97641',
    'D976b1',
    'J00jx1',
    'F975l1',
    'J02lw1' };
fprintf('PROJECT : Block Design (HighRes), N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Block Design (High Resolution)');
  fix_300604(SESSIONS{N});
end


% Faces
SESSIONS = {...
    'A996K1',
    'A016S1',
    'C016W1',
    'A997R1',
    'E008b1',
    'C01fZ1',
    'C01iE1', };
fprintf('PROJECT : Block Design (Faces), N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Block Design (Faces)');
  fix_300604(SESSIONS{N});
end


% Anesthesia Phys
SESSIONS = {...
    'G98nm1',
    'G98nm2',
    'G02nm1',
    'G97nm1',
    'C98nm1' };
fprintf('PROJECT : Anesthesia Phys, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Anesthesia Phys');
  fix_300604(SESSIONS{N});
end


% Anesthesia Phys+MRI
SESSIONS = {...
    'G02j21',
    'C01jn1',
    'M02jC1',
    'S02jT1',
    'C01jW1',
    'C01kx1',
    'N02lp1',
    'J00lq1',
    'M02lx1' };
fprintf('PROJECT : Aneshtesia Phys+MRI, N=%d\n',length(SESSIONS));
for N = 1:length(SESSIONS),
  %fix_convSesfile(SESSIONS{N},'Anesthesia Phys+MRI');
  fix_300604(SESSIONS{N});
end


% Anesthesia MRI
% SESSIONS = {
%     'M00ft1',
%     'M00hv1',
%     'M02i81',
%     'M02in1',
%     'M00iB1',
%     'J03lS1',
%     'M03lU1' };
% fprintf('PROJECT : Anesthesia MRI, N=%d\n',length(SESSIONS));
% for N = 1:length(SESSIONS),
%   fix_convSesfile(SESSIONS{N},'Anesthesia MRI');
% end


%diary off;
