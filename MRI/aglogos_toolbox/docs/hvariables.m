function hvariables
%HVARIABLES - Analysis of results from monkey fMRI and/or Imaging Experiments
%	---------------------------
%	SINGLE-EXPERIMENT MAT FILE
%	---------------------------
%		Cln.dat(NT,NoChan,NoObsp)				Denoised comprehensive signal
%		ClnSpc.dat(NT,NF,NoChan,NoObsp)			Spectrograms
%		SigPow/Spkt/Sdf.dat(NT,NoChan,NoObsp)	Spike-density functions
%		Spkt.times(NT,NoChan,NoObsp)			Rasters (no average is possible)
%		tcImg.dat(XDim,YDim,Slices,NT,NoObsp)	Images
%		Xcor{SliceNo}.map(XDim,YDim)            Z-score/R Maps
%		Xcor{SliceNo}.dat(XDim,YDim,NT)         Time Series
%	---------------------------
%	GROUP MAT FILE
%	---------------------------
%		Cln.dat(NT,NoChan,NoObsp*NoExp)
%		ClnSpc.dat(NT,NF,NoChan,NoObsp*NoExp)
%		SigPow/Spkt/Sdf.dat(NT,NoChan,NoObsp*NoExp)		
%		Spkt.times(NT,NoChan,NoObsp*NoExp)	
%		tcImg.dat(XDim,YDim,Slices,NT,NoObsp*NoExp)
%		Xcor{SliceNo}.map(XDim,YDim,NoExp)            Z-score/R Maps
%		Xcor{SliceNo}.dat(XDim,YDim,NT,NoExp)         Time Series
%	---------------------------
%	TRIAL-RESORTED GROUP FILE SIGNALS
%	---------------------------
%		Cln.dat(NT,NoChan,NoObsp*NoExp)
%		ClnSpc.dat(NT,NF,NoChan,NoObsp*NoExp)
%		SigPow/Spkt/Sdf.dat(NT,NoChan,NoObsp*NoExp)		
%		Spkt.times(NT,NoChan,NoObsp*NoExp)	
%		tcImg.dat(XDim,YDim,Slices,NT,NoObsp*NoExp)
%		Xcor{SliceNo}.map(XDim,YDim,NoExp)            Z-score/R Maps
%		Xcor{SliceNo}.dat(XDim,YDim,NT,NoExp)         Time Series
%
%	---------------------------
%	BANDPASS FILTERED SIGNALS (EEG bands -- in getses)
%	---------------------------
%	ses.anap.eeg{1} = [1 4];
%	ses.anap.eeg{2} = [4 8];
%	ses.anap.eeg{3} = [8 12];
%	ses.anap.eeg{4} = [12 24];
%	ses.anap.eeg{5} = [24 90];
%	ses.anap.eeg{6} = [4 99];
%	ses.anap.eeg{7} = [150 400];
%	ses.anap.eeg{8} = [400 2500];
%
%	---------------------------
%	BANDPASS FILTERED SIGNALS (large bands -- in getses)
%	---------------------------
%	ses.anap.bands.Lfp			= [1 90];	
%	ses.anap.bands.Gamma		= [24 90];	
%	ses.anap.bands.LfpL			= [1 12];	
%	ses.anap.bands.LfpM			= [12 24];	
%	ses.anap.bands.LfpH			= [24 90];	
%	ses.anap.bands.Mua			= [500 2500];
%	ses.anap.bands.lfpcutoff	= 10;			
%	ses.anap.bands.muacutoff	= 100;			
%	ses.anap.bands.samprate		= 250;			
%
%	---------------------------
%	SIGNAL GROUPS (in getses)
%	---------------------------
%	ses.RFSigs			= {'LfpH';'Mua';'Sdf'};
%	ses.SigBands		= {'Lfp', 'Gamma', 'Mua', 'Sdf'};
%	ses.GrpSigs			= {'LfpL';'LfpM';'LfpH';'Mua';'Spkt'; 'Sdf'};
%	ses.GrpRFSigs		= {'VLfpH3';'VMua3';'VSdf3'};
%	ses.GrpCFSigs		= {'cfLfp';'cfGamma';'cfMua';'cfSdf'};
%	ses.GrpCHSigs		= {'chLfp';'chGamma';'chMua';'chSdf'};
%	ses.GrpImgSigs		= {'Pts';'xcor'};
%  

helpwin hvariables








