function rep = ot_report(data, res, outdir)
%OT_REPORT Build figures and HTML report (NIST CSF 2.0 + NIS2).
if nargin < 3, outdir = pwd; end
if ~isfolder(outdir), mkdir(outdir); end
tt = data.time;

% ---------- Figure A: telemetry with attack windows ----------
fA = figure('Visible','off','Position',[100 100 1100 820],'Color','w');
tl = tiledlayout(fA,4,1,'TileSpacing','compact','Padding','compact');
title(tl,'Fjarrvarme - OT-telemetri med markerade attackfonster','FontWeight','bold');
ax1 = nexttile(tl); plotSig(ax1, tt,[data.Tsupply data.Tsp],{'Framledning','Borvarde'},'\circC');
ax2 = nexttile(tl); plotSig(ax2, tt, data.Treturn,{'Returtemp'},'\circC');
ax3 = nexttile(tl); plotSig(ax3, tt, data.flow,{'Flode'},'m^3/h');
ax4 = nexttile(tl); plotSig(ax4, tt, data.pump,{'Pumpvarvtal'},'%');
shadeAttacks([ax1 ax2 ax3 ax4], data, tt);
exportgraphics(fA, fullfile(outdir,'fig_telemetry.png'),'Resolution',130); close(fA);

% ---------- Figure B: anomaly score + detections ----------
fB = figure('Visible','off','Position',[100 100 1100 430],'Color','w');
ax = axes(fB); hold(ax,'on');
for k = 1:numel(data.incidents)
    xregion(ax, tt(data.incidents(k).i0), tt(data.incidents(k).i1), ...
        'FaceColor',[1 0.55 0.55],'FaceAlpha',0.25);
end
plot(ax, tt, max(res.d2,1e-3), 'LineWidth',1.0, 'Color',[0 0.45 0.74]);
yline(ax, res.thr, '--', 'Larmtroskel','Color',[0.85 0.1 0.1],'LineWidth',1.2);
al = res.alarm;
scatter(ax, tt(al), max(res.d2(al),1e-3), 9, [0.85 0.1 0.1],'filled');
set(ax,'YScale','log'); grid(ax,'on');
ylabel(ax,'Anomali-score (Mahalanobis^2)');
title(ax,'Avvikelsedetektion mot inlard normalprofil');
legend(ax,{'Attackfonster','Score','Larmtroskel','Larm'},'Location','northwest','NumColumns',2);
exportgraphics(fB, fullfile(outdir,'fig_detection.png'),'Resolution',130); close(fB);

% ---------- Figure C: risk heatmap ----------
risk = ot_risk();
fC = figure('Visible','off','Position',[100 100 760 600],'Color','w');
ax = axes(fC); M = (1:5)'.*(1:5);
imagesc(ax,1:5,1:5,M); set(ax,'YDir','normal'); hold(ax,'on');
colormap(ax, riskColors()); clim(ax,[1 25]);
for s = 1:numel(risk.scenarios)
    plot(ax,risk.likelihood(s),risk.consequence(s),'o','MarkerEdgeColor','k', ...
        'MarkerFaceColor','w','MarkerSize',11,'LineWidth',1.4);
    text(ax,risk.likelihood(s)+0.10,risk.consequence(s),sprintf('%d',s), ...
        'FontWeight','bold','FontSize',10);
end
xlabel(ax,'Sannolikhet (1-5)'); ylabel(ax,'Konsekvens (1-5)');
title(ax,'Risk- och sarbarhetsanalys: sannolikhet x konsekvens');
xticks(ax,1:5); yticks(ax,1:5); axis(ax,[0.5 5.5 0.5 5.5]);
exportgraphics(fC, fullfile(outdir,'fig_risk.png'),'Resolution',130); close(fC);

