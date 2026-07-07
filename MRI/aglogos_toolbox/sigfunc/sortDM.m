function [ oSig ] = sortDM(iSig, varargin )
%sortDM   -   Sort trials that contain Digital Markers
%
% USE:
%   Compute and SAVE
%   ----------------
%   sortDM(iSig,'ParName',ParValue,...);
%
%   Compute and return
%   ----------------
%   [ pars ] = sortDM(iSig,'ParName',ParValue,...);
%
%  Parameters can be controled by GRPP
%==========================================================================
%  Overall Parameters
%==========================================================================
%    GRPP.sortDM.Average         = 1;   % {0} | 1
%    GRPP.sortDM.SaveName        = [];  %{[]} | Alternative name to save
%    GRPP.sortDM.Save            = 0;   % {0} | 1
%==========================================================================
%  Other Parameters
%==========================================================================
%    GRPP.sortDM.use_sig_pars    = 0;   % {0} | 1 - use pars of iSig
%==========================================================================
%
%   VERSION
%==========================================================================
%    1.0, RMN: 15.10.15
%
% See also: getgrp, ricparsepars, ricgetpars

% Written by Ricardo Melo Neves


% Function called with no arguments ---------------------------------------
if nargin < 1,  eval(['help ' mfilename]); return;  end

if ~issig(iSig), oSig=[];return;end
if ~iscell(iSig), iSig = {iSig};end

SesName = iSig{1}.session;
ExpNo   = iSig{1}.ExpNo;

grp = getgrp(SesName, ExpNo);
if ~isfield(grp,'sortDM'),DFpars=[];else DFpars=grp.sortDM; end
%==========================================================================
%Function  Standard Parameters
%==========================================================================
std_pars = {'Average',0,'SaveName',[],'Save',0,'use_sig_pars',0};

f = sctmerge_prior(varargin, DFpars, std_pars);   

%=========
% Option - use_sig_pars
%=========
if f.use_sig_pars
    pars.DigMark = iSig{1}.DigMark;
else
    try
        pars  = ricgetpars(SesName,ExpNo);
    catch
        pars = expgetpar(SesName,ExpNo);        
    end        
end

%In case there is no digital marker, the signal was already sorted or it
%may  have been sorted elsewhere
if ~isfield(pars,'marker')||isempty(pars.marker)||...
        isfield(iSig{1},'sortDM')||length(iSig)>1
%     fprintf('\nsortDM %s|ExpNo:%d-sorting canceled', SesName,ExpNo);
    oSig = iSig;
    return
end
DM      = cellfun(@(x) x(:),pars.marker.char); 
UniqDM  = unique(DM);
lUniqDM = length(UniqDM);

tmpdat = iSig{1}.dat; 
iSig{1}.dat = [];

oSig = cell(1,lUniqDM);

SigName = iSig{1}.dir.dname;

fprintf('\n[sortDM] %s|ExpNo:%s|DM:%s\n',...
    SesName,num2str(ExpNo), regexprep(UniqDM','.{1}', '$0,'));
for aa = 1:lUniqDM
    
    oSig{aa} = iSig{1}; 
    
    cDM = UniqDM(aa);  
    idx = DM == cDM;
    
    oSig{aa}.sortDM.UniqDM = cDM;    
    oSig{aa}.sortDM.f      = f;
    oSig{aa}.sortDM.idx    = find(idx);        
    %Correct number of repeats
    oSig{aa}.sigsort.nrepeats = length(find(idx));
    
    switch SigName
        case 'ricspk'
            try
            oSig{aa}.tspk_times = iSig{1}.tspk_times(:,idx);
            oSig{aa}.tspk_bin = iSig{1}.tspk_bin(:,:,idx);
            catch
                keyboard
            end
        case 'tblp'
            oSig{aa}.dat = tmpdat(:,:,:,idx); DIM=4;
        case 'tCln'
            oSig{aa}.dat = tmpdat(:,:,idx); DIM=3;
        otherwise
            
            if aa==1
                DMs = bsxfun(@(x,y)  x==y, size(tmpdat), length(DM));                
                DIM = find(DMs);
                
                if isempty(DIM),fprintf('Matching DIM not found!\n');return;end
                
                per    = [DIM find(~DMs)];
                [~,IX] = sort(per);
                
                perdat = permute(tmpdat,per);
            end            
            oSig{aa}.dat = permute(perdat(idx,:,:,:,:),IX);
    end
    %=========
    % cln_rmart
    %=========   
%     if isfield(oSig{aa}, 'cln_rmart')
%         if aa==1, cln_rmart = oSig{1}.cln_rmart; end
%         subf = {'char','pulsdur','trainfrq','pulsnum','offset'};
%         
%         for bb=1:length(subf)
%             csubf = subf{bb};
%             oSig{aa}.cln_rmart.(csubf) =...
%                 cln_rmart.(csubf)(min(aa, length(cln_rmart.(csubf))));
%         end
%     end    
    %=========
    % Option - Average
    %=========
    if ismemberm(SigName,f.Average), oSig{aa}.dat = nanmean(oSig{aa}.dat,DIM);end
end
%==========================================================================
% SAVE
%==========================================================================
if isempty(f.SaveName),f.SaveName = SigName;end
if nargout < 1 || f.Save
    sigsave(SesName,ExpNo,f.SaveName,oSig);
end
end

