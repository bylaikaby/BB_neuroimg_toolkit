function GROI = rat_henry(varargin)
%RAT_HENRY - Returns the ROIs of the rat - 2013-April-24
%
%
%  EXAMPLE :
%    groi = macaque_henry;
%    groi = rat_henry;
%
%  See also macaque_heny paxroigroups


% HENRY  2013-04-24: I subdivided some of the ROI:
% Hippocampus: dHipp -- iHipp -- vHipp -- Sub
% Striatum: dlStriatum -- vmStriatum -- Acc
% Thalamus: aThal -- mThal -- lThal
% PFC: mPFC -- lPFC
% Ins: aIns -- dgIns
% S1-2: S1 -- S2
% M1-2: M1 -- M2
%
% HENRY  2013-01-19: I started to work on the grouping (started on 2013-01-04). I will change the
% date here above (after "HENRY...:") everyday I make new changes. My goal
% is to have a list that parallels as much as possible the list I made for
% the monkey. I will also update mroiatlas.mat accordingly.
GROI = {};


% LEFT-RIGHT+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GROI{end+1} =  {'LEFT','LEFT', [0.5 0.1 0.2],  'LEFT'};
GROI{end+1} =  {'RIGHT','RIGHT', [0.5 0.1 0.2],  'RIGHT'};
% RHOMBENCEPHALON (BRAINSTEM)++++++++++++++++++++++++++++++++++++++++++++++
GROI{end+1} =  {'Brainstem','Brainstem', [0.5 0.1 0.2],...
                {'LVe','SpVe','MVePC','MVeMC','SuVe','Cu','BCu','cu',...
                'sp5','Pa5','Sp5C','Sp5I','Sp5O','Pr5VL','PCRtA','PCRt',...
                'MdD','IRt','Gi','DPGi','MdV','12','LRtS5','RVL','CVL'}};

% METENCEPHALON (PONS + CEREBELLUM)++++++++++++++++++++++++++++++++++++++++
% Cerebellum (dorsal met.)-------------------------------------------------
% proximal muscles - trunk/posture - spinocerebellum proximal  
GROI{end+1} =  {'Vermis','Vermis', [0.57 0.06 0.20], {'vermis'}};                    
% distal muscles - limbs - spinocerebellum distal
GROI{end+1} =  {'IntHemCb','Intermediate cerebellar hemisphere', [0.59 0.06 0.39],...
                {'inthemCb'}};                                            
% proximal muscles - trunk/posture - spinocerebellum proximal
GROI{end+1} =  {'alCb','Anterior cerebellar lobe', [0.63 0.06 0.78], {'alCb'}};
% receive cortical afferent from the pontine nucleus - cerebrocerebellum
GROI{end+1} =  {'LatHemCb','Lateral cerebellar hemisphere', [0.61 0.06 0.59],...
                {'lathemCb'}};                                           
% receive vestibular afferent - vestibullo/oculocerebellum 
GROI{end+1} =  {'pflCb','Parafloculonodular', [0.90 0.22 0.78],...
                {'pflCb'}};                                               
% output of the cerebellum - massive projections to thalamus (+few others)
GROI{end+1} =  {'DCbN', 'Deep cerebellar nuclei', [.2 .2 1],...
                {'DCbN'}};

% Pons (ventral met.)------------------------------------------------------
GROI{end+1} =  {'PontReg','Pontine Region',[.7 .7 .7],... %HENRY: renamed as in mky
                {'lfp','Pn','PnO','RtTg','RtTgP','tfp'}};
GROI{end+1} =  {'Raphe', 'Raphe', [.2 .2 1],... %Already as in mky
                {'CLi','DR','DRC','DRV','DRVL','PMnR','RLi','MnR'}};
GROI{end+1} =  {'LCreg','LC+CGn+SubC', [.1 .5 .7],...
                {'LC','SubCA'}};
       
% MESENCEPHALON++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GROI{end+1} =  {'MesE','MesE',[.2 .2 .2],... %not mapped in mky
                {'DpMe','APT','IMLF','IMLFG','PaR','REth','RMC','RPC'}};

%Tectum--------------------------------------------------------------------
GROI{end+1} =  {'SC', 'Superior Colliculus',      [.4 .3 .1],...
                {'DpG','DpGWh','DpWh','InG','InWh','Op','SuG','SC'}};
