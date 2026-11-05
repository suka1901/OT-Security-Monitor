function rep = ot_threat(data, outdir)
%OT_THREAT Defensive phishing->ransomware demonstration.
%  Generates SIMULATED IT-side indicator counts (failed logins, anomalous
%  east-west connections, mass file-renames), detects the escalation, draws a
%  kill-chain timeline (ATT&CK for ICS) and writes a Swedish threat report.
%  No functional malware/phishing -- counts only, on the defender side.
if nargin < 2, outdir = pwd; end
if ~isfolder(outdir), mkdir(outdir); end
N = data.N; dt = data.dt_min; tt = data.time; S = data.cfg;
trainEnd = round(S.train_frac*N);
H = @(h) min(N, max(1, trainEnd + round(h*60/dt)));
rng(7);

% ---- simulated IT-side indicators (counts) ----
fl = max(0, round(0.3*abs(randn(N,1))));     % failed logins
ew = max(0, round(0.8*abs(randn(N,1))));     % anomalous east-west connections
fr = zeros(N,1);                              % mass file-rename events

a = H(58); b = H(62); n = b-a+1;
fl(a:b) = fl(a:b) + round(linspace(4,14,n)') + round(2*abs(randn(n,1)));
a = H(70); b = H(76); n = b-a+1;
ew(a:b) = ew(a:b) + round(linspace(6,18,n)') + round(2*abs(randn(n,1)));
a = H(80); b = H(86); n = b-a+1;
fr(a:b) = round(linspace(20,180,n)') + round(8*abs(randn(n,1)));

% ---- baseline detection (mean + k*std on the clean training window) ----
tr = 1:trainEnd;
thr = @(x) mean(x(tr)) + 6*std(x(tr)) + 1;
tfl = thr(fl); tew = thr(ew); tfr = thr(fr);
alarm = (fl>tfl) | (ew>tew) | (fr>tfr);

rep.indicators = struct('time',tt,'failedLogins',fl,'eastWest',ew, ...
    'fileRenames',fr,'alarm',alarm,'thr',[tfl tew tfr]);

% ---- Figure: kill-chain timeline ----
kc = ot_killchain();
cmap = [0.20 0.55 0.85; 0.30 0.50 0.75; 0.65 0.45 0.30; 0.80 0.35 0.25; 0.75 0.15 0.15];
fK = figure('Visible','off','Position',[100 100 1180 420],'Color','w');
ax = axes(fK); hold(ax,'on');
for i = 1:numel(kc)
    x0 = tt(H(kc(i).h0)); x1 = tt(H(kc(i).h1));
    plot(ax, [x0 x1], [i i], 'LineWidth', 12, 'Color', cmap(i,:));
    text(ax, x1, i, "   " + string(kc(i).name) + "  [" + string(kc(i).attack) + "]", ...
        'VerticalAlignment','middle','FontSize',8);
end
ylim(ax,[0.5 numel(kc)+1.5]); set(ax,'YTick',1:numel(kc),'YDir','reverse');
grid(ax,'on'); xlabel(ax,'Tid');
title(ax,'Phishing -> ransomware kill-chain (MITRE ATT&CK for ICS)');
exportgraphics(fK, fullfile(outdir,'fig_killchain.png'),'Resolution',130); close(fK);

% ---- Figure: IT-side indicators ----
fI = figure('Visible','off','Position',[100 100 1100 640],'Color','w');
tl = tiledlayout(fI,3,1,'TileSpacing','compact','Padding','compact');
title(tl,'Simulerade IT-indikatorer (defender-vy)','FontWeight','bold');
plotInd(nexttile(tl), tt, fl, tfl, 'Misslyckade inloggningar');
plotInd(nexttile(tl), tt, ew, tew, 'Avvikande ost-vast-anslutningar');
plotInd(nexttile(tl), tt, fr, tfr, 'Massfilomdopningar (kryptering)');
exportgraphics(fI, fullfile(outdir,'fig_indicators.png'),'Resolution',130); close(fI);

% ---- HTML threat report (Swedish) ----
htmlPath = fullfile(outdir,'OT_Threat_Report.html');
fid = fopen(htmlPath,'w','n','UTF-8'); W = @(s) fprintf(fid,'%s\n',s);
W('<!doctype html><html lang="sv"><head><meta charset="utf-8"><title>Hotrapport - phishing/ransomware</title><style>');
W('body{font-family:Segoe UI,Arial,sans-serif;max-width:980px;margin:24px auto;color:#1b2733;padding:0 16px}');
W('h1{margin-bottom:0}h2{border-bottom:2px solid #b00020;padding-bottom:4px;margin-top:32px;color:#8a0018}');
W('table{border-collapse:collapse;width:100%;font-size:14px}th,td{border:1px solid #cfdbe2;padding:6px 8px;text-align:left}');
W('th{background:#8a0018;color:#fff}tr:nth-child(even){background:#f7f3f4}img{max-width:100%;border:1px solid #d7e3e8;border-radius:6px}');
W('.note{color:#5a6b78;font-size:13px}.box{background:#fff4f4;border:1px solid #f0c8c8;border-radius:8px;padding:12px;margin:12px 0}');
W('</style></head><body>');
W('<h1>Hotrapport &mdash; phishing till ransomware</h1>');
W('<div class="note">Defensiv demonstration (simulerade indikatorer). Ingen funktionell skadlig kod.</div>');
W('<div class="box"><b>Scenario:</b> ett spearphishing-mejl ger angriparen fotfaste i IT-natet. ');
W('Stulna uppgifter anvands for sidledes rorelse mot OT, dar styrparametrar manipuleras och ');
W('tillgangligheten slas ut (ransomware). Malet ar att <b>upptacka tidigt</b> och bryta kedjan.</div>');

W('<h2>1. Kill-chain och ATT&amp;CK for ICS</h2>');
W('<img src="fig_killchain.png" alt="killchain">');
W('<table><tr><th>Steg</th><th>ATT&amp;CK for ICS</th><th>CSF 2.0</th><th>Forsvarsatgard</th></tr>');
for i = 1:numel(kc)
    W(sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', ...
        kc(i).name, kc(i).attack, kc(i).csf, kc(i).control));
end
W('</table>');

W('<h2>2. IT-indikatorer och tidig detektion</h2>');
W('<img src="fig_indicators.png" alt="indicators">');
W(sprintf('<p class="note">Larm pa %d av %d sampel. Eskalerande indikatorer (inloggningar -&gt; ', ...
    sum(alarm), N));
W('ost-vast-trafik -&gt; massfilomdopningar) ger forvarning innan OT-storningen intraffar, ');
W('vilket mojliggor inneslutning och NIS2-rapportering i tid.</p>');

W('<h2>3. Respons (NIST ransomware-profil + NIS2)</h2><ul>');
W('<li><b>Detect:</b> korrelera IT-indikatorer med OT-avvikelser (denna monitor).</li>');
W('<li><b>Respond:</b> isolera drabbade segment, aktivera IR-plan, out-of-band-kommunikation.</li>');
W('<li><b>NIS2:</b> tidig varning 24h, anmalan 72h, slutrapport 1 manad till MSB.</li>');
W('<li><b>Recover:</b> aterstall fran immutabla, testade backuper; verifiera integritet.</li>');
W('<li><b>Govern/Protect:</b> phishing-resistent MFA, segmentering IT/OT, allowlisting.</li></ul>');
W('<p class="note">Se aven OT_Security_Report.html och KILL_CHAIN_PLAYBOOK.md.</p>');
W('</body></html>'); fclose(fid);

rep.html = htmlPath;
rep.figs = {fullfile(outdir,'fig_killchain.png'), fullfile(outdir,'fig_indicators.png')};
rep.alarms = sum(alarm);
end

function plotInd(ax, tt, y, thr, name)
area(ax, tt, y, 'FaceColor',[0.2 0.45 0.74],'FaceAlpha',0.5,'EdgeColor',[0.1 0.3 0.6]);
hold(ax,'on'); yline(ax, thr, '--', 'Troskel','Color',[0.85 0.1 0.1],'LineWidth',1.1);
grid(ax,'on'); ylabel(ax,'antal'); legend(ax,{name},'Location','northwest','FontSize',8);
end
