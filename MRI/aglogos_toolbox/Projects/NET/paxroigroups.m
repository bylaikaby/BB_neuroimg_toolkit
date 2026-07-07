function [grproi, roinames, roicolor, roidescription] = paxroigroups(StructName, GrpType, Animal)
%PAXROIGROUPS - Returns the group to which StructName belongs
% grproi = paxroigroups(StructName) is used to decrease the number of ROI that are too
% detailed for certain projects. For instance, sbdivisions of superior colliculus, such as
% DpG, DpGWh, DpWh, for instance are unimportant for the first phase of Ripple-Project
% analysis. They can all be substituted by SC...
%
% This function is called by PAXGETROIS('mkgroups', Sesname);
% PAXGETROITS must be called before running MROI(SesName)
% Calling PAXGETROITS will generate the RoiGrp structure with the following roi-names:
%
%
%
%
% NKL 17 May 2011
%
%  See also macaque_henry rat_henry


if strcmp(StructName,'ROI'),
  Animal = GrpType;
elseif nargin < 3,
  Animal = 'rat';
end;

VERBOSE = 0;
if VERBOSE, fprintf('Processing %s data\n',Animal); end;
if strcmp(lower(Animal),'monkey'),
  if strcmp(StructName,'ROI') & nargout == 1,
    grproi=paxroigroups_macaque(StructName);
  else
    [grproi,roinames,roicolor,roidescription]=paxroigroups_macaque(StructName,GrpType);
  end;
else
  if strcmp(StructName,'ROI') & nargout == 1,
    grproi=paxroigroups_rat(StructName);
  else
    [grproi,roinames,roicolor,roidescription]=paxroigroups_rat(StructName,GrpType);
  end;
end;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [grproi, roinames, roicolor, roidescription] = paxroigroups_rat(StructName, GrpType)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GROI = rat_henry();

if strcmp(StructName,'ROI') & nargout == 1,
  for N=1:length(GROI),
    grproi{N} = GROI{N}{1};
  end;
  return;
end;

% RETURN ROIs..........
if nargin < 2 | strcmp(GrpType,'roi'),
  for N=1:length(GROI),
    if any(find(strcmp(lower(GROI{N}{4}),lower(StructName)))),
      grproi = GROI{N}{1};
      
      if nargout > 1,
        roinames = GROI{N}{4};
      end;
      
      if nargout > 2,
        roicolor = GROI{N}{3};
      end;
      
      if nargout > 3,
        roidescription = GROI{N}{2};
      end;
      return;
    end;
  end;
  
  grproi = 'etc';
  if nargout > 1, roinames = 'unknown'; end;
  if nargout > 2, roicolor = [0 0 0]; end;
  if nargout > 3, roidescription = 'Unsorted ROIs'; end;
else
  
  if ~strcmp(GrpType,'roigrp'),
    fprintf('Error: PAXROIGROUPS-arg2(%s) is roi or roigrp\n',GrpType);
    keyboard;
  end;
  
  for N=1:length(GROI),
    if any(find(strcmp(lower(GROI{N}{1}),lower(StructName)))),
      grproi = GROI{N}{1};
      if nargout > 1,
        roinames = GROI{N}{4};
      end;
      
      if nargout > 2,
        roicolor = GROI{N}{3};
      end;
      
      if nargout > 3,
        roidescription = GROI{N}{2};
      end;
      return;
    end;
  end;
  
  grproi = StructName;
  if nargout > 1, roinames = 'MROI'; end;
  if nargout > 2, roicolor = [0 0 0]; end;
  if nargout > 3, roidescription = 'User Defined ROI'; end;
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [grproi, roinames, roicolor, roidescription] = paxroigroups_macaque(StructName, GrpType)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GROI = macaque_henry();

if strcmp(StructName,'ROI') & nargout == 1,
  for N=1:length(GROI),
    grproi{N} = GROI{N}{1};
  end;
  return;
end;

% RETURN ROIs..........
if nargin < 2 | strcmp(GrpType,'roi'),
  for N=1:length(GROI),
    if any(find(strcmp(lower(GROI{N}{4}),lower(StructName)))),
      grproi = GROI{N}{1};
      
      if nargout > 1,
        roinames = GROI{N}{4};
      end;
      
      if nargout > 2,
        roicolor = GROI{N}{3};
      end;
      
      if nargout > 3,
        roidescription = GROI{N}{2};
      end;
      return;
    end;
  end;
  
  grproi = 'etc';
  if nargout > 1, roinames = 'unknown'; end;
  if nargout > 2, roicolor = [0 0 0]; end;
  if nargout > 3, roidescription = 'Unsorted ROIs'; end;
else
  
  for N=1:length(GROI),
    if any(find(strcmp(lower(GROI{N}{4}),lower(StructName)))),
      grproi = GROI{N}{1};
      
      if nargout > 1,
        roinames = GROI{N}{4};
      end;
      
      if nargout > 2,
        roicolor = GROI{N}{3};
      end;
      
      if nargout > 3,
        roidescription = GROI{N}{2};
      end;
      return;
    end;
  end;
  
  grproi = 'etc';
  if nargout > 1, roinames = 'unknown'; end;
  if nargout > 2, roicolor = [0 0 0]; end;
  if nargout > 3, roidescription = 'Unsorted ROIs'; end;
end
return;


% Rat Brain Composite Structures

% Wed Nov  8 15:25:18 2006

% Accumbens
%  +"accumbens nucleus, core " (AcbC)
%  +"accumbens nucleus, shell " (AcbSh)
%  +lateral accumbens shell (LAcbSh)
%  +"anterior commissure, anterior part, intraAcb" (aca_intraAcb)

