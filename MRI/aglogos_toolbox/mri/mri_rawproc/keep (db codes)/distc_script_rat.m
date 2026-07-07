
%!! take care if EPI is with System Ramp configuration!! PSF may not be
%correctly acquired

%WARNING: Ramp Sampling Compensation NOT COMPATIBLE with PSF-correction yet
%TRY: Antialiasing (oversampling) for effective resolution == wanted resolution in read
%direction

clear all
close all
clc
set(0,'DefaultFigureWindowStyle','docked');

pathdat = '/mridata_wks21/rat.K61/'; %!!!!ANPASSEN
psfdat = 29;
psfmeth = readBrukerParamFile([pathdat num2str(psfdat) '/method']);
epidat = 28;

psf = psfread([pathdat num2str(psfdat) '/'],'fidCopy_EG');    

for n = epidat
    eval(['cd ' pathdat num2str(n) '/pdata/1']);
    epirec = readBrukerParamFile('reco');
    epiacqp = readBrukerParamFile('../../acqp');
    
    fid = fopen('2dseq','r');
    d = single(fread(fid,inf,'int16'));
    fclose(fid);
    epi = reshape(d, [epirec.RECO_size(1) epirec.RECO_size(2) epiacqp.NSLICES epiacqp.NR]); 
    
    a = distcfast(epi,circshift(psf,[0 0]),0.12,4);
    
    ma = max(abs(a(:))); md =max(abs(d(:)));
    %cabs = int16( abs(a) / m * single( intmax('int16') ) ) ;
    cabs = int16( abs(a) / ma * md ) ;
    
    figure, montage(permute(epi(:,:,:,1),[2 1 4 3]),'DisplayRange',[0 1e4],'Size',[4 5]),
    title('original EPI')
    figure, montage(permute(cabs(:,:,:,1),[2 1 4 3]),'DisplayRange',[0 1e4],'Size',[4 5])
    title('corrected EPI')
    
    eval('mkdir ../2');
    eval('cd ../2');
    eval('!cp ../1/* .');
    fid = fopen('2dseq','w');
    fwrite(fid,cabs,'int16',0,'a');
    fclose(fid);  
end

set(0,'DefaultFigureWindowStyle','normal');