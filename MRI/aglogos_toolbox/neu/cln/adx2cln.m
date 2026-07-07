function Cln = adx2cln(SESSION,ExpNo)
%ADX2CLN - Remove electromagnetic interference patterns from physiology signal.
%	ADX2CLN(SESSION,ExpNo) imports the ADX file data into the Cln
%	structure and save the result into our standard Matlab files.
%
%	See also
%	CLNMAIN CLNADF CLNADJEVT CLNHELP GETCLOCKERROR

SAVE		= 1;				% Create/Append MAT file

if nargin & nargin < 2,
	error('ADX2CLN: usage: Cln = adx2cln(SESSION,ExpNo,ARGS);');
end;

Ses = goto(SESSION);
name = catfilename(Ses,ExpNo,'adx');
[NoChan,NoObsp,sampt,obslen] = adx_info(name);

Cln = getcln(Ses,ExpNo);
for ChanNo = NoChan:-1:1,
  for ObspNo = NoObsp:-1:1,
	Cln.dat(:,ChanNo,ObspNo) = adx_read(name,ObspNo-1,ChanNo-1);
  end;
end;

if ~nargout & SAVE,
  cd(Ses.sysp.matdir);
  if (~exist(Cln.dir.clnfile,'file')),
    % mkdir if needed
    [fp,fn,fe] = fileparts(Cln.dir.clnfile);
    if ~isdir(fp),
      [fp,fn,fe] = fileparts(fp);
      mkdir(fp,strcat(fn,fe));
    end
	save(Cln.dir.clnfile,'Cln');
	fprintf('Saved "Cln" into %s!\n', Cln.dir.clnfile);
  else
	save(Cln.dir.clnfile,'Cln','-append');
	fprintf('Appended "Cln" into %s!\n', Cln.dir.clnfile);
  end
end;