% AcbC
%  +"accumbens nucleus, core " (AcbC)
%  +"anterior commissure, anterior part, intraAcb" (aca_intraAcb)

% AcbSh
%  +"accumbens nucleus, shell " (AcbSh)
%  +lateral accumbens shell (LAcbSh)

% Amygdala
%  +amygdala intermediate tissue (amyg)
%  +anterior amygdaloid area  (AA)
%  +"anterior amygdaloid area, dorsal part " (AAD)
%  +"anterior amygdaloid area, ventral part " (AAV)
%  +anterior cortical amygdaloid nucleus (Aco)
%  +"amygdalohippocampal area, anterolateral part " (AHiAL)
%  +"amygdalohippocampal area, posteromedial part" (AHiPM)
%  +amygdalopiriform transition area (APir)
%  +amygdalostriatal transition area  (AStr)
%  +"basolateral amygdaloid nucleus, anterior part " (BLA)
%  +"basolateral amygdaloid nucleus, posterior part " (BLP)
%  +"basolateral amygdaloid nucleus, ventral part " (BLV)
%  +"basomedial amygdaloid nucleus, anterior part " (BMA)
%  +"basomedial amygdaloid nucleus, posterior part " (BMP)
%  +"bed nucleus of the stria terminalis, intraamygdaloid division " (BSTIA)
%  +"central amygdaloid nucleus, capsular part" (CeC)
%  +"central amygdaloid nucleus, lateral division" (CeL)
%  +"central amygdaloid nucleus, medial division" (CeM)
%  +cortex- amygdala transition zone  (CxA)
%  +intercalated nuclei of the amygdala  (I)
%  +"intercalated amygdaloid nucleus, main part" (IM)
%  +amygdaloid intramedullary gray  (IMG)
%  +"lateral amygdaloid nucleus, dorsolateral part " (LaDL)
%  +"lateral amygdaloid nucleus, ventrolateral part " (LaVL)
%  +"lateral amygdaloid nucleus, ventromedial part " (LaVM)
%  +"medial amygdaloid nucleus, anterior dorsal " (MeAD)
%  +"medial amygdaloid nucleus, anteroventral part " (MeAV)
%  +"medial amygdaloid nucleus, posterodorsal part " (MePD)
%  +"medial amygdaloid nucleus, posteroventral part " (MePV)
%  +posterolateral cortical amygdaloid nucleus (C2) (PLCo)
%  +posteromedial cortical amygdaloid nucleus (C3) (PMCo)

% AmygBLA
%  +"basolateral amygdaloid nucleus, anterior part " (BLA)
%  +"basolateral amygdaloid nucleus, posterior part " (BLP)
%  +"basolateral amygdaloid nucleus, ventral part " (BLV)

% AmygBMA
%  +"basomedial amygdaloid nucleus, anterior part " (BMA)
%  +"basomedial amygdaloid nucleus, posterior part " (BMP)

% AmygCeA
%  +"central amygdaloid nucleus, capsular part" (CeC)
%  +"central amygdaloid nucleus, lateral division" (CeL)
%  +"central amygdaloid nucleus, medial division" (CeM)

% AmygMeA
%  +"medial amygdaloid nucleus, anterior dorsal " (MeAD)
%  +"medial amygdaloid nucleus, anteroventral part " (MeAV)
%  +"medial amygdaloid nucleus, posterodorsal part " (MePD)
%  +"medial amygdaloid nucleus, posteroventral part " (MePV)

% BNST
%  +"bed nucleus of the stria terminalis, lateral division" (BSTL)
%  +"bed nucleus of the stria terminalis, lateral division, dorsal part" (BSTLD)
%  +"bed nucleus of the stria terminalis, lateral division, intermediate part" (BSTLI)
%  +"bed nucleus of the stria terminalis, lateral division, juxtacapsular part" (BSTLJ)
%  +"bed nucleus of the stria terminalis, lateral division, posterior part" (BSTLP)
%  +"bed nucleus of the stria terminalis, lateral division, ventral part" (BSTLV)
%  +"bed nucleus of the stria terminalis, medial division, anterior part" (BSTMA)
%  +"bed nucleus of the stria terminalis, medial division, posterointermediate part" (BSTMPI)
%  +"bed nucleus of the stria terminalis, medial division, posterolateral part" (BSTMPL)
%  +"bed nucleus of the stria terminalis, medial division, posteromedial part" (BSTMPM)
%  +"bed nucleus of the stria terminalis, medial division, ventral part" (BSTMV)
%  +"bed nucleus of stria terminalis, supracapsular part" (BSTS)

% BNSTlateral
%  +"bed nucleus of the stria terminalis, lateral division" (BSTL)
%  +"bed nucleus of the stria terminalis, lateral division, dorsal part" (BSTLD)
%  +"bed nucleus of the stria terminalis, lateral division, intermediate part" (BSTLI)
%  +"bed nucleus of the stria terminalis, lateral division, juxtacapsular part" (BSTLJ)
%  +"bed nucleus of the stria terminalis, lateral division, posterior part" (BSTLP)
%  +"bed nucleus of the stria terminalis, lateral division, ventral part" (BSTLV)

% BNSTmedial
%  +"bed nucleus of the stria terminalis, medial division, anterior part" (BSTMA)
%  +"bed nucleus of the stria terminalis, medial division, posterointermediate part" (BSTMPI)
%  +"bed nucleus of the stria terminalis, medial division, posterolateral part" (BSTMPL)
%  +"bed nucleus of the stria terminalis, medial division, posteromedial part" (BSTMPM)
%  +"bed nucleus of the stria terminalis, medial division, ventral part" (BSTMV)

