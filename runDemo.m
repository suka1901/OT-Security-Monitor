function out = runDemo()
%RUNDEMO District-Heating OT Security Monitor - end-to-end demo.
here = fileparts(mfilename('fullpath'));
cfg  = ot_config();
data = ot_simulate(cfg);
data = ot_inject_attacks(data);
res  = ot_detect(data);

outdir = fullfile(here,'output');
if ~isfolder(outdir), mkdir(outdir); end
rep    = ot_report(data, res, outdir);
threat = ot_threat(data, outdir);
auto   = ot_autoreport(data);

fprintf('\n==== OT Security Monitor (fjarrvarme) - sammanfattning ====\n');
fprintf('Telemetri      : %d sampel (%.0f dygn @ %d min)\n', ...
        data.N, data.N*data.dt_min/1440, data.dt_min);
fprintf('Injicerade incidenter : %d\n', numel(data.incidents));
fprintf('Detekterade handelser : %d\n', numel(res.events));
fprintf('Recall %.0f%% | Precision %.0f%% | F1 %.2f\n', ...
        100*res.recall, 100*res.precision, res.f1);
fprintf('OT-rapport     : %s\n', rep.html);
fprintf('Hotrapport     : %s\n', threat.html);
fprintf('Autorapport    : %s\n', auto.html);
fprintf('Live-demo      : kor  ot_live   (eller  ot_live(2)  for snabbare)\n\n');

out.data = data; out.res = res; out.rep = rep; out.threat = threat; out.auto = auto;
if nargout == 0, clear out; end
end
