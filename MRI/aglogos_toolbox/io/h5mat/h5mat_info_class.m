function cname = h5mat_info_class(info)
cname = 'unknown';
if ~isfield(info,'Attributes'),  return;  end
for N = 1:length(info.Attributes)
  if strcmpi(info.Attributes(N).Name,'MATLAB_class')
    cname = info.Attributes(N).Value;
    break;
  end
end

return
