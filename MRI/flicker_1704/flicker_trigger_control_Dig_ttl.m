function flicker_trigger_control_Dig_ttl(nRepeats, dev, trigLine, outLines, n_dummy)
% Wait for MRI digital trigger, then run TTL flicker on digital output bus.
% Defaults:
%   trigger  = port2/line0   (commonly PFI8/P2.0 on many NI rigs)
%   output   = port1/line0:7 (8-bit bus)
%   n_dummy  = 0 (ignore first n_dummy trigger pulses)
%
% Example:
%   flicker_trigger_control_ttl
%   flicker_trigger_control_ttl(20, "Dev1", "port2/line0", "port1/line0:7", 5)

if nargin < 1 || isempty(nRepeats), nRepeats = 10; end
if nargin < 2 || isempty(dev),      dev = "Dev1"; end
if nargin < 3 || isempty(trigLine), trigLine = "port2/line0"; end
if nargin < 4 || isempty(outLines), outLines = "port2/line4"; end
if nargin < 5 || isempty(n_dummy),  n_dummy = 8; end

freqHz = 2.5;
preOff = 8.0;
onWin = 4.0;
postOff = 18.0;

T = 1 / freqHz;
n = floor(onWin / T);
ton = T / 2;
toff = T / 2;

timeoutSec = 300;
pollDt = 0.001;
trigThr = 0.5;

dqIn = daq("ni");
addinput(dqIn, dev, trigLine, "Digital");

dqOut = daq("ni");
addoutput(dqOut, dev, outLines, "Digital");

nLines = numel(dqOut.Channels);
lo = false(1, nLines);
hi = true(1, nLines);

write(dqOut, lo);
cleanupObj = onCleanup(@() writeSafe(dqOut, lo)); %#ok<NASGU>

fprintf("Trigger in: %s/%s\n", dev, trigLine);
fprintf("TTL out   : %s/%s (%d lines)\n", dev, outLines, nLines);
fprintf("Waiting for trigger... (n_dummy=%d)\n", n_dummy);

t0 = tic;
prevHigh = readDigitalHigh(dqIn);
triggered = false;
pulseCount = 0;

while toc(t0) < timeoutSec
    drawnow('limitrate');
    curHigh = readDigitalHigh(dqIn);

    if ~prevHigh && curHigh
        pulseCount = pulseCount + 1;
        if pulseCount > n_dummy
            triggered = true;
            break;
        else
            fprintf("Ignoring dummy trigger %d/%d\n", pulseCount, n_dummy);
        end
    end

    prevHigh = curHigh;
    pause(pollDt);
end

if ~triggered
    clear('cleanupObj');
    error("No valid trigger after %d dummy pulse(s) on %s within %.0f s.", n_dummy, trigLine, timeoutSec);
end

fprintf("Trigger OK. Running protocol...\n");

for r = 1:nRepeats
    fprintf("Repeat %d/%d\n", r, nRepeats);

    write(dqOut, lo); pause(preOff);

    for k = 1:n
        write(dqOut, hi); pause(ton);
        write(dqOut, lo); pause(toff);
    end

    write(dqOut, lo); pause(postOff);
end

write(dqOut, lo);
clear('cleanupObj');
fprintf("Done.\n");
end

function high = readDigitalHigh(dq)
    x = readScalarDigital(dq);
    % Same logic as mri_input_monitor.m: treat any value > 0.5 as HIGH.
    high = x > 0.5;
end

function x = readScalarDigital(dq)
    v = read(dq);
    if isnumeric(v) || islogical(v)
        x = double(v(1));
        return;
    end
    if istable(v) || isa(v, "timetable")
        a = table2array(v);
        x = double(a(1));
        return;
    end
    error("read(): unsupported type %s", class(v));
end

function writeSafe(dq, v)
try
    write(dq, v);
catch
end
end


