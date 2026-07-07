function Sig = blpselect(blp,BandName)
%BLPSELECT - select blp bands and return as a signal structure
%  SIG = BLPSELECT(BLP,BANDNAME) selects blp bands and returns as SIG.
%
%  EXAMPLE :
%    >> blp = sigload(Ses,ExpNo,'blp');
%    >> sig = blpselect(blp,'Mua');
%
%  VERSION :
%    0.90 18.12.07 YM  pre-release
%
%  See also getrf

if nargin < 2,  eval(sprintf('help %s',mfilename)); return;  end


if ischar(BandName),  BandName = { BandName };  end

idx = [];  signame = 'blp';
for N = 1:length(BandName),
  bname = BandName{N};
  % if BandName as blp[xxx], then remove 'blp','[]'
  bname = strrep(bname,'blp','');
  bname = strrep(bname,'[','');
  bname = strrep(bname,']','');
  for K = 1:length(blp.info.band),
    if strcmpi(blp.info.band{K}{2},bname),
      idx(end+1) = K;
      signame = sprintf('%s_%s',signame,bname);
    end
  end
end


Sig = blp;
Sig.dat = blp.dat(:,:,idx,:);  % (t,chan,band,...)
Sig.dir.dname = signame;
Sig.info.band = blp.info.band(idx);
if isfield(blp,'filters') & ~isempty(blp.filters),
  Sig.filters = blp.filters(idx);
end

return
