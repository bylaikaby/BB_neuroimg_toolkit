function grapat = getgrapat(SESSION,ExpNo,ObspNo,mrievt)
%GETGRAPAT - Get gradient pattern vectors
%	The gradient-inteference patterns depend on segment, slice etc.
%	because the slice-slection, dephasing etc. pulse are different
%	To perfectly denoise, we search for specific patterns (DAL, 2001).
%	This function selects different gradient-interference patterns
%	that are used to reallign the MRI events. They usually have
%	some jitter because of ETS etc..
%	DAL, NKL, 06.10.02, 26.10.02
%
%	grapat = GETGRAPAT(Ses,ExpNo,ObspNo,mrievt)
%	SESSION: Session name or Ses strucure
%	ExpNo: Experiment number
%	ObspNo: Observation period number
%	mrievt: Original MRI events converted in seconds
%
%	Returns:
%	grapat: Vector with gradient interference
%	if nargout == 0, plots the gradient pattern
%
%	See also CLNADF, CLNEVT, GETGRAPAT

Ses = goto(SESSION);
ep	= sesdumppar(Ses);
ep	= ep{ExpNo};

if nargin < 3,	ObspNo = 1; end;
if nargin < 2,	ExpNo = 1; end;
if nargin < 4,
	% Original MRI events convertd in SECONDS! (rather than msec)
	mrievt = ep.neu.mri{ObspNo}.orgt;
end;

gtypes	= ep.img.gradtype;
grange	= ep.img.grange;
gch		= ep.neu.nch-1;
rawdx	= ep.neu.dx;
recofs	= round(ep.neu.mri{ObspNo}.ofs/rawdx);
reclen	= round(ep.neu.mri{ObspNo}.len/rawdx);

physfile = catfilename(Ses,ExpNo,'phys');
gra = adf_read(physfile,ObspNo-1,gch,recofs,reclen);

for g = gtypes,
	patdat = grange{g}/1000;
	valindxs = find(gtypes == g);
	firstexample = valindxs(1);
	ofsix = 1+round((mrievt(firstexample) + patdat(1))/rawdx);
	lenix = 1+round((patdat(2)-patdat(1))/rawdx);
	grapat{g} = gra(ofsix:ofsix+lenix);
end

if ~nargout,
	mfigure([10 50 600 900],sprintf('getgrapat(''%s'', %d)',Ses.name,ExpNo));
	for N=1:length(gtypes),
		patdat = grange{N};
		t = 1000 * [0:length(grapat{N})-1]*rawdx;
		subplot(length(gtypes),1,N);
		plot(t+patdat(1),grapat{N},'k');
		set(gca,'xlim',patdat);
		xlabel('Time in msec');
		title(sprintf('Gradient(%d), DT(%d-%d)',N,N,N+1));
	end;
end;


