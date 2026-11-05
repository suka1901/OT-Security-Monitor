function rep = ot_autoreport(data)
%OT_AUTOREPORT Automatiserat incidentrapporteringssystem (NIS2 + GDPR + sakerhetsskydd).
%  Klassar detekterade incidenter, beraknar lagstadgade tidsfrister och genererar
%  automatiskt: (1) incidentregister (CSV + HTML), (2) ifyllda anmalningar per incident,
%  (3) en oversiktsdashboard. Demonstration -- syntetisk data.
if nargin < 1
    cfg = ot_config(); data = ot_simulate(cfg); data = ot_inject_attacks(data);
end
here = fileparts(mfilename('fullpath'));
outdir = fullfile(here,'output'); if ~isfolder(outdir), mkdir(outdir); end
repdir = fullfile(outdir,'reports'); if ~isfolder(repdir), mkdir(repdir); end

org = "Energibolag AB (exempel)"; sektor = "Energi (fjarrvarme)";
kontakt = "Informationssakerhetssamordnare"; dpo = "Dataskyddsombud (DPO)";
inc = data.incidents; n = numel(inc);

% ---- klassning per incident ----
ID = strings(n,1); Scenario = strings(n,1); Allvar = zeros(n,1);
Detektion = NaT(n,1); NIS2_24h = NaT(n,1); NIS2_72h = NaT(n,1); NIS2_slut = NaT(n,1);
GDPR = strings(n,1); GDPR_72h = strings(n,1); Saksskydd = strings(n,1); Status = strings(n,1);
files = strings(n,1);

for k = 1:n
    c = inc(k);
    tdet = data.time(c.i0);
    isGDPR = contains(string(c.name),"Ransomware","IgnoreCase",true);   % dataexfiltrering
    isSaks = c.severity >= 5;                                            % allvarlig paverkan
    ID(k) = sprintf("INC-2026-%03d",k);
    Scenario(k) = string(c.name);
    Allvar(k) = c.severity;
    Detektion(k) = tdet;
    NIS2_24h(k) = tdet + hours(24);
    NIS2_72h(k) = tdet + hours(72);
    NIS2_slut(k) = tdet + calmonths(1);
    GDPR(k) = ternary(isGDPR,"Ja","Nej");
    GDPR_72h(k) = ternary(isGDPR, fmt(tdet+hours(72)), "-");
    Saksskydd(k) = ternary(isSaks,"Ja (skyndsamt)","Nej");
    Status(k) = "Oppen";
    files(k) = writeNotice(repdir, ID(k), c, tdet, org, sektor, kontakt, dpo, isGDPR, isSaks);
end

% ---- incidentregister (CSV) ----
T = table(ID, Scenario, Allvar, string(fmtv(Detektion)), string(fmtv(NIS2_24h)), ...
    string(fmtv(NIS2_72h)), string(fmtv(NIS2_slut)), GDPR, GDPR_72h, Saksskydd, Status, ...
    'VariableNames', {'IncidentID','Scenario','Allvar','Detekterad','NIS2_TidigVarning_24h', ...
    'NIS2_Anmalan_72h','NIS2_Slutrapport_1man','GDPR','GDPR_IMY_72h','Sakerhetsskydd','Status'});
csvPath = fullfile(outdir,'incident_register.csv');
writetable(T, csvPath);

% ---- dashboard: tidslinje for frister ----
fig = figure('Visible','off','Color','w','Position',[80 80 1150 460]);
ax = axes(fig); hold(ax,'on');
sevcol = @(s)[0.2+0.15*s, 0.6-0.1*s, 0.2];
for k = 1:n
    plot(ax,[Detektion(k) NIS2_72h(k)],[k k],'LineWidth',11,'Color',sevcol(min(5,Allvar(k))));
    plot(ax,NIS2_24h(k),k,'o','MarkerFaceColor','w','MarkerEdgeColor','k','MarkerSize',7);
    plot(ax,NIS2_slut(k),k,'s','MarkerFaceColor',[.85 .1 .1],'MarkerEdgeColor','k','MarkerSize',8);
    text(ax,Detektion(k),k+0.32,"  "+ID(k)+"  ("+Scenario(k)+")",'FontSize',8);
end
ylim(ax,[0.4 n+0.9]); set(ax,'YTick',1:n,'YDir','reverse'); grid(ax,'on');
xlabel(ax,'Tid'); title(ax,'Automatiska NIS2-rapporteringsfrister (o = 24h varning, linje = 72h anmalan, fyrkant = slutrapport 1 man)');
exportgraphics(fig, fullfile(outdir,'fig_deadlines.png'),'Resolution',130); close(fig);

