
FPS = 10;
fname = sprintf('flicker_%03dHz.avi',FPS);


tmpimg = zeros(180,240,3,'uint8');
tmpv   = 0;
try,
  aviobj = avifile(fullfile('y:/temp',fname),...
                   'fps',FPS,'quality',100,'compression','Indeo5');
  for N = 1:10*FPS,
    tmpv = (1 - tmpv)*255;
    tmpimg(:) = uint8(tmpv);
    aviobj = addframe(aviobj,tmpimg);
  end
catch
  aviobj = close(aviobj);
end
aviobj = close(aviobj);






