function oSig = catsig_Spkt(Ses,GrpExp,SigName,varargin)
%CATSIG_SPKT - subfunction for catsig(Spkt).
%  oSig = CATSIG_SPKT(Ses,GrpExp,SigName,...) 
%
%  SigName : 'Spkt' 'tSpkt' 'esSpkt'
%
%  VERSION :
%    0.90 19.01.12 YM  copied from catsig().
%
%  See also catsig



Ses = goto(Ses);
if isnumeric(GrpExp),
  EXPS = GrpExp;
  grp = getgrp(Ses,EXPS(1));
else
  grp = getgrp(Ses,GrpExp);
  EXPS = grp.exps;
end

fprintf('<%s(%s)>: %s %s "%s", ExpNo: ',upper(mfilename),SigName,...
        Ses.name,grp.name,SigName);


for iExp = 1:length(EXPS)
  clear Sig;
  
  ExpNo = EXPS(iExp);

  fprintf('%d.',ExpNo);
  
  [isok filename] = sigexist(Ses,ExpNo,SigName);
  if ~isok,
	fprintf('!! %s WARNING: %s was not found in %s\n',mfilename,SigName,filename);
	oSig = {};
	return;
  end;
  
  Sig = sigload(Ses,ExpNo,SigName);

  if isempty(Sig),
    fprintf('%s: Skipping empty signal %s\n', mfilename,SigName);
    oSig = Sig;
    return;
  end;

  if isstruct(Sig), % make it cell array even if a single condition...
    RECOVER_STRUCT = 1;
    Sig = { Sig };
  else
    RECOVER_STRUCT = 0;
  end;

  
  % ====================================================================
  % DO SOMTHING HERE ===================================================
  if iExp == 1,
    clear LEN
    oSig = Sig;
    if isstruct(oSig{1}),
      for K = 1:length(oSig), oSig{K}.ExpNo = EXPS;  end
      LEN = size(Sig{1}.dat, 1);
    else
      for KK=1:length(oSig),
        for K = 1:length(oSig{KK}), oSig{KK}{K}.ExpNo = EXPS;  end
        LEN{KK} = size(Sig{KK}{1}.dat, 1);
      end;
    end;
  else
    if isstruct(oSig{1}),
      for K = 1:length(oSig),
        if size(Sig{K}.dat,1) > LEN,
          Sig{K}.dat = Sig{K}.dat(1:LEN,:,:);
        elseif size(Sig{K}.dat,1) < LEN,
          DLEN = LEN-size(Sig{K}.dat,1);
          Sig{K}.dat = cat(1,Sig{K}.dat,...
                           repmat(Sig{K}.dat(end,:,:),[DLEN 1 1]));
        end;
        oSig{K}.dat = cat(3,oSig{K}.dat,Sig{K}.dat);
        oSig{K}.times = cat(2,oSig{K}.times,Sig{K}.times);
        
        % must concat the mean rate... for esSpkt!
        %  esSpkt.sesesmean
        %          twin: [-0.1000 1]
        %          navr: 44
        %     spontMean: [0.0891 0.1069 0.1010 0.2317 0.0119 0.1525 0.0891 0.1149 0.0871 0.0317]
        %      spontStd: [0.3642 0.4084 0.3876 0.5800 0.1884 0.5686 0.3115 0.4299 0.4585 0.2157]          
        if isfield(oSig{K},'sesesmean') && isfield(oSig{K}.sesesmean,'spontMean'),
          oSig{K}.sesesmean.spontMean = cat(1, oSig{K}.sesesmean.spontMean, Sig{K}.sesesmean.spontMean);
          oSig{K}.sesesmean.spontStd = cat(1, oSig{K}.sesesmean.spontStd, Sig{K}.sesesmean.spontStd);
        end;
      end;
    else
      for KK=1:length(oSig),
        for K = 1:length(oSig{KK}),
          if size(Sig{KK}{K}.dat,1) > LEN{KK},
            Sig{KK}{K}.dat = Sig{KK}{K}.dat(1:LEN{KK},:,:);
          elseif size(Sig{KK}{K}.dat,1) < LEN{KK},
            DLEN = LEN{KK}-size(Sig{KK}{K}.dat,1);
            Sig{KK}{K}.dat = cat(1,Sig{KK}{K}.dat,...
                                 repmat(Sig{KK}{K}.dat(end,:,:),[DLEN 1 1]));
          end;
          oSig{KK}{K}.dat = cat(3,oSig{KK}{K}.dat,Sig{KK}{K}.dat);
          oSig{KK}{K}.times = cat(2,oSig{KK}{K}.times,Sig{KK}{K}.times);
          if isfield(oSig{KK}{K},'sesesmean') && isfield(oSig{KK}{K}.sesesmean,'spontMean'),
            oSig{KK}{K}.sesesmean.spontMean=cat(1,oSig{KK}{K}.sesesmean.spontMean,Sig{KK}{K}.sesesmean.spontMean);
            oSig{KK}{K}.sesesmean.spontStd=cat(1,oSig{KK}{K}.sesesmean.spontStd,Sig{KK}{K}.sesesmean.spontStd);
          end;
        end;
      end;
    end;
  end;
  % ====================================================================

end



if RECOVER_STRUCT > 0 && iscell(oSig) && length(oSig) == 1,
  oSig = oSig{1};
end


oSig = subUpdateGrpName(oSig,grp.name);


fprintf(' done.\n');
return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update group name to avoid error
function oSig = subUpdateGrpName(oSig,GrpName)
if iscell(oSig),
  for N = 1:numel(oSig),
    oSig{N} = subUpdateGrpName(oSig{N},GrpName);
  end
  return;
end

oSig.grpname = GrpName;

return

