function Cln = vdecmain(SESSION,ExpNo,ARGS)
%VDECMAIN - Decimate signal collected with video stimuli.
% VDECMAIN(SESSION,ExpNo,ARGS)
%  decimates the original signal from 22300Hz to about 7000Hz.
%  There are two important differences between this function
% and decmain: (a) This function concatanates the channel-data from
% two different adf files, and (b)it is customized to work with the files
% collected during the video presentation. A special function is
% required because movie information is included in the Signal
% structure.
%
% In summary the function does the following:
% 1. Read the standard adf file with most of the channels (max 15)j
% 2. Read the second adf file, which contains the "16th" signal if
%	 all signals are good, and it also contains the movie information.
% 3. For each adf file, the channel 16 has the common synchronication signal.
% 4. The converted MAT file has maximally 16 channels, whereby the
%	 16th will come from the second file.
% 5. Decimate the signals etc....  
%
% STRUCTURE:
% Sig.dat	= [NT,NoChan,NoObsp]
%
%  VERSION :
%   0.90 06.02.04 YM
%   0.91 31.01.12 YM  use sigfilename()
%   0.92 17.07.13 YM  use sigsave()
%
% See also DECMAIN CLNMAIN VCLNMAIN VGETFRAMEDATA SIGSAVE


if nargin < 2,
  error('VDECMAIN: usage: Cln = vdecmain(SESSION,ExpNo,ARGS);');
end;

Ses	= goto(SESSION);
par = expgetpar(Ses,ExpNo);

SAVE		= 1;	% Create/Append MAT file

if exist('ARGS','var'),
  Cln = decmain(SESSION,ExpNo,ARGS);
else
  Cln = decmain(SESSION,ExpNo);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOVIE-SPECIFIC INFORMATION
% get frame indices of movie;
adfofsSec = Cln.usr.adfoffset*Cln.dx;
adflenSec = size(Cln.dat,1)*Cln.dx;
Cln.dir.videofile = expfilename(Ses,ExpNo,'video');
Cln.movie = vgetframedata(Ses,ExpNo,par.evt.validobsp,adfofsSec,adflenSec);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



if ~nargout & SAVE,
  % fname = sigfilename(Ses,ExpNo,'Cln');
  % if ~exist(fname,'file'),
  %   mmkdir(fileparts(fname));
  %   fprintf(' Saving "Cln" into %s ...', fname);
  %   save(fname,'Cln');
  % else
  %   fprintf(' Appending "Cln" into %s ...', fname);
  %   save(fname,'Cln','-append');
  % end
  % fprintf('done.!\n');
  sigsave(Ses,ExpNo,'Cln',Cln);
end;


% if nargout == 0, then likely to be called from sesdecmain.
% Let's free 'Cln' for next processing,
% otherwise matlab holds 'Cln' as 'ans' within sesdecmain 
% that will cause 'Out of memory' bussiness...
if nargout == 0, Cln = {};  end
