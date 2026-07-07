function varargout = hcln(varargin)
%HCLN - Invokes Help browser for "cln" functions
%
%
web(sprintf('file://%s',which('hcln.html')),'-browser');