% ---- oversikts-HTML ----
ovPath = fullfile(outdir,'OT_Autoreport.html');
fid = fopen(ovPath,'w','n','UTF-8'); W = @(s)fprintf(fid,'%s\n',s);
W('<!doctype html><html lang="sv"><head><meta charset="utf-8"><title>Automatiserad incidentrapportering</title><style>');
W('body{font-family:Segoe UI,Arial,sans-serif;max-width:1000px;margin:24px auto;color:#1b2733;padding:0 16px}');
W('h1{margin-bottom:0}h2{border-bottom:2px solid #0E5F7A;color:#0e5f7a;padding-bottom:4px;margin-top:30px}');
W('.cards{display:flex;gap:12px;flex-wrap:wrap;margin:14px 0}.card{flex:1;min-width:140px;background:#f3f7f9;border:1px solid #d7e3e8;border-radius:8px;padding:12px}');
W('.card b{font-size:24px;color:#0e5f7a;display:block}table{border-collapse:collapse;width:100%;font-size:13px}');
W('th,td{border:1px solid #cfdbe2;padding:5px 7px;text-align:left}th{background:#0e5f7a;color:#fff}tr:nth-child(even){background:#f6fafb}');
W('img{max-width:100%;border:1px solid #d7e3e8;border-radius:6px}.note{color:#5a6b78;font-size:12px}a{color:#0e5f7a}');
W('</style></head><body>');
W('<h1>Automatiserad incidentrapportering</h1>');
W(sprintf('<div class="note">%s &middot; %s &middot; genererad %s</div>', org, sektor, fmt(datetime("now"))));
W('<div class="cards">');
W(sprintf('<div class="card"><b>%d</b>incidenter</div>', n));
W(sprintf('<div class="card"><b>%d</b>NIS2-anmalningar</div>', n));
W(sprintf('<div class="card"><b>%d</b>GDPR (IMY)</div>', sum(GDPR=="Ja")));
W(sprintf('<div class="card"><b>%d</b>sakerhetsskydd</div>', sum(startsWith(Saksskydd,"Ja"))));
W(sprintf('<div class="card"><b>%s</b>narmaste 72h-deadline</div>', fmt(min(NIS2_72h))));
W('</div>');
W('<h2>Incidentregister</h2><table><tr><th>ID</th><th>Scenario</th><th>Allvar</th><th>Detekterad</th><th>NIS2 24h</th><th>NIS2 72h</th><th>Slutrapport</th><th>GDPR</th><th>Sak.skydd</th><th>Anmalan</th></tr>');
for k = 1:n
    W(sprintf(['<tr><td>%s</td><td>%s</td><td>%d/5</td><td>%s</td><td>%s</td><td>%s</td>' ...
        '<td>%s</td><td>%s</td><td>%s</td><td><a href="reports/%s">oppna</a></td></tr>'], ...
        ID(k), Scenario(k), Allvar(k), fmt(Detektion(k)), fmt(NIS2_24h(k)), fmt(NIS2_72h(k)), ...
        fmt(NIS2_slut(k)), GDPR(k), Saksskydd(k), basename(files(k))));
end
W('</table>');
W('<h2>Tidslinje for rapporteringsfrister</h2><img src="fig_deadlines.png" alt="deadlines">');
W('<h2>Om systemet</h2>');
W('<p>Vid detektion klassas varje incident automatiskt (typ, allvar, berorda regelverk), ');
W('tidsfrister beraknas och anmalningsdokument fylls i. NIS2/cybersakerhetslagen: tidig varning ');
W('inom 24 h, anmalan inom 72 h, slutrapport inom en manad till MSB. GDPR: anmalan till IMY inom ');
W('72 h vid personuppgiftsincident. Sakerhetsskydd: skyndsam anmalan till tillsynsmyndighet.</p>');
W('<p class="note">Syntetisk demonstration. Mallarna ar forenklade och ersatter inte officiella anmalningsformular.</p>');
W('</body></html>'); fclose(fid);

rep.html = ovPath; rep.csv = csvPath; rep.notices = files;
fprintf('Autorapportering klar: %d incidenter, %d GDPR, %d sakerhetsskydd.\n', n, sum(GDPR=="Ja"), sum(startsWith(Saksskydd,"Ja")));
fprintf('Oversikt: %s\n', ovPath);
end

