function manual_flicker_nidaq()
% Manual NI-DAQ TTL control for flicker device
% Edit dev/line to match your NI mapping.

dev  = "Dev1";
line = "port0/line0";   % <- change to your flicker output line

port = 'ao1';

dq = daq("ni");
% addoutput(dq, dev, line, "Digital");


addoutput(dq, dev, port, "Voltage");

% Always start OFF
write(dq, 0);
fprintf("Connected to %s %s\n", dev, line);
fprintf("Commands: on, off, pulse <ms>, flicker <Hz> <sec>, quit\n");

while true
    cmd = strtrim(lower(input(">> ", "s")));
    if isempty(cmd), continue; end

    parts = split(cmd);
    key = parts{1};

    switch key
        case "on"
            write(dq, 1);
            fprintf("ON\n");

        case "off"
            write(dq, 0);
            fprintf("OFF\n");

        case "pulse"
            if numel(parts) < 2, fprintf("Usage: pulse <ms>\n"); continue; end
            ms = str2double(parts{2});
            if isnan(ms) || ms <= 0, fprintf("Invalid ms\n"); continue; end
            write(dq, 1); pause(ms/1000); write(dq, 0);
            fprintf("Pulse %.1f ms\n", ms);

        case "flicker"
            if numel(parts) < 3
                fprintf("Usage: flicker <Hz> <sec>\n");
                continue;
            end
            hz = str2double(parts{2});
            dur = str2double(parts{3});
            if isnan(hz) || isnan(dur) || hz <= 0 || dur <= 0
                fprintf("Invalid flicker args\n");
                continue;
            end
            T = 1/hz;
            n = floor(dur/T);
            ton = T/2; toff = T/2;
            fprintf("Flicker %.3f Hz for %.3f s (%d cycles)\n", hz, dur, n);
            for k = 1:n
                write(dq, 3); pause(ton);
                write(dq, 0); pause(toff);
            end
            write(dq, 0);
            fprintf("Done flicker\n");

        case {"quit","exit","q"}
            write(dq, 0);
            fprintf("Exit\n");
            break;

        otherwise
            fprintf("Unknown command\n");
    end
end
end