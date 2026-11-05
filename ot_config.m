function cfg = ot_config()
%OT_CONFIG Parameters for the District-Heating OT Security Monitor demo.
cfg.seed         = 42;
cfg.dt_min       = 5;            % sampling interval [minutes]
cfg.N            = 7*24*12;      % 7 days @ 5 min = 2016 samples
cfg.Tout_mean    = 1;            % mean outdoor temp [C] (winter)
cfg.Tout_amp     = 5;            % daily outdoor swing [C]
cfg.Tout_ref     = 17;          % reference indoor temp for demand [C]
cfg.demand_base  = 12;          % base heat demand [MW]
cfg.demand_gain  = 1.1;         % demand rise per degree colder
cfg.Tsupply_min  = 70;          % supply temp limits [C]
cfg.Tsupply_max  = 110;
cfg.curve_b      = 88;          % heating curve intercept
cfg.curve_k      = 1.6;         % heating curve slope
cfg.dT_design    = 38;          % design supply-return delta [C]
cfg.flow_base    = 800;         % base flow [m3/h]
cfg.press_base   = 6;           % base pressure [bar]
cfg.track_a      = 0.85;        % supply-temp tracking inertia (AR1)
cfg.train_frac   = 0.40;        % first 40% = clean baseline for learning
cfg.alarm_quantile = 0.999;     % Mahalanobis alarm threshold (training quantile)
cfg.resid_k      = 5;           % physics-residual sigma multiplier
end
