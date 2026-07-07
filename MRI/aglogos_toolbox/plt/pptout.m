function pptout(FileName,Fmt)
%PPTOUT - dump the plot as image of format fmt
%	PPTOUT(FileName)	dumps in EMF format
%	PPTOUT(FileName,Fmt) dumps in Fmt format, Fmt = EMF, JPEG, TIF, etc.
%	NKL, 30.12.02

global DispPars;
  
if nargin < 2,
	Fmt = 'meta';
end;

Fmt = strcat('-d',Fmt);
FileName = hstrfext(FileName,'');
fprintf('PPTOUT: %s to %s\n', Fmt, FileName);
print(Fmt,FileName);
if DispPars.erase,
  close gcf
end;

