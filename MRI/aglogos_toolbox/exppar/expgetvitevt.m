function [pleth,resp] = expgetvitevt(SESSION, ExpNo)
%EXPGETVITEVT - Read vital signs, i.e. plethysmogram and respiration
% [pleth, resp] = EXPGETVITEVT(SESSION,ExpNo) reads the plethysmogram
% and the respiratory signals from the event files.
% NKL 12.03.04

if nargin < 2,
   error('usage: oSig = expgetvitevt(Ses, ExpNo);');
   return;
end;

Ses = goto(SESSION);
grp = getgrp(Ses,ExpNo);
evt = expgetevt(Ses,ExpNo);
ems = evt.dg.ems;

if ~isempty(ems{1}),
	dx = ems{1}{1}/1000.0;		% the same for all obsp

	pleth.session		= Ses.name;
	pleth.grpname		= grp.name;
	pleth.ExpNo         = ExpNo;
	pleth.dir.dname     = 'pleth';
	pleth.dir.evtfile	= catfilename(Ses,ExpNo,'dgz');
	pleth.dir.matfile	= catfilename(Ses,ExpNo,'mat');
	pleth.dsp.func      = 'dsppleth';
	pleth.dsp.args      = {'color';'k';'linestyle';'-';'linewidth';0.5};
	pleth.dsp.label{1}	= 'Time in seconds';
	pleth.dsp.label{2}	= 'Plethysmogram Amplitude';
	pleth.dx            = dx;
    pleth.dat           = ems{1}{2};
    
	resp.session		= Ses.name;
	resp.grpname		= grp.name;
	resp.ExpNo			= ExpNo;
	resp.dir.dname		= 'resp';
	resp.dir.evtfile	= catfilename(Ses,ExpNo,'dgz');
	resp.dir.matfile	= catfilename(Ses,ExpNo,'mat');
	resp.dsp.func		= 'dspresp';
	resp.dsp.args		= {'color';'b';'linestyle';'-';'linewidth';1};
	resp.dsp.label{1}	= 'Time in seconds';
	resp.dsp.label{2}	= 'Respiration Phase';
	resp.dx = dx;
    resp.dat           = ems{1}{3};
else
	pleth = {};
	resp = {};
end;
return;