% ---------- HTML report ----------
htmlPath = fullfile(outdir,'OT_Security_Report.html');
fid = fopen(htmlPath,'w','n','UTF-8');
W = @(s) fprintf(fid,'%s\n',s);
W('<!doctype html><html lang="sv"><head><meta charset="utf-8">');
W('<title>OT Security Monitor - Fjarrvarme</title><style>');
W('body{font-family:Segoe UI,Arial,sans-serif;max-width:980px;margin:24px auto;color:#1b2733;padding:0 16px}');
W('h1{margin-bottom:0} h2{border-bottom:2px solid #1380a4;padding-bottom:4px;margin-top:34px;color:#0e5f7a}');
W('.sub{color:#5a6b78;margin-top:4px} .cards{display:flex;gap:12px;flex-wrap:wrap;margin:16px 0}');
W('.card{flex:1;min-width:150px;background:#f3f7f9;border:1px solid #d7e3e8;border-radius:8px;padding:12px}');
W('.card b{font-size:24px;color:#0e5f7a;display:block} table{border-collapse:collapse;width:100%;font-size:14px}');
W('th,td{border:1px solid #cfdbe2;padding:6px 8px;text-align:left} th{background:#0e5f7a;color:#fff}');
W('tr:nth-child(even){background:#f6fafb} img{max-width:100%;border:1px solid #d7e3e8;border-radius:6px}');
W('.ok{color:#177245;font-weight:bold}.miss{color:#b00020;font-weight:bold}.note{color:#5a6b78;font-size:13px}');
W('</style></head><body>');
W('<h1>OT Security Monitor &mdash; Fjarrvarme</h1>');
W(sprintf('<div class="sub">Demo projekt &middot; genererad %s</div>', ...
    char(string(datetime("now"),'yyyy-MM-dd HH:mm'))));

W('<div class="cards">');
W(sprintf('<div class="card"><b>%d</b>telemetri-sampel<br><span class="note">%.0f dygn @ %d min</span></div>', ...
    data.N, data.N*data.dt_min/1440, data.dt_min));
W(sprintf('<div class="card"><b>%d</b>injicerade incidenter</div>', numel(data.incidents)));
W(sprintf('<div class="card"><b>%d</b>detekterade handelser</div>', numel(res.events)));
W(sprintf('<div class="card"><b>%.0f%%</b>recall (tackning)</div>', 100*res.recall));
W(sprintf('<div class="card"><b>%.0f%%</b>precision</div>', 100*res.precision));
W('</div>');

W('<p>Systemet larmar normala fjarrvarmedrift fran en ren baslinjeperiod och ');
W('larmar darefter på avvikelser: multivariata avvikelser (Mahalanobis-avstånd), brutna ');
W('fysikaliska samband (t.ex. givarförfalskning) och forlorad telemetri (tillgänglighet). ');
W('Metodiken motsvarar en strukturerad risk- och sarbarhetsanalys samt kontinuerlig ');
W('overvakning enligt NIST CSF 2.0 och kraven i NIS2/cybersakerhetslagen.</p>');

W('<h2>1. OT-telemetri och attacker</h2>');
W('<img src="fig_telemetry.png" alt="telemetri">');
W('<h2>2. Avvikelsedetektion</h2>');
W('<img src="fig_detection.png" alt="detektion">');
W(sprintf('<p class="note">Detektionskvalitet mot facit: recall %.0f%%, precision %.0f%%, F1 %.2f.</p>', ...
    100*res.recall, 100*res.precision, res.f1));

% Incident table with NIS2 deadlines
W('<h2>3. Incidenter och NIS2-rapporteringsfrister</h2>');
W('<table><tr><th>#</th><th>Scenario</th><th>CSF</th><th>Allvar</th><th>Detektionstid</th>');
W('<th>Tidig varning (24h)</th><th>Anmälan (72h)</th><th>Slutrapport (1 man)</th><th>Status</th></tr>');
for k = 1:numel(data.incidents)
    c = data.incidents(k);
    tdet = tt(c.i0);
    det  = any(res.alarm(c.i0:c.i1));
    stat = '<span class="ok">Detekterad</span>'; if ~det, stat='<span class="miss">Missad</span>'; end
    W(sprintf(['<tr><td>%d</td><td>%s</td><td>%s</td><td>%d/5</td><td>%s</td>' ...
        '<td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>'], k, c.name, c.csf, c.severity, ...
        fmt(tdet), fmt(tdet+hours(24)), fmt(tdet+hours(72)), fmt(tdet+calmonths(1)), stat));