% CaudatePutamen
%  +caudate putamen (striatum)  (CPu)

% CorpusCollosum
%  +corpus collosum (cc)
%  +forceps minor of the corpus callosum (fmi)
%  +forceps major of the corpus callosum (fmj)

% CortexEntorhinal
%  +dorsal endopiriform nucleus (DEn)
%  +ectorhinal cortex (Ect)
%  +lateral entorhinal cortex  (LEnt)
%  +perirhinal cortex (PRh)
%  +ventral endopiriform nucleus (VEn)
%  +medial entorhinal cortex  (MEnt)

% CortexPiriform
%  +Piriform layer (region external to) (Pir/ext)
%  +Piriform layer (Pir)
%  +Piriform layer (region internal to) (Pir/int)
%  +Piriform cortex (PirCtx)

% CortexEntorhinalPiriform
%  +dorsal endopiriform nucleus (DEn)
%  +ectorhinal cortex (Ect)
%  +lateral entorhinal cortex  (LEnt)
%  +perirhinal cortex (PRh)
%  +Piriform layer (region external to) (Pir/ext)
%  +Piriform layer (Pir)
%  +Piriform layer (region internal to) (Pir/int)
%  +Piriform cortex (PirCtx)
%  +ventral endopiriform nucleus (VEn)
%  +medial entorhinal cortex  (MEnt)

% CortexMotor
%  +primary motor cortex  (M1)
%  +secondary motor cortex (M2)

% CortexS1
%  +primary somatosensory cortex (S1)
%  +"primary somatosensory cortex, barrel field" (S1BF)
%  +"primary somatosensory cortex, dysgranular region" (S1DZ)
%  +"primary somatosensory cortex, forelimb region " (S1FL)
%  +"primary somatosensory cortex, hindlimb region " (S1HL)
%  +"primary somatosensory cortex, jaw region" (S1J)
%  +"primary somatosensory cortex, jaw region, oral surface" (S1JO)
%  +"primary somatosensory cortex, trunk region" (S1Tr)
%  +"primary somatosensory cortex, upper lip region" (S1ULp)

% CortexSomatosensory
%  +primary somatosensory cortex (S1)
%  +"primary somatosensory cortex, barrel field" (S1BF)
%  +"primary somatosensory cortex, dysgranular region" (S1DZ)
%  +"primary somatosensory cortex, forelimb region " (S1FL)
%  +"primary somatosensory cortex, hindlimb region " (S1HL)
%  +"primary somatosensory cortex, jaw region" (S1J)
%  +"primary somatosensory cortex, jaw region, oral surface" (S1JO)
%  +"primary somatosensory cortex, trunk region" (S1Tr)
%  +"primary somatosensory cortex, upper lip region" (S1ULp)
%  +secondary somatosensory cortex (S2)

% CortexInsular
%  +agranular insular cortex (AI)
%  +"agranular insular cortex, dorsal part" (AID)
%  +"agranular insular cortex, posterior part" (AIP)
%  +"agranular insular cortex, ventral part" (AIV)
%  +dysgranular insular cortex (DI)
%  +granular insular cortex (GI)

% CortexAgranularInsular
%  +agranular insular cortex (AI)
%  +"agranular insular cortex, dorsal part" (AID)
%  +"agranular insular cortex, posterior part" (AIP)
%  +"agranular insular cortex, ventral part" (AIV)

% CortexCingulate
%  +"cingulate cortex, area 1 " (Cg1)
%  +"cingulate cortex, area 2 " (Cg2)

% CortexRetrosplenial
%  +retrosplenial agranular cortex (RSA)
%  +retrosplenial granular a cortex (RSGa)
%  +retrosplenial granular b cortex (RSGb)

% CortexVisual
%  +"primary visual cortex, binocular area" (V1B)
%  +"primary visual cortex, monocular area" (V1M)
%  +"secondary visual cortex, lateral area" (V2L)
%  +"secondary visual cortex, mediolateral area" (V2ML)
%  +"secondary visual cortex, mediomedial area" (V2MM)

% CortexAuditory
%  +primary auditory cortex (Au1)
%  +"secondary auditory cortex, dorsal area" (AuD)
%  +"secondary auditory cortex, ventral area" (AuV)

% CortexSensory
%  +primary auditory cortex (Au1)
%  +"secondary auditory cortex, dorsal area" (AuD)
%  +"secondary auditory cortex, ventral area" (AuV)
%  +primary somatosensory cortex (S1)
%  +"primary somatosensory cortex, barrel field" (S1BF)
%  +"primary somatosensory cortex, dysgranular region" (S1DZ)
%  +"primary somatosensory cortex, forelimb region " (S1FL)
%  +"primary somatosensory cortex, hindlimb region " (S1HL)
%  +"primary somatosensory cortex, jaw region" (S1J)
%  +"primary somatosensory cortex, jaw region, oral surface" (S1JO)
%  +"primary somatosensory cortex, trunk region" (S1Tr)
%  +"primary somatosensory cortex, upper lip region" (S1ULp)
%  +secondary somatosensory cortex (S2)
%  +"primary visual cortex, binocular area" (V1B)
%  +"primary visual cortex, monocular area" (V1M)
%  +"secondary visual cortex, lateral area" (V2L)
%  +"secondary visual cortex, mediolateral area" (V2ML)
%  +"secondary visual cortex, mediomedial area" (V2MM)

