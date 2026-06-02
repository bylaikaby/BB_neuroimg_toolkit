function flicker_gui
% FLICKER_GUI  Direct-control GUI for NiDAQ flicker stimulation in MRI.
%
% Features:
%   1. Toggle fixed-schedule vs. MRI-triggered mode
%   2. Configure stimulation parameters (freq, timing, repeats)
%   3. Configure NiDAQ ports (device, analog/digital channels)
%   4. Visualisation of the stimulation paradigm (simplified schematic)
%   5. Run stimulation directly from the GUI (requires Data Acquisition Toolbox)
%   6. Emergency stop during run
%   7. Monitor trigger input (live line level and pulse count)
%   8. Export current configuration as a MATLAB script (File menu)
%
% See also: daq, flicker_fixed_control, flicker_trigger_control

% ── Figure ──
fig = uifigure('Name', 'Flicker Stimulation - NiDAQ Direct Control', ...
               'Position', [90 70 1380 860], ...
               'Resize', 'on', ...
               'NumberTitle', 'off');

% ── Menu ──
mnu = uimenu(fig, 'Label', 'File');
uimenu(mnu, 'Label', 'Generate MATLAB Script...', ...
    'Callback', @(~,~) generateScript());
uimenu(mnu, 'Label', 'Load Defaults', 'Callback', @(~,~) loadDefaults());
uimenu(mnu, 'Label', 'About', ...
    'Callback', @(~,~) uialert(fig, ...
        'Flicker Stimulation GUI v1.0 - Direct NiDAQ control', 'About', ...
        'Icon', 'info'));

% ── Main grid: left controls | right viz+status ──
mainGrid = uigridlayout(fig, [1 2], ...
    'ColumnWidth', {430, '1x'}, ...
    'RowHeight', {'1x'}, ...
    'Padding', [10 10 10 10], ...
    'ColumnSpacing', 10);

% ╔══════════════════════════════════════════════════════════════════╗
% ║  LEFT PANEL                                                     ║
% ╚══════════════════════════════════════════════════════════════════╝
leftPanel = uipanel(mainGrid, 'Title', '', 'BorderType', 'none');
leftGrid = uigridlayout(leftPanel, [4 1], ...
    'RowHeight', {118, 198, 316, '1x'}, ...
    'RowSpacing', 12, ...
    'Padding', [8 8 8 8]);

% ── 1. Output Type ──
outPanel = uipanel(leftGrid, 'Title', 'Output Type', 'FontWeight', 'bold');
outGrid = uigridlayout(outPanel, [1 1], 'Padding', [8 8 8 8], ...
    'ColumnWidth', {'1x'}, 'RowHeight', {'1x'});
outType = uibuttongroup(outGrid, 'BorderType', 'none');
rbAnalog  = uiradiobutton(outType, 'Text', 'Analog (Voltage)', ...
    'Position', [10 18 170 24], 'Value', false);
rbDigital = uiradiobutton(outType, 'Text', 'Digital (TTL)', ...
    'Position', [210 18 160 24], 'Value', true);
outType.SelectionChangedFcn = @(~,~) updateViz();

% ── 2. Trigger Mode ──
trigPanel = uipanel(leftGrid, 'Title', 'Trigger Mode', 'FontWeight', 'bold');
trigGrid = uigridlayout(trigPanel, [6 2], ...
    'RowHeight', {34, 34, 34, 34, 34, 34}, ...
    'ColumnWidth', {120, '1x'}, ...
    'Padding', [12 10 12 10], ...
    'RowSpacing', 8, ...
    'ColumnSpacing', 10);

trigEnable = uicheckbox(trigGrid, 'Text', 'Enable trigger (MRI pulse)', ...
    'Value', true);
trigEnable.Layout.Row = 1;
trigEnable.Layout.Column = [1 2];

lblTrigLine = uilabel(trigGrid, 'Text', 'Trigger line:', 'HorizontalAlignment', 'right');
lblTrigLine.Layout.Row = 2; lblTrigLine.Layout.Column = 1;
trigLine = uieditfield(trigGrid, 'text', 'Value', 'port2/line0');
trigLine.Layout.Row = 2; trigLine.Layout.Column = 2;

lblTrigDummy = uilabel(trigGrid, 'Text', 'Dummy pulses:', 'HorizontalAlignment', 'right');
lblTrigDummy.Layout.Row = 3; lblTrigDummy.Layout.Column = 1;
trigDummy = uispinner(trigGrid, 'Value', 8, 'Limits', [0 99], ...
    'ValueDisplayFormat', '%.0f', 'RoundFractionalValues', 'on', ...
    'ValueChangedFcn', @(~,~) updateViz());
trigDummy.Layout.Row = 3; trigDummy.Layout.Column = 2;

lblTrigTimeout = uilabel(trigGrid, 'Text', 'Timeout (s):', 'HorizontalAlignment', 'right');
lblTrigTimeout.Layout.Row = 4; lblTrigTimeout.Layout.Column = 1;
trigTimeout = uispinner(trigGrid, 'Value', 300, 'Limits', [1 3600]);
trigTimeout.Layout.Row = 4; trigTimeout.Layout.Column = 2;

