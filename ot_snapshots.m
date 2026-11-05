function ot_snapshots()
%OT_SNAPSHOTS Save static PNGs of the live dashboard and the Simulink demo
%  for inclusion in the project report.
here = fileparts(mfilename('fullpath')); addpath(here);
outdir = fullfile(here,'output'); if ~isfolder(outdir), mkdir(outdir); end
cfg = ot_config(); d = ot_simulate(cfg); d = ot_inject_attacks(d); r = ot_detect(d);
x = d.t; al = r.alarm;

f = figure('Visible','off','Color','w','Position',[60 60 1200 680]);
tl = tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
title(tl,'OT Security Monitor - live-vy (slutlage)','FontWeight','bold');
ax1 = nexttile(tl); plot(ax1,x,[d.Tsupply d.Tsp],'LineWidth',1); grid(ax1,'on');
ylabel(ax1,'\circC'); legend(ax1,{'Framledning','Borvarde'},'Location','northwest','FontSize',8);
title(ax1,'Framledningstemp vs borvarde');
ax2 = nexttile(tl); semilogy(ax2,x,max(r.d2,1e-3),'LineWidth',1); hold(ax2,'on'); grid(ax2,'on');
yline(ax2,r.thr,'--','Larmtroskel','Color',[0.85 0.1 0.1]);
plot(ax2,x(al),max(r.d2(al),1e-3),'ro','MarkerFaceColor','r','MarkerSize',3);
ylabel(ax2,'Anomali-score'); xlabel(ax2,'Tid (timmar)'); title(ax2,'Anomali-score med larm');
ax3 = nexttile(tl); axis(ax3,'off');
on = find(diff([0;al])==1); lines = strings(0,1);
for i = 1:min(8,numel(on))
    k = on(i);
    lines(end+1) = string([char(string(d.time(k),'yyyy-MM-dd HH:mm')) '   LARM: ' evt(r,k)]); %#ok<AGROW>
end
text(ax3,0.01,0.95,'STATUS: KLAR - uppspelning slutford','FontSize',13,'FontWeight','bold','Units','normalized');
text(ax3,0.01,0.72,strjoin(lines,newline),'FontSize',9,'FontName','Consolas', ...
    'VerticalAlignment','top','Units','normalized');
exportgraphics(f, fullfile(outdir,'fig_live.png'),'Resolution',130); close(f);

if ~bdIsLoaded('ot_security_demo')
    if isfile(fullfile(here,'ot_security_demo.slx')), load_system('ot_security_demo');
    else, ot_build_demo(false); end
end
print('-sot_security_demo','-dpng','-r130', fullfile(outdir,'fig_simulink.png'));
disp('snapshots saved: fig_live.png, fig_simulink.png');
end

function s = evt(r,k)
if r.gap(k),       s = 'Forlorad telemetri';
elseif r.resid(k), s = 'Brutet fysiskt samband';
elseif r.sp(k),    s = 'Borvardesavvikelse';
else,              s = 'Multivariat avvikelse';
end
end
