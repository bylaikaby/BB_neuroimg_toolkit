function flicker_fixed_control(nRepeats, dev, port)
% Fixed-schedule flicker — same DAQ + flicker loop as working test.m.
%
% test.m (your version):
%   port = 'ao1';
%   dq = daq("ni"); addoutput(dq, dev, port, "Voltage");
%   flicker: T=1/hz; n=floor(dur/T); ton=toff=T/2;
%            write(dq,3); pause(ton); write(dq,0); pause(toff);
%
% Protocol per repeat: (preOff @ 0 V -> onWin flicker -> postOff @ 0 V)
% Default: 8 s, 4 s @ 2.5 Hz, 18 s, x nRepeats.
%
% Example:
%   flicker_fixed_control(20, "Dev1", "ao1")

if nargin < 1 || isempty(nRepeats), nRepeats = 20; end
if nargin < 2 || isempty(dev),      dev = "Dev1"; end
if nargin < 3 || isempty(port),     port = "ao1"; end

% --- same high level as test.m flicker branch ---
V_hi = 3;   % volts during ON (same literal as test.m write(dq,3))
V_lo = 0;

freqHz = 2.5;
preOff = 8.0;
onWin  = 4.0;
postOff = 18.0;

T = 1 / freqHz;
n = floor(onWin / T);
ton = T / 2;
toff = T / 2;

% --- DAQ: same as test.m (lines 10–14) ---
dq = daq("ni");
addoutput(dq, dev, port, "Voltage");

write(dq, V_lo);
cleanupObj = onCleanup(@() write(dq, V_lo)); %#ok<NASGU>

fprintf("Connected to %s %s (Voltage, same as test.m)\n", dev, port);
fprintf("Pattern: (%.0f s @0V -> %.1f s @ %.1f Hz [%d cycles] -> %.0f s @0V) x %d\n", ...
    preOff, onWin, freqHz, n, postOff, nRepeats);

for r = 1:nRepeats
    fprintf("Repeat %d/%d\n", r, nRepeats);

    write(dq, V_lo);
    pause(preOff);

    % ON window: same body as test.m "flicker" (lines 59–62)
    for k = 1:n
        write(dq, V_hi); pause(ton);
        write(dq, V_lo); pause(toff);
    end
    write(dq, V_lo);

    write(dq, V_lo);
    pause(postOff);
end

write(dq, V_lo);
fprintf("Done.\n");
end
