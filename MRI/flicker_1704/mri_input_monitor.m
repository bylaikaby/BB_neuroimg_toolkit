function mri_input_monitor(dev, line, runSeconds, dt)
% MRI_INPUT_MONITOR  Watch MRI TTL on a digital input (short utility).
%
%   mri_input_monitor % Dev1, port2/line0, until Ctrl+C
%   mri_input_monitor("Dev1","port2/line0",60) % stop after 60 s
%   mri_input_monitor("Dev1","port2/line0",30,0.005) % 5 ms poll

if nargin < 1 || isempty(dev),        dev = "Dev1"; end
if nargin < 2 || isempty(line),       line = "port2/line0"; end
if nargin < 3 || isempty(runSeconds), runSeconds = inf; end
if nargin < 4 || isempty(dt),         dt = 0.001; end

dq = daq("ni");
addinput(dq, dev, line, "Digital");

fprintf("MRI monitor: %s / %s | dt=%.4f s", dev, line, dt);
if isfinite(runSeconds)
    fprintf(" | stop after %.1f s\n", runSeconds);
else
    fprintf(" | stop with Ctrl+C\n");
end

t0 = tic;
triggerCount = 0;
prevHigh = readScalar(read(dq)) > 0.5;
while toc(t0) < runSeconds
    x = readScalar(read(dq));
    curHigh = x > 0.5;

    % Count trigger on rising edge (LOW -> HIGH)
    if ~prevHigh && curHigh
        triggerCount = triggerCount + 1;
    end

    fprintf("[%8.3f s]  %g  | triggers=%d\n", toc(t0), x, triggerCount);
    prevHigh = curHigh;
    pause(dt);
end
fprintf("Done. Total triggers: %d\n", triggerCount);
end

function x = readScalar(v)
    if isnumeric(v) || islogical(v)
        x = double(v(1));
    elseif istable(v) || isa(v, "timetable")
        a = table2array(v);
        x = double(a(1));
    else
        error("Unsupported read() type: %s", class(v));
    end
end
