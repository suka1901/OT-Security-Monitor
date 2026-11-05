function OTSecurityMonitor()
%OTSECURITYMONITOR Interactive dashboard for the district-heating OT monitor.
here = fileparts(mfilename('fullpath')); addpath(here);
cfg = ot_config();

f = uifigure('Name','OT Security Monitor - Fjärrvarme','Position',[80 80 1120 700],'Color','w');
g = uigridlayout(f,[3 3]); g.RowHeight = {44,'1x','1x'}; g.ColumnWidth = {'2x','1x','1x'};

ttl = uilabel(g,'Text','OT Security Monitor  -  Fjärrvarme (demo)','FontSize',16,'FontWeight','bold');
ttl.Layout.Row = 1; ttl.Layout.Column = [1 2];
btn = uibutton(g,'Text','Kör analys','FontWeight','bold');
btn.Layout.Row = 1; btn.Layout.Column = 3;

ax1 = uiaxes(g); ax1.Layout.Row = 2; ax1.Layout.Column = [1 2]; title(ax1,'Telemetri'); grid(ax1,'on');
ax2 = uiaxes(g); ax2.Layout.Row = 3; ax2.Layout.Column = [1 2]; title(ax2,'Anomali-score'); grid(ax2,'on');

p  = uipanel(g,'Title','Resultat'); p.Layout.Row = [2 3]; p.Layout.Column = 3;
pg = uigridlayout(p,[7 1]);
labels = {'Incidenter: -','Detekterade: -','Recall: -','Precision: -','F1: -', ...
          'Rapport: (kör analys)',''};
lbl = gobjects(numel(labels),1);
for i = 1:numel(labels), lbl(i) = uilabel(pg,'Text',labels{i}); end

btn.ButtonPushedFcn = @(~,~) runAndShow();

    function runAndShow()
        btn.Enable = 'off'; lbl(7).Text = 'Kör...'; drawnow;
        d = ot_simulate(cfg); d = ot_inject_attacks(d); r = ot_detect(d);
        plot(ax1, d.time, [d.Tsupply d.Treturn], 'LineWidth',1);
        legend(ax1,{'Framledning','Retur'},'Location','northeast'); title(ax1,'Telemetri (\circC)');
        plot(ax2, d.time, max(r.d2,1e-3), 'LineWidth',1); set(ax2,'YScale','log');
        yline(ax2, r.thr, '--r'); title(ax2,'Anomali-score (Mahalanobis^2)');
        outdir = fullfile(here,'output'); if ~isfolder(outdir), mkdir(outdir); end
        ot_report(d, r, outdir);
        lbl(1).Text = sprintf('Incidenter: %d', numel(d.incidents));
        lbl(2).Text = sprintf('Detekterade: %d', numel(r.events));
        lbl(3).Text = sprintf('Recall: %.0f%%', 100*r.recall);
        lbl(4).Text = sprintf('Precision: %.0f%%', 100*r.precision);
        lbl(5).Text = sprintf('F1: %.2f', r.f1);
        lbl(6).Text = 'Rapport: output/OT_Security_Report.html';
        lbl(7).Text = 'Klar.';
        btn.Enable = 'on';
    end
end
