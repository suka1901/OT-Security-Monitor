function res = ot_ueba(alog)
%OT_UEBA User & Entity Behaviour Analytics for the access log.
%  Learns each account's normal behaviour from a clean baseline window, then
%  scores every access by how far it deviates (Mahalanobis distance on
%  behavioural features) augmented with novelty penalties for unseen
%  location / out-of-role resource. Flagged events are classified into the
%  four confidentiality threat types. Base MATLAB only.
acfg = alog.Properties.UserData;
n = height(alog);
t0 = acfg.t0;

% --- raw behavioural quantities -----------------------------------------
hr   = hour(alog.time) + minute(alog.time)/60;          % hour-of-day
lv   = log1p(alog.vol);                                  % volume (log)
sens = arrayfun(@(a) acfg.act_sens.(char(a)), alog.action);  % action weight

% --- baseline (clean) window --------------------------------------------
tcut = t0 + days(acfg.train_frac*acfg.days);
base = alog.time < tcut & alog.label==0;

% per-user volume baseline, known locations, in-role resources, work hours
zvol    = zeros(n,1); offh = false(n,1);
locNov  = false(n,1); resNov = false(n,1);
gLv = mean(lv(base)); gSd = std(lv(base));
users = unique(alog.user,'stable');
for i = 1:numel(users)
    u  = users(i);
    ui = alog.user==u;
    bi = ui & base;
    if nnz(bi) >= 3, mu=mean(lv(bi)); sd=std(lv(bi)); else, mu=gLv; sd=gSd; end
    if sd < 1e-3, sd = max(gSd,1e-3); end
    zvol(ui) = (lv(ui)-mu)/sd;

    knownLoc = unique(alog.loc(bi));
    locNov(ui) = ~ismember(alog.loc(ui), knownLoc);

    uc = userCfg(acfg,u);
    if ~isempty(uc)
        resNov(ui) = ~ismember(alog.resource(ui), uc.res);
        offh(ui)   = hr(ui) < (uc.h0-1) | hr(ui) > (uc.h1+1);
    end
end

% --- Mahalanobis on continuous behaviour features -----------------------
F = [sin(2*pi*hr/24), cos(2*pi*hr/24), zvol, sens];
mu = mean(F(base,:));
C  = cov(F(base,:)) + 1e-6*eye(size(F,2));
L  = chol(C,'lower');
w  = (L \ (F-mu).').';
d2c = sum(w.^2,2);

% --- augment with novelty penalties (unseen location / out-of-role) -----
Wloc = 30; Wres = 25;
d2 = d2c + Wloc*locNov + Wres*resNov;

thr = max(acfg.score_floor, localQuantile(d2(base), acfg.alarm_quantile));
alarm = d2 > thr;

% --- classify each flagged event into a threat type ---------------------
pred = repmat("",n,1);
for k = find(alarm).'
    if locNov(k)
        pred(k) = "Stulna inloggningsuppgifter";
    elseif resNov(k) && sens(k) >= 4
        pred(k) = "Privilegiemissbruk";
    elseif alog.action(k)=="export" && zvol(k) >= 3
        pred(k) = "Dataexfiltrering";
    elseif offh(k) && zvol(k) >= 3
        pred(k) = "Insidermissbruk";
    elseif resNov(k)
        pred(k) = "Privilegiemissbruk";
    else
        pred(k) = "Avvikande beteende";
    end
end

% --- detection quality vs ground truth ----------------------------------
lab = alog.label > 0;
tp = nnz(alarm & lab); fp = nnz(alarm & ~lab);
fn = nnz(~alarm & lab); tn = nnz(~alarm & ~lab);

res.hr=hr; res.zvol=zvol; res.sens=sens; res.offh=offh;
res.locNov=locNov; res.resNov=resNov;
res.d2=d2; res.d2c=d2c; res.thr=thr; res.alarm=alarm; res.pred=pred;
res.tp=tp; res.fp=fp; res.fn=fn; res.tn=tn;
res.precision = tp/max(1,tp+fp);
res.recall    = tp/max(1,tp+fn);
res.f1 = 2*res.precision*res.recall/max(eps,res.precision+res.recall);

% list of flagged events (table)
idx = find(alarm);
res.events = table(alog.time(idx),alog.user(idx),alog.resource(idx), ...
    alog.action(idx),round(alog.vol(idx)),round(d2(idx),1),pred(idx), ...
    alog.typeName(idx), ...
    'VariableNames',{'time','user','resource','action','volMB','score','predType','truth'});
end

% ---- local helpers (no toolbox) ----
function uc = userCfg(acfg,u)
uc = [];
for j = 1:numel(acfg.users)
    if acfg.users(j).user == u, uc = acfg.users(j); return; end
end
end

function q = localQuantile(x,p)
x = sort(x(~isnan(x)));
if isempty(x), q = Inf; return; end
nn = numel(x); pos = max(1,min(nn,p*(nn-1)+1));
lo=floor(pos); hi=ceil(pos); q = x(lo)+(pos-lo)*(x(hi)-x(lo));
end
