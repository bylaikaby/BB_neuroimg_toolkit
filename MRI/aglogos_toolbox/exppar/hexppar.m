function varargout = hexppar(varargin)
%HEXPPAR - Invokes Help browser for "exppar" functions
%
%
web(sprintf('file://%s',which('hexppar.html')),'-browser');
