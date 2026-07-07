[Usage]
  [eeg dap rs3 ceo] = nscan_loaddat7(DAT_FILANAME)
  For example,
  >> [eeg dap rs3 ceo] = nscan_loaddat7('E:\DataEEG\MyCurry7Acquisition 001.dat');

[Notes, 2014.Jan]
  The programs are tested in our settings (Curry7.0.6, SynAmpsRT, MATLAB2011b).
  In other environment, one may need to update/adapt the codes.

[update: eeglab.m]
cb_loaddat7    = [ nocheck '[EEG LASTCOM] = pop_loaddat7;'     e_newset ];
...
uimenu( neuro_m, 'Label', 'From Neuroscan Curry7 .DAT file'       , 'CallBack', cb_loaddat7);



[License]
Copyright (c) 2014, Yusuke Muarayama, Max Planck Institute for Biological Cybernetics
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of the FreeBSD Project.
