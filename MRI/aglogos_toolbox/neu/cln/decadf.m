function sig = decadf(Ses, ANAP)
%DECADF - Decimate original data
%	sig = CLNADF(Ses, ANAP) does the actual cleaning of MRI+Phys Data
%	NKL, 26.04.03
%	See also CLNMAIN CLNEVT GETGRANAPAT

DEBUG = 0;
VERBOSE = 1;

% -----------------------------------------------------------------------
% STRUCTURE USED BY CATSIGNAL TO PUT THINGS TOGETHER
% -----------------------------------------------------------------------
sig.ObspNo	= ANAP.ObspNo;				% Current Obsp (resolve by catsignal)
sig.ChanNo	= 1;						% Current Channel (set below)
sig.ChunkNo = ANAP.chunk;				% Which segment we are in...
sig.cln		= [];						% Here save the data
sig.dx		= ANAP.dx*ANAP.decfrac;		% Dx after decimation

% -----------------------------------------------------------------------
% This here is just to ensure we will not have artifacts at the last
% samples. So, we denoise a few more which won't be taking into account
% when we glue things together with the catsignal function!
% -----------------------------------------------------------------------
OLAP = 2 * ANAP.NoGrad;					% One overlapping volume
mri = ANAP.mri{ANAP.ObspNo};			% Corrected MRI events
imri = round(mri/ANAP.dx);				% MRI Events in points
imri = imri - imri(1);					% Offset corrected
imri = round(imri/ANAP.decfrac);		% And decimated
ANAP.uniqlen = round(ANAP.uniqlen/ANAP.decfrac);

sig.segbeg = ANAP.Seg{ANAP.chunk}.beg;			% First MRI Event of chunk
sig.segend = ANAP.Seg{ANAP.chunk}.end + OLAP;	% Last MRI Event of chunk
sig.segofs = imri(ANAP.Seg{ANAP.chunk}.beg);	% Start here in catsignal
if sig.segofs < 1, sig.segofs = 1; end;

% -----------------------------------------------------------------------
% CHECK FOR THE LAST EVENT: THE LAST SEGMENT SHOULD NOT HAVE THE "OLAP"
% REMEMBER: Often there is a "last" MRI events with no further recording
% To avoid chrashes we analyze up to one before the last MRI event!
% Also, the record to be read from the ADF file should be by one TR
% longer than the last event...
% -----------------------------------------------------------------------
if sig.segend > length(mri)-1,
	sig.segend = length(mri)-1;
end;

% -----------------------------------------------------------------------
% ANAP.grd HAS THE GRADIENT TYPES 111222333444111222333444.... etc.
% curgrd selects the relevant portion for the current CHUNK!
% Curmri selects the relevant portion of MRI for the current CHUNK!
% -----------------------------------------------------------------------
curgrd = ANAP.grd(sig.segbeg:sig.segend);
curmri = imri(sig.segbeg:sig.segend);
curmri = curmri - curmri(1);

% -----------------------------------------------------------------------
% NOW WE COMPUTE THE FILE OFFSET AND RECORD LEN
% THIS IS ONLY USED TO READ THE DATA
% -----------------------------------------------------------------------
sig.recofs = round(mri(sig.segbeg)/ANAP.dx);
sig.reclen = round((mri(sig.segend+1)-mri(sig.segbeg))/ANAP.dx);
sig.seglen = round((mri(ANAP.Seg{ANAP.chunk}.end)-mri(sig.segbeg))/ANAP.dx);
sig.seglen = round(sig.seglen/ANAP.decfrac);

if sig.reclen > ANAP.obslen - sig.recofs,
	sig.reclen = ANAP.obslen - sig.recofs;
end;

for ch = [1:ANAP.NoChan-1],
  sig.ChanNo = ch;				% Store it here; to be used by catsignal()
  fprintf('Processing Channel %d\n', sig.ChanNo);
  dat = adfread(Ses,ANAP.ExpNo,sig.ObspNo,ch,sig.recofs,sig.reclen);
  if ANAP.decfrac > 1,
	dat = decimate(dat(:),ANAP.decfrac);
  end;
  sig.cln = dat;

  fprintf('Cleaning %d different gradient types: ', ANAP.NoUniq);

  MatFile=sprintf('%s/%s_e%05d_to_e%05d_o%03d_c%03d.mat',...
		ANAP.tmpdir,ANAP.root,sig.segbeg,sig.segend,sig.ObspNo,ch);

  fprintf('Saving clean segment to file:\n\t%s\n',MatFile);
  if exist(MatFile) == 2,
	save(MatFile,'sig','-Append');
  else
	save(MatFile,'sig');
  end;

  sig = rmfield(sig,{'dat2' 'dat2avg' 'Reco'});
  fprintf('...done\n');

end;	%%% END of ch
return;


