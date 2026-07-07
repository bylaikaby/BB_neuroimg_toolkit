
%!! take care if EPI is with System Ramp configuration!! PSF may not be
%correctly acquired

clear all
close all
clc
[~, psf] = fidcopyreadnew('/opt/PV6.0/data/guest/20161102_085012_K13_1_22/37/','fidCopy_EG'); %ANPASSEN!!20161102_085012_K13_1_22
psf2 = interpft(psf, 96);
% psf2 = permute(interpft(permute(psf2,[4 1 2 3]), size(epi,2)),[2 3 4 1]);
% psf3 = imrotate(interpft(psf2, 128),-45,'bicubic','crop');

    
for n = [38:41]
    eval(['cd /opt/PV6.0/data/guest/20161102_085012_K13_1_22/' num2str(n) '/pdata/1']);
    D = dir('.');
    for cnt=1:numel(D), 
        w(cnt) = ~strcmp(D(cnt).name,'2dseq_orig');
    end
        if all(w),
            eval('!mv 2dseq 2dseq_orig');
        end
    
    clear w
%     fid = fopen('2dseq_orig','r');
    fid = fopen('2dseq_orig','r');
    d = single(fread(fid,inf,'int16'));
    fclose(fid);
    epi = reshape(d, [96 96 4 1200]); %ANPASSEN!
    
    epi = phcorr_segm(epi,'nMVM',60);
    
    
    
    %[a,b,c] = distcfast(epi,circshift(psf2,[-1 -2]),0.12,4);
    [a,b,c] = distcfast(epi,circshift(psf2,[0 0]),0.2,4);
    
    m = max(a(:));
    cabs = int16( abs(a) / m * single( intmax('int16') ) ) ;
    figure, montage(permute(epi(:,:,:,1),[2 1 4 3]),'DisplayRange',[0 1],'Size',[4 6]),
    title('original EPI')
    figure, montage(permute(cabs(:,:,:,1),[2 1 4 3]),'DisplayRange',[0 3e4],'Size',[4 6])
    title('corrected EPI')
   % cabs = flipdim(flipdim(cabs,1),3);
    cabs = flipdim(cabs,1);
    fid = fopen('2dseq','w');
    fwrite(fid,cabs,'int16',0,'a');
    fclose(fid);
    
    eval('cd ../2');
    for cnt=1:numel(D), 
        w(cnt) = ~strcmp(D(cnt).name,'2dseq_orig');
    end
        if all(w),
            eval('!mv 2dseq 2dseq_orig');
        end
    
    clear w
    a = interpft(a, 128);
    a = permute(interpft(permute(a,[2 1 3 4]),128),[2 1 3 4]);
    m = max(a(:));
    cabs = int16( abs(a) / m * single( intmax('int16') ) ) ;
   % cabs = flipdim(flipdim(cabs,1),3);
    cabs = flipdim(cabs,1);
    fid = fopen('2dseq','w');
    fwrite(fid,cabs,'int16',0,'a');
    fclose(fid);
end