trigEnable.ValueChangedFcn = @(~,~) updateViz();

btnMonitorTrig = uibutton(trigGrid, 'push', ...
    'Text', 'Monitor Trigger Input', ...
    'ButtonPushedFcn', @(~,~) monitorTriggerInput(), ...
    'FontWeight', 'bold');
btnMonitorTrig.Layout.Row = 6;
btnMonitorTrig.Layout.Column = [1 2];

% ── 3. Stimulation Parameters ──
stimPanel = uipanel(leftGrid, 'Title', 'Stimulation Parameters', 'FontWeight', 'bold');
stimGrid = uigridlayout(stimPanel, [7 2], ...
    'RowHeight', {34, 34, 34, 34, 34, 34, 34}, ...
    'ColumnWidth', {135, '1x'}, ...
    'Padding', [12 10 12 10], ...
    'RowSpacing', 8, ...
    'ColumnSpacing', 10);

stimFields = struct();
labels = {'Frequency (Hz):', 'Pre-off (s):', 'ON window (s):', ...
          'Post-off (s):', 'Repeats:', 'High level (V):', 'Low level (V):'};
defaults = [2.5, 8, 4, 18, 20, 3, 0];
limits  = [0.1 100; 0 300; 0.1 300; 0 300; 1 999; -10 10; -10 10];
for i = 1:7
    uilabel(stimGrid, 'Text', labels{i}, 'HorizontalAlignment', 'right');
    if i == 5
        stimFields.(sprintf('f%d',i)) = uispinner(stimGrid, ...
            'Value', defaults(i), 'Limits', limits(i,:), ...
            'ValueDisplayFormat', '%.0f', ...
            'ValueChangedFcn', @(~,~) updateViz());
    else
        stimFields.(sprintf('f%d',i)) = uispinner(stimGrid, ...
            'Value', defaults(i), 'Limits', limits(i,:), ...
            'ValueDisplayFormat', '%.2f', ...
            'ValueChangedFcn', @(~,~) updateViz());
    end
end

% ── 4. NiDAQ Port Settings ──
portPanel = uipanel(leftGrid, 'Title', 'NiDAQ Port Settings', 'FontWeight', 'bold');
portGrid = uigridlayout(portPanel, [3 2], ...
    'RowHeight', {34, 34, 34}, ...
    'ColumnWidth', {120, '1x'}, ...
    'Padding', [12 10 12 10], ...
    'RowSpacing', 8, ...
    'ColumnSpacing', 10);

uilabel(portGrid, 'Text', 'Device:', 'HorizontalAlignment', 'right');
portDev = uieditfield(portGrid, 'text', 'Value', 'Dev1');

uilabel(portGrid, 'Text', 'Analog out:', 'HorizontalAlignment', 'right');
portAOut = uieditfield(portGrid, 'text', 'Value', 'ao1');

uilabel(portGrid, 'Text', 'Digital out:', 'HorizontalAlignment', 'right');
portDOut = uieditfield(portGrid, 'text', 'Value', 'port2/line4');

% ╔══════════════════════════════════════════════════════════════════╗
% ║  RIGHT PANEL                                                    ║
% ╚══════════════════════════════════════════════════════════════════╝
rightPanel = uipanel(mainGrid, 'Title', '', 'BorderType', 'none');
rightGrid = uigridlayout(rightPanel, [4 1], ...
    'RowHeight', {'1x', 88, 28, 52}, ...
    'RowSpacing', 8, ...
    'Padding', [6 6 6 6]);

% ── Row 1: Axes ──
ax = uiaxes(rightGrid, ...
    'XLim', [0 90], 'YLim', [-0.8 4], ...
    'XGrid', 'on', 'YGrid', 'on', ...
    'FontSize', 10, 'Box', 'on');
ax.Layout.Row = 1;
hold(ax, 'on');

% ── Row 2: Info bar (protocol summary + status + elapsed in one compact row) ──
infoGrid = uigridlayout(rightGrid, [2 4], ...
    'ColumnWidth', {130, 130, 220, '1x'}, ...
    'RowHeight', {30, 30}, ...
    'Padding', [4 4 4 4], ...
    'ColumnSpacing', 10, ...
    'RowSpacing', 4);
infoGrid.Layout.Row = 2;

% Quick protocol summary
sumFreq  = uilabel(infoGrid, 'Text', 'Freq: -- Hz', ...
    'FontWeight', 'bold', 'FontSize', 11);
sumFreq.Layout.Row = 1;
sumFreq.Layout.Column = 1;
sumOn    = uilabel(infoGrid, 'Text', 'ON: -- s', ...
    'FontWeight', 'bold', 'FontSize', 11);
sumOn.Layout.Row = 1;
sumOn.Layout.Column = 2;
sumTotal = uilabel(infoGrid, 'Text', 'Total: --', ...
    'FontWeight', 'bold', 'FontSize', 11);
sumTotal.Layout.Row = 1;
sumTotal.Layout.Column = [3 4];

% Status
statusLabel = uilabel(infoGrid, 'Text', 'Ready', ...
    'FontWeight', 'bold', 'FontSize', 11, ...
    'HorizontalAlignment', 'left');