% CortexFrontalAssociation
%  +frontal association cortex (FrA)

% CortexParietalAssociation
%  +parietal association cortex (PtA)

% CortexTemporalAssociation
%  +temporal association cortex (TeA)

% CortexOrbitofrontal
%  +dorsolateral orbital cortex (DLO)
%  +lateral orbital cortex  (LO)
%  +medial orbital cortex  (MO)
%  +ventral orbital cortex  (VO)

% CortexMedialPrefrontal
%  +dorsal peduncular cortex  (DP)
%  +infralimbic cortex  (IL)
%  +prelimbic cortex  (PrL)

% DiagonalBand
%  +nucleus of the horizontal limb of the diagonal band (HDB)
%  +nucleus of the vertical limb of the diagonal band (VDB)

% GlobusPallidus
%  +lateral globus pallidus (LGP)

% Hippocampus
%  +"field CA3 of hippocampus, dorsal part" (CA3d)
%  +"dentate gyrus, dorsal part" (DGd)
%  +hippocampus fronto-dorsal (hc_fd)
%  +"hippocampus posterior, dorsal part" (hc_d)
%  +"subiculum, dorsal part" (DS)
%  +"hippocampus posterior, ventral part" (hc_v)
%  +"field CA3 of hippocampus, ventral part" (CA3v)
%  +"subiculum, ventral part" (VS)
%  +"dentate gyrus, ventral part" (DGv)
%  +polymorph layer of the dentate gyrus (PoDG)
%  +"subiculum, transition area" (STr)
%  +parasubiculum (PaS)
%  +postsubiculum (Post)
%  +presubiculum (PrS)

% HippocampusAnteroDorsal
%  +"field CA3 of hippocampus, dorsal part" (CA3d)
%  +"dentate gyrus, dorsal part" (DGd)
%  +hippocampus fronto-dorsal (hc_fd)

% HippocampusPosteroDorsal
%  +"hippocampus posterior, dorsal part" (hc_d)

% HippocampusPDwithDS
%  +"hippocampus posterior, dorsal part" (hc_d)
%  +"subiculum, dorsal part" (DS)

% HippocampusVentral
%  +"field CA3 of hippocampus, ventral part" (CA3v)
%  +"hippocampus posterior, ventral part" (hc_v)

% HippocampusVwithVS
%  +"field CA3 of hippocampus, ventral part" (CA3v)
%  +"hippocampus posterior, ventral part" (hc_v)
%  +"subiculum, ventral part" (VS)

% HippocampusDGposterior
%  +"dentate gyrus, ventral part" (DGv)
%  +polymorph layer of the dentate gyrus (PoDG)

% HippocampusPosterior
%  +"dentate gyrus, ventral part" (DGv)
%  +polymorph layer of the dentate gyrus (PoDG)
%  +"subiculum, transition area" (STr)
%  +parasubiculum (PaS)
%  +postsubiculum (Post)
%  +presubiculum (PrS)

% HippocampusSubiculum
%  +parasubiculum (PaS)
%  +postsubiculum (Post)
%  +presubiculum (PrS)
%  +"subiculum, dorsal part" (DS)
%  +"subiculum, ventral part" (VS)
%  +"subiculum, transition area" (STr)

% Hypothalamus
%  +"hypothalamus, ventral intermediate tissue" (HTv)
%  +"hypothalamus, dorsal intermediate tissue" (HTd)
%  +"anterior hypothalamic area, anterior part " (AHA)
%  +"anterior hypothalamic area, central part " (AHC)
%  +"anterior hypothalamic area, posterior part " (AHP)
%  +"arcuate hypothalamic nucleus, dorsal part " (ArcD)
%  +"arcuate hypothalamic nucleus, lateral part " (ArcL)
%  +"arcuate hypothalamic nucleus, lateroposterior part" (ArcLP)
%  +"arcuate hypothalamic nucleus, medial part " (ArcM)
%  +"arcuate hypothalamic nucleus, medial posterior part " (ArcMP)
%  +circular nucleus  (Cir)
%  +dorsal hypothalamic area (DA)
%  +"dorsomedial hypothalamic nucleus, compact part " (DMC)
%  +"dorsomedial hypothalamic nucleus, dorsal part " (DMD)
%  +"dorsomedial hypothalamic nucleus, ventral part" (DMV)
%  +dorsal tuberomammillary nucleus 4 (DTM)
%  +gemini hypothalamic nucleus  (Gem)
%  +lateroanterior hypothalamic nucleus  (LA)
%  +lateral hypothalamic area  (LH)
%  +lateral mammillary nucleus  (LM)
%  +lateral preoptic area (LPO)
%  +magnocellular nucleus of the lateral hypothalamus  (MCLH)
%  +"medial eminence, external layer " (MEE)
%  +"medial eminence, internal layer " (MEI)
%  +"medial mammillary nucleus, lateral part" (ML)
%  +"medial mammillary nucleus, medial part" (MM)
%  +"medial mammillary nucleus, median part" (MMn)
%  +mammillary peduncle  (mp)
%  +medial preoptic area  (MPA)
%  +medial preoptic nucleus  (MPO)
%  +"medial preoptic nucleus, lateral part" (MPOL)
%  +"medial preoptic nucleus, medial part" (MPOM)
%  +mammillary recess of the 3rd ventricle (MRe)
%  +medial tuberal nucleus  (MTu)
%  +"paraventricular hypothalamic nucleus, anterior magnocellular" (PaAM)
%  +"paraventricular hypothalamic nucleus, anterior parvicellular part " (PaAP)
%  +"paraventricular hypothalamic nucleus, dorsal cap " (PaDC)
%  +"paraventricular hypothalamic nucleus, lateral magnocellular part " (PaLM)
%  +"paraventricular hypothalamic nucleus, medial parvicellular part " (PaMP)
%  +"paraventricular hypothalamic nucleus, posterior part " (PaPo)
%  +"paraventricular hypothalamic nucleus, ventral part " (PaV)
%  +periventricular hypothalamic nucleus  (Pe)
%  +perifornical nucleus  (PeF)
%  +posterior hypothalamic area  (PH)
%  +principal mammillary tract  (pm)
%  +"premammillary nucleus, dorsal part " (PMD)
%  +"premammillary nucleus, ventral part " (PMV)
%  +retrochiasmatic area  (RCh)
%  +submammillothalamic nucleus  (SMT)
%  +supramammillary nucleus (SuM)
%  +"supramammillary nucleus, lateral part" (SuML)
%  +"supramammillary nucleus, medial part" (SuMM)
%  +tuber cinereum area  (TC)
%  +terete hypothalamic nucleus  (Te)
%  +ventrolateral hypothalamic nucleus (VLH)
%  +"ventromedial hypothalamic nucleus, anterior part " (VMHA)
%  +"ventromedial hypothalamic nucleus, central part " (VMHC)
%  +"ventromedial hypothalamic nucleus,dorsomedial part " (VMHDM)
%  +"ventromedial hypothalamic nucleus, ventrolateral part " (VMHVL)
%  +ventral tuberomammillary nucleus  (VTM)

