function varargout = setfront(handles)
%SETFRONT - sets graphic object(s) in front of others
%  SETFRONT(HANDLES) sets graphic object(s) in front of others.
%
%  VERSION :
%    0.90 31.10.05 YM  pre-release
%
%  See also SETBACK

if nargin == 0,  help setfront; return;  end

handles = handles(find(ishandle(handles)));
if isempty(handles),  return;  end


% get the current order of handles
hParent = get(handles(1),'Parent');
hChildren = get(hParent,'Children');

% change the order
for N = length(handles):-1:1,
  tmpflags = hChildren == handles(N);
  idx  = find(tmpflags);
  if ~isempty(idx),
    idx2 = find(~tmpflags);
    hChildren = hChildren([idx idx2(:)']);
  end
end

% set the new order of handles
set(hParent,'Children',hChildren);
drawnow;	% update to draw


return;