statusLabel.Layout.Row = 2;
statusLabel.Layout.Column = [1 2];

% Elapsed / repeat
infoLine = uilabel(infoGrid, 'Text', '', ...
    'FontSize', 10, 'HorizontalAlignment', 'right');
infoLine.Layout.Row = 2;
infoLine.Layout.Column = [3 4];

% ── Row 3: Progress bar ──
prog = uigauge(rightGrid, 'Linear', ...
    'Value', 0, 'Limits', [0 100], ...
    'MajorTicks', [0 50 100], 'MinorTicks', []);
prog.Layout.Row = 3;

% ── Row 4: Buttons ──
btnGrid = uigridlayout(rightGrid, [1 4], ...
    'ColumnWidth', {'1x', '1x', '1x', '1x'}, ...
    'Padding', [2 2 2 2], ...
    'ColumnSpacing', 8);
btnGrid.Layout.Row = 4;

btnUpdate = uibutton(btnGrid, 'push', ...
    'Text', 'Update Preview', ...
    'ButtonPushedFcn', @(~,~) updateViz(), ...
    'FontWeight', 'bold');

btnRun = uibutton(btnGrid, 'push', ...
    'Text', 'Run Stimulation', ...
    'ButtonPushedFcn', @(~,~) runStimulation(), ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.7 0.9 0.7]);

btnStop = uibutton(btnGrid, 'push', ...
    'Text', 'Stop', ...
    'ButtonPushedFcn', @(~,~) stopStimulation(), ...
    'FontWeight', 'bold', ...
    'BackgroundColor', [0.95 0.7 0.7], ...
    'Enable', 'off');

btnDefaults = uibutton(btnGrid, 'push', ...
    'Text', 'Defaults', ...
    'ButtonPushedFcn', @(~,~) loadDefaults());

% ═══════════════════════════════════════════════════════════════════
%  STATE
% ═══════════════════════════════════════════════════════════════════
stopRequested        = false;
isRunning            = false;
isMonitoring         = false;
monitorStopRequested = false;

    function s = getParams()
        s.freqHz    = stimFields.f1.Value;
        s.preOff    = stimFields.f2.Value;
        s.onWin     = stimFields.f3.Value;
        s.postOff   = stimFields.f4.Value;
        s.nRepeats  = readSpinnerInt(stimFields.f5);
        s.vHi       = stimFields.f6.Value;
        s.vLo       = stimFields.f7.Value;
        s.device    = strtrim(portDev.Value);
        s.analogPort = strtrim(portAOut.Value);
        s.digPort   = strtrim(portDOut.Value);
        s.isDigital = rbDigital.Value;
        s.isTrigger = trigEnable.Value;
        s.trigLine  = strtrim(trigLine.Value);
        s.nDummy    = readSpinnerInt(trigDummy);
        s.timeout_s = trigTimeout.Value;
    end

    function v = readSpinnerInt(sp)
        % Commit in-progress spinner edits before read (MATLAB UI quirk).
        drawnow('limitrate');
        v = round(double(sp.Value));
    end

    function p = calcStim(s)
        p = s;
        p.T      = 1 / max(s.freqHz, 0.01);
        p.n      = floor(s.onWin / p.T);
        p.ton    = p.T / 2;
        p.toff   = p.T / 2;
        p.repDur = s.preOff + s.onWin + s.postOff;
        p.total  = p.repDur * s.nRepeats;
    end

% ═══════════════════════════════════════════════════════════════════
%  STATUS HELPERS
% ═══════════════════════════════════════════════════════════════════
    function setStatus(txt)
        statusLabel.Text = txt;
        drawnow('limitrate');
    end

    function setInfo(r, n, elap)
        if nargin < 3; elap = []; end
        parts = {};
        if nargin >= 1
            parts{end+1} = sprintf('Repeat: %d / %d', r, n);
        end
        if ~isempty(elap)
            parts{end+1} = sprintf('Elapsed: %.1f s', elap);
        end
        if isempty(parts)
            infoLine.Text = '';
        else
            infoLine.Text = strjoin(parts, '  |  ');
        end
        drawnow('limitrate');
    end

    function setProgress(pct)
        prog.Value = pct;
        drawnow('limitrate');
    end

    function setControlsEnabled(en)
        state = iif(en, 'on', 'off');
        trigEnable.Enable = state;
        trigLine.Enable = state;
        trigDummy.Enable = state;
        trigTimeout.Enable = state;
        btnMonitorTrig.Enable = state;
        stimFields.f1.Enable = state;
        stimFields.f2.Enable = state;
        stimFields.f3.Enable = state;
        stimFields.f4.Enable = state;
        stimFields.f5.Enable = state;
        stimFields.f6.Enable = state;
        stimFields.f7.Enable = state;
        portDev.Enable = state;
        portAOut.Enable = state;
        portDOut.Enable = state;
        rbAnalog.Enable = state;
        rbDigital.Enable = state;
        btnDefaults.Enable = state;
        btnUpdate.Enable = state;
        btnRun.Enable = state;
        btnStop.Enable = iif(en, 'off', 'on');
    end

