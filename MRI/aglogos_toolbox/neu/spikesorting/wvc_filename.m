function FILENAME = wvc_filename(Ses,GrpName,Chan,Type)
%WVC_FILENAME - Get a filename for "wave_clus".
%  FILENAME = WVC_FILENAME(Ses,GrpName,Chan,Type) gets a spike file for "wave_clus".
%
%  EXAMPLE :
%    spkfile = wvc_filename('rat10043','spont',7,'spike')
%    spkfile_aligned =  wvc_filename('rat10043','spont',7,'aligned')
%
%  VERSION :
%    0.90 25.03.14 YM  pre-release
%
%  See also waveclus2spk waveclus_GetSpikes waveclus_DoClustering

if nargin < 4,  eval(['help ' mfilename]); return;  end



Ses = getses(Ses);
grp = getgrp(Ses,GrpName);

switch lower(Type)
 case {'spike' 'spikes'}
  FILENAME = sprintf('%s_%s_ch%d_spikes.mat',Ses.name,grp.name,Chan);
 case {'align' 'aligned'}
  FILENAME = sprintf('%s_%s_ch%d_aligned.mat',Ses.name,grp.name,Chan);
 case {'cluster'}
  FILENAME = sprintf('%s_%s_ch%d_cluster.mat',Ses.name,grp.name,Chan);
 case {'cluster_txt'}
  FILENAME = sprintf('%s_%s_ch%d_cluster.txt',Ses.name,grp.name,Chan);
 case {'fig' 'figure'}
  FILENAME = sprintf('%s_%s_ch%d_cluster.fig',Ses.name,grp.name,Chan);
 case {'run_fname'}
  FILENAME = sprintf('%s_%s_ch%d_temp',Ses.name,grp.name,Chan);
 case {'run_fname_in'}
  FILENAME = sprintf('%s_%s_ch%d_temp_data',Ses.name,grp.name,Chan);
 otherwise
  error(' ERROR %s: unsupported ''Type'' %s.\n',mfilename,Type);
end

FILENAME = fullfile('waveclus',FILENAME);


return
