% User MATLAB startup hook for imaging_toolkit.
% Copy to Documents\MATLAB\startup.m, or merge the block below into yours.
% Edit toolkit if the repo lives elsewhere.

toolkit = 'D:\imaging_toolkit';
matlabDir = fullfile(toolkit, 'matlab');
if isfolder(toolkit) && isfolder(matlabDir)
    addpath(matlabDir);
    add_imaging_toolkit_paths();
end
