function flicker_dig_ttl_gui()
% FLICKER_DIG_TTL_GUI  GUI for digital-TTL flicker (fixed schedule or MRI trigger).
%
% Wraps the same protocol as flicker_fixed_control_Dig_ttl.m and
% flicker_trigger_control_Dig_ttl.m: pre-off, flicker window, post-off per repeat.
% Trigger mode waits for rising edges on the trigger line, skipping n_dummy pulses
% before the first stimulation block.
%
%   flicker_dig_ttl_gui

existing = findall(0, "Type", "figure", "Name", "NI DAQ — TTL flicker");
if ~isempty(existing) && isvalid(existing(1))
    figure(existing(1));
    return;
end

fig = uifigure("Name", "NI DAQ — TTL flicker", "Position", [80 60 760 580]);
fig.UserData.abort = false;
fig.UserData.running = false;

gl = uigridlayout(fig, [3 2]);
gl.RowHeight = {28, "1x", 210};
gl.ColumnWidth = {"1x", 200};
gl.Padding = [10 10 10 10];
gl.RowSpacing = 8;
gl.ColumnSpacing = 10;

% --- Top: run mode ---
top = uigridlayout(gl, [1 3]);
top.Layout.Row = 1;
top.Layout.Column = [1 2];
top.ColumnWidth = {"fit", "fit", "1x"};
top.Padding = [0 0 0 0];

uilabel(top, "Text", "Mode:");
bgMode = uibuttongroup(top, "Title", "", "BorderType", "none");
rbFixed = uiradiobutton(bgMode, "Text", "Fixed schedule", "Position", [2 2 130 22], "Value", true);
rbTrig = uiradiobutton(bgMode, "Text", "MRI trigger", "Position", [140 2 110 22], "Value", false);

% --- Paradigm plot (left) + log (right) ---
ax = uiaxes(gl);
ax.Layout.Row = 2;
ax.Layout.Column = 1;
title(ax, "One repeat (stimulation window)");
xlabel(ax, "Time (s)");
ax.YTick = [];
ax.YLim = [0 1];
ax.Toolbar.Visible = "off";

txLog = uitextarea(gl, "Editable", "off", "FontName", "Consolas", "FontSize", 10);
txLog.Layout.Row = 2;
txLog.Layout.Column = 2;
txLog.Value = 'Log:';

% --- Bottom: channel/stimulation panels + buttons ---
bot = uigridlayout(gl, [2 2]);
bot.Layout.Row = 3;
bot.Layout.Column = [1 2];
bot.RowHeight = {"1x", 28};
bot.ColumnWidth = {"1x", "1x"};
bot.Padding = [0 0 0 0];
bot.RowSpacing = 6;
bot.ColumnSpacing = 10;

panCh = uipanel(bot, "Title", "Channel setup");
panCh.Layout.Row = 1;
panCh.Layout.Column = 1;
cg = uigridlayout(panCh, [3 2]);
cg.RowHeight = {22, 22, "1x"};
cg.ColumnWidth = {110, "1x"};
cg.Padding = [8 8 8 8];
cg.RowSpacing = 6;
cg.ColumnSpacing = 8;

lineItems = makeLineItems();
lineItems = reshape(cellstr(lineItems), 1, []);

uilabel(cg, "Text", "Device:");
edDev = uieditfield(cg, "Value", "Dev1");
uilabel(cg, "Text", "Output line:");
ddOut = uidropdown(cg, "Items", lineItems, "Value", 'port2/line4');
uilabel(cg, "Text", "Trigger line:");
ddTrig = uidropdown(cg, "Items", lineItems, "Value", 'port2/line0');

panStim = uipanel(bot, "Title", "Stimulation setup");
panStim.Layout.Row = 1;
panStim.Layout.Column = 2;
sg = uigridlayout(panStim, [4 4]);
sg.RowHeight = repmat({22}, 1, 4);
sg.ColumnWidth = {120, "1x", 120, "1x"};
sg.Padding = [8 8 8 8];
sg.RowSpacing = 6;
sg.ColumnSpacing = 8;

uilabel(sg, "Text", "Pre off (s):");
spPre = uispinner(sg, "Limits", [0 3600], "Value", 8, "Step", 0.5);
uilabel(sg, "Text", "Stim window (s):");
spOn = uispinner(sg, "Limits", [0.01 3600], "Value", 4, "Step", 0.1);

uilabel(sg, "Text", "Post off (s):");
spPost = uispinner(sg, "Limits", [0 3600], "Value", 18, "Step", 0.5);
uilabel(sg, "Text", "Repeats:");
spRep = uispinner(sg, "Limits", [1 10000], "Value", 10, "Step", 1);

uilabel(sg, "Text", "Freq (Hz):");
spFreq = uispinner(sg, "Limits", [0.1 200], "Value", 2.5, "Step", 0.1);
uilabel(sg, "Text", "Duty cycle:");
ddDuty = uidropdown(sg, "Items", {'50%'}, "Value", '50%');
ddDuty.Enable = "off";

