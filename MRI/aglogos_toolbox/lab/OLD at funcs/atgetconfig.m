function Ses = atgetconfig(Ses,cfgType)
%ATGETCONFIG - Get electrode configuration
% ATGETCONFIG defines the lay out of the channels

Ses.confunc.type = cfgType;

switch cfgType,
 case 'wire',
  Ses.confunc.eleconfig = Ses.confunc.WIRECONFIG;
  Ses.confunc.idist = Ses.confunc.WIREDIST;
  Ses.confunc.maxchan = Ses.confunc.WIRENO;
  Ses.confunc.chan = Ses.confunc.WIRECHAN;
  Ses.confunc.subplot = [1 2];
 case 'tetrode',
  Ses.confunc.eleconfig = Ses.confunc.TETCONFIG;
  Ses.confunc.idist = Ses.confunc.TETDIST;
  Ses.confunc.maxchan = Ses.confunc.TETNO;
  Ses.confunc.chan = Ses.confunc.TETCHAN;
  Ses.confunc.subplot = [3 3];
 case 'cell',
  Ses.confunc.eleconfig = Ses.confunc.CELLCONFIG;
  Ses.confunc.idist = Ses.confunc.CELLDIST;
  Ses.confunc.maxchan = Ses.confunc.CELLNO;
  Ses.confunc.chan = Ses.confunc.CELLCHAN;
  Ses.confunc.subplot = [4 4];
 otherwise,
  error('atgetelepos: cfgType = tetrode | wire | cell');
end;
