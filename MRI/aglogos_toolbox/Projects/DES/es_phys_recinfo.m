function RI = es_phys_recinfo(SesName)
%ES_PHYS_RECINFO - Returns a struct with sties, depth, channels and the session's test-group
% es_phys_fig_psth(SesIndex) selects session SesIndex and:
%   [esSpkt, esblp] = sigload(SesName, GrpName, 'esSpkt', 'esblp');
%   Then plots average esSpkt.dat, average low freq BLPs and gamma
%
% NKL 25.12.09
%  
% Some DEMO selections
% SES{end+1} = {'f05nm2', {'esp500fr1'},[1 2 3 4 6]};         %  1 Long pause        (***)-
% SES{end+1} = {'e04nm5', {'esp500fr1'},[2 3 5 6 8 9]};       %  2 Long pause        (***)-
% SES{end+1} = {'h05nm3', {'esp250fr1nov'}, [2 3 5 7 8]};     %  3 Long pause        (***)-
% SES{end+1} = {'e04nm5', {'esp150fr1'},[2 3 5 6 8 9]};       %  4 Long pause        (***)-
% SES{end+1} = {'f05nm3', {'esp300fr1'}, [1 6]};              %  5 Long pause        (***)-
% SES{end+1} = {'f05nm5', {'esp250fr1'},[3 4 5 6 9 11]};      %  6 Medium            (**)-
% SES{end+1} = {'h05nm2', {'esp200fr1'},[3 5 9]};             %  7 Short + Increase  (**)-
% SES{end+1} = {'d04nm5', {'esp100fr1'},[1 2 3 5 6 8 9]};     %  8 Medium + Decrease (**)-
% SES{end+1} = {'d04nm5', {'Besp100fr1'},[1 2 3 5 6 8 9]};    %  9 Medium + Decrease (**)-
% SES{end+1} = {'f05nm1', {'esp80fr1'},[3:6 8]};              % 10 Short + Increase  (**)-
% SES{end+1} = {'f05nm5', {'esp80fr1'},[3:6 9 12]};           % 11 Medium            (**)-
% SES{end+1} = {'f05nm2', {'esp50fr1'},[2 3 6 ]};             % 12 Short + Decrease  (**)-
% SES{end+1} = {'h05nm4', {'esp250fr1'},[6]};                 % 13 Short + Increase  (***)+
% ------------------------------------------------------------------------------------------
% SES{end+1} = {'d04nm5', {'esp100fr2'},[1 2 3 4 5 6 9]};     % 14 No change         ()
% SES{end+1} = {'f04nm3', {'esp100fr2'},[1 2 3 4 5 6 9]};     % 15 No change         (***)
% SES{end+1} = {'e04nm2', {'estim1'},[1 2 4 5 8 9 10]};       % 16 No change         (-)
% SES{end+1} = {'f05nm1', {'esp80fr2'},[1 4 5 6 8 10]};       % 17 Short + Positive  (*)
% SES{end+1} = {'c03nm1', {'estim1'},[4 8]};                  % 18 No change         (-)
% SES{end+1} = {'e04nm2', {'estim2'},[1 2 4 5 8 9 10]};       % 19 No change         (-)
% SES{end+1} = {'f04nm2', {'esp80fr2'},[1:6 9]};              % 20 Short + Positive  (*)
%
% ATTENTION:
% To edit individual description files, type 
% ses = es_phys_session('edit');
% edit ses{1}; etc..
% or showspiking(ses{1});
%
  
