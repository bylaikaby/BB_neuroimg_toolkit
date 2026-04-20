function flicker_fixed_control_Dig_ttl(nRepeats, dev, outLines)
% Fixed-schedule TTL flicker on NI digital output lines.
% Default target: port1/line0:7 (8-bit bus high/low together)
%
% Example:
%   flicker_fixed_control
%   flicker_fixed_control(20, "Dev1", "port1/line0:7")
% 17/04 binbin: based on the description on the nidaq, we could access the
% specific port with BNC output, and in fact we could use the dedicated
% line marked on the device, instead of evoking the whole bus.
% in this case, we can directly tune the p2.4 (port 2, line 4) which
% support bnc output.

if nargin < 1 || isempty(nRepeats), nRepeats = 20; end
if nargin < 2 || isempty(dev),      dev = "Dev1"; end
if nargin < 3 || isempty(outLines), outLines = "port2/line4"; end

freqHz = 2.5;
preOff = 8.0;
onWin = 4.0;
postOff = 18.0;

T = 1 / freqHz;
n = floor(onWin / T);
ton = T / 2;
toff = T / 2;

dq = daq("ni");
addoutput(dq, dev, outLines, "Digital");

nLines = numel(dq.Channels);
lo = false(1, nLines);
hi = true(1, nLines);

write(dq, lo);
cleanupObj = onCleanup(@() writeSafe(dq, lo)); %#ok<NASGU>

fprintf("TTL out: %s/%s (%d lines)\n", dev, outLines, nLines);
fprintf("Pattern: (%.0fs OFF -> %.1fs @ %.1fHz -> %.0fs OFF) x %d\n", ...
    preOff, onWin, freqHz, postOff, nRepeats);

for r = 1:nRepeats
    fprintf("Repeat %d/%d\n", r, nRepeats);

    write(dq, lo); pause(preOff);

    for k = 1:n
        write(dq, hi); pause(ton);
        write(dq, lo); pause(toff);
    end

    write(dq, lo); pause(postOff);
end

write(dq, lo);
fprintf("Done.\n");
end

function writeSafe(dq, v)
try
    write(dq, v);
catch
end
end
