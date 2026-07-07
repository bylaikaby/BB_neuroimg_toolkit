function mnfix_roitmat(SESSION,GRPNAME)
%mnfix_roimat - makes .mask as logical
% 06.06.05 YM
% 13.06.05 YM  make this as a function, not script
% 06.02.12 YM  use mroi_file().

%SESSION = 'm02th1';

Ses = goto(SESSION);


tmptxt = sprintf('Do you really need to modify Roi of ''%s''? Y/N[N]: ',Ses.name);
c = input(tmptxt,'s');
if isempty(c), c = 'N';  end

switch lower(c)
 case 'n'
  return;
end

load(mroi_file(Ses,'RoiDef'),'RoiDef');

% make images as int16.
if strcmpi(class(RoiDef.ana),'double'),
  RoiDef.ana = int16(round(RoiDef.ana));
end
if strcmpi(class(RoiDef.img),'double'),
  RoiDef.img = int16(round(RoiDef.img));
end

SEL_IDX = [];  % index for valid ROI.
for N = 1:length(RoiDef.roi),
  if isfield(RoiDef.roi{N},'mask'),
    RoiDef.roi{N}.mask    = logical(RoiDef.roi{N}.mask);
    if isfield(RoiDef.roi{N},'anamask'),
      RoiDef.roi{N}.anamask = RoiDef.roi{N}.mask;
    end
    SEL_IDX(end+1) = N;
  end
end
% remove non-sense ROIs without '.mask'.
RoiDef.roi = RoiDef.roi(SEL_IDX);


mroi_save(Ses,'RoiDef',RoiDef,'verbose',0,'backup',1);
