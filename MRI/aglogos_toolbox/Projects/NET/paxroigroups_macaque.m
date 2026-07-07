function [grproi, roinames, roicolor, roidescription] = paxroigroups_macaque(StructName, GrpType)
%PAXROIGROUPS_MACAQUE - Returns the group to which StructName belongs
% grproi = paxroigroups_macaque(StructName) is used to decrease the number of ROI that are too
% detailed for certain projects. For instance, sbdivisions of superior colliculus, such as
% DpG, DpGWh, DpWh, for instance are unimportant for the first phase of Ripple-Project
% analysis. They can all be substituted by SC...
%
% This function is called by PAXGETROIS('mkgroups', Sesname);
% PAXGETROITS must be called before running MROI(SesName)
% Calling PAXGETROITS will generate the RoiGrp structure with the following roi-names:
%
% ROI.names = {'hele' 'cele' 'A1' 'Assoc' 'BG' 'Fro' 'Hip' 'M' 'MGN' 'Olf' 'Par' 'S' 'SC'...
%              'SN' 'Septum' 'Th' 'Tmp' 'V' 'etc' 'pAcqGr' };
%
%  VERSION :
%    0.90 ALK/YM  modified from paxroigroups.m, cut&paste from the excel file.
%
%  See also paxroigroups

GROI = {};

GROI{end+1} =  {'HP', 'Hippocampus',              [1 0 0],...
                {'DG' 'HipF' 'CA1' 'CA1''' 'CA2' 'CA3' 'CA4' 'IG' ...
                 'S' 'PaS' 'ProS' 'PrS' 'SS' 'Shi'} };

GROI{end+1} =  {'Ent', 'Enthorhinal Cortex',      [0 1 0],...
                {'EC' 'ECL' 'EI' 'EL' 'ELC' 'ELR' 'EOI' 'ER'} };

GROI{end+1} =  {'Vis', 'Visual Cortex',           [0 0 1],...
                {'V1' 'V2' 'V3' 'V3D' 'V3V' 'V3A' ...
                 'V4' 'V4A' 'V4D' 'V4V' 'V4T' 'MT'} };

GROI{end+1} =  {'Aud', 'Auditory Cortex',         [1 1 0],...
                {'AKL' 'AKM'} };

GROI{end+1} =  {'Som', 'Somatosensory Cortex',    [1 0 1],...
                {'S1' '1' '2' '2Ve' '2/1' '3a' '3b' 'S2' 'S2E' 'S2I'} };

GROI{end+1} =  {'Mot', 'Motor Cortex',            [0 1 1],...
                {'4(F1)'} };

GROI{end+1} =  {'Ass', 'Association Cortex',      [.8 .5 1],...
                {'INS' 'AI' 'DI' 'GI' 'Ipro'} };

GROI{end+1} =  {'SC', 'Superior Colliculus',      [.4 .3 .1],...
                {'bsc' 'csc' 'DpG' 'DpWh' 'InG' 'InWh' 'Op' 'SuG' 'Zo'} };

GROI{end+1} =  {'Tha', 'Thalamus',                [1 .8 .5],...
                {'AThal' 'AD' 'AM' 'AV' 'IAM' 'CMn' 'CMnL' 'CMnM' 'ithp' 'LThal' ...
                 'CL' 'LDt' 'LDSF' 'VA' 'VAL' 'VAL(pal)' 'VAL(VO)' 'VAL(VO)+pal' ...
                 'VAM' 'VAMC' 'VL' 'VLL' 'VLM' 'VPThal' 'VPL' 'VPM' 'MedLam' ...
                 'eml' 'iml' 'MG' 'MGD' 'MGM' 'MGV' 'mt' 'MThal' 'CM' 'IMD' 'MD' ...
                 'MDC' 'MDD' 'MDL' 'MDM' 'PC' 'PF' 'PT' 'Pul' 'Apul' 'Ipul' 'Lpul' 'MPul' ...
                 'PV' 'PVA' 'PVP' 'Re' 'Rt' 'SG' 'SPF' 'SPFPC' 'Xi'} };

GROI{end+1} =  {'BG',  'Basal Ganglia',           [.5 .8 1],...
                {'Acb' 'AcbC' 'AcbSh' 'ICj' 'ICjM' 'Cd' 'Cl' 'Pall' 'EGP' 'IGP' 'VP' ...
                 'Pu' 'SN' 'SNV' 'SNVL' 'SNC' 'SNCV' 'SND' 'SNL' 'VTA'} };

GROI{end+1} =  {'Lmb', 'Limbic System',           [.6 .6 0],...
                {'Amyg' 'AA' 'BL' 'BLD' 'BLDL' 'BLI' 'BLV' 'BLVL' 'BLVM' ...
                 'BM' 'BMMC' 'BMPC' 'BMPCD' 'BMPCV' 'BMPCVM' 'Ce' 'CeL' 'CeM' 'I' 'IMG' ...
                 'La' 'Me' 'CeMV' 'PaL' 'PaLGl' 'VACo' 'VCo' 'VColn' 'VColnf' 'VCoSu' ...
                 'Pir' 'DEn' 'VEn' 'CG' 'ACG' 'Cg1' 'Cg2' 'PECg' 'cgs' 'Spt' 'LS' 'LSD' 'LSV' ...
                 'MS' 'TS' 'HDB' 'VDB' 'BST' 'BSTL' 'BSTLD' 'BSTLI' 'BSTLJ' 'BSTM' 'BSTMA' ...
                 'BSTMP' 'BSTMPL' 'BSTMPM' 'BSTMV' 'SFi' 'SHi' 'SHy' 'f' 'OlfSys' ...
                 'AO' 'AOL' 'AOM' 'Olb' 'OlfTract' 'lo' 'Tu' } };


GROI{end+1} =  {'ME',  'Mesencephalic System',    [0 0 0],...
                {'PAG' 'LPAG' 'DLPAG' 'DMPAG' 'Su3' 'Su3C' 'CGPn' 'Pn' 'DPPN' 'VPPn' 'DMPn' ...
                 'PnR' 'PnC' 'PnO' 'gamma' 'PPTg' 'RtTg' 'RtTgP' 'mcp' 'scp' 'ptpn' 'LC' ...
                 'DLL' 'VLL' 'SOI' 'LSO' 'MSO' 'tz' 'DR' 'DRC' 'DRD' 'DRI' 'DRV' 'DRVL' ...
                 'MnR' 'PMnR' 'RIP' 'RMg' 'ROb' 'RPa' 'CLi' 'RLi' 'DpMe' 'APT' 'IMLF' ...
                 'RI' 'ml' 'R' 'RMC' 'RPC' 'RRF' } };


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
  if ~strcmp(GrpType,'grproi'),
    fprintf('Error: PAXROIGROUPS_MACAQUE-arg2 is roi or groi\n');
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
