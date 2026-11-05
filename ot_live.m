function ot_live(speed)
%OT_LIVE Animated LIVE playback of attack + detection (for live demos).
%  Plays district-heating telemetry forward in time and raises alarms as
%  attacks unfold, with a running incident log. Usage: ot_live  or  ot_live(3)
if nargin < 1, speed = 1; end
here = fileparts(mfilename('fullpath')); addpath(here);
cfg = ot_config(); d = ot_simulate(cfg); d = ot_inject_attacks(d); r = ot_detect(d);
N = d.N; x = d.t;                       % numeric time in hours (animatedline-safe)
ts = @(k) char(string(d.time(k), 'yyyy-MM-dd HH:mm'));

f = figure('Name','OT Security Monitor - LIVE','Color','w','Position',[60 70 1200 660]);
tl = tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
title(tl,'OT Security Monitor - LIVE (fjarrvarme)','FontWeight','bold');

axS = nexttile(tl); hold(axS,'on'); grid(axS,'on'); ylabel(axS,'\circC');
title(axS,'Framledningstemp vs borvarde'); xlim(axS,[x(1) x(end)]); ylim(axS,[60 120]);
axA = nexttile(tl); hold(axA,'on'); grid(axA,'on'); set(axA,'YScale','log');
ylabel(axA,'Anomali-score'); xlim(axA,[x(1) x(end)]); ylim(axA,[0.1 1e6]);
xlabel(axA,'Tid (timmar)'); yline(axA, r.thr, '--', 'Larmtroskel','Color',[0.85 0.1 0.1]);
axL = nexttile(tl); axis(axL,'off');
status = text(axL,0.01,0.85,'STATUS: NORMAL','FontSize',15,'FontWeight','bold', ...
    'Color',[0.1 0.5 0.2],'Units','normalized');
logTxt = text(axL,0.01,0.62,'','FontSize',9,'VerticalAlignment','top', ...
    'FontName','Consolas','Units','normalized');

lnS  = animatedline(axS,'Color',[0 0.45 0.74],'LineWidth',1.1);
lnSp = animatedline(axS,'Color',[0.85 0.4 0.1],'LineWidth',1.0);
lnA  = animatedline(axA,'Color',[0 0.45 0.74],'LineWidth',1.0);
legend(axS,[lnS lnSp],{'Framledning','Borvarde'},'Location','northwest','FontSize',8);

logLines = strings(0,1); inAlarm = false; step = max(1,round(4/speed));
for k = 1:step:N
    addpoints(lnS, x(k), d.Tsupply(k));
    addpoints(lnSp, x(k), d.Tsp(k));
    addpoints(lnA, x(k), max(r.d2(k),1e-3));
    if r.alarm(k)
        status.String = ['STATUS: LARM  ' ts(k)]; status.Color = [0.80 0 0];
        if ~inAlarm
            logLines(end+1) = string([ts(k) '   LARM: ' eventType(r,k)]); %#ok<AGROW>
            logTxt.String = strjoin(logLines(max(1,end-8):end), newline);
            plot(axA, x(k), max(r.d2(k),1e-3), 'ro','MarkerFaceColor','r');
            inAlarm = true;
        end
    else
        status.String = ['STATUS: NORMAL  ' ts(k)]; status.Color = [0.1 0.5 0.2];
        inAlarm = false;
    end
    drawnow limitrate; pause(0.01/speed);
end
status.String = 'STATUS: KLAR - uppspelning slutford'; status.Color = [0 0 0];
end

function s = eventType(r,k)
if r.gap(k),        s = 'Forlorad telemetri (tillganglighet)';
elseif r.resid(k),  s = 'Brutet fysiskt samband (givarforfalskning)';
elseif r.sp(k),     s = 'Borvardesavvikelse (command injection)';
else,               s = 'Multivariat avvikelse';
end
end
