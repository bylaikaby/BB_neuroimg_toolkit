function em = expgeteyemov(SESSION, ExpNo)
%EXPGETEYEMOV - Read eye movement traces
% usage: em = getexpvitevgt(Ses, ExpNo)
% em: structure em{}.x, em{}.y with x/y eye position
% NKL, .7.2.1

if nargin < 2,
   error('usage: oSig = expgeteyemov(Ses, ExpNo);');
   return;
end;

Ses = goto(SESSION);
ep = sesparload(Ses);
grp = ep{ExpNo}.grp;
evt = expgetevt(Ses,ExpNo);
ems = evt.evt.ems;

if ~isempty(ems{1}),
	dx = ems{1}{1}/1000.0;		% the same for all obsp

	em.session		= Ses.name;
	em.grpname		= grp.name;
	em.ExpNo	= ExpNo;

	em.dir.dname	= 'em';
	em.dir.evtfile	= catfilename(Ses,ExpNo,'dgz');
	em.dir.matfile	= catfilename(Ses,ExpNo,'mat');

	em.stm		= ep{ExpNo}.stm;

	em.dsp.func = 'dspem';
	em.dsp.args = ...
		{'color';'k';'linestyle';'none';'marker';'.';...
		'markersize';0.5; 'markerfacecolor';'k';'markeredgecolor';'k'};
	em.dsp.label{1}	= 'X Eye Position';
	em.dsp.label{2}	= 'Y Eye Position';

	em.dx = dx;

	for N=length(evt.obs),
		mrievt = evt.obs{N}.times.mri;
		ofs = mrievt(1)/1000 + grp.adfoffset;		% mri(1) and user offset
		len = grp.adflen;
		ofspnt = round(ofs/dx);
		lenpnt = round(len/dx);
		endpnt = ofspnt + lenpnt;

		tmpx  = ems{N}{2};
		tmpy = ems{N}{3};

		L = min([length(tmpx) length(tmpy)]);
		if (endpnt > L), endpnt = L; end;

		% Fill raw data with the actual vital signs
		tmpx = tmpx(ofspnt:L);
		tmpy = tmpy(ofspnt:L);
		tmpx = detrend(tmpx);
		tmpx = tmpx/max(abs(tmpx(:)));
		tmpy = detrend(tmpy);
		tmpy = tmpy/max(abs(tmpy(:)));

		em.dat{N}.x = tmpx;
		em.dat{N}.y = tmpy;
		em.beg(N) = ofs;
		em.end(N) = L*dx;
	end;
else
	em = {};
end;

if ~nargout,
	emplot(em);
end;
	