GROI{end+1} =  {'InfCol',  'Inferior Colliculus', [0.08 0.22 0.39],...  %added
                {'BIC','CIC','cic','ECIC','IC','DCIC','bic'...
                 'PBG'}};

% Tegmentum-----------(many small areas omitted)---------------------------
GROI{end+1} =  {'PAG', 'Periaqueductal Gray', [.5 .5 .5],... %renamed
                {'DLPAG','DMPAG','LPAG','PAG','Su3','Su3C','VLPAG'}};
     
           
% DIENCEPHALON+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%Basal Forebrain-----------------------------------------------------------             
GROI{end+1} =  {'DBMS', 'Diagonal Band + Septum', [.3 .5 .7],... %IMO, too small to be drawn spearately, like in monkeys
                {'HDB','VDB', 'df','f','Ld','LSD','LSI','LSV','MS',...
                 'PLd','SFi','SHi','SL','TS'}};                          
%GROI{end+1} =  {'DB', 'DiagonalBand', [.3 .5 .7], {'HDB','VDB'}};
%GROI{end+1} =  {'Septum', 'Septum', [.2 1 .2],...
%               {'df','f','Ld','LSD','LSI','LSV','MS','PLd','SFi','SHi','SL','TS'}};
GROI{end+1} =  {'BNST', 'StriaTerm', [.5 0 0],... %not yet mapped in mky
                {'BSTL',',BSTLD','BSTLI','BSTLJ','BSTLP','BSTLV','BSTMA',...
                 'BSTMPI','BSTMPL','BSTMPM','BSTMV','BSTS'}};
             
%Basal Ganglia-------------------------------------------------------------
%GROI{end+1} =  {'BG',  'Striatum', [.5 .8 1],... %inserted Accumbens
%                {'CPu','AcbC','AcbSh', 'LAcbSh', 'aca_intraAcb'}};  
%GROI{end+1} =  {'Acc', 'Accumbens', [1 0 0],...  %now in Striatum
               % {'AcbC', 'AcbSh', 'LAcbSh', 'aca_intraAcb'}};          
GROI{end+1} =  {'SN','SubNigra',[.3 .1 .6],...
                {'PBP','PN','SN','SNCD','SNL','SNM','SNR','SNRDM','SNRVL'}};
GROI{end+1} =  {'VTA','Ventral Tegmental Area', [.4 .6 1], {'VTA'}}; 

%Smaller and 'hard to map' regions-----------------------------------------
%GROI{end+1} =  {'IPAC', 'Interpeduncular-Interestitial',[.3 .5 .7],...
                %{'IPAC','IPACL','IPACM','IP','IPA','IPD','IPL','IPR','IPRL'}};
                % HENRY: WAY TO SMALL AND POSSIBLY TOO VENTRAL

%Hypothalamus------------------------------------------------------------
GROI{end+1} =  {'HTh', 'Hypothalamus', [0 .5 0]...
                {'HTv','HTd','AHA','AHC','AHP','ArcD','ArcL','ArcLP','ArcM',...
                 'ArcMP','Cir','DA','DMC','DMD','DMV','DTM','Gem','LA','LH','LM','LPO',...
                 'MCLH','MEE','MEI','ML','MM','MMn','mp','MPA','MPO','MPOL','MPOM','MRe','MTu',...
                 'PaAM','PaAP','PaDC','PaLM','PaMP','PaPo','PaPo','PaV','Pe','PeF','PH','pm',...
                 'PMD','PMV','Rch','SMT','SuM','SuML','SuMM','TC','Te','VLH','VMHA','VMHC',...
                 'VMHDM','VMHVL','VTM'}};          
%GROI{end+1} =  {'Tha', 'Thalamus',                [1 .8 .5],  'Tha'};
GROI{end+1} =  {'aTha', 'Anterior Thalamus', [1 .8 .5],...
                {'AD','AM','AV', 'AVDM','AVVL','VA','AMV','IAM'}};
GROI{end+1} =  {'mTha', 'Median Thalamus',                [1 .8 .5],...
                {'CL','CM','IAD','IMD','iml','imvc','LHb','LHbL','LHbM','MD',...
                 'MDC','MDL','MDM','MDPL','OPC','PC','PF','PoMn','PT','pv','PV','PVA', ...
                 'PVP','SM','sm','SPF','SPFPC'}};
