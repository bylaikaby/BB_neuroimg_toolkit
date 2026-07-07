function varargout = hgetstarted(varargin)
%HGETSTARTED - Invokes Help browser for "get-started" stuff.
%
%
web(sprintf('file://%s',which('hgetstarted.html')),'-browser');
