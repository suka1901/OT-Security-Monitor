function acfg = ot_access_config()
%OT_ACCESS_CONFIG Parameters for the access-log / UEBA demo (confidentiality).
%  Models "normal values in the wrong hands": legitimate-looking access that
%  is abnormal in WHO / WHEN / WHERE / HOW MUCH rather than in the OT values.
acfg.seed       = 7;
acfg.days       = 7;                       % same horizon as telemetry demo
acfg.t0         = datetime(2026,1,12,0,0,0);
acfg.train_frac = 0.45;                     % first 45% of days = clean baseline
acfg.alarm_quantile = 0.995;               % UEBA score threshold (train quantile)
acfg.score_floor    = 3.0;                  % minimum d2 to ever raise an alarm

% Users: who they are, their role, home location(s), active hours, normal load
%        and the set of resources their role legitimately touches.
U = struct('user',{},'role',{},'loc',{},'h0',{},'h1',{}, ...
           'nday',{},'vmean',{},'res',{});
U(1) = mk("anna.op","Operator","Kontrollrum-LAN",6,22,9,8, ...
          ["HMI_SCADA","Historian"]);
U(2) = mk("bo.op","Operator","Kontrollrum-LAN",6,22,9,8, ...
          ["HMI_SCADA","Historian"]);
U(3) = mk("cecilia.eng","Ingenjor","Kontor-LAN",8,17,6,30, ...
          ["EngWorkstation","PLC_Config","Historian","Natdiagram"]);
U(4) = mk("david.it","IT-admin","Kontor-LAN",8,18,7,40, ...
          ["AD_Directory","Backup","Servrar"]);
U(5) = mk("eva.eko","Ekonomi","Kontor-LAN",8,17,8,15, ...
          ["Faktura_DB","Kund_DB"]);
U(6) = mk("frank.vendor","Leverantor","VPN-Leverantor",10,12,1,12, ...
          ["EngWorkstation","PLC_Config"]);   % only in booked windows
acfg.users = U;

% All resources, ordered (rows of the access heatmap). Sensitivity 1..4.
acfg.resources = ["HMI_SCADA","Historian","EngWorkstation","PLC_Config", ...
                  "Natdiagram","AD_Directory","Backup","Servrar", ...
                  "Faktura_DB","Kund_DB"];
acfg.res_sens  = [   1,          2,          3,             4, ...
                     3,          3,          3,         2, ...
                     2,          2];
% Action sensitivity weights
acfg.act_sens.read   = 1;
acfg.act_sens.export = 3;
acfg.act_sens.config = 4;
end

function s = mk(user,role,loc,h0,h1,nday,vmean,res)
s.user=user; s.role=role; s.loc=loc; s.h0=h0; s.h1=h1;
s.nday=nday; s.vmean=vmean; s.res=res;
end