uilabel(sg, "Text", "Dummy triggers:");
spDummy = uispinner(sg, "Limits", [0 1000], "Value", 8, "Step", 1, ...
    "Tooltip", "Trigger mode only: ignore first N rising edges before starting protocol.");
uilabel(sg, "Text", "Trig timeout (s):");
spTOut = uispinner(sg, "Limits", [1 7200], "Value", 300, "Step", 10);

btRow = uigridlayout(bot, [1 3]);
btRow.Layout.Row = 2;
btRow.Layout.Column = [1 2];
btRow.ColumnWidth = {120, 120, "1x"};
btRow.Padding = [0 0 0 0];

btnStart = uibutton(btRow, "Text", "Start", "ButtonPushedFcn", @onStart);
btnStop = uibutton(btRow, "Text", "Abort", "Enable", "off", "ButtonPushedFcn", @onStop);
lblStatus = uilabel(btRow, "Text", "Idle", "FontColor", [0.2 0.2 0.2]);

% Wire callbacks
bgMode.SelectionChangedFcn = @(s, e) refreshModeUI();
spPre.ValueChangedFcn = @(~,~) updatePlot();
spOn.ValueChangedFcn = @(~,~) updatePlot();
spPost.ValueChangedFcn = @(~,~) updatePlot();
spFreq.ValueChangedFcn = @(~,~) updatePlot();
spDummy.ValueChangedFcn = @(~,~) updatePlot();

refreshModeUI();
updatePlot();

fig.CloseRequestFcn = @onClose;

    function logLine(msg)
        v = txLog.Value;
        if ischar(v)
            v = {v};
        elseif isstring(v)
            v = cellstr(v);
        end
        txLog.Value = [v(:); {char(msg)}];
        try %#ok<TRYNC>
            scroll(txLog, "bottom");
        end
    end

    function refreshModeUI()
        trig = (bgMode.SelectedObject == rbTrig);
        if trig
            ddTrig.Enable = "on";
            spDummy.Enable = "on";
            spTOut.Enable = "on";
        else
            ddTrig.Enable = "off";
            spDummy.Enable = "off";
            spTOut.Enable = "off";
        end
        updatePlot();
    end

    function updatePlot()
        preOff = spPre.Value;
        onWin = spOn.Value;
        postOff = spPost.Value;
        freqHz = spFreq.Value;
        T = 1 / max(freqHz, 0.001);
        ton = T / 2;
        toff = T / 2;
        drawParadigmAxes(ax, preOff, onWin, postOff, ton, toff, (bgMode.SelectedObject == rbTrig), spDummy.Value);
    end

    function onStop(~, ~)
        fig.UserData.abort = true;
        logLine("Abort requested…");
    end

    function onClose(src, ~)
        if fig.UserData.running
            fig.UserData.abort = true;
            pause(0.3);
        end
        delete(src);
    end

    function onStart(~, ~)
        if fig.UserData.running
            return;
        end
        fig.UserData.abort = false;
        fig.UserData.running = true;
        btnStart.Enable = "off";
        btnStop.Enable = "on";
        drawnow;

        try
            runProtocol();
        catch ME
            logLine(ME.message);
            uialert(fig, ME.message, "Run error");
        end

        fig.UserData.running = false;
        btnStart.Enable = "on";
        btnStop.Enable = "off";
        lblStatus.Text = "Idle";
        logLine("---");
    end

    function runProtocol()
        dev = string(strtrim(edDev.Value));
        outLines = string(strtrim(ddOut.Value));
        trigLine = string(strtrim(ddTrig.Value));
        nRep = round(spRep.Value);
        preOff = spPre.Value;
        onWin = spOn.Value;
        postOff = spPost.Value;
        freqHz = spFreq.Value;
        n_dummy = round(spDummy.Value);
        timeoutSec = spTOut.Value;
        trigMode = (bgMode.SelectedObject == rbTrig);

        T = 1 / max(freqHz, 0.001);
        ton = T / 2;
        toff = T / 2;
        nPulse = floor(onWin / T);
        freqHz = 1 / T;

        lblStatus.Text = "Running…";
        logLine(sprintf("%s | %s → %s | %d repeats", char(dev), char(trigLine), char(outLines), nRep));
        logLine(sprintf("Pattern: %.1fs off → %.1fs @ %.2f Hz (50%% duty, ON %.3fs / OFF %.3fs) → %.1fs off", ...
            preOff, onWin, freqHz, ton, toff, postOff));

        dqOut = daq("ni");
        addoutput(dqOut, dev, outLines, "Digital");
        nLines = numel(dqOut.Channels);
        lo = false(1, nLines);
        hi = true(1, nLines);
        write(dqOut, lo);
        cleanupOut = onCleanup(@() writeSafe(dqOut, lo));

        if trigMode
            dqIn = daq("ni");
            addinput(dqIn, dev, trigLine, "Digital");
            cleanupIn = onCleanup(@() safeRelease(dqIn));
            pollDt = 0.001;
            trigThr = 0.5;
            prevHigh = readDigitalHigh(dqIn, trigThr);
            pulseCount = 0;
            triggered = false;
            t0 = tic;
            logLine(sprintf("Waiting for trigger (skip first %d edges)…", n_dummy));
            while toc(t0) < timeoutSec
                if fig.UserData.abort
                    break;
                end
                drawnow limitrate;
                curHigh = readDigitalHigh(dqIn, trigThr);
                if ~prevHigh && curHigh
                    pulseCount = pulseCount + 1;
                    if pulseCount > n_dummy
                        triggered = true;
                        break;
                    else
                        logLine(sprintf("Dummy trigger %d / %d ignored", pulseCount, n_dummy));
                    end
                end
                prevHigh = curHigh;
                pause(pollDt);
            end
            clear("cleanupIn");
            if fig.UserData.abort
                logLine("Aborted during wait.");
                return;
            end
            if ~triggered
                error("No valid trigger within %.0f s (after %d dummy).", timeoutSec, n_dummy);
            end
            logLine("Trigger OK — starting protocol.");
        end

        for r = 1:nRep
            if fig.UserData.abort
                logLine("Aborted.");
                break;
            end
            lblStatus.Text = sprintf("Repeat %d / %d", r, nRep);
            logLine(sprintf("Repeat %d / %d", r, nRep));

            chunkedPause(preOff);
            if fig.UserData.abort, break; end

            for k = 1:nPulse
                if fig.UserData.abort, break; end
                write(dqOut, hi);
                chunkedPause(ton);
                if fig.UserData.abort, break; end
                write(dqOut, lo);
                chunkedPause(toff);
            end
            if fig.UserData.abort, break; end

            write(dqOut, lo);
            chunkedPause(postOff);
        end

        write(dqOut, lo);
        clear("cleanupOut");
        if ~fig.UserData.abort
            logLine("Done.");
            lblStatus.Text = "Finished";
        else
            lblStatus.Text = "Aborted";
        end
    end

    function chunkedPause(secTotal)
        dt = 0.05;
        nStep = max(1, ceil(secTotal / dt));
        for s = 1:nStep
            if fig.UserData.abort
                return;
            end
            pause(min(dt, secTotal - (s - 1) * dt));
        end
    end
