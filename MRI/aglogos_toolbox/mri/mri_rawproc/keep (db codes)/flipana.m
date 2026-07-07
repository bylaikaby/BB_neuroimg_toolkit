for n = [50]
    eval(['cd /opt/PV6.0/data/guest/20161017_095530_K13_1_21/' num2str(n) '/pdata/1']);
    D = dir('.');
    for cnt=1:numel(D), 
        w(cnt) = ~strcmp(D(cnt).name,'2dseq_orig');
    end
    if all(w),
        eval('!mv 2dseq 2dseq_orig');
    end
    
    clear w
    fid = fopen('2dseq_orig','r');
    d = single(fread(fid,inf,'int16'));
    fclose(fid);
    rare = reshape(d, [256 256 44]); %ANPASSEN!
    cabs = flipdim(flipdim(rare,1),3);
    fid = fopen('2dseq','w');
    fwrite(fid,cabs,'int16',0,'a');
    fclose(fid); 
end