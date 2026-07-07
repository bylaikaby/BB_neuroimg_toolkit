function varargout = hio(varargin)
%HIO - Invokes Help browser for IO functions
%
%
web(sprintf('file://%s',which('hio.html')),'-browser');
