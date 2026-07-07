function SaveFilename = tcorr_filename(SES,GRPEXP,MriSig,RoiName,NeuSig,NeuChans,ppZscore2,ppSigSelect)
%TCORR_FILENAME - Get a filename to save the tcorr result.
%  FILENAME = TCORR_FILENAME(SES,GRPEXP,MriSig,RoiName,NeuSig,NeuChans)
%  FILENAME = TCORR_FILENAME(SES,GRPEXP,MriSig,RoiName,NeuSig,NeuChans,ppZscore2,ppSigSelect)
%  gets a filename to save the tcorr result.
%
%  EXAMPLE :
%    tcorr_filename('monkey','spont','roiTs','v1','blp','all')  % for grouped one
%    tcorr_filename('e10a31','spont','roiTs','v1','blp','all')  % for each session
%
%  VERSION :
%    0.90 12.02.12 YM  modified from tkcca_filename.
%
%  See also sestcor tcorr_filename


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


if 1,
  fpath = sprintf('%s.tcorr',MriSig);
  fname = sn;
  if ~isempty(gn),
    if ~isempty(fname),  fname = sprintf('%s_',fname);  end
    fname = sprintf('%s%s',fname,gn);
  end
  if ~isempty(fname),  fname = sprintf('%s_',fname);  end
  fname = sprintf('%sroi(%s)',fname,strrep(sub_text(RoiName),' ','+'));
  fname = sprintf('%s_%s(%s)',fname,...
                  NeuSig,strrep(sub_text(NeuChans),' ','+'));
  if nargin > 6,
    SaveFilename = sprintf('%s_pp(drv(%d)-%s)',fname,...
                           ppZscore2,ppSigSelect);
  end
  fname = sprintf('%s.mat',strrep(fname,' ',''));
  SaveFilename = fullfile(fpath,fname);
else
  SaveFilename = sprintf('tcorr_%s_%s(%s)_%s(%s)',gn,...
                         MriSig,strrep(sub_text(RoiName),' ','+'),...
                         NeuSig,strrep(sub_text(NeuChans),' ','+'));
  if nargin > 6,
    SaveFilename = sprintf('%s_pp(drv(%d)-%s)',SaveFilename,...
                           ppZscore2,ppSigSelect);
  end
  SaveFilename = sprintf('%s.mat',strrep(SaveFilename,' ',''));
end
  
  
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