GROI{end+1} =  {'lTha', 'Lateral Thalamus',                [1 .8 .5],...
                {'DLG','LDDM','LDVL','LPL','LPLC','LPLR',...
                 'LPMC','LPMR','PIL','Po','PoT','Rt','Sc','SG','VL','VLG',...
                 'VLGMC','VLGPC','VM','VPL','VPM','VPPC','mt','Re',...
                 'Rh','Sub','SubD','SubV','VRe','MGD','MGV'}};
GROI{end+1} =  {'Amy', 'Amygdala', [.8 0 0],...
                {'amyg','AA','AAD','AAV','Aco','AHiAL','AHiPM','APir',...
                 'AStr','BLA','BLP','BLV','BMA','BMP','BSTIA','CeC','CeL','CeM','CxA',...
                 'I','IM','IMG','LaVL','LaVM','MeAD','MePD','MePV','PLCo','PMCo'}};         
%GROI{end+1} =  {'Striatum',  'Striatum', [.5 .8 1],... %inserted Accumbens
 %               {'CPu','AcbC','AcbSh', 'LAcbSh', 'aca_intraAcb'}};  
GROI{end+1} =  {'dlStriatum',  'Dorsolateral Striatum', [.5 .8 1],...
                {'CPu'}}; 
GROI{end+1} =  {'vmStriatum',  'Ventromedial Striatum', [.5 .8 1],...
                {'CPu'}}; 
GROI{end+1} =  {'Acc', 'Accumbens', [.5 .8 .1],...
                {'AcbC','AcbSh', 'LAcbSh', 'aca_intraAcb'}};
GROI{end+1} =  {'GP',  'Globus Pallidus', [.5 .8 1],... %separated from striatum
                {'LGP','MGP','VP'}}; %added MGP
%GROI{end+1} =  {'MGN','MGN',[.4 .4 .4], {'MGD','MGV'}};
GROI{end+1} =  {'ZoIns','Zona Inserta', [.7 .5 .3], {'ZI','ZID','ZIV'}};
%GROI{end+1} =  {'SubInn','SubInn',[.4 1 .4], {'SI','SIB','SID','SIV'}};

%TELENCEPHALON - CEREBRAL CORTEX++++++++++++++16 GROI's++++++++++++++++++++
GROI{end+1} =  {'Olf','Olfactory',[ .3 .3 .3],...
                {'AOD','AOE','AOL','AOM','AOP','aci','Tu1','Tu2','Tu3','Tu'}};
%GROI{end+1} =  {'HP', 'Hippocampus', [1 0 0],...
 %              {'CA3d','DGd','hc_fd','hc_d','DS','hc_v','CA3v','VS','DGv','PoDG','STr', ...
  %              'PAs','Post','PrS'}};      
GROI{end+1} =  {'dHP', 'Dorsal Hippocampus', [1 0 0],...
                {'CA3d','DGd','hc_fd','hc_d','DS','CA3v','VS','DGv','PoDG'}}; 
GROI{end+1} =  {'iHP', 'Intermediate Hippocampus', [1 0 0],...
                {'CA3d','DGd','hc_fd','hc_d','DS','hc_v','CA3v','VS','DGv','PoDG'}};
GROI{end+1} =  {'vHP', 'Ventral Hippocampus', [1 0 0],...
                {'CA3d','DGd','hc_fd','DS','hc_v','CA3v','VS','DGv','PoDG'}}; 
GROI{end+1} =  {'Sub', 'Subiculum', [1 0 0],...
                {'PAs','Post','PrS'}};
GROI{end+1} =  {'Ent', 'Entorhinal Cortex',      [0 1 0],...
                {'DEn','Ect','LEnt','PRh','VEn','MEnt'}};         
GROI{end+1} =  {'PirFo','Piriform Cortex',[.1 .5 .1], {'Pir/ext','Pir/int','Pir','PirCtx'}}; 

%Sensorimotor Areas--------------------------------------------------------
%GROI{end+1} =  {'M1-2','Motor Cortex', [.3 .4 .9], {'M1','M2'}};
GROI{end+1} =  {'M1','Primary Motor Cortex', [.3 .4 .9], {'M1'}};
GROI{end+1} =  {'M2','Secondary Motor Cortex', [.3 .4 .9], {'M2'}};
%GROI{end+1} =  {'S1-2', 'Somatosensory Cortex',    [1 0 1],...
 %               {'S1','S1BF','S1DZ','S1FL','S1HL','S1J','S1JO','S1Tr','S1ULp','S2'}};
