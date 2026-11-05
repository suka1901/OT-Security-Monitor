function data = ot_simulate(cfg)
%OT_SIMULATE Generate synthetic district-heating OT telemetry (normal operation).
if nargin < 1, cfg = ot_config(); end
rng(cfg.seed);
N = cfg.N; dt = cfg.dt_min;
t   = (0:N-1)'*dt/60;                 % time [hours]
day = t/24;

% Exogenous outdoor temperature: daily cycle + slow weather + noise
Tout = cfg.Tout_mean + cfg.Tout_amp*sin(2*pi*(t-6)/24) + 2*sin(2*pi*day/3.5) + 0.4*randn(N,1);

% Heat demand: colder -> more demand, with a morning/evening usage profile
demand = cfg.demand_base + cfg.demand_gain*(cfg.Tout_ref - Tout) ...
       + 1.2*sin(2*pi*(t-7)/24) + 0.6*randn(N,1);
demand = max(2, demand);

% Supply-temperature setpoint from the heating curve
Tsp = min(cfg.Tsupply_max, max(cfg.Tsupply_min, cfg.curve_b - cfg.curve_k*Tout));

% Supply temperature tracks setpoint with first-order inertia (stable)
Tsupply = zeros(N,1); Tsupply(1) = Tsp(1);
a = cfg.track_a;
for k = 2:N
    Tsupply(k) = a*Tsupply(k-1) + (1-a)*Tsp(k) + 0.2*randn;
end

% Normalised demand for flow/pump scaling
dn = (demand - min(demand)) / (max(demand) - min(demand) + eps);
flow = cfg.flow_base.*(0.45 + 0.55*dn) + 4*randn(N,1);  flow = max(50, flow);
pump = 20 + 70*dn + 1.5*randn(N,1);                     pump = min(100, max(0, pump));
Treturn = Tsupply - cfg.dT_design - 0.06*demand + 0.2*randn(N,1);
press   = cfg.press_base + 0.0025*(flow - cfg.flow_base) + 0.05*randn(N,1);

data.cfg = cfg; data.N = N; data.dt_min = dt;
data.t = t;
data.t0   = datetime(2026,1,12,0,0,0);
data.time = data.t0 + minutes((0:N-1)'*dt);
data.Tout = Tout; data.demand = demand; data.Tsp = Tsp;
data.Tsupply = Tsupply; data.Treturn = Treturn;
data.flow = flow; data.pump = pump; data.press = press;
data.labels = zeros(N,1);   % 0 = normal, 1 = under attack (ground truth)
data.incidents = struct('name',{},'i0',{},'i1',{},'type',{},'csf',{},'severity',{});
end
