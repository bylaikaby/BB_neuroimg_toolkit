Readme.txt : 2006.Mar  YM
             2007.Dec  YM  updated for Matlab R2007b(v7.4~)
             2013.May  YM  updated for Matlab R2011b~
             2019.Jul  YM  updated for Matlab R2017a~

See also "docs" directory for detail.


FOR USERS ==============================================================
	1.	This analysis package contains fruits of hard work by 
		many collaborators.  Therefore, please be careful not to 
		distribute/take any codes without permission from NKL 
		even by an accident.
	2.	Read all documentations and play around yourself before ask.


INSTALL ================================================================
	1.	Copy the whole directory to your local disk.
	2.	Make a shortcut of Matlab (we are using R2017a).
	3.	Select "properties" of the shortcut and set "Start in" 
		as the copied directory.
        For newer MATLAB (R2017a?): To run "startup.m" correctly, "Initial working
        folder" in Preference-General should be like "C:\Users\YOUR_ACCOUNT\Documents\MATLAB".
        Checking "Last workding forlder" would cause troubles of path-settings in "startup.m".

	4.	Start the matlab from that shortcut, then have funs.

		You may need to edit "startup.m" and "utils/getdir.m" for 
		directory setting for your environment.  Documentation is not 
		fully available and you need to explore and trace functions 
		for yourself, but "hgetstarted" command may make you happy.

		Do not use "Set Path..." from the MATLAB menu.  "starup.m" in 
		the copied directory (start-in) is automatically loaded by
		MATALB and sets paths.
NOTES ==================================================================
    *   You many need to install Visual C++ runtime library (2008, 2010 and/or 2017)
        for running some mex-programs (mexw64/mexw32).
        Microsoft Visual C++ Redistributable package:
         https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads

		!!! FOR MATLAB (v7.4) ONLY !!!!!!!
		Note that MATLAB-v7.4 requires optional 
		argument '-sd' to set start-up directory.
		Add '-sd your-dir' to "Targe" of shortcut "propertyes" like...
		"C:\Program files\MATLAB\R2007a\bin\matlab" -sd "D:\Mri\MatLab"


TESTING ================================================================
	1.	Make your session file in "/Projects/ana" directory. Six chars of 
		filename (like m02lx1.m) is recommended consisted of first 3 
		chars for monkey ID and last 3 chars for session ID.
	2.	Run sescheck.m to validate the session file.
	3.	sesdumppar loads experiment parameters as matlab file.  
		At this point you need to make dumped parameters to be 
		compatible with this package.  Looking at expgetpar.m may help 
		to do so.
	4.	Normal processing is like sesascan/sescscan/sesimgload/mroi/...
		for MRI data, and 
		sesgetcln/sesclnspc/sesgetblp/sesgetspk
		for neural signals.
	5.	Load any generated signals generated with "sigload.m".
		For an example,
		  % move to data direcotry for "m02lx1"
		  goto('m02lx1');
		  % load "tcImg" signal (cropped 2dseq time course).
		  tcImg = sigload('m02lx1',1,'tcImg);