GROI{end+1} =  {'S1', 'Primary Somatosensory Cortex',    [1 0 1],...
                {'S1','S1BF','S1DZ','S1FL','S1HL','S1J','S1JO','S1Tr','S1ULp'}};
GROI{end+1} =  {'S2', 'Secondary Somatosensory Cortex',    [1 0 1],...
                {'S2'}};
%GROI{end+1} =  {'Som', 'Somatosensory Cortex',    [1 0 1],...
        %        {'S1','S1BF','S1DZ','S1FL','S1HL','S1J','S1JO','S1Tr','S1ULp','S2'}};

%Insular Areas-------------------------------------------------------------
GROI{end+1} =  {'apIns', 'Agranular Posterior Insular Cortex', [.7 1 .5], {'AIP'}};
GROI{end+1} =  {'aIns', 'Agranular Insular Cortex', [.7 1 .5], {'AI','AID','AIV'}};
GROI{end+1} =  {'dgIns', 'Dysgranular Granular Insular Cortex Dorsal', [.7 1 .5], {'DI','GI'}};
%GROI{end+1} =  {'Ins', 'Insular Cortex', [.7 1 .5], {'AIV','AIP','AI','AID','DI','GI'}};

%Cingulate Areas-----------------------------------------------------------
GROI{end+1} =  {'Cing','Cingulate', [1 0 0], {'Cg1','Cg2'}};
GROI{end+1} =  {'RetSplen', 'Retrosplenial Cortex', [1 0 0], {'RSA','RSGa','RSGb'}};  %part of the cingulate... Important for antergrade amnesia, connections with HP and Anterior Thalamus

%Prefrontal Areas----------------------------------------------------------
%GROI{end+1} =  {'OrbFro','Orbitofronal Cortex', [.5 .5 0], {'DLO','LO','MO','VO'}};
GROI{end+1} =  {'OFC','Orbitofronal Cortex', [.5 .5 0], {'DLO','LO','MO','VO'}};
GROI{end+1} =  {'FrA','Frontal Association', [1 .4 .4], {'FrA'}};
GROI{end+1} =  {'mPFC','Infralimbic-Prelimbic', [1 .4 .4], {'DP','IL','PrL'}};
%GROI{end+1} =  {'PFC','Prefrontal Cortex', [1 .4 .4], {'FrA','DP','IL','PrL'}};

%Visual Areas--------------------------------------------------------------
%GROI{end+1} =  {'V','Visual Cortex', [0 1 0], {'V1B','V1M','V2L','V2ML','V2MM'}};
%GROI{end+1} =  {'V1-2','Visual Cortex', [0 1 0], {'V1B','V1M','V2L','V2ML','V2MM'}};
GROI{end+1} =  {'V1','Visual Cortex', [0 1 0], {'V1B','V1M','V2L','V2ML','V2MM'}};
GROI{end+1} =  {'V2','Area V2', [0 .7 0], {}};

%Auditory Areas------------------------------------------------------------
%GROI{end+1} =  {'A','Auditory Cortex', [0 0 1], {'Au1','AuD','AuV'}};
%GROI{end+1} =  {'A1-2','Auditory Cortex', [0 0 1], {'Au1','AuD','AuV'}};
GROI{end+1} =  {'A1','Primary Auditory Cortex', [0 0 1], {'Au1'}};
GROI{end+1} =  {'A2','Secondary Auditory Cortices', [0 0 1], {'AuD','AuV'}};
%GROI{end+1} =  {'A1','Auditory Cortex', [0 0 1], {'Au1','AuD','AuV'}};
%GROI{end+1} =  {'A2','Secondary Auditory Cortex', [0 0 .7], {}};

%Temporal Associative------------------------------------------------------
GROI{end+1} =  {'Temp','Temporal Association Cortex', [0 .5 0],{'TeA'}}; %replaced PtA with TeA

%Parietal Associative------------------------------------------------------
GROI{end+1} =  {'Par','Parietal Association Cortex', [.5 0 0], {'PtA'}};