% ═══════════════════════════════════════════════════════════════════
%  RESPONSIVE PAUSE
% ═══════════════════════════════════════════════════════════════════
    function ok = responsivePause(durSec)
        poll = 0.05;
        elapsed = 0;
        while elapsed < durSec
            if stopRequested; ok = false; return; end
            step = min(poll, durSec - elapsed);
            pause(step);
            elapsed = elapsed + step;
            drawnow('limitrate');
        end
        ok = true;
    end

% ═══════════════════════════════════════════════════════════════════
%  TRIGGER WAIT / MONITOR
% ═══════════════════════════════════════════════════════════════════
    function setTriggerWaitInfo(pulseCount, nDummy, lineVal, elapsed)
        infoLine.Text = sprintf('Dummy pulse: %d / %d  |  line: %g  |  %.1f s', ...
            pulseCount, nDummy, lineVal, elapsed);
        drawnow('limitrate');
    end

    function triggered = waitForTrigger(dqIn, ln, ~, to)
        % Rising-edge count; no debounce (MRI TTL pulses are often < 3 ms).
        % Same logic as flicker_trigger_control_Dig_ttl.m.
        nDummyNow = readSpinnerInt(trigDummy);
        setStatus(sprintf('Waiting for trigger on %s (skip %d dummy, then start)...', ln, nDummyNow));
        setTriggerWaitInfo(0, nDummyNow, NaN, 0);
        setProgress(0);
        pollDt = 0.001;
        thr = 0.5;
        try
            prevHigh = readDigitalHigh(dqIn, thr);
        catch
            prevHigh = false;
        end
        pulseCount = 0;
        t0 = tic;
        triggered = false;
        while toc(t0) < to
            if stopRequested
                return;
            end
            nDummyNow = readSpinnerInt(trigDummy);
            elapsed = toc(t0);
            try
                x = readScalarDigital(dqIn);
                curHigh = x > thr;
            catch ME
                setStatus(sprintf('Trigger read error: %s', ME.message));
                pause(pollDt);
                drawnow('limitrate');
                continue;
            end
            if ~prevHigh && curHigh
                pulseCount = pulseCount + 1;
                if pulseCount > nDummyNow
                    triggered = true;
                    setStatus('Trigger acquired — starting flicker.');
                    setTriggerWaitInfo(pulseCount, nDummyNow, x, elapsed);
                    return;
                end
                setStatus(sprintf('Dummy pulse %d / %d on %s', pulseCount, nDummyNow, ln));
            end
            setTriggerWaitInfo(pulseCount, nDummyNow, x, elapsed);
            prevHigh = curHigh;
            pause(pollDt);
            drawnow('limitrate');
        end
        setStatus(sprintf('Trigger timeout (%d s). Uncheck trigger or reduce dummy count.', round(to)));
    end

    function monitorTriggerInput()
        if isRunning || isMonitoring
            uialert(fig, 'Stop the current run or monitor first.', 'Busy', ...
                'Icon', 'warning');
            return;
        end
        s = getParams();
        try
            dqtest = daq("ni");
            clear dqtest;
        catch
            uialert(fig, 'Data Acquisition Toolbox or NI support not available.', ...
                'DAQ Error', 'Icon', 'error');
            return;
        end

        dur = min(max(s.timeout_s, 5), 600);
        thr = 0.5;
        pollDt = 0.001;
        dqIn = [];
        isMonitoring = true;
        monitorStopRequested = false;
        setControlsEnabled(false);
        btnStop.Enable = 'on';

        try
            dqIn = daq("ni");
            addinput(dqIn, s.device, s.trigLine, "Digital");
            setStatus(sprintf('Monitoring %s / %s', s.device, s.trigLine));
            t0 = tic;
            pulseCount = 0;
            prevHigh = readDigitalHigh(dqIn, thr);
            while toc(t0) < dur && ~monitorStopRequested
                elapsed = toc(t0);
                try
                    x = readScalarDigital(dqIn);
                catch ME
                    setStatus(sprintf('Monitor read error: %s', ME.message));
                    pause(pollDt);
                    drawnow('limitrate');
                    continue;
                end
                curHigh = x > thr;
                if ~prevHigh && curHigh
                    pulseCount = pulseCount + 1;
                end
                setTriggerWaitInfo(pulseCount, readSpinnerInt(trigDummy), x, elapsed);
                setStatus(sprintf('Monitor %s  |  HIGH=%d', s.trigLine, curHigh));
                setProgress(100 * elapsed / dur);
                prevHigh = curHigh;
                pause(pollDt);
                drawnow('limitrate');
            end
            if monitorStopRequested
                setStatus(sprintf('Monitor stopped (%d pulse(s)).', pulseCount));
            else
                setStatus(sprintf('Monitor done (%d pulse(s) in %.0f s).', pulseCount, dur));
            end
        catch ME
            setStatus('Monitor error - see console.');
            uialert(fig, sprintf('DAQ error:\n%s', ME.message), ...
                'Monitor Error', 'Icon', 'error');
        end

        isMonitoring = false;
        monitorStopRequested = false;
        setControlsEnabled(true);
        setProgress(0);
        try
            if ~isempty(dqIn) && isvalid(dqIn)
                delete(dqIn);
            end
        catch
        end
    end

