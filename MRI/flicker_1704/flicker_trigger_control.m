function flicker_trigger_control(nRepeats, dev, trigLine, port)
% Wait for digital TTL trigger, then run voltage flicker (same as working test.m).
%
% test.m output path:
%   port = 'ao1'; addoutput(dq, dev, port, "Voltage");
%   flicker: T=1/hz; n=floor(dur/T); ton=toff=T/2;
%            write(dq,3); pause(ton); write(dq,0); pause(toff);
%
% Example:
%   flicker_trigger_control(20, "Dev1", "port2/line0", "ao1")

if nargin < 1 || isempty(nRepeats), nRepeats = 20; end
if nargin < 2 || isempty(dev),      dev = "Dev1"; end
if nargin < 3 || isempty(trigLine), trigLine = "port2/line0"; end
if nargin < 4 || isempty(port),     port = "ao1"; end

% --- same levels as test.m flicker ---
V_hi = 3;
V_lo = 0;

freqHz = 2.5;
preOff = 8.0;
onWin  = 4.0;
postOff = 18.0;

% --- same math as test.m "flicker" ---
T = 1 / freqHz;
n = floor(onWin / T);
ton = T / 2;
toff = T / 2;

timeoutSec = 300;
pollDt = 0.001;
debounceMs = 3;
trigThr = 0.5;

dqIn = daq("ni");
addinput(dqIn, dev, trigLine, "Digital");

dqOut = daq("ni");
addoutput(dqOut, dev, port, "Voltage");

write(dqOut, V_lo);
cleanupObj = onCleanup(@() safeWrite(dqOut, V_lo));

fprintf("Trigger in : %s / %s (Digital)\n", dev, trigLine);
fprintf("Flicker out: %s / %s (Voltage, same as test.m)\n", dev, port);
fprintf("Waiting for trigger ...\n");

t0 = tic;
prevHigh = readDigitalHigh(dqIn, trigThr);
triggered = false;

while toc(t0) < timeoutSec
    drawnow('limitrate');
    curHigh = readDigitalHigh(dqIn, trigThr);

    if ~prevHigh && curHigh
        if waitStableHigh(dqIn, trigThr, debounceMs / 1000, pollDt)
            triggered = true;
            break;
        end
    end

    prevHigh = curHigh;
    pause(pollDt);
end

if ~triggered
    clear('cleanupObj');
    error("No trigger on %s within %.0f s.", trigLine, timeoutSec);
end

fprintf("Trigger OK. Running protocol...\n");

for r = 1:nRepeats
    fprintf("Repeat %d/%d\n", r, nRepeats);

    write(dqOut, V_lo);
    pause(preOff);

    for k = 1:n
        write(dqOut, V_hi); pause(ton);
        write(dqOut, V_lo); pause(toff);
    end
    write(dqOut, V_lo);

    write(dqOut, V_lo);
    pause(postOff);
end

write(dqOut, V_lo);
clear('cleanupObj');
fprintf("Done.\n");
end

%% --- helpers (robust read; avoids logical(read) errors) ---

function high = readDigitalHigh(dq, thr)
    x = readScalarDigital(dq);
    high = x > thr;
end

function x = readScalarDigital(dq)
    v = read(dq);
    if isnumeric(v) || islogical(v)
        x = double(v(1));
        return;
    end
    if istable(v)
        a = table2array(v);
        x = double(a(1));
        return;
    end
    if isa(v, "timetable")
        a = table2array(v);
        x = double(a(1));
        return;
    end
    error("read(): unsupported type %s", class(v));
end

function ok = waitStableHigh(dq, thr, winSec, pollDt)
    t = tic;
    ok = true;
    while toc(t) < winSec
        if ~readDigitalHigh(dq, thr)
            ok = false;
            return;
        end
        pause(pollDt);
    end
end

function safeWrite(dq, v)
    try
        write(dq, v);
    catch
    end
end
