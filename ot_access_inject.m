function alog = ot_access_inject(alog)
%OT_ACCESS_INJECT Add four confidentiality incidents to a normal access log.
%  Every injected event uses a VALID account and normal OT values - the only
%  abnormal thing is the access behaviour (who/when/where/how much).
acfg = alog.Properties.UserData;
t0 = acfg.t0;

ev = {};  % {time, user, role, loc, resource, action, vol, label, typeName}

% 1) INSIDER MISUSE - operator pulls a bulk historian dump at 03:xx (own data,
%    but wrong time and ~40x normal volume).
ev(end+1,:) = {t0+days(4)+hours(3)+minutes(8),  "anna.op","Operator", ...
    "Kontrollrum-LAN","Historian","read", 360, 1,"Insidermissbruk"};
ev(end+1,:) = {t0+days(4)+hours(3)+minutes(26), "anna.op","Operator", ...
    "Kontrollrum-LAN","Historian","read", 410, 1,"Insidermissbruk"};

% 2) STOLEN CREDENTIALS - engineer account logs in from an unknown foreign IP
%    at 02:40 (valid account, novel location + off-hours).
ev(end+1,:) = {t0+days(5)+hours(2)+minutes(40), "cecilia.eng","Ingenjor", ...
    "Okand-IP (utland)","EngWorkstation","read", 12, 2,"Stulna inloggningsuppgifter"};
ev(end+1,:) = {t0+days(5)+hours(2)+minutes(52), "cecilia.eng","Ingenjor", ...
    "Okand-IP (utland)","PLC_Config","read", 18, 2,"Stulna inloggningsuppgifter"};

% 3) DATA EXFILTRATION - finance account exports the entire customer DB
%    (valid account, valid resource, but export + ~50x normal volume).
ev(end+1,:) = {t0+days(5)+hours(14)+minutes(5),  "eva.eko","Ekonomi", ...
    "Kontor-LAN","Kund_DB","export", 720, 3,"Dataexfiltrering"};
ev(end+1,:) = {t0+days(5)+hours(14)+minutes(33), "eva.eko","Ekonomi", ...
    "Kontor-LAN","Faktura_DB","export", 540, 3,"Dataexfiltrering"};

% 4) PRIVILEGE ABUSE - IT-admin account reconfigures a PLC it should never
%    touch (resource outside role + config action).
ev(end+1,:) = {t0+days(6)+hours(11)+minutes(20), "david.it","IT-admin", ...
    "Kontor-LAN","PLC_Config","config", 25, 4,"Privilegiemissbruk"};
ev(end+1,:) = {t0+days(6)+hours(11)+minutes(41), "david.it","IT-admin", ...
    "Kontor-LAN","EngWorkstation","config", 30, 4,"Privilegiemissbruk"};

add = cell2table(ev,'VariableNames', ...
    {'time','user','role','loc','resource','action','vol','label','typeName'});
add.user=string(add.user); add.role=string(add.role); add.loc=string(add.loc);
add.resource=string(add.resource); add.action=string(add.action);
add.typeName=string(add.typeName);

alog = [alog(:,1:9); add];
alog = sortrows(alog,'time');
alog.Properties.UserData = acfg;
end
