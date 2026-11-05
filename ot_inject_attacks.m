function data = ot_inject_attacks(data)
%OT_INJECT_ATTACKS Inject four OT attack scenarios with ground-truth labels.
N = data.N; dt = data.dt_min; S = data.cfg;
trainEnd = round(S.train_frac*N);
H = @(h) trainEnd + round(h*60/dt);     % index h hours into the "live" period
inc = data.incidents;
add = @(name,i0,i1,type,csf,sev) struct('name',name,'i0',i0,'i1',i1, ...
        'type',type,'csf',csf,'severity',sev);

% 1) Sensor spoofing / false data injection
%    Supply-temp sensor is forged to look on-setpoint while the real process drifts.
i0 = H(6); i1 = H(11);
drift = linspace(0,12,i1-i0+1)';
data.Tsupply(i0:i1) = data.Tsp(i0:i1) - 1.0;          % forged "all good" reading
data.Treturn(i0:i1) = data.Treturn(i0:i1) + drift;     % real heat leaks into return temp
data.labels(i0:i1) = 1;
inc(end+1) = add("Sensor spoofing (false data injection)", i0, i1, ...
    "Manipulerad givare", "DE.AE / PR.DS", 4);

% 2) Command injection (unauthorised setpoint change) -> overheating
i0 = H(28); i1 = H(31);
data.Tsupply(i0:i1) = data.Tsupply(i0:i1) + linspace(8,22,i1-i0+1)';
data.press(i0:i1)   = data.press(i0:i1) + 0.8;
data.labels(i0:i1)  = 1;
inc(end+1) = add("Command injection (andrat borvarde)", i0, i1, ...
    "Obehorig styrning", "RS.MA / PR.AA", 5);

% 3) Replay attack: yesterday's flow/pump replayed onto the live signal
i0 = H(50); i1 = H(54);
src = i0 - round(24*60/dt);
n = i1 - i0;
data.flow(i0:i1) = data.flow(src:src+n);
data.pump(i0:i1) = data.pump(src:src+n);
data.labels(i0:i1) = 1;
inc(end+1) = add("Replay attack (uppspelning av historik)", i0, i1, ...
    "Replay", "DE.CM / PR.AA", 3);

% 4) Ransomware-like OT disruption: erratic pump, pressure spikes, telemetry gaps
i0 = H(80); i1 = H(86);
m = (0:i1-i0)';
data.pump(i0:i1)  = min(100, max(0, 50 + 40*sin(2*pi*m/3) + 20*randn(numel(m),1)));
data.press(i0:i1) = data.press(i0:i1) + 1.2*abs(randn(numel(m),1));
drop = (i0+round(0.4*(i1-i0))) : (i0+round(0.5*(i1-i0)));
data.flow(drop)    = NaN;     % lost telemetry
data.Tsupply(drop) = NaN;
data.labels(i0:i1) = 1;
inc(end+1) = add("Ransomware-like OT disruption", i0, i1, ...
    "Tillganglighetsstorning", "RC.RP / DE.CM", 5);

data.incidents = inc;
end