% ═══════════════════════════════════════════════════════════════════
%  WRITE HELPERS
% ═══════════════════════════════════════════════════════════════════
    function nOut = nDaqOutputLines(dq)
        % Output-only channel count (unified trigger+out session has inputs too).
        ch = dq.Channels;
        nOut = 0;
        for i = 1:numel(ch)
            try
                isOut = strcmpi(string(ch(i).Direction), "Output");
            catch
                isOut = false;
            end
            if isOut
                nOut = nOut + 1;
            end
        end
        if nOut < 1
            nOut = numel(ch);
        end
    end

    function writeLo(dq, p)
        nOut = nDaqOutputLines(dq);
        if p.isDigital
            write(dq, false(1, nOut));
        elseif nOut > 1
            write(dq, repmat(p.vLo, 1, nOut));
        else
            write(dq, p.vLo);
        end
    end
    function writeHi(dq, p)
        nOut = nDaqOutputLines(dq);
        if p.isDigital
            write(dq, true(1, nOut));
        elseif nOut > 1
            write(dq, repmat(p.vHi, 1, nOut));
        else
            write(dq, p.vHi);
        end
    end
    function safeWriteLo(dq, p)
        try writeLo(dq, p); catch; end
    end

% ═══════════════════════════════════════════════════════════════════
%  RUN STIMULATION
% ═══════════════════════════════════════════════════════════════════
    function runStimulation()
        if isRunning
            uialert(fig, 'Already running.', 'Error', 'Icon', 'error');
            return;
        end
        s = getParams(); p = calcStim(s);
        if p.n < 1
            uialert(fig, 'ON window too short for 1 cycle at this frequency.', ...
                'Parameter Error', 'Icon', 'error'); return;
        end
        if p.nRepeats < 1
            uialert(fig, 'At least 1 repeat required.', 'Parameter Error', ...
                'Icon', 'error'); return;
        end
        try dqpre = daq("ni"); clear dqpre;
        catch
            uialert(fig, 'Data Acquisition Toolbox or NI support not available.', ...
                'DAQ Error', 'Icon', 'error'); return;
        end

        dq = [];
        runAborted = false;
        stopRequested = false; isRunning = true;
        setControlsEnabled(false);

        try
            % One NI session: trigger input first, then output (same as scripts).
            dq = daq("ni");
            if p.isTrigger
                addinput(dq, p.device, p.trigLine, "Digital");
            end
            if p.isDigital
                addoutput(dq, p.device, p.digPort, "Digital");
            else
                addoutput(dq, p.device, p.analogPort, "Voltage");
            end
            writeLo(dq, p);
            cleanupDq = onCleanup(@() safeWriteLo(dq, p));

            if p.isTrigger
                ok = waitForTrigger(dq, p.trigLine, [], p.timeout_s);
                p = calcStim(getParams());
                if ~ok
                    runAborted = true;
                    if stopRequested
                        setStatus('Stopped during trigger wait.');
                    else
                        uialert(fig, sprintf(['No trigger after %d dummy pulse(s) within %.0f s.\n' ...
                            'Try: uncheck Enable trigger, lower Dummy pulses, or start the scanner.'], ...
                            p.nDummy, p.timeout_s), 'Trigger Timeout', 'Icon', 'warning');
                    end
                end
            end

            % Loop
            if ~runAborted
                if p.isTrigger
                    setStatus('Running flicker (triggered)...');
                else
                    setStatus('Running flicker (fixed schedule)...');
                end
                totalElapsed = 0;
                for r = 1:p.nRepeats
                    if stopRequested; break; end
                    setInfo(r, p.nRepeats, totalElapsed);
                    setProgress(100 * (r-1) / p.nRepeats);

                    writeLo(dq, p);
                    if ~responsivePause(p.preOff); break; end
                    totalElapsed = totalElapsed + p.preOff;
                    setInfo(r, p.nRepeats, totalElapsed);

                    for k = 1:p.n
                        if stopRequested; break; end
                        writeHi(dq, p);
                        if ~responsivePause(p.ton); break; end
                        writeLo(dq, p);
                        if ~responsivePause(p.toff); break; end
                    end
                    if stopRequested; break; end

                    writeLo(dq, p);
                    totalElapsed = totalElapsed + p.onWin;
                    if ~responsivePause(p.postOff); break; end
                    totalElapsed = totalElapsed + p.postOff;
                    setInfo(r, p.nRepeats, totalElapsed);
                end

                writeLo(dq, p);
                setProgress(100);
                if stopRequested
                    setStatus('Stopped by user.');
                else
                    setStatus('Completed.');
                    setInfo(p.nRepeats, p.nRepeats, p.total);
                end
            end

        catch ME
            try writeLo(dq, p); catch; end
            setStatus('Error - see console.');
            uialert(fig, sprintf('DAQ error:\n%s', ME.message), ...
                'Run Error', 'Icon', 'error');
        end

        % Cleanup
        isRunning = false; stopRequested = false;
        setControlsEnabled(true);
        try if ~isempty(dq) && isvalid(dq); delete(dq); end; catch; end
    end

    function stopStimulation()
        if isMonitoring
            monitorStopRequested = true;
            setStatus('Stopping monitor...');
            return;
        end
        if ~isRunning
            setStatus('Not running.');
            return;
        end
        stopRequested = true;
        btnStop.Enable = 'off';
        setStatus('Stopping...');
    end

