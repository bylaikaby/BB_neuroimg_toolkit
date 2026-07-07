function clnupdate(SESSION)
%CLNUPDATE - Updating the old "nature" sessions
%	CLNUPDATE(SESSION) Updating the old "nature" sessions
%	NKL, 24.10.02

Ses = goto(SESSION);
EXPS = validexps(Ses);
eps=sesparload(Ses);


%%% THIS WAS THE TRICK TO DEBUG MULTIPLE CHANNELS/OBSPS
if 0,
   for ExpNo=EXPS,
	   ep = eps{ExpNo};
	   name = catfilename(Ses,ExpNo,'mat');
	   load(name,'Cln');
	   Cln.dat = reshape(Cln.dat,[size(Cln.dat,1) 2 4]);
	   save(name,'Cln');
	   fprintf('clnupdate: %s done!\n',name);
   end;
end;

for ExpNo=EXPS,
	ep = eps{ExpNo};

	name = catfilename(Ses,ExpNo,'mat');
	load(name,'Cln');
	tmp = Cln.dat;
	evt = Cln.evt;
	usr = Cln.usr;
	dx  = Cln.dx;
	clear Cln;

	Cln.session		= Ses.name;
	Cln.grpname		= ep.grp.name;
	Cln.ExpNo		= ExpNo;

	Cln.dir.dname	= 'Cln';
	Cln.dir.physfile= catfilename(Ses,ExpNo,'phys');
	Cln.dir.imgfile	= catfilename(Ses,ExpNo,'img');
	Cln.dir.evtfile	= catfilename(Ses,ExpNo,'evt');
	Cln.dir.matfile	= catfilename(Ses,ExpNo,'mat');

	Cln.dsp.func	= 'dspcln';
	Cln.dsp.args	= {'color';'k';'linestyle';'-';'linewidth';0.5};
	Cln.dsp.label	= {'Time in sec'; 'ADC Units'};

	% SELECTION OF RELEVANT Ses.grp FIELDS
	Cln.grp			= ep.grp;
	Cln.usr			= {};
	Cln.evt			= {};
	Cln.mri			= ep.mri;
	Cln.stm			= ep.stm;
	Cln.dx			= 0;
	Cln.dat			= [];

	% CRITICAL PARAMETERS/VARIABLE ADJUSTED BY THE USER
	Cln.usr.oldusr			= usr;
	Cln.usr.oldevt			= evt;
	Cln.usr.neuofs			= ep.neu.ofs;
	Cln.usr.neulen			= ep.neu.len;
	Cln.usr.args.gtype		= ep.img.gradtype;
	Cln.usr.args.grange		= ep.img.grange;
	Cln.usr.args.graddur	= ep.img.graddur;

	Cln.dat = tmp;
	Cln.dx = dx;

	save(name,'Cln');	
	fprintf('clnupdate: %s done!\n',name);
end;



