function rep = ot_access_report(alog, res, outdir)
%OT_ACCESS_REPORT Figures + HTML for the UEBA / confidentiality demo.
if nargin < 3, outdir = fullfile(fileparts(mfilename('fullpath')),'output'); end
if ~isfolder(outdir), mkdir(outdir); end
acfg = alog.Properties.UserData;
[uu,~,uy] = unique(alog.user,'stable');
nU = numel(uu);
al = res.alarm; x = alog.time;

% ---- Fig 1: access timeline (marker size ~ data volume) ----------------
f1 = figure('Visible','off','Color','w','Position',[60 60 1180 520]);
ax = axes(f1); hold(ax,'on'); grid(ax,'on');
sz = 16 + 70*(alog.vol/max(alog.vol));
nrm = ~al;
scatter(ax,x(nrm),uy(nrm),sz(nrm),[0.20 0.45 0.80],'filled','MarkerFaceAlpha',0.45);
scatter(ax,x(al), uy(al), sz(al)+25,[0.85 0.12 0.12],'filled');
set(ax,'YTick',1:nU,'YTickLabel',uu,'TickLabelInterpreter','none');
ylim(ax,[0.5 nU+0.5]);
title(ax,'Atkomsthandelser per konto  -  rott = UEBA-larm  (markstorlek ~ datavolym)');
xlabel(ax,'Tid'); legend(ax,{'Normal','Larm'},'Location','northoutside','Orientation','horizontal');
exportgraphics(f1, fullfile(outdir,'fig_access_timeline.png'),'Resolution',130); close(f1);

% ---- Fig 2: UEBA anomaly score over time -------------------------------
f2 = figure('Visible','off','Color','w','Position',[60 60 1180 480]);
ax = axes(f2); hold(ax,'on'); grid(ax,'on');
scatter(ax,x(~al),max(res.d2(~al),0.1),14,[0.45 0.6 0.85],'filled','MarkerFaceAlpha',0.5);
yline(ax,res.thr,'--','Larmtroskel','Color',[0.85 0.1 0.1],'LineWidth',1.1);
scatter(ax,x(al),res.d2(al),48,[0.85 0.12 0.12],'filled');
set(ax,'YScale','log');
ylabel(ax,'UEBA-score (Mahalanobis + nyhet)'); xlabel(ax,'Tid');
title(ax,'UEBA-score per atkomsthandelse');
% annotate flagged with threat type
idx = find(al);
for i = 1:numel(idx)
    k = idx(i);
    text(ax,x(k),res.d2(k)*1.15,shortType(res.pred(k)),'FontSize',7, ...
        'Rotation',25,'Color',[0.5 0 0],'Interpreter','none');
end
exportgraphics(f2, fullfile(outdir,'fig_ueba_scores.png'),'Resolution',130); close(f2);

% ---- Fig 3: user x resource access heatmap (with novelty markers) -------
R = acfg.resources; nR = numel(R);
M = zeros(nU,nR);
for i = 1:height(alog)
    ri = find(R==alog.resource(i),1); if ~isempty(ri), M(uy(i),ri)=M(uy(i),ri)+1; end
end
f3 = figure('Visible','off','Color','w','Position',[60 60 1080 520]);
ax = axes(f3); imagesc(ax,M); hold(ax,'on');
colormap(ax,flipud(gray)); cb=colorbar(ax); cb.Label.String='Antal atkomster';
set(ax,'XTick',1:nR,'XTickLabel',R,'XTickLabelRotation',35, ...
    'YTick',1:nU,'YTickLabel',uu,'TickLabelInterpreter','none');
title(ax,'Beteendebaslinje: konto x resurs  (O = out-of-role-larm)');
for k = find(al & res.resNov).'
    ri = find(R==alog.resource(k),1);
    plot(ax,ri,uy(k),'o','MarkerSize',16,'LineWidth',2.2,'Color',[0.85 0.1 0.1]);
end
exportgraphics(f3, fullfile(outdir,'fig_access_matrix.png'),'Resolution',130); close(f3);

% ---- HTML summary ------------------------------------------------------
html = fullfile(outdir,'OT_UEBA.html');
fid = fopen(html,'w');
fprintf(fid,'<html><head><meta charset="utf-8"><title>UEBA</title></head><body style="font-family:Segoe UI,Arial">');
fprintf(fid,'<h2>UEBA - konfidentialitet (normala varden i fel hander)</h2>');
fprintf(fid,'<p>Handelser: %d &nbsp;|&nbsp; Larm: %d &nbsp;|&nbsp; Recall %.0f%% &nbsp; Precision %.0f%% &nbsp; F1 %.2f</p>', ...
    height(alog), nnz(al), 100*res.recall, 100*res.precision, res.f1);
fprintf(fid,'<table border="1" cellpadding="5" cellspacing="0"><tr>');
fprintf(fid,'<th>Tid</th><th>Konto</th><th>Resurs</th><th>Atgard</th><th>MB</th><th>Score</th><th>Klassad som</th></tr>');
for i = 1:height(res.events)
    e = res.events(i,:);
    fprintf(fid,'<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%.1f</td><td>%s</td></tr>', ...
        char(string(e.time,'yyyy-MM-dd HH:mm')), e.user, e.resource, e.action, e.volMB, e.score, e.predType);
end
fprintf(fid,'</table></body></html>'); fclose(fid);

rep.figs = ["fig_access_timeline.png","fig_ueba_scores.png","fig_access_matrix.png"];
rep.html = html;
end

function s = shortType(t)
switch t
    case "Stulna inloggningsuppgifter", s="Stulna uppg.";
    case "Privilegiemissbruk",          s="Priv.missbruk";
    case "Dataexfiltrering",            s="Exfiltrering";
    case "Insidermissbruk",             s="Insider";
    otherwise,                          s=char(t);
end
end