% ═══════════════════════════════════════════════════════════════════
%  SIMPLIFIED VISUALISATION
% ═══════════════════════════════════════════════════════════════════
    function updateViz()
        s = getParams(); p = calcStim(s);
        cla(ax);
        hold(ax, 'on');

        % Update quick-summary labels
        sumFreq.Text  = sprintf('Freq: %.1f Hz', p.freqHz);
        sumOn.Text    = sprintf('ON: %.1f s', p.onWin);
        sumTotal.Text = sprintf('Repeats: %d  |  Dummy: %d  |  %.0f s', ...
            p.nRepeats, p.nDummy, p.total);

        if p.n < 1
            text(ax, 0.5, 0.5, 'Adjust parameters (ON window too short) ...', ...
                'Units', 'normalized', 'HorizontalAlignment', 'center');
            hold(ax, 'off');
            return;
        end

        % ── Block-diagram schematic (no dense waveform) ──
        nViz = min(2, p.nRepeats);
        totalViz = nViz * p.repDur;
        yBot = p.vLo - 0.6; yTop = p.vHi + 0.6;
        phaseBoundaries = [];
        repeatJunctionBoundaries = [];

        % Draw each repeat as blocks
        for r = 0:nViz-1
            base = r * p.repDur;
            tPreEnd = base + p.preOff;
            tOnEnd  = tPreEnd + p.onWin;
            tPostEnd = min(base + p.repDur, tOnEnd + p.postOff);

            % --- Phase background fills ---
            % Pre-off (grey)
            fill(ax, [base tPreEnd tPreEnd base], [yBot yBot yTop yTop], ...
                [0.88 0.88 0.88], 'EdgeColor', 'none');
            % Flicker window (light orange)
            fill(ax, [tPreEnd tOnEnd tOnEnd tPreEnd], [yBot yBot yTop yTop], ...
                [1 0.92 0.75], 'EdgeColor', 'none');
            % Post-off (grey)
            if tPostEnd > tOnEnd
                fill(ax, [tOnEnd tPostEnd tPostEnd tOnEnd], [yBot yBot yTop yTop], ...
                    [0.88 0.88 0.88], 'EdgeColor', 'none');
            end

            % --- Signal line ---
            % Draw an actual square-wave preview (not spike markers).
            maxCyclesViz = 120;
            nCyclesViz = min(p.n, maxCyclesViz);
            if nCyclesViz < p.n
                tonViz = p.onWin / (2 * nCyclesViz);
                toffViz = tonViz;
            else
                tonViz = p.ton;
                toffViz = p.toff;
            end
            tSig = [base, tPreEnd];
            ySig = [p.vLo, p.vLo];
            tc = tPreEnd;
            for k = 1:nCyclesViz
                tSig = [tSig, tc, tc + tonViz, tc + tonViz, tc + tonViz + toffViz];
                ySig = [ySig, p.vLo, p.vHi, p.vHi, p.vLo];
                tc = tc + tonViz + toffViz;
            end
            if tc < tOnEnd
                tSig = [tSig, tOnEnd];
                ySig = [ySig, p.vLo];
            end
            tSig = [tSig, tPostEnd];
            ySig = [ySig, p.vLo];
            stairs(ax, tSig, ySig, 'b-', 'LineWidth', 1.8);

            % --- Phase labels ---
            yLbl = yTop - 0.3;
            if p.preOff >= 2
                text(ax, base + p.preOff/2, yLbl, 'OFF', ...
                    'HorizontalAlignment', 'center', 'FontSize', 10, ...
                    'Color', [0.5 0.5 0.5], 'FontWeight', 'bold');
            end
            if p.onWin >= 1
                text(ax, tPreEnd + p.onWin/2, yLbl, 'FLICKER', ...
                    'HorizontalAlignment', 'center', 'FontSize', 10, ...
                    'Color', [0.8 0.4 0], 'FontWeight', 'bold');
            end
            if p.postOff >= 2
                text(ax, tOnEnd + p.postOff/2, yLbl, 'OFF', ...
                    'HorizontalAlignment', 'center', 'FontSize', 10, ...
                    'Color', [0.5 0.5 0.5], 'FontWeight', 'bold');
            end

            % Collect boundaries:
            % - phase transitions (OFF <-> FLICKER)
            % - repeat junctions (OFF -> OFF) for repeat separation
            phaseBoundaries = [phaseBoundaries, tPreEnd, tOnEnd];
            repeatJunctionBoundaries = [repeatJunctionBoundaries, base, tPostEnd];
        end

        % Draw one line per unique OFF/FLICKER boundary.
        pb = unique(round(phaseBoundaries, 6));
        for xb = pb
            plot(ax, [xb xb], [yBot yTop], ...
                'LineStyle', ':', 'Color', [0.65 0.65 0.65], 'LineWidth', 0.9, ...
                'HandleVisibility', 'off');
        end

        % Draw one line per unique repeat junction (OFF -> OFF) with a distinct style.
        rb = unique(round(repeatJunctionBoundaries, 6));
        for xb = rb
            plot(ax, [xb xb], [yBot yTop], ...
                'LineStyle', '--', 'Color', [0.50 0.50 0.50], 'LineWidth', 1.0, ...
                'HandleVisibility', 'off');
        end

        hold(ax, 'off');
        ax.XLim = [-(totalViz*0.02) max(totalViz*1.02, 10)];
        ax.YLim = [yBot, yTop];
        xlabel(ax, 'Time (s)', 'FontWeight', 'bold');
        ylabel(ax, 'Level', 'FontWeight', 'bold');
        title(ax, sprintf('Stimulation Paradigm  (showing %d/%d repeat(s), %d cycles @ %.1f Hz)', ...
            nViz, p.nRepeats, p.n, p.freqHz), 'FontSize', 11, 'FontWeight', 'bold');
        ax.FontSize = 10;
        ax.XGrid = 'off'; ax.YGrid = 'off';
        ax.Box = 'on';

        % Figure title
        if p.isTrigger
            fig.Name = sprintf('Flicker - %d repeats, %d dummy, %.0f s total', ...
                p.nRepeats, p.nDummy, p.total);
        else
            fig.Name = sprintf('Flicker Stimulation - %d x %.0f s = %.0f s (%.1f min)', ...
                p.nRepeats, p.repDur, p.total, p.total/60);
        end
    end