% HypothalamusLateral
%  +gemini hypothalamic nucleus  (Gem)
%  +lateral hypothalamic area  (LH)
%  +lateral preoptic area (LPO)
%  +magnocellular nucleus of the lateral hypothalamus  (MCLH)
%  +ventrolateral hypothalamic nucleus (VLH)

% HypothalamusMedial
%  +"hypothalamus, ventral intermediate tissue" (HTv)
%  +"hypothalamus, dorsal intermediate tissue" (HTd)
%  +"anterior hypothalamic area, anterior part " (AHA)
%  +"anterior hypothalamic area, central part " (AHC)
%  +"anterior hypothalamic area, posterior part " (AHP)
%  +"arcuate hypothalamic nucleus, dorsal part " (ArcD)
%  +"arcuate hypothalamic nucleus, lateral part " (ArcL)
%  +"arcuate hypothalamic nucleus, lateroposterior part" (ArcLP)
%  +"arcuate hypothalamic nucleus, medial part " (ArcM)
%  +"arcuate hypothalamic nucleus, medial posterior part " (ArcMP)
%  +circular nucleus  (Cir)
%  +dorsal hypothalamic area (DA)
%  +"dorsomedial hypothalamic nucleus, compact part " (DMC)
%  +"dorsomedial hypothalamic nucleus, dorsal part " (DMD)
%  +"dorsomedial hypothalamic nucleus, ventral part" (DMV)
%  +dorsal tuberomammillary nucleus 4 (DTM)
%  +lateroanterior hypothalamic nucleus  (LA)
%  +lateral mammillary nucleus  (LM)
%  +"medial eminence, external layer " (MEE)
%  +"medial eminence, internal layer " (MEI)
%  +"medial mammillary nucleus, lateral part" (ML)
%  +"medial mammillary nucleus, medial part" (MM)
%  +"medial mammillary nucleus, median part" (MMn)
%  +mammillary peduncle  (mp)
%  +medial preoptic area  (MPA)
%  +medial preoptic nucleus  (MPO)
%  +"medial preoptic nucleus, lateral part" (MPOL)
%  +"medial preoptic nucleus, medial part" (MPOM)
%  +mammillary recess of the 3rd ventricle (MRe)
%  +medial tuberal nucleus  (MTu)
%  +"paraventricular hypothalamic nucleus, anterior magnocellular" (PaAM)
%  +"paraventricular hypothalamic nucleus, anterior parvicellular part " (PaAP)
%  +"paraventricular hypothalamic nucleus, dorsal cap " (PaDC)
%  +"paraventricular hypothalamic nucleus, lateral magnocellular part " (PaLM)
%  +"paraventricular hypothalamic nucleus, medial parvicellular part " (PaMP)
%  +"paraventricular hypothalamic nucleus, posterior part " (PaPo)
%  +"paraventricular hypothalamic nucleus, ventral part " (PaV)
%  +periventricular hypothalamic nucleus  (Pe)
%  +perifornical nucleus  (PeF)
%  +posterior hypothalamic area  (PH)
%  +principal mammillary tract  (pm)
%  +"premammillary nucleus, dorsal part " (PMD)
%  +"premammillary nucleus, ventral part " (PMV)
%  +retrochiasmatic area  (RCh)
%  +submammillothalamic nucleus  (SMT)
%  +supramammillary nucleus (SuM)
%  +"supramammillary nucleus, lateral part" (SuML)
%  +"supramammillary nucleus, medial part" (SuMM)
%  +tuber cinereum area  (TC)
%  +terete hypothalamic nucleus  (Te)
%  +"ventromedial hypothalamic nucleus, anterior part " (VMHA)
%  +"ventromedial hypothalamic nucleus, central part " (VMHC)
%  +"ventromedial hypothalamic nucleus,dorsomedial part " (VMHDM)
%  +"ventromedial hypothalamic nucleus, ventrolateral part " (VMHVL)
%  +ventral tuberomammillary nucleus  (VTM)

