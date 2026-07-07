function grpclnspc(SESSION,GrpName)
%GRPCLNSPC - Make spectrograms for the Cln signal of each group
%	GRPCLNSPC(SesName,GrpName) - Where, GrpName is the name of a
%	valid group defined in the description file.
%	are the experiments of a
%
%	See also SIGSPC, SHOWSPC0, SHOWSPC3
%
%	NKL, 10.10.02

Ses = goto(SESSION);
name = strcat(GrpName,'.mat');
load(name,'Cln');

if length(Cln) == 1,
  gClnSpc = getClnSpc(Cln);
else
  clear gClnSpc;
  for K=1:length(Cln),
	gClnSpc{K} = getClnSpc(Cln{K});
  end;
end;

save(name,'gClnSpc','-append');
fprintf('gClnSpc: Saved file %s\n', name);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ClnSpc = getClnSpc(Cln)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(Cln.evt,'voltr'),
  T = Cln.evt.voltr;
else
  % We'll use the inter-trigger time as window length
  % It gives better time resolution to the spectrogram...
  % T = Cln.stm.ntrig * Cln.stm.intertrigt / 1000.0;
  T = Cln.stm.voldt;
end;
len = T / Cln.dx;
NFFT = getpow2(len,'ceiling');
ClnSpc = sigspc(Cln, T, T, NFFT, 'hanning');
return;