% ═══════════════════════════════════════════════════════════════════
%  LOAD DEFAULTS
% ═══════════════════════════════════════════════════════════════════
    function loadDefaults()
        trigEnable.Value = true;
        trigLine.Value = 'port2/line0';
        trigDummy.Value = 8;
        trigTimeout.Value = 300;
        stimFields.f1.Value = 2.5;
        stimFields.f2.Value = 8;
        stimFields.f3.Value = 4;
        stimFields.f4.Value = 18;
        stimFields.f5.Value = 20;
        stimFields.f6.Value = 3;
        stimFields.f7.Value = 0;
        portDev.Value = 'Dev1';
        portAOut.Value = 'ao1';
        portDOut.Value = 'port2/line4';
        rbDigital.Value = true;
        updateViz();
        setStatus('Defaults loaded.');
        setInfo();
        setProgress(0);
    end

% ═══════════════════════════════════════════════════════════════════
%  SCRIPT GENERATION (File menu)
% ═══════════════════════════════════════════════════════════════════
    function generateScript()
        s = getParams(); p = calcStim(s);
        if p.isTrigger && p.isDigital; hint = 'trigger_ttl';
        elseif p.isTrigger && ~p.isDigital; hint = 'trigger_analog';
        elseif ~p.isTrigger && p.isDigital; hint = 'fixed_ttl';
        else; hint = 'fixed_analog'; end
        showPreviewDialog(fig, generateScriptText(p), ['flicker_' hint]);
    end

% ═══════════════════════════════════════════════════════════════════
%  INIT
% ═══════════════════════════════════════════════════════════════════
updateViz();
setStatus('Ready.');

end % flicker_gui


% ═══════════════════════════════════════════════════════════════════
%  LOCAL HELPERS
% ═══════════════════════════════════════════════════════════════════

function txt = generateScriptText(p)
isDigital = p.isDigital;
isTrigger = p.isTrigger;

if isDigital
    outDesc = '"Digital"'; hiStr = 'true(1, nLines)';
    loStr = 'false(1, nLines)'; loInit = 'lo';
else
    outDesc = '"Voltage"'; hiStr = 'V_hi';
    loStr = 'V_lo'; loInit = 'V_lo';
end

nl = newline; txt = '';
txt = [txt sprintf('%%%% Flicker - auto-generated (%s)', datestr(now)) nl];
txt = [txt sprintf('%%%% Device: %s, Output: %s', p.device, ...
    iif(p.isDigital, p.digPort, p.analogPort)) nl];
txt = [txt sprintf('%%%% Trigger: %s', iif(p.isTrigger, ...
    sprintf('%s (%d dummy)', p.trigLine, p.nDummy), 'none')) nl];
txt = [txt nl];

txt = [txt sprintf('freqHz  = %.2f;', p.freqHz) nl];
txt = [txt sprintf('preOff  = %.1f;', p.preOff) nl];
txt = [txt sprintf('onWin   = %.1f;', p.onWin) nl];
txt = [txt sprintf('postOff = %.1f;', p.postOff) nl];
txt = [txt sprintf('nRepeats= %d;', p.nRepeats) nl];
txt = [txt sprintf('V_hi = %.1f; V_lo = %.1f;', p.vHi, p.vLo) nl];
txt = [txt nl];
txt = [txt sprintf('T = 1/freqHz; nC = floor(onWin/T);') nl];
txt = [txt sprintf('ton = T/2; toff = T/2;') nl];
if isTrigger
    txt = [txt sprintf('to = %.0f; pd = 0.001; thr = 0.5; nd = %d;', ...
        p.timeout_s, p.nDummy) nl];
    txt = [txt sprintf('trigLine = "%s";', p.trigLine) nl];