% ================= helpers =================
function f = writeNotice(repdir, id, c, tdet, org, sektor, kontakt, dpo, isGDPR, isSaks)
f = fullfile(repdir, char(id)+"_anmalan.html");
fid = fopen(f,'w','n','UTF-8'); W = @(s)fprintf(fid,'%s\n',s);
W('<!doctype html><html lang="sv"><head><meta charset="utf-8"><title>'+string(id)+'</title><style>');
W('body{font-family:Segoe UI,Arial,sans-serif;max-width:820px;margin:24px auto;color:#1b2733;padding:0 16px}');
W('h2{color:#0e5f7a;border-bottom:1px solid #cfdbe2;padding-bottom:3px}dt{font-weight:bold;margin-top:6px}');
W('dd{margin:0 0 4px 0}.tag{display:inline-block;background:#0e5f7a;color:#fff;border-radius:4px;padding:1px 7px;font-size:12px}</style></head><body>');
W(sprintf('<h1>Incidentanmalan %s</h1>', id));
W(sprintf('<p><span class="tag">NIS2</span> %s <span class="tag">Allvar %d/5</span></p>', ...
    ternary(isGDPR,'<span class="tag">GDPR</span>',''), c.severity));
W('<h2>1. NIS2 / cybersakerhetslagen -- tidig varning (24h) och anmalan (72h)</h2><dl>');
W(sprintf('<dt>Verksamhet</dt><dd>%s -- %s</dd>', org, sektor));
W(sprintf('<dt>Kontakt</dt><dd>%s</dd>', kontakt));
W(sprintf('<dt>Incident-ID</dt><dd>%s</dd>', id));
W(sprintf('<dt>Upptackt</dt><dd>%s</dd>', fmt(tdet)));
W(sprintf('<dt>Typ</dt><dd>%s (%s)</dd>', c.name, c.type));
W(sprintf('<dt>CSF-funktion</dt><dd>%s</dd>', c.csf));
W('<dt>Preliminar bedomning</dt><dd>Misstankt angrepp mot OT/styrsystem; paverkan pa overvakning och leverans utreds.</dd>');
W('<dt>Gransoverskridande paverkan</dt><dd>Nej (bedoms preliminart)</dd>');
W(sprintf('<dt>Tidig varning (24h)</dt><dd>%s</dd>', fmt(tdet+hours(24))));
W(sprintf('<dt>Incidentanmalan (72h)</dt><dd>%s</dd>', fmt(tdet+hours(72))));
W(sprintf('<dt>Slutrapport (1 manad)</dt><dd>%s</dd>', fmt(tdet+calmonths(1))));
W('<dt>Mottagare</dt><dd>MSB</dd></dl>');
if isGDPR
    W('<h2>2. GDPR -- personuppgiftsincident (Art. 33, anmalan inom 72h)</h2><dl>');
    W(sprintf('<dt>Dataskyddsombud</dt><dd>%s</dd>', dpo));
    W('<dt>Kategorier av uppgifter</dt><dd>Kunduppgifter (faktura/matvarden) -- omfattning utreds.</dd>');
    W('<dt>Uppskattat antal registrerade</dt><dd>Utreds</dd>');
    W('<dt>Sannolika konsekvenser</dt><dd>Risk for konfidentialitetsforlust vid dataexfiltrering.</dd>');
    W('<dt>Atgarder</dt><dd>Inneslutning, aterstallning fran backup, forstarkt overvakning.</dd>');
    W(sprintf('<dt>Anmalan till IMY (72h)</dt><dd>%s</dd>', fmt(tdet+hours(72))));
    W('</dl>');
end
if isSaks
    W('<h2>3. Sakerhetsskydd -- skyndsam anmalan</h2><dl>');
    W('<dt>Bedomning</dt><dd>Handelsen kan ha betydelse for sakerhetskanslig verksamhet.</dd>');
    W('<dt>Atgard</dt><dd>Skyndsam anmalan till tillsynsmyndighet/Sakerhetspolisen.</dd></dl>');
end
W('<p style="color:#5a6b78;font-size:12px">Auto-genererad demonstration. Forenklad mall.</p>');
W('</body></html>'); fclose(fid);
end

function r = ternary(c,a,b), if c, r=a; else, r=b; end, end
function s = fmt(dt), s = char(string(dt,'yyyy-MM-dd HH:mm')); end
function v = fmtv(dts), v = strings(numel(dts),1); for i=1:numel(dts), v(i)=string(dts(i),'yyyy-MM-dd HH:mm'); end, end
function b = basename(p), [~,n,e]=fileparts(char(p)); b=[n e]; end