% HypothalamusArc
%  +"arcuate hypothalamic nucleus, dorsal part " (ArcD)
%  +"arcuate hypothalamic nucleus, lateral part " (ArcL)
%  +"arcuate hypothalamic nucleus, lateroposterior part" (ArcLP)
%  +"arcuate hypothalamic nucleus, medial part " (ArcM)
%  +"arcuate hypothalamic nucleus, medial posterior part " (ArcMP)

% HypothalamusPVN
%  +"paraventricular hypothalamic nucleus, anterior magnocellular" (PaAM)
%  +"paraventricular hypothalamic nucleus, anterior parvicellular part " (PaAP)
%  +"paraventricular hypothalamic nucleus, dorsal cap " (PaDC)
%  +"paraventricular hypothalamic nucleus, lateral magnocellular part " (PaLM)
%  +"paraventricular hypothalamic nucleus, medial parvicellular part " (PaMP)
%  +"paraventricular hypothalamic nucleus, posterior part " (PaPo)

% InterpeduncularNucleus
%  +interpeduncular nucleus (IP)
%  +"interpeduncular nucleus, apical subnucleus" (IPA)
%  +"interpeduncular nucleus, dorsolateral and dorsomedial subnuclei" (IPD)
%  +"interpeduncular nucleus, lateral subnucleus" (IPL)
%  +"interpeduncular nucleus, rostral subnucleus" (IPR)
%  +"interpeduncular nucleus, rostrolateral subnucleus" (IPRL)

% IPAC
%  +interstitial nucleus of the posterior limb of the anterior commissure (IPAC)
%  +"interstitial nucleus of the posterior limb of the anterior commissure, lateral part" (IPACL)
%  +"interstitial nucleus of the posterior limb of the anterior commissure, medial part" (IPACM)

% MesencephalicRegion
%  +deep mesencephalic (DpMe)
%  +anterior pretectal nucleus (APT)
%  +interstitial nucleus of the medial longitudinal fasciculus (IMLF)
%  +"interstitial nucleus of medial longitudinal fasciculus, greater part" (IMLFG)
%  +medial lemniscus (ml)
%  +pararubral nucleus (PaR)
%  +retroethmoid nucleus (REth)
%  +"red nucleus, magnocellular part" (RMC)
%  +"red nucleus, parvicellular part" (RPC)

% MedialGeniculate
%  +"medial geniculate nucleus, dorsal part" (MGD)
%  +"medial geniculate nucleus, ventral part" (MGV)

% OlfactoryNuclei
%  +"anterior olfactory nucleus, dorsal part" (AOD)
%  +"anterior olfactory nucleus, external part" (AOE)
%  +"anterior olfactory nucleus, lateral part" (AOL)
%  +"anterior olfactory nucleus, medial part" (AOM)
%  +"anterior olfactory nucleus, posterior part" (AOP)
%  +"anterior commissure, intrabulbar part" (aci)

% OlfactoryTubercle
%  +"olfactory tubercle, granular layer" (Tu1)
%  +"olfactory tubercle, layer 2" (Tu2)
%  +"olfactory tubercle, polymorph layer" (Tu3)
%  +olfactory tubercle (Tu)

% PeriaqueductalGrey
%  +dorsolateral periaqueductal gray (DLPAG)
%  +dorsomedial periaqueductal gray (DMPAG)
%  +lateral periaqueductal gray (LPAG)
%  +periaqueductal grey (PAG)
%  +supraoculomotor periaqueductal gray (Su3)
%  +supraoculomotor cap (Su3C)
%  +ventrolateral periaqueductal gray (VLPAG)

% Pons
%  +longitudinal fasciculus of the pons (lfp)
%  +pontine nuclei (Pn)
%  +"pontine reticular nucleus, oral part" (PnO)
%  +reticulotegmental nucleus of the pons (RtTg)
%  +"reticulotegmental nucleus of the pons, pericentral part" (RtTgP)
%  +transverse fibers of the pons (tfp)

% Raphe
%  +caudal linear nucleus of the raphe  (CLi)
%  +dorsal raphe nucleus  (DR)
%  +"dorsal raphe nucleus, caudal part " (DRC)
%  +"dorsal raphe nucleus, dorsal part " (DRD)
%  +"dorsal raphe nucleus, ventral part " (DRV)
%  +"dorsal raphe nucleus, ventrolateral part" (DRVL)
%  +paramedian raphe nucleus  (PMnR)
%  +rostral linear nucleus of the raphe  (RLi)
%  +median raphe nucleus  (MnR)

% RapheDorsal
%  +dorsal raphe nucleus  (DR)
%  +"dorsal raphe nucleus, caudal part " (DRC)
%  +"dorsal raphe nucleus, dorsal part " (DRD)
%  +"dorsal raphe nucleus, ventral part " (DRV)
%  +"dorsal raphe nucleus, ventrolateral part" (DRVL)

% RapheMedian
%  +median raphe nucleus  (MnR)
%  +paramedian raphe nucleus  (PMnR)

% RapheLinear
%  +caudal linear nucleus of the raphe  (CLi)
%  +rostral linear nucleus of the raphe  (RLi)

% Septum
%  +dorsal fornix  (df)
%  +fornix  (f)
%  +lambdoid septal zone  (Ld)
%  +"lateral septal nucleus, dorsal part " (LSD)
%  +"lateral septal nucleus, intermediate part" (LSI)
%  +"lateral septal nucleus, ventral part " (LSV)
%  +medial septal nucleus  (MS)
%  +paralambdoid septal nucleus  (PLd)
%  +septofimbrial nucleus  (SFi)
%  +septohippocampal nucleus  (SHi)
%  +semilunar nucleus  (SL)
%  +triangular septal nucleus  (TS)

