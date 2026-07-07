function label(x,y,str,sz,wt)
%LABEL - Stick a label anywhere on a figure in normalized coordinates.
%	LABEL(xpos, ypos, str, [fontsize])
%	(Places an invisibly small axis first)
%

if nargin < 3
  fprintf('USAGE: Usage: label(xpos, ypos, str, [fontsize])\n');	
  return
end

if ~exist('sz')
   sz = 12;
end
if ~exist('wt')
   wt = 'Normal';
end

wid = min(1.0,length(str)/140.);
axes('Position',[x y 0.01 0.01]);
axis off
text(0,0,fixString(str),'FontSize',sz,'HorizontalAlign','center','VerticalAlign','Middle','FontWeight',wt);


