function varargout = hmn(varargin)
%HMN - Invokes Help browser for manganese functions
%
%
web(sprintf('file://%s',which('hmn.html')),'-browser');
