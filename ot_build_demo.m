function mdl = ot_build_demo(open_it)
%OT_BUILD_DEMO Streaming Simulink security demo using MATLAB Function blocks.
%  Plant telemetry -> AttackInjector -> Detector (Mahalanobis) -> scopes/alarm.
%  The detector baseline (mu, inverse covariance, threshold) is learned in
%  MATLAB and baked into the Detector block. Build with: ot_build_demo
if nargin < 1, open_it = true; end
here = fileparts(mfilename('fullpath')); addpath(here);

% ---- learn baseline + prepare streaming telemetry ----
cfg = ot_config(); d = ot_simulate(cfg);
N = d.N;
X = [d.Tsupply, d.Treturn, d.flow, d.pump, d.press];   % 5 channels
tr = 1:round(cfg.train_frac*N);
mu = mean(X(tr,:));
C  = cov(X(tr,:)) + 1e-6*eye(5);
Sinv = inv(C);
dm = sum(((X(tr,:)-mu)*Sinv).*(X(tr,:)-mu), 2);
thr = locQuantile(dm, 0.999);

tsec = (0:N-1)';
assignin('base','otTel', timeseries(X, tsec));   % From Workspace source
assignin('base','otN', N);

% ---- build model ----
mdl = 'ot_security_demo';
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl);

add_block('simulink/Sources/From Workspace',[mdl '/Telemetri'], ...
    'VariableName','otTel','Interpolate','off','OutputAfterFinalValue','Holding final value', 'Position',[40 90 130 130]);
add_block('simulink/Sources/Clock',[mdl '/Tid'], 'Position',[40 190 70 220]);
add_block('simulink/User-Defined Functions/MATLAB Function',[mdl '/AttackInjector'], ...
    'Position',[190 85 320 165]);
add_block('simulink/User-Defined Functions/MATLAB Function',[mdl '/Detector'], ...
    'Position',[400 95 530 175]);
add_block('simulink/Sinks/Scope',[mdl '/Telemetri_scope'], 'Position',[600 70 640 110]);
add_block('simulink/Sinks/Scope',[mdl '/Anomali_score'],   'Position',[600 150 640 190]);
add_block('simulink/Sinks/Display',[mdl '/LARM'],          'Position',[600 230 670 260]);
add_block('simulink/Sinks/To Workspace',[mdl '/score_out'], ...
    'VariableName','otScore','SaveFormat','Timeseries','Position',[600 300 680 330]);

% ---- MATLAB Function block code (baseline baked into Detector) ----
setChart(mdl,'AttackInjector', injectorCode());
setChart(mdl,'Detector', detectorCode(mu, Sinv, thr));

% ---- wiring ----
add_line(mdl,'Telemetri/1','AttackInjector/1','autorouting','on');
add_line(mdl,'Tid/1','AttackInjector/2','autorouting','on');
add_line(mdl,'AttackInjector/1','Detector/1','autorouting','on');
add_line(mdl,'AttackInjector/1','Telemetri_scope/1','autorouting','on');
add_line(mdl,'Detector/1','Anomali_score/1','autorouting','on');
add_line(mdl,'Detector/1','score_out/1','autorouting','on');
add_line(mdl,'Detector/2','LARM/1','autorouting','on');

set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'FixedStep','1','StopTime',num2str(N-1));

slx = fullfile(here,[mdl '.slx']);
save_system(mdl, slx);
if open_it, open_system(mdl); end
fprintf('Simulink security demo saved: %s\n', slx);
fprintf('Tryck Run i Simulink for att se telemetri, anomali-score och LARM live.\n');
end

% ================= helpers =================
function setChart(mdl, blk, code)
rt = sfroot;
ch = rt.find('-isa','Stateflow.EMChart','-and','Path',[mdl '/' blk]);
ch.Script = code;
end

function c = injectorCode()
c = sprintf([ ...
'function y = AttackInjector(u, t)\n' ...
'%%#codegen\n' ...
'%% Live attack injection (simulated effects only)\n' ...
'y = u;\n' ...
'if t>=900 && t<=1000\n' ...
'    y(1) = 88;            %% sensor spoofing: forged supply temp\n' ...
'elseif t>=1150 && t<=1200\n' ...
'    y(1) = u(1) + 20;     %% command injection: overheating\n' ...
'elseif t>=1780 && t<=1840\n' ...
'    y(4) = 50 + 40*sin(2*pi*t/3);   %% ransomware: erratic pump\n' ...
'    y(5) = u(5) + 1.5;              %% pressure spike\n' ...
'end\n' ...
'end\n']);
end

function c = detectorCode(mu, Sinv, thr)
c = sprintf([ ...
'function [score, alarm] = Detector(u)\n' ...
'%%#codegen\n' ...
'%% Online Mahalanobis-distance detector (baseline learned offline)\n' ...
'mu = %s;\n' ...
'Sinv = %s;\n' ...
'thr = %g;\n' ...
'dv = u(:).'' - mu;\n' ...
'score = dv * Sinv * dv.'';\n' ...
'alarm = double(score > thr);\n' ...
'end\n'], mat2str(mu,6), mat2str(Sinv,6), thr);
end

function q = locQuantile(x, p)
x = sort(x(~isnan(x))); n = numel(x);
if n==0, q = Inf; return; end
pos = max(1, min(n, p*(n-1)+1)); lo = floor(pos); hi = ceil(pos);
q = x(lo) + (pos-lo)*(x(hi)-x(lo));
end
