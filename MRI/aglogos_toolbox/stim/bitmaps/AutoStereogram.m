function [im, repmask] = AutoStereogram(Z)
% Algorithm for generating a random dot autostereogram
%
% Based on code from H.W. Thimbleby et al.
%
% Z       is a relief map with values from 0 to 1.
% im      is the resultant image,
% repmask is the contraint matrix.
%
% Copyright 2000,2001, Trausti Kristjansson, April 12, 2000


DPI = 72;
E = 2.5*DPI;
mju = 1/3;

far = separation(0);
im = Z * 0;
repmask = Z*0;
[ MaxY MaxX ] = size(Z);

for y = 1:MaxY
  pix = zeros(1,MaxX);
  Same = 1:MaxX;
  for x = 1:MaxX
    s = separation(Z(y,x));
    left = x - round(s/2);
    right = left + s;
    if (1 <= left) & (right <= MaxX)
      t = 1;
      visible = 1; zt = 0;
      while (visible & ( zt < 1 ))
        zt = Z(y,x) + 2*(2 - mju*Z(y,x))*t/(mju*E);
        visible = (Z(y,x-t) < zt) & (Z(y,x+t) < zt);
        t = t+1;
      end;
      if (visible)
        l = Same(left);
        while ((l ~= left) & (l~= right))
          if (l < right)
            left = l;
            l = Same(left);
          else
            Same(left) = right;
            left = right;
            l = Same(left);
            right = l;
          end;
        end; % while
        Same(left) = right;
      end; % if visible 
    end; % if (l<= left
  end; % for x 

  %disp(Same);    
  for x = fliplr(1:MaxX)
    if (Same(x) == x) 
      pix(x) = (rand(1) > 0.5);
    else 
      pix(x) = pix(Same(x));
    end;
    im(y,x) = pix(x);
  end;
  disp(['line' num2str(y)]);
  repmask(y,:) = Same;

end; % for y


% draw two dots
im = DrawCircle(round(MaxX/2-far/2),round(MaxY*18/20),7,im);
im = DrawCircle(round(MaxX/2+far/2),round(MaxY*18/20),7,im);


return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function r = separation(z)
DPI = 72;
E = 2.5*DPI;
mju = 1/3;
r = round((1-mju*z)*E/(2-mju*z));

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function im2 = DrawCircle(x,y,r,im2)
try,
for i = (y-r):(y+r)
  delta = round(cos(asin((i-y)/r))*r)
  for j = (x-delta):(x+delta)
    im2(i,j) = 0;
  end;
end;
catch
  lasterror
  keyboard
end

return;
