function oSig = sigsctcat( Fname, Dim, Sig)
%SIGSCTCAT - Concatenate structures and some of their fields.
%	oSig = SIGSCTCAT({'pts','nts',2,XcorAct})
%	oSig = XcorAct{1} where the fields pts & nts have been concatinated
%	with those in XcorAct{2:end} along the 2nd dim.
%	NKL, 10.10.02

if ~isa(Fname,'cell'), Fname = {Fname}; end;
if length(Dim(:)) < length(Fname(:)),
   Dim = cat(1,Dim(:),ones(length(Fname(:))-length(Dim(:)),1)*Dim(end));
end;
if ~isa(Sig,'cell'), Sig = {Sig}; end;
oSig = Sig{1};

for f = 1:length(Fname(:)),
   for n = 2:length(Sig(:)),
	  if ~isempty(Sig{n}),
	      oSig = setfield( oSig, Fname{f},...
		    cat( Dim(f), getfield(oSig,Fname{f}), getfield(Sig{n},Fname{f})));
	  end;
   end;
end;

return;
