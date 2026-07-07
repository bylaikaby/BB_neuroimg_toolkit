
homedir = 'y:/Mri/Matlab';
%homedir = 'd:/analysis/matlab_mri';

%tmpfiles = dir(sprintf('%s/microstimulation/*.m',homedir));  % no good example for Cln
%tmpfiles = dir(sprintf('%s/flash/*.m',homedir));
%tmpfiles = dir(sprintf('%s/hyperc/*.m',homedir)); % no good example
tmpfiles = dir(sprintf('%s/ana/*.m',homedir)); % no good example



errsucks = {'a05am1','f04wb1','f04yd1','k02y81','k02yl1',...
            'j04an1','b03bb1','b03bd1','f04wm1','f05bf1',...
            'b05qr1','i04ze1',...
            'b00bi1','b00cg1','g02j21','j00f11','j04an1'};

for N = 1:length(tmpfiles),
  tmpf = tmpfiles(N).name;
  if length(tmpf) ~= 8, continue;  end
  if isempty(str2num(tmpf([2 3 6]))), continue;  end
  if any(strcmpi(tmpf(1:6),errsucks)), continue;  end
  try,
    Ses = goto(tmpf(1:6));
    EXPS = validexps(Ses);
    for iExp = 1:length(EXPS),
      ExpNo = EXPS(iExp);
      if isimaging(Ses,ExpNo) & isrecording(Ses,ExpNo) & ~ismicrostimulation(Ses,ExpNo),
        fprintf('%3d/%d  %s %d:',N,length(tmpfiles),Ses.name,ExpNo);
        try,
          axel_plot(Ses,ExpNo,[],1);
        catch
          fprintf(' error\n');
        end
        break;
      end
    end
  catch,
    continue;
  end
end