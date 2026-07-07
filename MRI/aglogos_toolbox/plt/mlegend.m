function mlegend(varargin)
%MLEGEND - Displays a ledend on an axis
% MLEGEND (varargin) is our version of legend
% permitting direct definition of properties in the command line.
% Examples:
% mlegend('something','linespec','fontweight','bold',...
%  'fontsize',11,'color',[.6 .6 .6]);
% mlegend('nikos','linespec','fontweight','bold',...
%  'fontsize',11,'color',[.6 .6 .6],'textspec','color','r');
%
% NKL 30.05.04

ix = strcmp(varargin,'linespec');
if any(ix),
  args = varargin(1:find(ix)-1);
  specargs = varargin(find(ix)+1:end);

  ix = strcmp(specargs,'textspec');
  if any(ix),
    textargs = specargs(find(ix)+1:end);
    specargs = specargs(1:find(ix)-1);
  end;
else
  args = varargin;
end;

[h, h1] = legend(args{:});

set(h,specargs{:});

if exist('textargs') & ~isempty(textargs),
  set(h1(1),textargs{:});
end;