% SubstantiaInnominata
%  +substantia innominata (SI)
%  +"substantia innominata, basal part" (SIB)
%  +"substantia innominata, dorsal part" (SID)
%  +"substantia innominata, ventral part" (SIV)

% SubstantiaNigra
%  +parabrachial pigmented nucleus  (PBP)
%  +paranigral nucleus  (PN)
%  +substantia nigra (SN)
%  +"substantia nigra, compact part, dorsal tier " (SNCD)
%  +"substantia nigra, lateral part " (SNL)
%  +"substantia nigra, medial part " (SNM)
%  +"substantia nigra, reticular part" (SNR)
%  +"substantia nigra, reticular part, dorsomedial tier" (SNRDM)
%  +"substantia nigra, reticular part, ventrolateral tier" (SNRVL)

% SuperiorColliculus
%  +deep gray layer of the superior colliculus (DpG)
%  +deep gray/white layers of the superior colliculus (DpGWh)
%  +deep white layer of the superior colliculus (DpWh)
%  +intermediate gray layer of the superior colliculus (InG)
%  +intermediate white layer of the superior colliculus (InWh)
%  +optic nerve layer of the superior colliculus (Op)
%  +superficial gray layer of the superior colliculus (SuG)
%  +superior colliculus (SC)

% ThalamusMidline_Dorsal
%  +centrolateral thalamic nucleus  (CL)
%  +central medial thalamic nucleus  (CM)
%  +fasciculus retroflexus  (fr)
%  +interanterodorsal thalamic nucleus (IAD)
%  +intermediodorsal thalamic nucleus  (IMD)
%  +internal medullary lamina  (iml)
%  +intermedioventral thalamic commissure  (imvc)
%  +lateral habenular nucleus  (LHb)
%  +"lateral habenular nucleus, lateral part" (LHbL)
%  +"lateral habenular nucleus, medial part" (LHbM)
%  +mediodorsal thalamic nucleus  (MD)
%  +"mediodorsal thalamic nucleus, central part" (MDC)
%  +"mediodorsal thalamic nucleus, lateral part" (MDL)
%  +"mediodorsal thalamic nucleus, medial part" (MDM)
%  +"mediodorsal thalamic nucleus, paralaminar part " (MDPL)
%  +oval paracentral thalamic nucleus  (OPC)
%  +paracentral thalamic nucleus  (PC)
%  +parafascicular thalamic nucleus  (PF)
%  +posteromedian thalamic nucleus  (PoMn)
%  +paratenial thalamic nucleus  (PT)
%  +periventricular fibre system (pv)
%  +paraventricular thalamic nucleus (PV)
%  +"paraventricular thalamic nucleus, anterior part " (PVA)
%  +"paraventricular thalamic nucleus, posterior part " (PVP)
%  +stria medullaris (SM)
%  +stria medullaris of the thalamus  (sm)
%  +subparafascicular thalamic nucleus (SPF)
%  +"subparafascicular thalamic nucleus, parvicellular part" (SPFPC)

% ThalamusDorsolateral
%  +anterodorsal thalamic nucleus  (AD)
%  +anteromedial thalamic nucleus  (AM)
%  +angular thalamic nucleus  (Ang)
%  +anteroventral thalamic nucleus (AV)
%  +"anteroventral thalamic nucleus, dorsomedial part " (AVDM)
%  +"anteroventral thalamic nucleus, ventrolateral part " (AVVL)
%  +dorsal lateral geniculate nucleus (DLG)
%  +ethmoid thalamic nucleus  (Eth)
%  +intramedullary thalamic area (IMA)
%  +"laterodorsal thalamic nucleus, dorsomedial part " (LDDM)
%  +"laterodorsal thalamic nucleus, ventrolateral part " (LDVL)
%  +lateral posterior thalamic nucleus (LPL)
%  +"lateral posterior thalamic nucleus, laterocaudal part" (LPLC)
%  +"lateral posterior thalamic nucleus, laterorostral part" (LPLR)
%  +"lateral posterior thalamic nucleus, mediocaudal part" (LPMC)
%  +"lateral posterior thalamic nucleus, mediorostral part " (LPMR)
%  +posterior intralaminar thalamic nucleus (PIL)
%  +posterior thalamic nuclear group  (Po)
%  +"posterior thalamic nuclear group, triangular part" (PoT)
%  +reticular thalamic nucleus  (Rt)
%  +scaphoid thalamic nucleus  (Sc)
%  +suprageniculate thalamic nucleus (SG)
%  +ventral anterior thalamic nucleus  (VA)
%  +ventrolateral thalamic nucleus  (VL)
%  +ventral lateral geniculate nucleus (VLG)
%  +"ventral lateral geniculate nucleus, magnocellular part" (VLGMC)
%  +"ventral lateral geniculate nucleus, parvicellular part" (VLGPC)
%  +ventromedial thalamic nucleus  (VM)
%  +ventral posterolateral thalamic nucleus (VPL)
%  +ventral posteromedial thalamic nucleus (VPM)
%  +"ventral posterior thalamic nucleus, parvicellular part" (VPPC)

% ThalamusVentromedial
%  +"anteromedial thalamic nucleus, ventral part " (AMV)
%  +interanteromedial thalamic nucleus  (IAM)
%  +mammillothalamic tract  (mt)
%  +reuniens thalamic nucleus  (Re)
%  +rhomboid thalamic nucleus  (Rh)
%  +submedius thalamic nucleus  (Sub)
%  +"submedius thalamic nucleus, dorsal part" (SubD)
%  +"submedius thalamic nucleus, ventral part" (SubV)
%  +ventral reuniens thalamic nucleus  (VRe)

