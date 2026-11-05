function out = runAccessDemo()
%RUNACCESSDEMO Confidentiality / insider-threat (UEBA) demo - end to end.
%  Companion to runDemo: same OT plant, but here the values are normal and
%  the threat is unauthorised ACCESS to data. Base MATLAB only.
here = fileparts(mfilename('fullpath')); addpath(here);
acfg = ot_access_config();
alog = ot_access_sim(acfg);
alog = ot_access_inject(alog);
res  = ot_ueba(alog);
outdir = fullfile(here,'output'); if ~isfolder(outdir), mkdir(outdir); end
rep  = ot_access_report(alog, res, outdir);

fprintf('\n==== UEBA / konfidentialitet - sammanfattning ====\n');
fprintf('Atkomsthandelser : %d (%d konton, %d dygn)\n', height(alog), ...
        numel(unique(alog.user)), acfg.days);
fprintf('Injicerade incidenter : %d  (%d handelser)\n', ...
        numel(unique(alog.typeName(alog.label>0))), nnz(alog.label>0));
fprintf('UEBA-larm : %d   Recall %.0f%% | Precision %.0f%% | F1 %.2f\n', ...
        nnz(res.alarm), 100*res.recall, 100*res.precision, res.f1);
disp(res.events);
fprintf('Figurer  : fig_access_timeline.png, fig_ueba_scores.png, fig_access_matrix.png\n');
fprintf('Rapport  : %s\n\n', rep.html);

out.alog=alog; out.res=res; out.rep=rep;
if nargout==0, clear out; end
end
