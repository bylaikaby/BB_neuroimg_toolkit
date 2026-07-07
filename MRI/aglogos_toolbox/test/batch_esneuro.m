

ses = es_physlist;

%ses = ses(6:10);
%ses = ses(11:13);
ses = ses(12:13);
%ses = ses(14:15);




%for N=1:length(ses),
%  tmpses = ses{N}{1};
%  sesgetspk(tmpses);
%end







for N=1:length(ses),
  tmpses = ses{N}{1};
  %sesgetspk(tmpses);
  %sesgetblp(tmpses);
  sesesmean(tmpses,[],{'Cln','blp','Sdf','Spkt'});
  sesgrpmake(tmpses);
end




for N=1:length(ses),
  tmpses = ses{N}{1};
  sesesmean(tmpses,[],{'Cln','blp','Sdf','Spkt'});
end




ses = {'c03nm1','c03nm2','d04nm5','e04nm2','e04nm3','e04nm4'};
ses = {'e04nm5','e04nm6','f04nm2','f04nm3','f04nm4'};
%ses = {'f05nm1','f05nm2','f05nm3'};
%ses = {'f05nm4','f05nm5'};
%ses = {'h05nm1','h05nm2'};
%ses = {'h05nm3','h05nm4'};
for N=1:length(ses),
  %sesgetspk(ses{N});
  %sesesmean(ses{N},[],{'Sdf','Spkt'});
  %sesgrpmake(ses{N},[],{'esSdf','esSpkt'});
  sesesmean(ses{N},[],{'blp'});
  sesgettrial(ses{N});
  sesgrpmake(ses{N});
end