% ThalamusSPF
%  +subparafascicular thalamic nucleus (SPF)
%  +"subparafascicular thalamic nucleus, parvicellular part" (SPFPC)

% ThalamusLP
%  +lateral posterior thalamic nucleus (LPL)
%  +"lateral posterior thalamic nucleus, laterocaudal part" (LPLC)
%  +"lateral posterior thalamic nucleus, laterorostral part" (LPLR)
%  +"lateral posterior thalamic nucleus, mediocaudal part" (LPMC)
%  +"lateral posterior thalamic nucleus, mediorostral part " (LPMR)

% ThalamusVP
%  +ventral posterolateral thalamic nucleus (VPL)
%  +ventral posteromedial thalamic nucleus (VPM)

% Thalamus
%  +centrolateral thalamic nucleus  (CL)
%  +central medial thalamic nucleus  (CM)
%  +fasciculus retroflexus  (fr)
%  +interanterodorsal thalamic nucleus (IAD)
%  +intermediodorsal thalamic nucleus  (IMD)
%  +internal medullary lamina  (iml)
%  +intermedioventral thalamic commissure  (imvc)
%  +lateral habenular nucleus  (LHb)
%  +"lateral habenular nucleus, lateral part" (LHbL)
%  +"lateral habenular nucleus, medial part" (LHbM)
%  +mediodorsal thalamic nucleus  (MD)
%  +"mediodorsal thalamic nucleus, central part" (MDC)
%  +"mediodorsal thalamic nucleus, lateral part" (MDL)
%  +"mediodorsal thalamic nucleus, medial part" (MDM)
%  +"mediodorsal thalamic nucleus, paralaminar part " (MDPL)
%  +oval paracentral thalamic nucleus  (OPC)
%  +paracentral thalamic nucleus  (PC)
%  +parafascicular thalamic nucleus  (PF)
%  +posteromedian thalamic nucleus  (PoMn)
%  +paratenial thalamic nucleus  (PT)
%  +periventricular fibre system (pv)
%  +paraventricular thalamic nucleus (PV)
%  +"paraventricular thalamic nucleus, anterior part " (PVA)
%  +"paraventricular thalamic nucleus, posterior part " (PVP)
%  +stria medullaris (SM)
%  +stria medullaris of the thalamus  (sm)
%  +subparafascicular thalamic nucleus (SPF)
%  +"subparafascicular thalamic nucleus, parvicellular part" (SPFPC)
%  +anterodorsal thalamic nucleus  (AD)
%  +anteromedial thalamic nucleus  (AM)
%  +angular thalamic nucleus  (Ang)
%  +anteroventral thalamic nucleus (AV)
%  +"anteroventral thalamic nucleus, dorsomedial part " (AVDM)
%  +"anteroventral thalamic nucleus, ventrolateral part " (AVVL)
%  +dorsal lateral geniculate nucleus (DLG)
%  +ethmoid thalamic nucleus  (Eth)
%  +intramedullary thalamic area (IMA)
%  +"laterodorsal thalamic nucleus, dorsomedial part " (LDDM)
%  +"laterodorsal thalamic nucleus, ventrolateral part " (LDVL)
%  +lateral posterior thalamic nucleus (LPL)
%  +"lateral posterior thalamic nucleus, laterocaudal part" (LPLC)
%  +"lateral posterior thalamic nucleus, laterorostral part" (LPLR)
%  +"lateral posterior thalamic nucleus, mediocaudal part" (LPMC)
%  +"lateral posterior thalamic nucleus, mediorostral part " (LPMR)
%  +posterior intralaminar thalamic nucleus (PIL)
%  +posterior thalamic nuclear group  (Po)
%  +"posterior thalamic nuclear group, triangular part" (PoT)
%  +reticular thalamic nucleus  (Rt)
%  +scaphoid thalamic nucleus  (Sc)
%  +suprageniculate thalamic nucleus (SG)
%  +ventral anterior thalamic nucleus  (VA)
%  +ventrolateral thalamic nucleus  (VL)
%  +ventral lateral geniculate nucleus (VLG)
%  +"ventral lateral geniculate nucleus, magnocellular part" (VLGMC)
%  +"ventral lateral geniculate nucleus, parvicellular part" (VLGPC)
%  +ventromedial thalamic nucleus  (VM)
%  +ventral posterolateral thalamic nucleus (VPL)
%  +ventral posteromedial thalamic nucleus (VPM)
%  +"ventral posterior thalamic nucleus, parvicellular part" (VPPC)
%  +"anteromedial thalamic nucleus, ventral part " (AMV)
%  +interanteromedial thalamic nucleus  (IAM)
%  +mammillothalamic tract  (mt)
%  +reuniens thalamic nucleus  (Re)
%  +rhomboid thalamic nucleus  (Rh)
%  +submedius thalamic nucleus  (Sub)
%  +"submedius thalamic nucleus, dorsal part" (SubD)
%  +"submedius thalamic nucleus, ventral part" (SubV)
%  +ventral reuniens thalamic nucleus  (VRe)

% VentralPallidum
%  +ventral pallidum (VP)

% VTA
%  +ventral tegmental area  (VTA)

% ZonaIncerta
%  +zona incerta (ZI)
%  +"zona incerta, dorsal part" (ZID)
%  +"zona incerta, ventral part" (ZIV)


