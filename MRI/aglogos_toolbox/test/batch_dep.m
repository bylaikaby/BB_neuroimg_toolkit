% Dependence studies with combined physiology and fMRI
%   m02lx1        - - OK Mov Phys+MRI, 2 ele, [dmovie1-dmovie15]
%   g02mn1        - - OK Mov Phys+MRI, 2 ele, [dmovie2 dmovie3]
%   b01mz1        - - OK Mov Phys+MRI, 2 ele [dmovie2 dmovie3 dmovie4] CHECK mucsimo (movie5!)
%   n02lp1        - - OK Mov Phys+MRI, 2 ele, [dmovie1 dmovie2 dmovie3 dmovie4 dmovie5 dbaseline]
%   n02m21        - - OK Mov Phys+MRI, 2 ele, [dmovie2 dmovie3 dmovie5 dmovie6 dmovie7 dmovie8 dmovie9]
%   j00me1        - - 00 Mov Phys+MRI, 2 ele, [dmovie2 dmovie3]
%   j00lq1        - - ?? Mov Phys+MRI, 2 ele, [dmovie1 dmovie2 dmovie3 dmovie4 dmovie5]
%   d01ml1        - - ?? Mov Phys+MRI, 2 ele, [dmovie2 dmovie3]
%   f01m91        - - ?? Mov Phys+MRI, 2 ele, [dmovie3 dmovie4]
%   g02lv1        - - ?? Mov Phys+MRI, 2 ele, [dmovie1 dmovie2 dmovie3 dmovie4 dmovie5]
%


ses = {};
%ses{end+1} = 'm02lx1';  % done
%ses{end+1} = 'g02mn1';  % done
%ses{end+1} = 'b01mz1';  % done 22.01.08 n07
%ses{end+1} = 'n02lp1';  % done 25.01.08 n07
%ses{end+1} = 'n02m21';  % done 22.01.08 n07

%ses{end+1} = 'j00me1';  % done 22.01.08 n07
%ses{end+1} = 'j00lq1';  % done 25.01.08 n07
%ses{end+1} = 'd01ml1';  % done 25.01.08 n07
%ses{end+1} = 'f01m91';  % done 25.01.08 n07
%ses{end+1} = 'g02lv1';  % done 25.01.08 n07



for N=1:length(ses),
  tmpses = ses{N};
  try,
    %sesconfuncnv_sfn03(tmpses,[],'nocco');
    %sesgrpmake(tmpses,[],'nocco1');

    %sesconfunc_sfn03(tmpses);
    %sesgrpmake(tmpses,[],'ch2');
    %sesgrpmake(tmpses,[],'cr2');
    %sesgrpmake(tmpses,[],'kc2');

    sesfitdep(SESSION{N},[],'nocco1');
  
  catch,
    txtfile = sprintf('Y:/DataMatlab/tmp/%s_%s.txt',tmpses,mfilename);
    fid = fopen(txtfile,'at+');
    fprintf(fid,'%s: FAILED %s by %s\n',datestr(now),tmpses,lasterr);
    fclose(fid);
  end
end




