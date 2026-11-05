function res = ot_detect(data)
%OT_DETECT Baseline-learning anomaly detector + physics-residual checks.
%  Learns normal behaviour from the clean training window, then flags
%  multivariate outliers (Mahalanobis), broken physical relationships, and
%  lost telemetry. Base MATLAB only.
S = data.cfg; N = data.N;
X = [data.Tsupply, data.Treturn, data.flow, data.pump, data.press, ...
     data.Tsupply - data.Treturn];

% Availability / telemetry-gap detector
gap = any(isnan(X),2);

% Impute gaps for the statistical model (carry forward/back)
Xf = fillmissing(X,'previous'); Xf = fillmissing(Xf,'next');

tr = 1:round(S.train_frac*N);
mu = mean(Xf(tr,:));
C  = cov(Xf(tr,:)) + 1e-6*eye(size(Xf,2));
L  = chol(C,'lower');
sol = (L \ (Xf - mu).').';          % whitened residuals
d2  = sum(sol.^2, 2);               % Mahalanobis^2
thr = localQuantile(d2(tr), S.alarm_quantile);
maha_alarm = d2 > thr;

% Physics residual: return temp should track supply - design delta
resid = data.Treturn - (data.Tsupply - S.dT_design);
rmu = mean(resid(tr),'omitnan'); rstd = std(resid(tr),'omitnan');
resid_alarm = abs(resid - rmu) > S.resid_k*rstd;

% Setpoint residual: supply should follow its setpoint
sres = data.Tsupply - data.Tsp;
smu = mean(sres(tr),'omitnan'); sstd = std(sres(tr),'omitnan');
sp_alarm = abs(sres - smu) > S.resid_k*sstd;

alarm = gap | maha_alarm | resid_alarm | sp_alarm;
alarm(isnan(alarm)) = true;

res.d2 = d2; res.thr = thr; res.alarm = alarm; res.gap = gap;
res.maha = maha_alarm; res.resid = resid_alarm; res.sp = sp_alarm;
res.events = groupEvents(alarm, d2, gap, resid_alarm, sp_alarm, data);

% Detection quality vs ground truth
lab = data.labels > 0;
res.tp = sum(alarm & lab);  res.fp = sum(alarm & ~lab);
res.fn = sum(~alarm & lab); res.tn = sum(~alarm & ~lab);
res.precision = res.tp / max(1, res.tp + res.fp);
res.recall    = res.tp / max(1, res.tp + res.fn);
res.f1 = 2*res.precision*res.recall / max(eps, res.precision + res.recall);
end

% ---- local helpers (no toolbox required) ----
function q = localQuantile(x, p)
x = sort(x(~isnan(x)));
if isempty(x), q = Inf; return; end
n = numel(x);
pos = max(1, min(n, p*(n-1)+1));
lo = floor(pos); hi = ceil(pos);
q = x(lo) + (pos-lo)*(x(hi)-x(lo));
end

function E = groupEvents(alarm, d2, gap, resid_alarm, sp_alarm, data)
E = struct('i0',{},'i1',{},'peak',{},'dominant',{},'duration_min',{});
a = alarm(:); i = 1; n = numel(a); minGap = 6;   % bridge gaps <= 30 min
while i <= n
    if a(i)
        j = i;
        k = i;
        while k <= n && (any(a(k:min(n,k+minGap))))
            if a(k), j = k; end
            k = k + 1;
        end
        seg = i:j;
        [pk,~] = max(d2(seg));
        if any(gap(seg)),            dom = "Lost telemetry (availability)";
        elseif any(resid_alarm(seg)),dom = "Broken physical relationship";
        elseif any(sp_alarm(seg)),   dom = "Setpoint deviation";
        else,                        dom = "Multivariate outlier";
        end
        E(end+1) = struct('i0',i,'i1',j,'peak',pk,'dominant',dom, ...
            'duration_min', (j-i+1)*data.dt_min); %#ok<AGROW>
        i = j + 1;
    else
        i = i + 1;
    end
end
end
