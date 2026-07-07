function SaveFilename = mrcca_filename(SES,GRPEXP,MriSig,RoiName)
%MRCCA_FILENAME - Get a filename to save the mr-tkcca result.
%  FILENAME = MRCCA_FILENAME(SES,GRPEXP,MriSig,RoiName)
%  gets a filename to save the mr-tkcca result.
%
%  EXAMPLE :
%    mrcca_filename('monkey','spont','roiTs','v1')  % for grouped one
%    mrcca_filename('e10a31','spont','roiTs','v1')  % for each session
%
%  VERSION :
%    0.90 08.01.13 YM  pre-release
%
%  See also sesmrcca


if any(strcmpi(SES,{'monkey','rat'})),
  sn  = SES;
elseif ~isempty(SES),
  SES = getses(SES);
  sn  = SES.name;
else
  sn  = '';
end

if isempty(GRPEXP),
  gn = '';
elseif isnumeric(GRPEXP),
  gn = strrep(deblank(sprintf('%d ',GRPEXP)),' ','+');
  gn = sprintf('exp(%s)',gn);
elseif ischar(GRPEXP),
  gn = GRPEXP;
elseif isstruct(GRPEXP),
  gn = GRPEXP.name;
end


fpath = sprintf('%s.tkcca',MriSig);
fname = sn;
if ~isempty(gn),
  if ~isempty(fname),  fname = sprintf('%s_',fname);  end
  fname = sprintf('%s%s',fname,gn);
end
if ~isempty(fname),  fname = sprintf('%s_',fname);  end
fname = sprintf('%s%s_mdl(%s)',fname,...
                MriSig,strrep(sub_text(RoiName),' ','+'));
fname = sprintf('%s.mat',strrep(fname,' ',''));
SaveFilename = fullfile(fpath,fname);
  
  
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function txt = sub_text(Vars)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Vars),
  txt = 'all';
elseif isnumeric(Vars),
  txt = deblank(sprintf('%g ',Vars));
elseif iscell(Vars),
  txt = '';
  for N = 1:length(Vars),
    txt = strcat(txt,sprintf(' %s',Vars{N}));
  end
  txt = strtrim(txt);
elseif ischar(Vars),
  txt = Vars;
else
  txt = '';
end
return
