function [ Cln ] = cln_rmart(SesName, ExpNo, varargin)
%CLNRMART  - Remove Artifacts from Cln signal
%
% USE:
%----------------------
%   [ Cln ] = cln_rmart(Cln, [],'ParName',ParValue,...);
%   [ Cln ] = cln_rmart(SesName,ExpNo);
%   [ Cln ] = cln_rmart(SesName,ExpNo,'ParName',ParValue,...);
%   [ Cln ] = cln_rmart(SesName,ExpNo,'ParName',ParValue,...);
%             cln_rmart(SesName,ExpNo);
%
%==========================================================================
%  Parameters can be controled by GRPP or GRPP.SPIKE2.marker
%==========================================================================
%    GRPP.cln_rmart.char         = ['A','B'];    %Digital Markers
%    GRPP.cln_rmart.pulsdur      = [5  , 5 ];    %(msec) Duration Of each pulse
%    GRPP.cln_rmart.offset       = 0;            %Add time offset (msec
%    GRPP.cln_rmart.trainfrq     = [10 , 30];    %(Hz) 
%    GRPP.cln_rmart.pulsnum      = [5  , 10];    %Number of pulses 
%    GRPP.cln_rmart.cancel       = 0;            %Cancel art removal for given char
%==========================================================================
%  Overwirte option for Each Channel
%==========================================================================
%    GRPP.cln_rmart.ch{ChNumber}.char         = [];       
%    GRPP.cln_rmart.ch{ChNumber}.pulsdur      = 5;        
%    GRPP.cln_rmart.ch{ChNumber}.offset       = 0;        
%    GRPP.cln_rmart.ch{ChNumber}.trainfrq     = 1;        
%    GRPP.cln_rmart.ch{ChNumber}.pulsnum      = 1;        
%    GRPP.cln_rmart.ch{ChNumber}.cancel       = 0;        
%==========================================================================
%
%  VERSION :
%    0.90 15.04.14 RMN  
%    0.91 15.11.15 RMN  
%
% See also sctmerge_prior

% Written by Ricardo Melo Neves
% Version 1.0

% Function called with no arguments ---------------------------------------
if nargin < 1,  eval(['help ' mfilename]); return;  end

Cln=[];
%Input Cln
if issig(SesName)
    Cln     = SesName;
    if iscell(Cln), Cln=Cln{1};end
    SesName = Cln.session;
    ExpNo   = Cln.ExpNo;
else
    Ses     = goto(SesName);
    SesName = Ses.name;
end
%Get all grp if not provided
if ~exist('Cln','var')&& (nargin<2||isempty(ExpNo)),ExpNo=validexps(SesName);end
if ischar(ExpNo), ExpNo = getexps(SesName,ExpNo); end

lExpNo = length(ExpNo);
for aa = 1:lExpNo
    
    cExpNo = ExpNo(aa);
    grp    = getgrp(SesName,cExpNo);
    %Description file parameters    
    if ~isfield(grp, mfilename), grp.(mfilename) = [];end
    if ~isfield(grp.SPIKE2, 'marker') , grp.SPIKE2.marker  = []; end
    %======================================================================
    %Function  Standard Parameters
    %======================================================================
    std_pars = {'char',[],'pulsdur',0,'trainfrq',1,'pulsnum',1,'offset',0,...
        'cancel',0,'ch',[],'iSigName',{'Cln'}};
    
    f = sctmerge_prior(varargin, grp.cln_rmart, grp.SPIKE2.marker, std_pars); 
    f = sub_check_pars(f);    
    %======================================================================
    % Event Times
    %======================================================================
    try
        pars  = ricgetpars(SesName,cExpNo);
    catch
        pars = expgetpar(SesName,cExpNo);
        
        pars.EvTimes = pars.stm.time{1}(pars.stm.val{1}==1); 
    end    
    Ev = pars.EvTimes;     
    
    if isfield(pars.stm, 'pON')
        Ev = pars.stm.pON;   
    end
    
    if isempty(Ev), continue;end
    %======================================================================
    % Load Cln Signal
    %======================================================================
    fprintf('[%s]|Ses:%s|ExpNo:%d',mfilename,SesName,cExpNo);
    if isempty(Cln) || aa>1
        pdot(aa,lExpNo, '|Loading Cln...')
        Cln = sigload(SesName, cExpNo, f.iSigName{1});
    end    
    dx  = Cln.dx;
    s1  = size(Cln.dat, 1);
    %******************
    %For all Events
    %******************
    lEv = length(Ev);
    for bb = 1:lEv        
        
        cEv = Ev(bb);
        % Every DigMark can have a different parameters
        % This is important random stimulation
        % paramenters within the same file
        cchar = [];
        if ~isempty(f.char) && ~isempty(f.char{1}) && ...
                isfield(pars,'marker') && ~isempty(pars.marker)
            cchar = pars.marker.char{bb};            
        end
        %******************
        %For all Channels
        %******************
        for dd=1:size(Cln.dat,2)            
            
            cf=f;
            %Overwrite parameters for each channel
            if ~isempty(f.ch) && length(f.ch)>=dd
                
                cf = sctmerge(f,f.ch{dd});
                cf = sub_check_pars(cf); 
            end
            ccf = sub_get_par(cf, cchar);            
            %=========
            % Option - NON
            %=========
            if ccf.cancel, continue; end                
            %******************
            %For all Pulses
            %******************            
            for cc = 1:ccf.pulsnum
                
                P1  = floor((cEv - abs(ccf.offset)/1000 + (cc-1)/ccf.trainfrq) /dx);
                P2  = P1 + round(ccf.pulsdur/1000 / dx);
                
                if P2 > s1, P2=s1;    end
                if P2 < 2 , continue; end
                if P1 > s1, break;    end
                if P1 <= 0, P1=2;     end
                
                len = P2-P1+1;
                
                Grad = (Cln.dat(P2, dd) - Cln.dat(P1-1, dd)) / (len+1);
                
                Cln.dat(P1 : P2, dd) = ((Grad * (1:len)) + Cln.dat(P1-1, dd))';     
            end
        end
    end
    Cln.(mfilename) = f;
    %======================================================================
    % Save
    %======================================================================    
    if nargout ==0 
       sigsave(Ses,cExpNo,'Cln',Cln);
       fprintf('\n');
    end
end
end
%==========================================================================
% Check parameters
%==========================================================================
function f = sub_check_pars(f)

if ischar(f.char), f.char = {f.char};end
if ~isempty(f.char)
    
    ParName = fieldnames(f);
    lchar = length(f.char);
    
    for bb = 1:length(ParName)
        
        cp = f.(ParName{bb});
        if isempty(cp), continue;end
        lpar = length(cp);
        
        tmp(1:lchar)    = f.(ParName{bb})(1);
        tmp(1:lpar)     = f.(ParName{bb})(1:lpar);
        f.(ParName{bb}) = tmp; clear tmp        
    end
end
end
%==========================================================================
% Return the parameters of a given char
%==========================================================================
function f = sub_get_par(f,char)

i = max([1, find(strcmp(char, f.char))]);
ParName = fieldnames(f);
for bb = 1:length(ParName)    
    
    if isempty(f.(ParName{bb})), continue;end
    
    f.(ParName{bb}) = f.(ParName{bb})(i);
end
end
