switch lower(SesName),
 case 'c03nm1',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [4 9 10];                           % Used by es_phys_eledepth, es_phys_fig_psth
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1','V1'};
  RI.depth  = [7113 5879 6014 7408 5614 5215 0 5206 7440 6811];
 case 'c03nm2',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [2];
  RI.site   = {'V2','V2','V1','V1','V2','V1','LGN','V1','V2'};
  RI.depth  = [10867 10289 7568 7292 12351 11483 0 13827 10892];
 case 'd04nm5',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [1:6 8:10];
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1','V1'};
  RI.depth  = [6032 6928 4597 5408 3999 4397 0 4174 9571 6000];
 case 'e04nm5',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [1:6 8:9];
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1'};
  RI.depth  = [3919 2911 3517 3397 3588 3398 0 3398 4062];
 case 'e04nm6',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [1:6 8:11];
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1','V1','V1'};
  RI.depth  = [3463 3199 2345 1988 3964 2971 0 2388 2798 2995 2597];
 case 'f04nm2',
  RI.essite = {'LGN',[6]};                          % LGN channel
  RI.select = [1:5 7:9];
  RI.site   = {'V1','V1','V1','V1','V1','LGN','V1','V1','V1'};
  RI.depth  = [5128 5246 6232 4205 5337 0 6407 4212 4504];
 case 'f04nm3',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [1:6 8];
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1','V1'};
  RI.depth  = [4676 5854 5727 6293 6157 6347 0 6429 6597 6461];
 case 'f04nm4',
  RI.essite = {'LGN',[5]};                          % LGN channel
  RI.select = [1:4 6:8];
  RI.site   = {'V1','V1','V1','V1','LGN','V1','V1','V1'};
  RI.depth  = [10759 13798 13404 14754 0 17072 15198 14500];
 case 'f05nm1',
  RI.essite = {'LGN',[7]};                  % LGN channel
  RI.select = [2:4 6 10];
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1','V1'};
  RI.depth  = [4563 4385 4567 4539 4628 5165 0 5241 5299 5058];
 case 'f05nm2',
  RI.essite = {'LGN',[5]};                          % LGN channel
  RI.select = [1:6 8:10];
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1','V1'};
  RI.depth  = [5050 4931 4787 4243 7081 5630 0 4472 7022 7703];
 case 'f05nm3',
  RI.essite = {'LGN',[5]};                          % LGN channel
  RI.select = [1:4 6:9];
  RI.site   = {'V2','V1','V1','V1','V1','V1','V1','V2','V2'};
  RI.depth  = [4387 3811 3500 3199 3000 4200 4028 4407 4905];
 case 'f05nm4',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [1:6 9 11:12];
  RI.site   = {'V1','V1','V1','V1','V1','V1','LGN','V1','V1','V1','V1','V1'};
  RI.depth  = [1455 2996 3382 3801 1822 2595 0 3604 2397 3155 4325 4554];
 case 'f05nm5',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [4 12];
  RI.site   = {'V2','V2','V2','V2','V2','V2','LGN','V2','V2','V2','V1','V1'};
  RI.depth  = [7001 10319 9333 8341 7183 8401 0 9530 8698 8603 5743 4965];
 case 'h05nm2',
  RI.essite = {'LGN',[7]};                          % LGN channel
  RI.select = [1:6 8:10];
  RI.site   = {'V1','V2','V2','V2','V1','V2','LGN','V2','V1', 'V1'};
  RI.depth  = [5619 7156 6401 7942 5091 6967 0 6935 5449 7187];
 case 'h05nm3',
  % Channel 8 has good 100ms pause!!!!!!!!!!!!!!!!!!!
  RI.essite = {'LGN',[6]};                          % LGN channel
  RI.select = [9 10];
  RI.site   = {'V1','V1','V1','V1','V1','LGN','V1','V1','V1','V1'};
  RI.depth  = [3798 3857 3597 3897 4671 0 6190 5963 4596 3765];
 case 'h05nm4',
  RI.essite = {'LGN',[4]};                          % LGN channel
  RI.select = [5 6];
  RI.site   = {'V2','V2','V2','LGN','V1','V1'};
  RI.depth  = [11729 11378 12608 0 6781 7461];
 case {'d04nm6'}
  RI.essite = {'LGN',[]};                       % LGN channel
  RI.select = [1 2 3 7 8 9 10];
  RI.site   = {'V1','V1','V1','V1','V1','V1','V1','V1','V1','V1','V1'};
  RI.depth  = [3426 3236 2951 4135 4152 0777 3982 3828 4417 4447 3828];
 case {'b06nm6'}
  RI.essite = {'LGN',[]};                       % LGN channel
  RI.select = [1:10];
  RI.site   = {'V1','V1','V1','V1','V1','V1','V1','V1','V1','V1'};
  RI.depth  = [1476 1179 1216 1108 1965 2032 2088 2097 2272 2205];
 case {'h05nm6'}
  RI.essite = {'LGN',[]};                       % LGN channel
  RI.select = [1:8];
  RI.site   = {'V1','V1','V1','V1','V1','V1','V1','V1'};
  RI.depth  = [2936 3383 3719 3890 3040 3970 3610 3517];
 case {'h05271'}
  RI.essite = {'LGN',[]};                       % LGN channel
  RI.select = [1];
  RI.site   = {'V1'};
  RI.depth  = [2936];
 case {'g032m1'}
  RI.essite = {'LGN',[]};                       % LGN channel
  RI.select = [1 2];
  RI.site   = {'V1' 'V2'};
  RI.depth  = [1000 2000];
 otherwise,
  fprintf('unknown session\n');
  RI = [];
  return;
end;