end

function drawParadigmAxes(ax, preOff, onWin, postOff, ton, toff, trigMode, nDummy)
cla(ax);
hold(ax, "on");
tEnd = preOff + onWin + postOff;
if tEnd <= 0
    tEnd = 1;
end

% Background phases
patch(ax, [0 preOff preOff 0], [0 0 0.85 0.85], [0.85 0.85 0.88], "EdgeColor", "none", "DisplayName", "Pre (off)");
patch(ax, [preOff preOff+onWin preOff+onWin preOff], [0 0 0.85 0.85], [1 0.75 0.4], "EdgeColor", [0.8 0.5 0.2], "LineWidth", 0.5, "DisplayName", "Stim window");
patch(ax, [preOff+onWin tEnd tEnd preOff+onWin], [0 0 0.85 0.85], [0.85 0.88 0.85], "EdgeColor", "none", "DisplayName", "Post (off)");

% Approximate square-wave train inside on-window
T = max(ton + toff, 1e-6);
nCyc = floor(onWin / T);
t = preOff;
yHi = 0.92;
yLo = 0.55;
for c = 1:nCyc
    t1 = t;
    t2 = min(t + ton, preOff + onWin);
    plot(ax, [t1 t2], [yHi yHi], "Color", [0.15 0.15 0.2], "LineWidth", 1.8);
    plot(ax, [t2 t2], [yHi yLo], "Color", [0.15 0.15 0.2], "LineWidth", 1.2);
    t3 = min(t2 + toff, preOff + onWin);
    plot(ax, [t2 t3], [yLo yLo], "Color", [0.15 0.15 0.2], "LineWidth", 1.8);
    if t3 >= preOff + onWin - 1e-9
        break;
    end
    plot(ax, [t3 t3], [yLo yHi], "Color", [0.15 0.15 0.2], "LineWidth", 1.2);
    t = t3;
end

xlim(ax, [0 tEnd]);
ylim(ax, [0 1]);
xlabel(ax, "Time within one repeat (s)");
yticks(ax, []);
grid(ax, "on");
ax.Box = "on";

freqHz = 1 / T;
ttl = sprintf("One repeat: %.1f s OFF  →  %.1f s stim (ON %.3f / OFF %.3f, %.2f Hz)  →  %.1f s OFF", ...
    preOff, onWin, ton, toff, freqHz, postOff);
if trigMode
    subt = sprintf("Trigger: skip first %d rising edges, then this pattern × repeats.", nDummy);
else
    subt = "Fixed: pattern starts immediately when you press Start.";
end
title(ax, {ttl, subt}, "FontSize", 10);
hold(ax, "off");
end

function items = makeLineItems()
items = arrayfun(@(n) sprintf('port%d/line%d', floor((n - 1) / 8), mod(n - 1, 8)), ...
    1:24, "UniformOutput", false);
end

function high = readDigitalHigh(dq, trigThr)
x = readScalarDigital(dq);
high = x > trigThr;
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

function safeRelease(dq)
try
    if ~isempty(dq)
        release(dq);
    end
catch
end
end
