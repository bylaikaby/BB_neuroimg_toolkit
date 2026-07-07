% VG : averaged brain
% VF : exp file

M.x = spm_coreg(VG,VF,flags);


% get the coords of averaged brain (in voxel)
[R C P] = nngrid(1:nx,1:ny,1:nz);
RCP = zeros(4,length(R(:)));  % allocate memory first to avoid memory problem
RCP(1,:) = R(:);  clear R;
RCP(2,:) = C(:);  clear C;
RCP(3,:) = P(:);  clear P;
RCP(4,:) = 1;



% convert the coords into EXP space
RCP = (VF.mat\spm_matrix(M.x(:)')*VG.mat)*RCP;
RCP = round(RCP);