end
txt = [txt nl];

txt = [txt sprintf('dqOut = daq("ni");') nl];
txt = [txt sprintf('addoutput(dqOut, "%s", "%s", %s);', ...
    p.device, iif(p.isDigital, p.digPort, p.analogPort), outDesc) nl];
if isDigital
    txt = [txt sprintf('nL = numel(dqOut.Channels); lo=false(1,nL); hi=true(1,nL);') nl];
end
txt = [txt sprintf('write(dqOut,%s);', loInit) nl];
txt = [txt sprintf('cleanupObj = onCleanup(@() writeSafe(dqOut,%s));', loInit) nl];
txt = [txt nl];

if isTrigger
    txt = [txt sprintf('dqIn = daq("ni");') nl];
    txt = [txt sprintf('addinput(dqIn, "%s", trigLine, "Digital");', p.device) nl];
    txt = [txt 'fprintf("Waiting for trigger...\n");' nl];
    txt = [txt 't0=tic; ph=readDigitalHigh(dqIn,thr); tr=false; pc=0;' nl];
    txt = [txt 'while toc(t0)<to' nl];
    txt = [txt '    drawnow("limitrate");' nl];
    txt = [txt '    ch=readDigitalHigh(dqIn,thr);' nl];
    txt = [txt '    if ~ph && ch' nl];
    txt = [txt '        pc=pc+1; if pc>nd, tr=true; break;' nl];
    txt = [txt '        else, fprintf("Dummy %d/%d\n",pc,nd); end' nl];
    txt = [txt '    end; ph=ch; pause(pd);' nl];
    txt = [txt 'end' nl];
    txt = [txt 'if~tr; error("No trigger"); end' nl];
    txt = [txt nl];
end

txt = [txt 'for r = 1:nRepeats' nl];
txt = [txt sprintf('    fprintf("Repeat %%d/%%d\\n",r,nRepeats);') nl];
txt = [txt sprintf('    write(dqOut,%s); pause(preOff);', loStr) nl];
txt = [txt sprintf('    for k = 1:nC') nl];
txt = [txt sprintf('        write(dqOut,%s); pause(ton);', hiStr) nl];
txt = [txt sprintf('        write(dqOut,%s); pause(toff);', loStr) nl];
txt = [txt sprintf('    end') nl];
txt = [txt sprintf('    write(dqOut,%s); pause(postOff);', loStr) nl];
txt = [txt 'end' nl];
txt = [txt sprintf('write(dqOut,%s);', loStr) nl];
txt = [txt 'clear cleanupObj; fprintf("Done.\n");' nl];
txt = [txt nl];
txt = [txt 'function writeSafe(dq,v); try write(dq,v); catch; end; end' nl];
txt = [txt 'function high=readDigitalHigh(dq,thr); high=readScalarDigital(dq)>thr; end' nl];
txt = [txt 'function x=readScalarDigital(dq); v=read(dq);' nl];
txt = [txt 'if isnumeric(v)||islogical(v), x=double(v(1));' nl];
txt = [txt 'elseif istable(v)||isa(v,"timetable"), a=table2array(v); x=double(a(1));' nl];
txt = [txt 'else, error("read(): unsupported type %%s",class(v)); end; end' nl];
end

function out = iif(cond, tVal, fVal)
if cond; out = tVal; else; out = fVal; end
end

function high = readDigitalHigh(dq, thr)
if nargin < 2
    thr = 0.5;
end
high = readScalarDigital(dq) > thr;
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

function showPreviewDialog(parentFig, scriptText, fname)
d = uifigure('Name', ['Script - ' fname], ...
    'Position', [200 150 720 540], ...
    'NumberTitle', 'off');
grid = uigridlayout(d, [3 1], 'RowHeight', {'1x', 36, 36}, 'Padding', [8 8 8 8]);
ta = uitextarea(grid, 'Value', scriptText, 'Editable', 'off', ...
    'FontName', 'Consolas', 'FontSize', 9, 'WordWrap', 'off');
btnRow = uigridlayout(grid, [1 3], 'ColumnWidth', {'1x', '1x', '1x'}, 'Padding', [0 0 0 0]);
uibutton(btnRow, 'push', 'Text', 'Save...', ...
    'ButtonPushedFcn', @(~,~) saveTheScript(d, scriptText), 'FontWeight', 'bold');
uibutton(btnRow, 'push', 'Text', 'Copy', ...
    'ButtonPushedFcn', @(~,~) copyTheScript(d, ta), 'FontWeight', 'bold');
uibutton(btnRow, 'push', 'Text', 'Close', ...
    'ButtonPushedFcn', @(~,~) delete(d));
end

function saveTheScript(fig, text)
[file, path] = uiputfile('*.m', 'Save');
if isequal(file, 0); return; end
fid = fopen(fullfile(path, file), 'w');
if fid == -1; uialert(fig, 'Cannot write file.', 'Error'); return; end
fprintf(fid, '%s', text); fclose(fid);
uialert(fig, sprintf('Saved:\n%s', fullfile(path, file)), 'Saved', 'Icon', 'success');
end

function copyTheScript(~, ta)
clipboard('copy', strjoin(ta.Value, newline));
end