end
W('</table>');
W('<p class="note">NIS2/cybersäkerhetslagen: tidig varning inom 24 timmar, incidentanmälan ');
W('inom 72 timmar och slutrapport inom en månad till MSB for vasentlig verksamhet.</p>');

% Risk
W('<h2>4. Risk- och sarbarhetsanalys</h2>');
W('<img src="fig_risk.png" alt="risk">');
W('<table><tr><th>#</th><th>Scenario</th><th>CSF</th><th>Sannolikhet</th><th>Konsekvens</th><th>Riskvarde</th></tr>');
for s = 1:numel(risk.scenarios)
    W(sprintf('<tr><td>%d</td><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%d</td></tr>', ...
        s, risk.scenarios(s), risk.csf(s), risk.likelihood(s), risk.consequence(s), risk.score(s)));
end
W('</table>');

% CSF mapping
W('<h2>5. Koppling till NIST CSF 2.0</h2>');
W('<table><tr><th>Funktion</th><th>Hur projektet adresserar den</th></tr>');
W('<tr><td>GOVERN</td><td>Riskaptit och prioritering via risk-/sarbarhetsanalysen; leverantorsrisk (GV.SC).</td></tr>');
W('<tr><td>IDENTIFY</td><td>Tillgangs- och dataflodeskartlaggning (IT/OT), riskbedomning per scenario.</td></tr>');
W('<tr><td>PROTECT</td><td>Rekommendationer: segmentering IT/OT, MFA, harden styrsystem, immutable backup.</td></tr>');
W('<tr><td>DETECT</td><td>Kontinuerlig overvakning och avvikelsedetektion (denna monitor).</td></tr>');
W('<tr><td>RESPOND</td><td>Incidentklassning, allvarsgrad och NIS2-rapporteringsfrister.</td></tr>');
W('<tr><td>RECOVER</td><td>Atgardsforslag och kontinuitet vid tillganglighetsstorning.</td></tr></table>');

% Recommendations
W('<h2>6. Rekommenderade atgarder (NIST ransomware-profil)</h2><ul>');
W('<li>Offline/immutabla och testade sakerhetskopior av styrsystem och historik.</li>');
W('<li>Segmentering och zero-trust mellan kontorsnat (IT) och produktionsnat (OT).</li>');
W('<li>Phishing-resistent MFA och least privilege for atkomst till styrsystem.</li>');
W('<li>Kontinuerlig overvakning av natverk, endpoints och givarsignaler.</li>');
W('<li>Ovad incidenthanterings- och aterstallningsplan med out-of-band-kommunikation.</li></ul>');

W('<p class="note">Obs: syntetisk data for demonstration. Modellen ar forenklad och visar ');
W('metodik och arbetssatt.</p>');
W('</body></html>');
fclose(fid);

rep.html = htmlPath;
rep.figs = {fullfile(outdir,'fig_telemetry.png'), fullfile(outdir,'fig_detection.png'), ...
            fullfile(outdir,'fig_risk.png')};
end

% ---------------- local helpers ----------------
function plotSig(ax, tt, Y, names, ylab)
plot(ax, tt, Y, 'LineWidth',1.0); grid(ax,'on');
ylabel(ax, ylab); legend(ax, names, 'Location','northeast','FontSize',8);
end

function shadeAttacks(axArr, data, tt)
for a = 1:numel(axArr)
    for k = 1:numel(data.incidents)
        xregion(axArr(a), tt(data.incidents(k).i0), tt(data.incidents(k).i1), ...
            'FaceColor',[1 0.55 0.55],'FaceAlpha',0.20,'HandleVisibility','off');
    end
end
end

function c = riskColors()
n = 256;
r = linspace(0.20,0.85,n)';
g = linspace(0.62,0.14,n)';
b = linspace(0.25,0.16,n)';
c = [r g b];
end

function s = fmt(dt)
s = char(string(dt,'yyyy-MM-dd HH:mm'));
end
